# Aplikasi Amikom (Unofficial)

Aplikasi mobile **tidak resmi** untuk portal akademik mahasiswa Universitas Amikom Purwokerto.
Dibangun dengan Flutter dan Material 3.

> ⚠️ Aplikasi ini tidak berafiliasi secara resmi dengan Universitas Amikom Purwokerto.

## Fitur

- Login / Logout dengan JWT (token + refresh token)
- Dashboard (profil, statistik, status akademik)
- Berita Kampus (list + detail, pagination Prev/Next)
- Kartu Hasil Studi / KHS (pilih tahun/semester, tabel nilai, download PDF, share)
- Pengumuman Akademik (list + detail + lampiran)
- Jadwal Perkuliahan *(dalam pengembangan)*
- Nilai *(dalam pengembangan)*

## Tech Stack

| Item | Detail |
|------|--------|
| Framework | Flutter 3.11+ (Dart SDK ^3.11.1) |
| Platform | Android (Material 3) |
| HTTP Client | Dio 5.9.x |
| State Management | setState |
| Persistence | SharedPreferences |
| File Download | path_provider |
| Lainnya | share_plus, permission_handler, flutter_dotenv |

## Prerequisites

- Flutter SDK 3.11+
- Android Studio / Emulator atau device Android fisik

## Cara Build & Install

1. Clone repositori ini:

   ```bash
   git clone https://github.com/username/app-amikom.git
   cd app-amikom
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Buat file `.env` dari template:

   ```bash
   cp .env.example .env
   ```

   Lalu isi `API_BASE_URL` dengan URL backend adapter Anda.

4. Build APK:

   ```bash
   flutter build apk --release
   ```

5. Install `build/app/outputs/flutter-apk/app-release.apk` ke device Android Anda.

## Kontribusi

Tertarik berkontribusi? Hubungi **[xxx]** untuk mendapatkan API Key khusus development.

## Disclaimer

- Aplikasi ini **tidak resmi** dan tidak berafiliasi dengan Universitas Amikom Purwokerto.
- API endpoint **tidak disertakan** dalam repositori ini. Anda perlu menyediakan backend adapter sendiri.
- Gunakan dengan bijak dan sesuai ketentuan yang berlaku.

## License

[MIT](LICENSE)
