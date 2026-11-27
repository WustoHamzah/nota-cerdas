from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.scan import ClassifyTextRequest, ClassifyTextResponse
from app.services.classifier import classify_text


router = APIRouter(prefix="/classify-text", tags=["Category Classification"])


@router.post("", response_model=ClassifyTextResponse)
def classify_expense(
    payload: ClassifyTextRequest,
    current_user: User = Depends(get_current_user),
):
    result = classify_text(payload.merchant_name, payload.description)
    return ClassifyTextResponse(status="success", **result)
