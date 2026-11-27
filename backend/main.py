"""NotaCerdas API (FastAPI). Jalankan: uvicorn main:app --host 0.0.0.0 --port 8000"""
import re
import sqlite3
from contextlib import asynccontextmanager
from datetime import date, datetime
from typing import Literal

from fastapi import Depends, FastAPI, File, HTTPException, Query, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator

from ai_service import get_ai_service
from auth import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)
from db import get_conn, init_db

MAX_UPLOAD_BYTES = 10 * 1024 * 1024
MONTH_RE = re.compile(r"^\d{4}-(0[1-9]|1[0-2])$")


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    get_ai_service()  # muat model sekali saat start
    yield


app = FastAPI(title="NotaCerdas API", version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)


# ----------------------------------------------------------------------- schemas
class RegisterIn(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str = Field(max_length=200)
    password: str = Field(min_length=6, max_length=128)

    @field_validator("email")
    @classmethod
    def _email(cls, v: str) -> str:
        v = v.strip().lower()
        if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", v):
            raise ValueError("Format email tidak valid")
        return v


class LoginIn(BaseModel):
    email: str
    password: str

    @field_validator("email")
    @classmethod
    def _email(cls, v: str) -> str:
        return v.strip().lower()


class TransactionIn(BaseModel):
    category_id: int
    merchant_name: str = Field(default="", max_length=200)
    description: str = Field(default="", max_length=500)
    purchased_at: str
    total_rupiah: int = Field(gt=0, le=10_000_000_000)
    source: Literal["scan", "manual"]

    @field_validator("purchased_at")
    @classmethod
    def _date(cls, v: str) -> str:
        try:
            return datetime.strptime(v[:10], "%Y-%m-%d").date().isoformat()
        except ValueError:
            raise ValueError("purchased_at harus berformat YYYY-MM-DD")


def _auth_response(user_id: int, name: str, email: str) -> dict:
    return {
        "access_token": create_access_token(user_id),
        "token_type": "bearer",
        "user": {"id": user_id, "name": name, "email": email},
    }


def _month_or_400(month: str | None) -> str | None:
    if month is not None and not MONTH_RE.match(month):
        raise HTTPException(status_code=400, detail="month harus berformat YYYY-MM")
    return month


TX_SELECT = """
    SELECT t.id, t.category_id, c.name AS category_name, t.merchant_name, t.description,
           t.purchased_at, t.total_rupiah, t.source
    FROM transactions t JOIN categories c ON c.id = t.category_id
"""


def _ensure_category(conn: sqlite3.Connection, category_id: int) -> None:
    if conn.execute("SELECT 1 FROM categories WHERE id = ?", (category_id,)).fetchone() is None:
        raise HTTPException(status_code=422, detail="category_id tidak ditemukan")


# ------------------------------------------------------------------------- system
@app.get("/")
def root():
    return {"app": "NotaCerdas API", "docs": "/docs", "health": "/health"}


@app.get("/health")
def health():
    with get_conn() as conn:
        conn.execute("SELECT 1")
    return {"status": "ok", "ai": get_ai_service().status()}


# --------------------------------------------------------------------------- auth
@app.post("/api/auth/register", status_code=status.HTTP_201_CREATED)
def register(body: RegisterIn):
    with get_conn() as conn:
        try:
            cur = conn.execute(
                "INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)",
                (body.name.strip(), body.email, hash_password(body.password)),
            )
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=409, detail="Email sudah terdaftar")
        return _auth_response(cur.lastrowid, body.name.strip(), body.email)


@app.post("/api/auth/login")
def login(body: LoginIn):
    with get_conn() as conn:
        row = conn.execute(
            "SELECT id, name, email, password_hash FROM users WHERE email = ?", (body.email,)
        ).fetchone()
    if row is None or not verify_password(body.password, row["password_hash"]):
        raise HTTPException(status_code=401, detail="Email atau password salah")
    return _auth_response(row["id"], row["name"], row["email"])


# ---------------------------------------------------------------------- categories
@app.get("/api/categories")
def list_categories(user: dict = Depends(get_current_user)):
    with get_conn() as conn:
        rows = conn.execute("SELECT id, name FROM categories ORDER BY id").fetchall()
    return [dict(r) for r in rows]


# ----------------------------------------------------------------------- dashboard
@app.get("/api/dashboard")
def dashboard(month: str | None = None, user: dict = Depends(get_current_user)):
    month = _month_or_400(month) or date.today().strftime("%Y-%m")
    with get_conn() as conn:
        rows = conn.execute(
            """SELECT c.id AS category_id, c.name AS category_name,
                      SUM(t.total_rupiah) AS total_rupiah, COUNT(*) AS n
               FROM transactions t JOIN categories c ON c.id = t.category_id
               WHERE t.user_id = ? AND substr(t.purchased_at, 1, 7) = ?
               GROUP BY c.id ORDER BY total_rupiah DESC""",
            (user["id"], month),
        ).fetchall()
    grand = sum(r["total_rupiah"] for r in rows)
    count = sum(r["n"] for r in rows)
    return {
        "month": month,
        "total_pengeluaran": grand,
        "jumlah_transaksi": count,
        "per_kategori": [
            {
                "category_id": r["category_id"],
                "category_name": r["category_name"],
                "total_rupiah": r["total_rupiah"],
                "persentase": round(r["total_rupiah"] / grand * 100, 1) if grand else 0.0,
            }
            for r in rows
        ],
    }


# ------------------------------------------------------------------- transactions
@app.get("/api/transactions")
def list_transactions(
    category_id: int | None = Query(default=None),
    month: str | None = Query(default=None),
    user: dict = Depends(get_current_user),
):
    month = _month_or_400(month)
    sql, params = TX_SELECT + " WHERE t.user_id = ?", [user["id"]]
    if category_id is not None:
        sql += " AND t.category_id = ?"
        params.append(category_id)
    if month:
        sql += " AND substr(t.purchased_at, 1, 7) = ?"
        params.append(month)
    sql += " ORDER BY t.purchased_at DESC, t.id DESC"
    with get_conn() as conn:
        return [dict(r) for r in conn.execute(sql, params).fetchall()]


def _get_tx(conn: sqlite3.Connection, tx_id: int, user_id: int) -> dict:
    row = conn.execute(TX_SELECT + " WHERE t.id = ? AND t.user_id = ?", (tx_id, user_id)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Transaksi tidak ditemukan")
    return dict(row)


@app.post("/api/transactions", status_code=status.HTTP_201_CREATED)
def create_transaction(body: TransactionIn, user: dict = Depends(get_current_user)):
    with get_conn() as conn:
        _ensure_category(conn, body.category_id)
        cur = conn.execute(
            """INSERT INTO transactions
               (user_id, category_id, merchant_name, description, purchased_at, total_rupiah, source)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (user["id"], body.category_id, body.merchant_name.strip(), body.description.strip(),
             body.purchased_at, body.total_rupiah, body.source),
        )
        return _get_tx(conn, cur.lastrowid, user["id"])


@app.put("/api/transactions/{tx_id}")
def update_transaction(tx_id: int, body: TransactionIn, user: dict = Depends(get_current_user)):
    with get_conn() as conn:
        _get_tx(conn, tx_id, user["id"])
        _ensure_category(conn, body.category_id)
        conn.execute(
            """UPDATE transactions SET category_id=?, merchant_name=?, description=?,
               purchased_at=?, total_rupiah=?, source=? WHERE id=? AND user_id=?""",
            (body.category_id, body.merchant_name.strip(), body.description.strip(),
             body.purchased_at, body.total_rupiah, body.source, tx_id, user["id"]),
        )
        return _get_tx(conn, tx_id, user["id"])


@app.delete("/api/transactions/{tx_id}")
def delete_transaction(tx_id: int, user: dict = Depends(get_current_user)):
    with get_conn() as conn:
        _get_tx(conn, tx_id, user["id"])
        conn.execute("DELETE FROM transactions WHERE id = ? AND user_id = ?", (tx_id, user["id"]))
    return {"status": "deleted", "id": tx_id}


# ------------------------------------------------------------------------- AI scan
@app.post("/api/scan-receipt")
def scan_receipt(file: UploadFile = File(...), user: dict = Depends(get_current_user)):
    # Endpoint sinkron (def) -> dijalankan di threadpool, tidak memblokir event loop.
    data = file.file.read(MAX_UPLOAD_BYTES + 1)
    if not data:
        raise HTTPException(status_code=400, detail="File kosong")
    if len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Ukuran gambar maksimal 10 MB")
    ai = get_ai_service()
    if not ai.ocr_available():
        raise HTTPException(
            status_code=503,
            detail="Tesseract OCR belum terpasang di server (lihat README: instal tesseract-ocr).",
        )
    try:
        return ai.scan_receipt(data)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
