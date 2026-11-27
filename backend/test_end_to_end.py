"""Uji end-to-end NotaCerdas: DB, Auth, CRUD, Dashboard, dan klasifikasi AI.

Jalankan:  python test_end_to_end.py
Memakai database sementara (tidak menyentuh notacerdas.db) dan FastAPI TestClient,
jadi server tidak perlu dinyalakan. Exit code 0 jika semua lolos.
"""
import os
import sys
import tempfile
from pathlib import Path

# DB sementara & JWT secret khusus test, ditetapkan SEBELUM modul aplikasi diimpor.
_tmp = tempfile.mkdtemp(prefix="notacerdas_test_")
os.environ["DB_PATH"] = str(Path(_tmp) / "test.db")
os.environ["JWT_SECRET"] = "test-secret"
os.environ["SEED_DEMO"] = "true"

BASE = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE))

PASSED, FAILED, SKIPPED = [], [], []


def check(name: str, cond: bool, detail: str = "") -> None:
    (PASSED if cond else FAILED).append(name)
    print(f"  [{'OK' if cond else 'GAGAL'}] {name}" + (f"  -> {detail}" if detail else ""))


def section(title: str) -> None:
    print(f"\n=== {title} ===")


def make_receipt_image() -> bytes:
    """Gambar struk sintetis (putih, teks hitam) untuk menguji OCR + regex."""
    import cv2
    import numpy as np

    img = np.full((520, 640, 3), 255, np.uint8)
    lines = [
        "INDOMARET", "JL MERDEKA NO 10", "25/11/2026 14:32",
        "SABUN MANDI    12.500", "SHAMPOO       20.000", "TISU          13.000",
        "TOTAL         45.500", "TUNAI         50.000", "KEMBALI        4.500",
    ]
    for i, line in enumerate(lines):
        cv2.putText(img, line, (30, 50 + i * 52), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 0, 0), 2, cv2.LINE_AA)
    ok, buf = cv2.imencode(".png", img)
    return buf.tobytes()


def main() -> int:
    # ------------------------------------------------------------------ model
    section("1. Model klasifikasi (mnb_model.pkl)")
    model_path = BASE / "models_ai" / "mnb_model.pkl"
    if not model_path.exists():
        print("  mnb_model.pkl belum ada -> melatih dulu...")
        import train_mnb_local

        train_mnb_local.train(verbose=False)
    check("mnb_model.pkl tersedia", model_path.exists())

    try:
        from fastapi.testclient import TestClient
    except ImportError as exc:
        print(f"\nFastAPI/httpx belum terpasang ({exc}). Jalankan: pip install -r requirements.txt")
        return 2

    import main as app_module

    with TestClient(app_module.app) as client:
        h = client.get("/health").json()
        check("Server hidup (/health)", h["status"] == "ok", str(h["ai"]))
        check("Mode klasifikasi = ml", h["ai"]["classifier_mode"] == "ml")

        # ------------------------------------------------------------- database
        section("2. Database & seed")
        demo = client.post("/api/auth/login", json={"email": "demo@notacerdas.id", "password": "demo12345"})
        check("User demo ter-seed & bisa login", demo.status_code == 200)
        demo_token = demo.json()["access_token"]
        dh = {"Authorization": f"Bearer {demo_token}"}
        cats = client.get("/api/categories", headers=dh).json()
        check("4 kategori ter-seed", [c["name"] for c in cats] == ["Makan", "Transportasi", "Kebutuhan", "Lainnya"], str(cats))
        month_now = __import__("datetime").date.today().strftime("%Y-%m")
        dash = client.get("/api/dashboard", params={"month": month_now}, headers=dh).json()
        check("Seeder demo menghasilkan transaksi", dash["jumlah_transaksi"] >= 1, f"{dash['jumlah_transaksi']} transaksi")

        # ----------------------------------------------------------------- auth
        section("3. Auth (bcrypt + JWT)")
        r = client.post("/api/auth/register", json={"name": "Budi", "email": "budi@example.com", "password": "rahasia123"})
        check("Register -> 201 + token", r.status_code == 201 and r.json().get("token_type") == "bearer", str(r.status_code))
        check("Register duplikat -> 409", client.post("/api/auth/register", json={"name": "Budi", "email": "budi@example.com", "password": "rahasia123"}).status_code == 409)
        r = client.post("/api/auth/login", json={"email": "budi@example.com", "password": "rahasia123"})
        check("Login benar -> 200", r.status_code == 200 and r.json()["user"]["email"] == "budi@example.com")
        token = r.json()["access_token"]
        H = {"Authorization": f"Bearer {token}"}
        check("Login password salah -> 401", client.post("/api/auth/login", json={"email": "budi@example.com", "password": "salah"}).status_code == 401)
        check("Tanpa token -> 401", client.get("/api/categories").status_code == 401)
        check("Token palsu -> 401", client.get("/api/categories", headers={"Authorization": "Bearer abc.def.ghi"}).status_code == 401)
        with app_module.get_conn() as conn:
            stored = conn.execute("SELECT password_hash FROM users WHERE email='budi@example.com'").fetchone()[0]
        check("Password tersimpan sebagai hash bcrypt", stored.startswith("$2") and "rahasia123" not in stored)

        # ------------------------------------------------------------------ CRUD
        section("4. CRUD transaksi")
        cat = {c["name"]: c["id"] for c in client.get("/api/categories", headers=H).json()}

        def payload(c, total, d, merchant="Toko", source="manual"):
            return {"category_id": cat[c], "merchant_name": merchant, "description": "uji",
                    "purchased_at": d, "total_rupiah": total, "source": source}

        a = client.post("/api/transactions", json=payload("Makan", 30000, "2026-10-05", "Warteg"), headers=H)
        b = client.post("/api/transactions", json=payload("Makan", 20000, "2026-10-12", "KFC", "scan"), headers=H)
        c = client.post("/api/transactions", json=payload("Transportasi", 50000, "2026-10-20", "Pertamina"), headers=H)
        d = client.post("/api/transactions", json=payload("Kebutuhan", 100000, "2026-11-02", "Indomaret"), headers=H)
        check("POST -> 201 (4 transaksi)", all(x.status_code == 201 for x in (a, b, c, d)))
        check("Response POST memuat category_name", a.json()["category_name"] == "Makan")
        check("Validasi: total <= 0 -> 422", client.post("/api/transactions", json=payload("Makan", 0, "2026-10-05"), headers=H).status_code == 422)
        check("Validasi: tanggal salah -> 422", client.post("/api/transactions", json=payload("Makan", 1000, "05-10-2026"), headers=H).status_code == 422)
        check("Validasi: source salah -> 422", client.post("/api/transactions", json={**payload("Makan", 1000, "2026-10-05"), "source": "x"}, headers=H).status_code == 422)
        check("Validasi: category_id tak ada -> 422", client.post("/api/transactions", json={**payload("Makan", 1000, "2026-10-05"), "category_id": 999}, headers=H).status_code == 422)

        allr = client.get("/api/transactions", headers=H).json()
        check("GET semua = 4", len(allr) == 4)
        check("GET filter month=2026-10 = 3", len(client.get("/api/transactions", params={"month": "2026-10"}, headers=H).json()) == 3)
        check("GET filter category=Makan = 2", len(client.get("/api/transactions", params={"category_id": cat["Makan"]}, headers=H).json()) == 2)
        check("GET month tidak valid -> 400", client.get("/api/transactions", params={"month": "2026-13"}, headers=H).status_code == 400)

        tx_id = a.json()["id"]
        up = client.put(f"/api/transactions/{tx_id}", json=payload("Lainnya", 35000, "2026-10-06", "Bioskop"), headers=H)
        check("PUT -> data berubah", up.status_code == 200 and up.json()["total_rupiah"] == 35000 and up.json()["category_name"] == "Lainnya")
        check("PUT id tak ada -> 404", client.put("/api/transactions/99999", json=payload("Makan", 1000, "2026-10-05"), headers=H).status_code == 404)

        # isolasi antar user
        other = client.post("/api/auth/register", json={"name": "Sari", "email": "sari@example.com", "password": "rahasia123"}).json()["access_token"]
        OH = {"Authorization": f"Bearer {other}"}
        check("User lain tak bisa melihat transaksi", client.get("/api/transactions", headers=OH).json() == [])
        check("User lain tak bisa menghapus (404)", client.delete(f"/api/transactions/{tx_id}", headers=OH).status_code == 404)

        # ------------------------------------------------------------- dashboard
        section("5. Dashboard")
        dd = client.get("/api/dashboard", params={"month": "2026-10"}, headers=H).json()
        # Okt 2026: Lainnya 35000 (hasil PUT) + Makan 20000 + Transportasi 50000 = 105000
        check("total_pengeluaran = 105000", dd["total_pengeluaran"] == 105000, str(dd["total_pengeluaran"]))
        check("jumlah_transaksi = 3", dd["jumlah_transaksi"] == 3)
        pct = sum(x["persentase"] for x in dd["per_kategori"])
        check("Persentase ~100%", abs(pct - 100) < 0.5, f"{pct:.1f}")
        check("Urut dari terbesar", dd["per_kategori"][0]["category_name"] == "Transportasi")
        check("Dashboard bulan kosong = 0", client.get("/api/dashboard", params={"month": "2020-01"}, headers=H).json()["total_pengeluaran"] == 0)

        r = client.delete(f"/api/transactions/{tx_id}", headers=H)
        check("DELETE -> 200", r.status_code == 200)
        check("DELETE lagi -> 404", client.delete(f"/api/transactions/{tx_id}", headers=H).status_code == 404)
        dd2 = client.get("/api/dashboard", params={"month": "2026-10"}, headers=H).json()
        check("Dashboard ikut berubah setelah DELETE", dd2["total_pengeluaran"] == 70000, str(dd2["total_pengeluaran"]))

        # ----------------------------------------------------------- klasifikasi
        section("6. Klasifikasi AI pada teks BARU (tidak ada di dataset latih)")
        import pandas as pd

        train_texts = set(pd.read_csv(BASE / "datasets" / "transaksi_indonesia.csv")["text"])
        ai = app_module.get_ai_service()
        cases = [
            ("rm padang sinar minang nasi rendang dan teh botol", "Makan"),
            ("grab bike antar jemput kantor", "Transportasi"),
            ("indomaret sabun cuci piring beras dan minyak goreng", "Kebutuhan"),
            ("tiket nonton film di bioskop xxi", "Lainnya"),
            ("pertamina spbu isi pertalite", "Transportasi"),
        ]
        print(f"  {'Teks':<55}{'Prediksi':<14}{'Confidence':>10}")
        for text, expected in cases:
            cat_pred, conf, mode = ai.classify(text)
            print(f"  {text:<55}{cat_pred:<14}{conf:>10.2%}")
            check(f"'{text[:38]}' -> {expected}", cat_pred == expected and mode == "ml" and text not in train_texts)

        # ------------------------------------------------------------- scan OCR
        section("7. POST /api/scan-receipt (OCR + regex + klasifikasi)")
        if not ai.ocr_available():
            SKIPPED.append("scan-receipt")
            print("  [LEWATI] Tesseract tidak terpasang (lihat README).")
        else:
            png = make_receipt_image()
            r = client.post("/api/scan-receipt", files={"file": ("struk.png", png, "image/png")}, headers=H)
            check("Scan -> 200", r.status_code == 200, str(r.status_code))
            js = r.json()
            keys = {"status", "receipt_detected", "merchant_name", "purchased_at", "total_rupiah",
                    "suggested_category", "category_confidence", "needs_review", "classifier_mode",
                    "processing_ms", "raw_ocr_text"}
            check("Skema respons sesuai kontrak", keys <= set(js))
            print(f"  hasil: merchant={js['merchant_name']} tanggal={js['purchased_at']} "
                  f"total={js['total_rupiah']} kategori={js['suggested_category']} "
                  f"conf={js['category_confidence']} review={js['needs_review']} ({js['processing_ms']} ms)")
            check("receipt_detected = true", js["receipt_detected"] is True)
            check("Total terbaca 45500", js["total_rupiah"] == 45500)
            check("Tanggal terbaca 2026-11-25", js["purchased_at"] == "2026-11-25")
            check("Merchant INDOMARET", js["merchant_name"] == "INDOMARET")
            check("Kategori saran = Kebutuhan", js["suggested_category"] == "Kebutuhan")
            blank = __import__("cv2").imencode(".png", __import__("numpy").full((300, 300, 3), 255, "uint8"))[1].tobytes()
            rb = client.post("/api/scan-receipt", files={"file": ("kosong.png", blank, "image/png")}, headers=H).json()
            check("Gambar kosong -> receipt_detected false", rb["receipt_detected"] is False)
            check("File bukan gambar -> 400", client.post("/api/scan-receipt", files={"file": ("x.txt", b"halo", "text/plain")}, headers=H).status_code == 400)
            check("Scan tanpa token -> 401", client.post("/api/scan-receipt", files={"file": ("a.png", png, "image/png")}).status_code == 401)

    section("RINGKASAN")
    print(f"  Lolos: {len(PASSED)} | Gagal: {len(FAILED)} | Dilewati: {len(SKIPPED)}")
    for f in FAILED:
        print(f"  - GAGAL: {f}")
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
