import re
from datetime import date, datetime
from io import BytesIO

from PIL import Image, ImageOps, ImageEnhance
import pytesseract
from pytesseract import TesseractNotFoundError, TesseractError

from app.core.config import settings
from app.services.classifier import classify_text


TOTAL_MARKERS = (
    "grand total", "total belanja", "total bayar", "total", "jumlah bayar",
    "jumlah", "tagihan", "amount due", "nett", "netto", "harus dibayar",
)
RECEIPT_MARKERS = (
    "total", "subtotal", "kasir", "cashier", "qty", "struk", "receipt",
    "invoice", "tunai", "kembali", "terima kasih", "thank you", "item",
)
AMOUNT_PATTERN = re.compile(
    r"(?<!\d)(?:\d{1,3}(?:[.,]\d{3})+|\d{4,})(?!\d)"
)


def _prepare_image(image_bytes: bytes) -> Image.Image:
    image = Image.open(BytesIO(image_bytes))
    image = ImageOps.exif_transpose(image).convert("RGB")

    # OCR lebih stabil pada gambar grayscale dengan kontras yang diperbaiki.
    image = ImageOps.grayscale(image)
    image = ImageOps.autocontrast(image)
    image = ImageEnhance.Contrast(image).enhance(1.25)

    if image.width < 1500:
        scale = min(2.0, 1500 / max(image.width, 1))
        image = image.resize(
            (int(image.width * scale), int(image.height * scale)),
            Image.Resampling.LANCZOS,
        )
    return image


def _run_ocr(image: Image.Image) -> str:
    try:
        available_languages = pytesseract.get_languages(config="")
        language = "ind+eng" if "ind" in available_languages else "eng"
        return pytesseract.image_to_string(
            image,
            lang=language,
            config="--oem 3 --psm 6",
            timeout=settings.ocr_timeout_seconds,
        )
    except (TesseractNotFoundError, TesseractError, RuntimeError, OSError):
        # API tetap mengembalikan hasil yang bisa dikonfirmasi manual jika OCR belum siap.
        return ""


def _parse_amount(token: str) -> int:
    value = re.sub(r"(?i)rp|idr|[^0-9.,]", "", token)
    if not value:
        return 0

    if "." in value and "," in value:
        # Format Indonesia: 1.234.567,00
        if value.rfind(",") > value.rfind("."):
            value = value.replace(".", "").split(",")[0]
        else:
            value = value.replace(",", "").split(".")[0]
    elif "." in value or "," in value:
        separator = "." if "." in value else ","
        parts = value.split(separator)
        if len(parts[-1]) == 3:
            value = "".join(parts)
        else:
            value = "".join(parts[:-1]) or "0"
    digits = re.sub(r"\D", "", value)
    try:
        return int(digits) if digits else 0
    except ValueError:
        return 0


def _extract_total(text: str) -> int:
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    candidates: list[tuple[int, int]] = []

    for index, line in enumerate(lines):
        lowered = line.lower()
        marker_found = any(marker in lowered for marker in TOTAL_MARKERS)
        if not marker_found and index > 0:
            marker_found = any(
                marker in lines[index - 1].lower() for marker in TOTAL_MARKERS
            )

        if marker_found:
            amounts = [_parse_amount(match.group(0)) for match in AMOUNT_PATTERN.finditer(line)]
            amounts = [amount for amount in amounts if amount > 0]
            if not amounts and index + 1 < len(lines):
                amounts = [
                    _parse_amount(match.group(0))
                    for match in AMOUNT_PATTERN.finditer(lines[index + 1])
                ]
                amounts = [amount for amount in amounts if amount > 0]
            if amounts:
                # Nilai terbesar pada baris total umumnya merupakan nilai akhir pembayaran.
                candidates.append((3 if "grand total" in lowered else 2, max(amounts)))

    if not candidates:
        return 0

    candidates.sort(key=lambda item: (item[0], item[1]), reverse=True)
    return candidates[0][1]


def _extract_date(text: str) -> date | None:
    patterns = [
        (re.compile(r"\b(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})\b"), "%Y-%m-%d", "ymd"),
        (re.compile(r"\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})\b"), None, "dmy"),
    ]

    for regex, fmt, kind in patterns:
        match = regex.search(text)
        if not match:
            continue
        try:
            if kind == "ymd":
                year, month, day = map(int, match.groups())
            else:
                day, month, year = map(int, match.groups())
                if year < 100:
                    year += 2000
            return date(year, month, day)
        except ValueError:
            continue

    month_names = {
        "jan": 1, "januari": 1, "feb": 2, "februari": 2,
        "mar": 3, "maret": 3, "apr": 4, "april": 4,
        "mei": 5, "may": 5, "jun": 6, "juni": 6,
        "jul": 7, "juli": 7, "agu": 8, "agustus": 8,
        "sep": 9, "september": 9, "okt": 10, "oktober": 10,
        "nov": 11, "november": 11, "des": 12, "desember": 12,
    }
    month_pattern = re.compile(
        r"\b(\d{1,2})\s+([A-Za-z]+)\s+(20\d{2})\b",
        re.IGNORECASE,
    )
    match = month_pattern.search(text)
    if match:
        day = int(match.group(1))
        month = month_names.get(match.group(2).lower())
        year = int(match.group(3))
        if month:
            try:
                return date(year, month, day)
            except ValueError:
                pass
    return None


def _extract_merchant(text: str) -> str:
    ignored = (
        "struk", "receipt", "invoice", "nota", "no telp", "telp",
        "tanggal", "date", "kasir", "cashier", "alamat", "address",
        "npwp", "customer", "terima kasih", "thank you",
    )
    for raw_line in text.splitlines()[:8]:
        line = re.sub(r"\s+", " ", raw_line).strip(" :-|")
        lowered = line.lower()
        if len(line) < 3 or any(term in lowered for term in ignored):
            continue
        if sum(character.isalpha() for character in line) < 3:
            continue
        return line[:200]
    return ""


def process_receipt(image_bytes: bytes) -> dict:
    image = _prepare_image(image_bytes)
    raw_text = _run_ocr(image).strip()
    merchant = _extract_merchant(raw_text)
    purchased_at = _extract_date(raw_text)
    total = _extract_total(raw_text)

    lowered = raw_text.lower()
    marker_count = sum(1 for marker in RECEIPT_MARKERS if marker in lowered)
    has_receipt_content = len(raw_text) >= 20 and (
        marker_count > 0 or (len(re.findall(r"\d", raw_text)) >= 6)
    )

    classification = classify_text(merchant, raw_text)
    needs_review = (
        not has_receipt_content
        or not merchant
        or purchased_at is None
        or total <= 0
        or classification["category_confidence"] < 0.60
    )

    return {
        "status": "success" if has_receipt_content else "needs_review",
        "receipt_detected": has_receipt_content,
        "merchant_name": merchant,
        "purchased_at": purchased_at.isoformat() if purchased_at else None,
        "total_rupiah": total,
        "suggested_category": classification["suggested_category"],
        "category_confidence": classification["category_confidence"],
        "needs_review": needs_review,
        "classifier_mode": classification["classifier_mode"],
        "raw_ocr_text": raw_text[:12000],
    }
