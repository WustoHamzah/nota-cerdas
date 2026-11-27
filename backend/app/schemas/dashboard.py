from pydantic import BaseModel


class CategorySummary(BaseModel):
    category_id: int
    category_name: str
    total_rupiah: int
    persentase: float


class DashboardResponse(BaseModel):
    month: str
    total_pengeluaran: int
    jumlah_transaksi: int
    per_kategori: list[CategorySummary]
