from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class TransactionPayload(BaseModel):
    category_id: int = Field(gt=0)
    merchant_name: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=5000)
    purchased_at: date
    total_rupiah: int = Field(gt=0)
    source: Literal["scan", "manual"]


class TransactionCreate(TransactionPayload):
    pass


class TransactionUpdate(TransactionPayload):
    pass


class TransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    category_id: int
    category_name: str
    merchant_name: str
    description: str | None
    purchased_at: date
    total_rupiah: int
    source: Literal["scan", "manual"]
    created_at: datetime


class DeleteTransactionResponse(BaseModel):
    status: str
    id: int
