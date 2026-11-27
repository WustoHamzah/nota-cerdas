"""SQLite (sqlite3 bawaan Python): koneksi, skema, seed kategori, dan seeder demo."""
import os
import sqlite3
from contextlib import contextmanager
from datetime import date, timedelta

try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:  # python-dotenv opsional
    pass

CATEGORIES = ["Makan", "Transportasi", "Kebutuhan", "Lainnya"]

DEMO_EMAIL = "demo@notacerdas.id"
DEMO_PASSWORD = "demo12345"


def db_path() -> str:
    # Dibaca setiap kali agar test bisa mengganti DB lewat environment variable.
    return os.getenv("DB_PATH", "notacerdas.db")


@contextmanager
def get_conn():
    conn = sqlite3.connect(db_path(), check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS categories (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS transactions (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id   INTEGER NOT NULL REFERENCES categories(id),
    merchant_name TEXT NOT NULL DEFAULT '',
    description   TEXT NOT NULL DEFAULT '',
    purchased_at  TEXT NOT NULL,              -- YYYY-MM-DD
    total_rupiah  INTEGER NOT NULL CHECK (total_rupiah > 0),
    source        TEXT NOT NULL CHECK (source IN ('scan', 'manual')),
    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_tx_user_date ON transactions(user_id, purchased_at);
"""


def init_db(seed_demo_data: bool | None = None) -> None:
    """Buat tabel, isi 4 kategori (idempoten), dan opsional seed demo."""
    with get_conn() as conn:
        conn.executescript(SCHEMA)
        for name in CATEGORIES:
            conn.execute("INSERT OR IGNORE INTO categories (name) VALUES (?)", (name,))
    if seed_demo_data is None:
        seed_demo_data = os.getenv("SEED_DEMO", "true").lower() in ("1", "true", "yes")
    if seed_demo_data:
        seed_demo()


def seed_demo() -> None:
    """User demo + transaksi contoh bulan ini. Aman dipanggil berulang."""
    from auth import hash_password  # import lokal agar tidak circular

    with get_conn() as conn:
        if conn.execute("SELECT 1 FROM users WHERE email = ?", (DEMO_EMAIL,)).fetchone():
            return
        cur = conn.execute(
            "INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)",
            ("Pengguna Demo", DEMO_EMAIL, hash_password(DEMO_PASSWORD)),
        )
        uid = cur.lastrowid
        cat = {r["name"]: r["id"] for r in conn.execute("SELECT id, name FROM categories")}
        today = date.today()
        samples = [
            ("Makan", "Warung Padang Sederhana", "Nasi rendang + es teh", 38000, "manual"),
            ("Makan", "Kopi Kenangan", "Kopi susu gula aren", 24000, "manual"),
            ("Makan", "KFC", "Paket hemat", 45500, "scan"),
            ("Transportasi", "Gojek", "Ojek ke kantor", 18000, "manual"),
            ("Transportasi", "Pertamina", "Pertalite", 50000, "scan"),
            ("Transportasi", "KRL Commuter Line", "Tiket KRL", 8000, "manual"),
            ("Kebutuhan", "Indomaret", "Belanja bulanan", 45500, "scan"),
            ("Kebutuhan", "Alfamart", "Sabun dan shampoo", 32000, "scan"),
            ("Kebutuhan", "Kimia Farma", "Vitamin C", 27500, "manual"),
            ("Lainnya", "CGV Cinema", "Tiket bioskop", 50000, "manual"),
            ("Lainnya", "Netflix", "Langganan bulanan", 54000, "manual"),
            ("Lainnya", "Gramedia", "Buku novel", 89000, "scan"),
        ]
        for i, (c, merchant, desc, total, source) in enumerate(samples):
            # Sebar tanggal dalam bulan berjalan (tidak pernah di masa depan).
            d = today - timedelta(days=min(i, max(today.day - 1, 0)))
            conn.execute(
                """INSERT INTO transactions
                   (user_id, category_id, merchant_name, description, purchased_at, total_rupiah, source)
                   VALUES (?, ?, ?, ?, ?, ?, ?)""",
                (uid, cat[c], merchant, desc, d.isoformat(), total, source),
            )
