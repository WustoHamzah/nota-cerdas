from pydantic import BaseModel, Field


class ScanReceiptResponse(BaseModel):
    status: str
    receipt_detected: bool
    merchant_name: str
    purchased_at: str | None
    total_rupiah: int
    suggested_category: str
    category_confidence: float = Field(ge=0, le=1)
    needs_review: bool
    classifier_mode: str
    processing_ms: int
    raw_ocr_text: str


class ClassifyTextRequest(BaseModel):
    merchant_name: str = Field(default="", max_length=200)
    description: str = Field(default="", max_length=5000)


class ClassifyTextResponse(BaseModel):
    status: str
    suggested_category: str
    category_confidence: float = Field(ge=0, le=1)
    classifier_mode: str
