import re

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.api.deps import get_current_user
from app.api.routes.dashboard import month_range
from app.core.database import get_db
from app.models.category import Category
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.transaction import (
    DeleteTransactionResponse,
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
)


router = APIRouter(prefix="/transactions", tags=["Transactions"])


def get_owned_transaction(db: Session, transaction_id: int, user_id: int) -> Transaction:
    transaction = db.scalar(
        select(Transaction)
        .options(joinedload(Transaction.category))
        .where(
            Transaction.id == transaction_id,
            Transaction.user_id == user_id,
        )
    )
    if transaction is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaksi tidak ditemukan.",
        )
    return transaction


def validate_category(db: Session, category_id: int) -> None:
    if db.get(Category, category_id) is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="category_id tidak ditemukan.",
        )


@router.get("", response_model=list[TransactionResponse])
def get_transactions(
    category_id: str | None = Query(default=None),
    month: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    statement = (
        select(Transaction)
        .options(joinedload(Transaction.category))
        .where(Transaction.user_id == current_user.id)
    )

    if category_id is not None and category_id.strip():
        try:
            parsed_category_id = int(category_id)
            if parsed_category_id <= 0:
                raise ValueError
        except ValueError:
            raise HTTPException(status_code=422, detail="category_id harus berupa bilangan bulat positif.")
        statement = statement.where(Transaction.category_id == parsed_category_id)

    if month and month.strip():
        if not re.fullmatch(r"\d{4}-(0[1-9]|1[0-2])", month):
            raise HTTPException(status_code=422, detail="month harus menggunakan format YYYY-MM.")
        start, end = month_range(month)
        statement = statement.where(
            Transaction.purchased_at >= start,
            Transaction.purchased_at < end,
        )

    statement = statement.order_by(
        Transaction.purchased_at.desc(),
        Transaction.created_at.desc(),
        Transaction.id.desc(),
    )
    return db.scalars(statement).all()


@router.post(
    "",
    response_model=TransactionResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_transaction(
    payload: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    validate_category(db, payload.category_id)

    transaction = Transaction(
        user_id=current_user.id,
        **payload.model_dump(),
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return get_owned_transaction(db, transaction.id, current_user.id)


@router.put("/{transaction_id}", response_model=TransactionResponse)
def update_transaction(
    transaction_id: int,
    payload: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transaction = get_owned_transaction(db, transaction_id, current_user.id)
    validate_category(db, payload.category_id)

    for field, value in payload.model_dump().items():
        setattr(transaction, field, value)

    db.commit()
    db.refresh(transaction)
    return get_owned_transaction(db, transaction.id, current_user.id)


@router.delete(
    "/{transaction_id}",
    response_model=DeleteTransactionResponse,
)
def delete_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transaction = get_owned_transaction(db, transaction_id, current_user.id)
    db.delete(transaction)
    db.commit()
    return DeleteTransactionResponse(status="deleted", id=transaction_id)
