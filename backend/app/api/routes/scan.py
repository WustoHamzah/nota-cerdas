import time
from io import BytesIO

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from PIL import Image, UnidentifiedImageError
from starlette.concurrency import run_in_threadpool

from app.api.deps import get_current_user
from app.core.config import settings
from app.models.user import User
from app.schemas.scan import ScanReceiptResponse
from app.services.receipt_ocr import process_receipt


router = APIRouter(prefix="/scan-receipt", tags=["Receipt Scan"])

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "application/octet-stream"}


@router.post("", response_model=ScanReceiptResponse)
async def scan_receipt(
    file: UploadFile = File(..., description="Foto struk JPG, PNG, atau WEBP"),
    current_user: User = Depends(get_current_user),
):
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Format file harus JPG, PNG, atau WEBP.",
        )

    content = await file.read()
    max_bytes = settings.max_upload_size_mb * 1024 * 1024
    if not content:
        raise HTTPException(status_code=400, detail="File gambar kosong.")
    if len(content) > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Ukuran gambar maksimal {settings.max_upload_size_mb} MB.",
        )

    try:
        with Image.open(BytesIO(content)) as image:
            image.verify()
    except (UnidentifiedImageError, OSError, ValueError):
        raise HTTPException(status_code=400, detail="File yang dikirim bukan gambar valid.")

    started = time.perf_counter()
    try:
        result = await run_in_threadpool(process_receipt, content)
    except Exception:
        # Kesalahan OCR tidak boleh membuat aplikasi kehilangan alur input manual.
        result = {
            "status": "needs_review",
            "receipt_detected": False,
            "merchant_name": "",
            "purchased_at": None,
            "total_rupiah": 0,
            "suggested_category": "Lainnya",
            "category_confidence": 0.0,
            "needs_review": True,
            "classifier_mode": "rule_based_v1",
            "raw_ocr_text": "",
        }

    processing_ms = int((time.perf_counter() - started) * 1000)
    return ScanReceiptResponse(
        **result,
        processing_ms=processing_ms,
    )
