"""Layanan AI NotaCerdas.

Pipeline: gambar -> (YOLO11n best.pt, opsional) crop struk -> OpenCV preprocessing
-> Tesseract OCR -> Regex (merchant, tanggal, total) -> klasifikasi kategori
(mnb_model.pkl, atau mode fallback berbasis kata kunci bila model tidak ada).
"""
from __future__ import annotations

import os
import re
import time
from datetime import date
from pathlib import Path

import numpy as np

try:
    import cv2
except ImportError:  # pragma: no cover
    cv2 = None
try:
    import pytesseract
except ImportError:  # pragma: no cover
    pytesseract = None

BASE_DIR = Path(__file__).resolve().parent
MODELS_DIR = Path(os.getenv("MODELS_DIR", BASE_DIR / "models_ai"))
CATEGORIES = ["Makan", "Transportasi", "Kebutuhan", "Lainnya"]
CONFIDENCE_THRESHOLD = float(os.getenv("CONFIDENCE_THRESHOLD", "0.60"))
TESSERACT_LANG = os.getenv("TESSERACT_LANG", "ind+eng")


# --------------------------------------------------------------------------- teks
def clean_text(text: str) -> str:
    """Preprocessing teks klasifikasi (HARUS sama dengan train_mnb_local.py & notebook)."""
    text = text.lower()
    text = re.sub(r"[^a-z\s]", " ", text)  # hapus angka & simbol
    return re.sub(r"\s+", " ", text).strip()


KEYWORDS = {
    "Makan": ["nasi", "ayam", "mie", "bakso", "kopi", "teh", "burger", "pizza", "resto", "warung",
              "kfc", "mcd", "starbucks", "soto", "sate", "bakery", "roti", "cafe", "boba", "jus"],
    "Transportasi": ["gojek", "grab", "bluebird", "bensin", "pertalite", "pertamax", "pertamina",
                     "shell", "tol", "parkir", "kereta", "kai", "krl", "mrt", "tiket", "taksi",
                     "bus", "transjakarta", "maxim", "bbm"],
    "Kebutuhan": ["indomaret", "alfamart", "alfamidi", "superindo", "hypermart", "sabun", "shampoo",
                  "beras", "minyak", "deterjen", "tisu", "apotek", "obat", "vitamin", "guardian",
                  "watsons", "listrik", "pulsa", "gula", "telur", "susu"],
    "Lainnya": ["bioskop", "cgv", "xxi", "netflix", "spotify", "game", "steam", "buku",
                "gramedia", "konser", "donasi", "hadiah", "kado", "salon", "gym", "hotel"],
}


def keyword_classify(text: str) -> tuple[str, float]:
    """Fallback tanpa model: skor kata kunci -> (kategori, confidence heuristik)."""
    tokens = clean_text(text).split()
    scores = {c: sum(1 for k in kws if k in tokens) for c, kws in KEYWORDS.items()}
    total = sum(scores.values())
    if total == 0:
        return "Lainnya", 0.25
    best = max(scores, key=scores.get)
    return best, round(scores[best] / total * 0.85, 4)


# ------------------------------------------------------------------------- parsing
MONTHS = {
    "jan": 1, "januari": 1, "feb": 2, "februari": 2, "mar": 3, "maret": 3, "apr": 4, "april": 4,
    "mei": 5, "may": 5, "jun": 6, "juni": 6, "jul": 7, "juli": 7, "agu": 8, "agt": 8, "agustus": 8,
    "aug": 8, "sep": 9, "sept": 9, "september": 9, "okt": 10, "oktober": 10, "oct": 10,
    "nov": 11, "november": 11, "des": 12, "desember": 12, "dec": 12,
}
KNOWN_MERCHANTS = [
    "INDOMARET", "ALFAMART", "ALFAMIDI", "SUPERINDO", "HYPERMART", "GIANT", "LOTTE MART",
    "TRANSMART", "GUARDIAN", "WATSONS", "KIMIA FARMA", "KFC", "MCDONALD", "STARBUCKS",
    "PIZZA HUT", "BURGER KING", "JANJI JIWA", "KOPI KENANGAN", "PERTAMINA", "SHELL", "BP",
    "CGV", "GRAMEDIA", "ACE HARDWARE", "INFORMA",
]
_TOTAL_KEYS = re.compile(
    r"(grand\s*total|total\s*(belanja|bayar|tagihan|harga)?|jumlah(\s*bayar)?|tagihan|amount\s*due)",
    re.I,
)
_SKIP_TOTAL = re.compile(r"(sub\s*total|kembali|kembalian|change|ppn|pajak|tax|diskon|disc|hemat|tunai|cash|debit|kartu|card)", re.I)
_AMOUNT = re.compile(r"(?<![\d.,])(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+|\d{3,9})(?:[.,]\d{2})?(?![\d])", re.I)


def parse_amount(token: str) -> int | None:
    """'45.500' / '45,500' / '45500' -> 45500 (ribuan dengan pemisah titik/koma)."""
    digits = re.sub(r"[.,\s]", "", token)
    if not digits.isdigit():
        return None
    value = int(digits)
    return value if 100 <= value <= 1_000_000_000 else None


def _amounts_in(line: str) -> list[int]:
    out = []
    for m in _AMOUNT.finditer(line):
        v = parse_amount(m.group(1))
        if v is not None:
            out.append(v)
    return out


def extract_total(text: str) -> int | None:
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    # 1) baris dengan kata kunci total (prioritas, yang terakhir menang), kecuali subtotal/kembalian
    for i in range(len(lines) - 1, -1, -1):
        line = lines[i]
        if _TOTAL_KEYS.search(line) and not _SKIP_TOTAL.search(line):
            amts = _amounts_in(line)
            if not amts and i + 1 < len(lines):  # nilai di baris berikutnya
                amts = _amounts_in(lines[i + 1])
            if amts:
                return max(amts)
    # 2) fallback: nominal terbesar di struk
    allamts = [a for l in lines if not _SKIP_TOTAL.search(l) for a in _amounts_in(l)]
    return max(allamts) if allamts else None


def _valid_date(y: int, m: int, d: int) -> str | None:
    if y < 100:
        y += 2000
    try:
        dt = date(y, m, d)
    except ValueError:
        return None
    if dt.year < 2000 or dt > date.today().replace(year=date.today().year + 1):
        return None
    return dt.isoformat()


def extract_date(text: str) -> str | None:
    m = re.search(r"\b(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})\b", text)  # YYYY-MM-DD
    if m and (r := _valid_date(int(m[1]), int(m[2]), int(m[3]))):
        return r
    m = re.search(r"\b(\d{1,2})\s+([A-Za-z]{3,9})\.?,?\s+(\d{2,4})\b", text)  # 25 Nov 2026
    if m and m[2].lower() in MONTHS and (r := _valid_date(int(m[3]), MONTHS[m[2].lower()], int(m[1]))):
        return r
    m = re.search(r"\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})\b", text)  # DD/MM/YYYY
    if m and (r := _valid_date(int(m[3]), int(m[2]), int(m[1]))):
        return r
    return None


def extract_merchant(text: str) -> str | None:
    upper = text.upper()
    for name in KNOWN_MERCHANTS:
        if re.search(rf"\b{re.escape(name)}", upper):
            return name
    for line in text.splitlines()[:6]:
        line = line.strip()
        letters = re.sub(r"[^A-Za-z ]", "", line).strip()
        if len(letters) >= 3 and not re.search(r"(struk|nota|invoice|kasir|tanggal|jl\.?|telp|npwp)", line, re.I):
            return line.upper()[:60]
    return None


# --------------------------------------------------------------------------- service
class AIService:
    def __init__(self) -> None:
        self.yolo = None
        self.classifier = None
        self.detector_mode = "none"
        self.classifier_mode = "keyword_fallback"
        self._load()

    # -- loading -----------------------------------------------------------------
    def _load(self) -> None:
        mnb = MODELS_DIR / "mnb_model.pkl"
        if mnb.exists():
            try:
                import joblib

                self.classifier = joblib.load(mnb)
                self.classifier_mode = "ml"
            except Exception as exc:  # model rusak -> tetap jalan dengan fallback
                print(f"[ai_service] gagal memuat mnb_model.pkl: {exc}")
        best = MODELS_DIR / "best.pt"
        if best.exists():
            try:
                from ultralytics import YOLO

                self.yolo = YOLO(str(best))
                self.detector_mode = "yolo"
            except Exception as exc:
                print(f"[ai_service] YOLO tidak dapat dimuat ({exc}); memakai heuristik OpenCV")
        if self.yolo is None:
            self.detector_mode = "opencv_heuristic"

    def status(self) -> dict:
        return {
            "classifier_mode": self.classifier_mode,
            "detector_mode": self.detector_mode,
            "ocr_available": self.ocr_available(),
        }

    @staticmethod
    def ocr_available() -> bool:
        if pytesseract is None or cv2 is None:
            return False
        try:
            pytesseract.get_tesseract_version()
            return True
        except Exception:
            return False

    # -- klasifikasi -------------------------------------------------------------
    def classify(self, text: str) -> tuple[str, float, str]:
        """Return (kategori, confidence, mode)."""
        cleaned = clean_text(text)
        if self.classifier is not None and cleaned:
            proba = self.classifier.predict_proba([cleaned])[0]
            idx = int(np.argmax(proba))
            return str(self.classifier.classes_[idx]), float(round(proba[idx], 4)), "ml"
        cat, conf = keyword_classify(text)
        return cat, conf, "keyword_fallback"

    # -- visi --------------------------------------------------------------------
    def _detect_and_crop(self, img: "np.ndarray") -> tuple["np.ndarray", bool]:
        """Return (gambar yang di-OCR, receipt_terdeteksi_oleh_detektor)."""
        if self.yolo is not None:
            res = self.yolo.predict(img, conf=0.25, verbose=False)[0]
            if res.boxes is not None and len(res.boxes) > 0:
                boxes = res.boxes.xyxy.cpu().numpy()
                areas = (boxes[:, 2] - boxes[:, 0]) * (boxes[:, 3] - boxes[:, 1])
                x1, y1, x2, y2 = boxes[int(np.argmax(areas))].astype(int)
                pad = 10
                h, w = img.shape[:2]
                crop = img[max(y1 - pad, 0):min(y2 + pad, h), max(x1 - pad, 0):min(x2 + pad, w)]
                if crop.size:
                    return crop, True
            return img, False
        return img, True  # tanpa YOLO: keputusan diambil dari isi hasil OCR

    @staticmethod
    def _preprocess(img: "np.ndarray") -> "np.ndarray":
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if img.ndim == 3 else img
        h, w = gray.shape[:2]
        if w < 1000:  # perbesar gambar kecil agar OCR lebih akurat
            scale = 1000 / w
            gray = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
        gray = cv2.fastNlMeansDenoising(gray, None, 10, 7, 21)
        return cv2.adaptiveThreshold(
            gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 31, 15
        )

    def ocr(self, img: "np.ndarray") -> str:
        proc = self._preprocess(img)
        try:
            return pytesseract.image_to_string(proc, lang=TESSERACT_LANG, config="--psm 6")
        except pytesseract.TesseractError:  # paket bahasa 'ind' belum terpasang
            return pytesseract.image_to_string(proc, lang="eng", config="--psm 6")

    # -- end to end --------------------------------------------------------------
    def scan_receipt(self, image_bytes: bytes) -> dict:
        t0 = time.perf_counter()
        if cv2 is None or pytesseract is None:
            raise RuntimeError("OpenCV / pytesseract belum terpasang")
        img = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("File bukan gambar yang valid")

        crop, detected_by_model = self._detect_and_crop(img)
        text = self.ocr(crop) if detected_by_model else ""
        total, tdate, merchant = extract_total(text), extract_date(text), extract_merchant(text)

        # Heuristik tanpa YOLO: dianggap struk jika ada nominal dan teks cukup panjang.
        receipt_detected = detected_by_model and (
            self.yolo is not None or (total is not None and len(text.strip()) >= 15)
        )
        elapsed = int((time.perf_counter() - t0) * 1000)
        base = {
            "status": "success",
            "receipt_detected": bool(receipt_detected),
            "merchant_name": None,
            "purchased_at": None,
            "total_rupiah": None,
            "suggested_category": None,
            "category_confidence": None,
            "needs_review": True,
            "classifier_mode": self.classifier_mode,
            "processing_ms": elapsed,
            "raw_ocr_text": text,
        }
        if not receipt_detected:
            return base

        category, conf, mode = self.classify(f"{merchant or ''} {text}")
        needs_review = (
            conf < CONFIDENCE_THRESHOLD or total is None or tdate is None or merchant is None
        )
        base.update(
            merchant_name=merchant,
            purchased_at=tdate,
            total_rupiah=total,
            suggested_category=category,
            category_confidence=conf,
            needs_review=bool(needs_review),
            classifier_mode=mode,
            processing_ms=int((time.perf_counter() - t0) * 1000),
        )
        return base


_service: AIService | None = None


def get_ai_service() -> AIService:
    global _service
    if _service is None:
        _service = AIService()
    return _service


def reload_ai_service() -> AIService:
    global _service
    _service = AIService()
    return _service
