# NotaCerdas Backend

Backend REST API untuk aplikasi Android Flutter NotaCerdas. Implementasi menggunakan FastAPI, SQLAlchemy, SQLite, JWT, Argon2, Tesseract OCR, dan klasifikasi kategori berbasis aturan.

## 1. Kebutuhan

- Python 3.11 atau lebih baru.
- Tesseract OCR untuk fitur scan struk.
- Bahasa OCR `eng` dan `ind` disarankan.

Jika menggunakan Windows, instal Tesseract OCR terlebih dahulu. Pastikan executable `tesseract.exe` masuk ke PATH. Paket bahasa Indonesia (`ind`) perlu tersedia. Jika Tesseract belum terpasang, endpoint scan tetap merespons tetapi hasil OCR kosong dan `needs_review=true`.

## 2. Instalasi di Windows

Buka terminal pada folder `notacerdas-backend`, lalu jalankan:

```powershell
py -3.11 -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

Edit `.env`. Ganti `JWT_SECRET_KEY` dengan secret acak yang panjang. Untuk penggunaan lokal, SQLite akan otomatis membuat file `notacerdas.db`.

Jalankan server:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Buka dokumentasi interaktif:

- Swagger UI: http://127.0.0.1:8000/docs
- Health check: http://127.0.0.1:8000/health

Tabel database dan sembilan kategori awal dibuat otomatis ketika aplikasi pertama kali dijalankan.

## 3. Koneksi Flutter Android

Base URL emulator Android:

```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

Untuk HP Android fisik, ganti dengan IP lokal laptop/PC yang menjalankan backend, misalnya:

```dart
static const String baseUrl = 'http://192.168.1.15:8000';
```

HP dan laptop harus berada pada jaringan Wi-Fi yang sama. Izinkan koneksi masuk TCP port `8000` pada Windows Firewall. Backend dijalankan dengan `--host 0.0.0.0` agar dapat diakses perangkat lain di jaringan lokal.

Untuk pengembangan Android dengan HTTP lokal, aplikasi Flutter mungkin perlu mengizinkan cleartext traffic pada konfigurasi Android. Jangan gunakan HTTP tanpa TLS untuk produksi.

## 4. Kontrak Endpoint

Semua endpoint selain `POST /api/auth/register` dan `POST /api/auth/login` memerlukan header:

```http
Authorization: Bearer <access_token>
```

| Method | Endpoint | Fungsi |
|---|---|---|
| POST | `/api/auth/register` | Registrasi |
| POST | `/api/auth/login` | Login |
| GET | `/api/auth/me` | Profil pengguna aktif |
| GET | `/api/categories` | Daftar kategori |
| GET | `/api/dashboard?month=YYYY-MM` | Ringkasan bulanan |
| GET | `/api/transactions?category_id=&month=YYYY-MM` | Daftar transaksi dan filter |
| POST | `/api/transactions` | Membuat transaksi |
| PUT | `/api/transactions/{id}` | Mengubah transaksi |
| DELETE | `/api/transactions/{id}` | Menghapus transaksi |
| POST | `/api/scan-receipt` | OCR foto struk, multipart key `file` |
| POST | `/api/classify-text` | Prediksi kategori dari teks |

### Contoh request transaksi

```json
{
  "category_id": 1,
  "merchant_name": "Warung Makan Sederhana",
  "description": "Makan siang",
  "purchased_at": "2026-11-26",
  "total_rupiah": 45000,
  "source": "manual"
}
```

Nilai `source` hanya menerima `scan` atau `manual`. `total_rupiah` disimpan sebagai bilangan bulat Rupiah, bukan string berformat `Rp`.

### Contoh request klasifikasi

```json
{
  "merchant_name": "Warung Bakso Pak Rudi",
  "description": "Bakso dan es teh"
}
```

### Upload struk

Kirim `multipart/form-data` dengan nama field tepat `file`. Format yang diterima JPG/JPEG, PNG, dan WEBP. Ukuran maksimal default 8 MB. Timeout OCR diatur maksimal 20 detik di proses Tesseract; batas timeout upload pada sisi Flutter tetap disarankan 25 detik.

## 5. Kategori Default

Kategori yang dibuat otomatis:

1. Makanan & Minuman
2. Transportasi
3. Belanja
4. Kesehatan
5. Tagihan & Utilitas
6. Hiburan
7. Pendidikan
8. Rumah Tangga
9. Lainnya

`category_id` ditentukan oleh database. Jangan mengasumsikan ID tertentu di Flutter; ambil daftar kategori dari `GET /api/categories`. Hasil `suggested_category` dari endpoint klasifikasi adalah nama kategori yang harus dicocokkan dengan field `name` untuk memperoleh `category_id`.

## 6. Perilaku Keamanan dan Data

- Password disimpan dalam bentuk hash Argon2, bukan teks asli.
- Token JWT memiliki masa berlaku sesuai `ACCESS_TOKEN_EXPIRE_MINUTES`.
- Data transaksi selalu dibatasi berdasarkan `user_id` dari token aktif.
- Pengguna tidak dapat mengubah atau menghapus transaksi milik pengguna lain.
- Token tidak valid/kedaluwarsa menghasilkan HTTP 401. Penghapusan token dan navigasi ke LoginPage dilakukan oleh aplikasi Flutter.
- Error validasi FastAPI menggunakan field `detail`.
- Database default SQLite tersimpan pada `notacerdas.db`.

## 7. Catatan OCR dan Klasifikasi

OCR memakai Tesseract lokal. Akurasi dipengaruhi resolusi, pencahayaan, kemiringan foto, kualitas cetak, dan format struk. Backend mengembalikan `needs_review=true` jika data penting tidak terbaca atau keyakinan kategori rendah. Pengguna tetap harus memeriksa merchant, tanggal, total, dan kategori sebelum menyimpan transaksi.

Classifier pada versi ini adalah **rule-based baseline**, bukan model AI/LLM yang dilatih. `category_confidence` merupakan skor heuristik, bukan probabilitas statistik terkalibrasi. Struktur service dipisahkan agar nantinya dapat diganti dengan model machine learning atau layanan AI tanpa mengubah kontrak API.

## 8. Menjalankan dengan Docker

Build dan jalankan:

```bash
docker build -t notacerdas-backend .
docker run --name notacerdas-api -p 8000:8000 \
  -e JWT_SECRET_KEY="GANTI_SECRET_PANJANG" \
  -v notacerdas-data:/app \
  notacerdas-backend
```

Volume menjaga file database tetap ada ketika container dibuat ulang. Untuk produksi, gunakan database terkelola seperti PostgreSQL, secret manager, HTTPS, backup, dan konfigurasi CORS yang spesifik.

## 9. Alur Uji Cepat di Swagger

1. Jalankan backend dan buka `/docs`.
2. Jalankan `POST /api/auth/register`.
3. Salin `access_token` dari response.
4. Klik **Authorize** dan masukkan token sebagai Bearer token.
5. Uji `GET /api/categories`.
6. Uji `POST /api/transactions`.
7. Uji `GET /api/dashboard?month=2026-11`.
8. Uji `POST /api/classify-text`.
9. Uji `POST /api/scan-receipt` dengan gambar struk.

Pastikan tanggal dan bulan pada pengujian disesuaikan dengan data transaksi yang dimasukkan.
