from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.api.deps import get_current_user
from app.models.category import Category
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.dashboard import CategorySummary, DashboardResponse


router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


def month_range(month: str) -> tuple[date, date]:
    year, month_number = map(int, month.split("-"))
    start = date(year, month_number, 1)
    if month_number == 12:
        end = date(year + 1, 1, 1)
    else:
        end = date(year, month_number + 1, 1)
    return start, end


@router.get("", response_model=DashboardResponse)
def get_dashboard(
    month: str = Query(..., pattern=r"^\d{4}-(0[1-9]|1[0-2])$"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    start, end = month_range(month)

    totals = db.execute(
        select(
            func.coalesce(func.sum(Transaction.total_rupiah), 0),
            func.count(Transaction.id),
        ).where(
            Transaction.user_id == current_user.id,
            Transaction.purchased_at >= start,
            Transaction.purchased_at < end,
        )
    ).one()

    total_pengeluaran = int(totals[0] or 0)
    jumlah_transaksi = int(totals[1] or 0)

    rows = db.execute(
        select(
            Category.id,
            Category.name,
            func.coalesce(func.sum(Transaction.total_rupiah), 0).label("total"),
        )
        .join(Transaction, Transaction.category_id == Category.id)
        .where(
            Transaction.user_id == current_user.id,
            Transaction.purchased_at >= start,
            Transaction.purchased_at < end,
        )
        .group_by(Category.id, Category.name)
        .order_by(func.sum(Transaction.total_rupiah).desc())
    ).all()

    per_kategori = [
        CategorySummary(
            category_id=int(row.id),
            category_name=row.name,
            total_rupiah=int(row.total or 0),
            persentase=round((int(row.total or 0) / total_pengeluaran) * 100, 2)
            if total_pengeluaran
            else 0.0,
        )
        for row in rows
    ]

    return DashboardResponse(
        month=month,
        total_pengeluaran=total_pengeluaran,
        jumlah_transaksi=jumlah_transaksi,
        per_kategori=per_kategori,
    )
