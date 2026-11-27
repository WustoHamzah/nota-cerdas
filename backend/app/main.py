from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.api.routes import auth, categories, classify, dashboard, scan, transactions
from app.core.config import settings
from app.core.database import Base, SessionLocal, engine
from app.models import Category


DEFAULT_CATEGORIES = [
    "Makanan & Minuman",
    "Transportasi",
    "Belanja",
    "Kesehatan",
    "Tagihan & Utilitas",
    "Hiburan",
    "Pendidikan",
    "Rumah Tangga",
    "Lainnya",
]


def initialize_database() -> None:
    Base.metadata.create_all(bind=engine)

    with SessionLocal() as db:
        existing_names = set(db.scalars(select(Category.name)).all())
        for name in DEFAULT_CATEGORIES:
            if name not in existing_names:
                db.add(Category(name=name))
        db.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    initialize_database()
    yield


app = FastAPI(
    title=settings.app_name,
    description=(
        "Backend NotaCerdas untuk autentikasi pengguna, pencatatan pengeluaran, "
        "dashboard, klasifikasi kategori, dan OCR struk belanja."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=False if settings.allowed_origins == ["*"] else True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api")
app.include_router(categories.router, prefix="/api")
app.include_router(dashboard.router, prefix="/api")
app.include_router(transactions.router, prefix="/api")
app.include_router(scan.router, prefix="/api")
app.include_router(classify.router, prefix="/api")


@app.get("/", tags=["Health"])
def health_check():
    return {
        "app": "NotaCerdas API",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok"}
