import re
from collections import defaultdict


CLASSIFIER_MODE = "rule_based_v1"

# Nama kategori harus sama persis dengan data kategori yang di-seed ke database.
KEYWORDS: dict[str, list[str]] = {
    "Makanan & Minuman": [
        "warteg", "restoran", "restaurant", "rumah makan", "cafe", "kafe",
        "coffee", "kopi", "bakso", "mie", "mi ayam", "nasi", "ayam geprek",
        "pizza", "burger", "sate", "soto", "martabak", "roti", "minuman",
        "makanan", "food", "drink", "gofood", "grabfood",
    ],
    "Transportasi": [
        "pertamina", "spbu", "bensin", "bbm", "shell", "pertamax", "solar",
        "parkir", "tol", "gojek", "grab", "angkot", "bus", "kereta",
        "travel", "tiket pesawat", "transport", "bengkel", "ojek",
    ],
    "Belanja": [
        "indomaret", "alfamart", "alfamidi", "superindo", "hypermart",
        "tokopedia", "shopee", "lazada", "blibli", "marketplace",
        "department store", "minimarket", "supermarket", "mall", "toko pakaian",
        "pakaian", "sepatu", "elektronik", "aksesoris",
    ],
    "Kesehatan": [
        "apotek", "apotik", "kimia farma", "guardian", "watsons",
        "rumah sakit", "rs ", "klinik", "dokter", "laboratorium",
        "laboratorium klinik", "obat", "medical", "kesehatan", "vitamin",
    ],
    "Tagihan & Utilitas": [
        "pln", "listrik", "pdam", "air", "internet", "wifi", "wi-fi",
        "indihome", "telkom", "pulsa", "paket data", "token listrik",
        "tagihan", "iuran", "bpjs", "pascabayar",
    ],
    "Hiburan": [
        "bioskop", "cinema", "xxi", "cgv", "netflix", "spotify",
        "youtube premium", "game", "steam", "playstation", "konser",
        "rekreasi", "tiket wisata", "hiburan", "karaoke",
    ],
    "Pendidikan": [
        "sekolah", "kampus", "universitas", "kuliah", "spp", "kursus",
        "bimbel", "buku pelajaran", "alat tulis", "pendidikan",
        "perpustakaan", "sertifikasi",
    ],
    "Rumah Tangga": [
        "toko bangunan", "material bangunan", "furniture", "mebel",
        "perabot", "gas elpiji", "gas 3kg", "gas 12kg", "peralatan rumah",
        "detergen", "sabun cuci", "kebersihan rumah", "perlengkapan rumah",
    ],
}

CATEGORY_ORDER = [
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


def classify_text(merchant_name: str | None, description: str | None) -> dict:
    text = f"{merchant_name or ''} {description or ''}".lower()
    text = re.sub(r"\s+", " ", text).strip()

    scores: dict[str, int] = defaultdict(int)
    for category, keywords in KEYWORDS.items():
        for keyword in keywords:
            if keyword in text:
                # Merchant match mendapat bobot sedikit lebih besar daripada deskripsi.
                merchant = (merchant_name or "").lower()
                scores[category] += 3 if keyword in merchant else 2

    if not scores:
        return {
            "suggested_category": "Lainnya",
            "category_confidence": 0.25,
            "classifier_mode": CLASSIFIER_MODE,
        }

    ranked = sorted(
        scores.items(),
        key=lambda item: (-item[1], CATEGORY_ORDER.index(item[0])),
    )
    best_category, best_score = ranked[0]
    second_score = ranked[1][1] if len(ranked) > 1 else 0

    # Skor ini adalah tingkat keyakinan heuristik, bukan probabilitas model ML.
    confidence = min(0.97, 0.55 + (0.07 * best_score))
    if second_score and best_score - second_score <= 1:
        confidence = min(confidence, 0.58)

    return {
        "suggested_category": best_category,
        "category_confidence": round(confidence, 2),
        "classifier_mode": CLASSIFIER_MODE,
    }
