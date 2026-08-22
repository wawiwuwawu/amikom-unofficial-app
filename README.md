# 📱 Aplikasi Amikom (Unofficial)

<p align="center">
  <img src="assets/icon_amiapp.png" alt="Logo Aplikasi Amikom" width="120">
  <br>
  <b>Aplikasi mobile non-resmi portal akademik untuk mahasiswa Universitas Amikom Purwokerto.</b>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/wawiwuwawu/amikom-unofficial-app/releases"><img src="https://img.shields.io/github/v/release/wawiwuwawu/amikom-unofficial-app" alt="Latest Release"></a>
  <a href="https://github.com/wawiwuwawu/amikom-unofficial-app/actions/workflows/ci.yml"><img src="https://github.com/wawiwuwawu/amikom-unofficial-app/actions/workflows/ci.yml/badge.svg" alt="CI Status"></a>
  <a href="https://github.com/wawiwuwawu/amikom-unofficial-app/releases/latest"><img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" alt="Platform: Android"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.11%2B-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://discord.gg/VNrPhWQCWf"><img src="https://img.shields.io/badge/Discord-Join%20Us-5865F2?logo=discord&logoColor=white" alt="Discord"></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"></a>
</p>

> ⚠️ **Aplikasi ini TIDAK resmi** dan tidak berafiliasi dengan Universitas Amikom Purwokerto.

Dibangun dengan **Flutter + Material 3**, aplikasi ini adalah klien Android untuk portal akademik
mahasiswa — dibuat oleh mahasiswa, untuk mahasiswa. 🎓

## ✨ Fitur

| Kategori | Fitur |
|---|---|
| 🔐 **Autentikasi** | Login/logout, refresh token otomatis, kredensial di secure storage (tanpa simpan password) |
| 📊 **Dashboard** | Profil, statistik & status akademik, evaluasi cumlaude, progress kelulusan, ringkasan SKPI, simulator target IPK |
| 💰 **Keuangan** | Riwayat & detail pembayaran, buat VA, pilih bank, multi-select bill, bukti PDF, panduan pembayaran |
| 📚 **KRS** | Daftar & submit KRS, auto-sync, status badge, konfirmasi |
| 🎓 **KHS** | Pilih tahun/semester, tabel nilai, download PDF, share |
| 📝 **Layanan Akademik** | Semester Pendek (SP), SKMK, Izin Penelitian, Surat Tugas, PKL, Ujian Susulan |
| 🏆 **Prestasi & Organisasi** | Prestasi mahasiswa, organisasi mahasiswa, pusat studi, asisten praktikum |
| 🎓 **Skripsi & Tugas Akhir** | 4 tab, download PDF, upload cek plagiarisme, pasca ujian |
| 📰 **Informasi Kampus** | Berita kampus, pengumuman akademik + lampiran |

🚧 *Dalam pengembangan: jadwal perkuliahan, nilai.*

## 🛠️ Tech Stack

| Item | Detail |
|------|--------|
| Framework | Flutter 3.11+ (Dart SDK ^3.11.1) |
| Platform | Android (Material 3, tema Ice Blue & Liquid Glass) |
| HTTP Client | Dio 5.9.x |
| State Management | setState |
| Persistence | flutter_secure_storage, shared_preferences |
| Grafik & Kalender | fl_chart, table_calendar |
| UI | google_fonts, flutter_animate |
| File & Share | path_provider, file_picker, open_filex, share_plus, permission_handler |
| Lainnya | flutter_dotenv, url_launcher, flutter_html, markdown |

## 📂 Struktur Proyek

```
lib/
├── main.dart          # Entry point, tema, & routes
├── models/            # Model data (JSON parsing)
├── services/          # ApiClient, auth, navigation
├── pages/             # Halaman per modul (krs/, keuangan/, pusat_studi/, ...)
└── widgets/           # Widget reusable
```

## 🚀 Cara Build & Install

**Prerequisites:** Flutter SDK 3.11+ dan Android Studio/emulator atau device Android fisik.

1. Clone repositori:

   ```bash
   git clone https://github.com/wawiwuwawu/amikom-unofficial-app.git
   cd amikom-unofficial-app
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Buat file `.env` dari template:

   ```bash
   cp .env.example .env
   ```

   Lalu isi `API_BASE_URL` dengan URL backend adapter kamu (lihat bagian Backend).

4. Build APK release:

   ```bash
   flutter build apk --release
   ```

5. Install `build/app/outputs/flutter-apk/app-release.apk` ke device Android kamu.

> 💡 Unduh APK siap pakai dari halaman [Releases](https://github.com/wawiwuwawu/amikom-unofficial-app/releases).

## 🔌 Backend Adapter

Repositori ini **hanya berisi aplikasi klien (Flutter)**. Endpoint API portal akademik
**tidak disertakan** — kamu perlu menyediakan/menunjuk backend adapter sendiri yang
kompatibel, lalu set `API_BASE_URL`-nya di `.env`.

> Kontributor boleh meminta **API Key khusus development** untuk mencoba aplikasi
> dengan data uji: gabung [Discord](https://discord.gg/VNrPhWQCWf) lalu **DM maintainer (@wawiwuwawu) secara pribadi** — jangan minta di channel publik (lihat [Kontribusi](CONTRIBUTING.md)).

## 🤝 Kontribusi

Repo ini terbuka untuk kontribusi siapa pun — dari lapor bug sampai nambah modul baru.
Cara lengkapnya ada di [CONTRIBUTING.md](CONTRIBUTING.md).

- 💬 **Diskusi & Q&A**: https://github.com/wawiwuwawu/amikom-unofficial-app/discussions
- 💬 **Discord** (chat real-time): https://discord.gg/VNrPhWQCWf
- 🐛 Lapor bug: gunakan template *Bug Report* di tab Issues
- ✨ Request fitur: gunakan template *Feature Request* di tab Issues

Semua kontributor wajib mematuhi [Code of Conduct](CODE_OF_CONDUCT.md).
Masalah keamanan? Baca [SECURITY.md](SECURITY.md) — jangan buat issue publik.

## ❗ Disclaimer

- Aplikasi ini **tidak resmi** dan **tidak berafiliasi** dengan Universitas Amikom Purwokerto.
- Penggunaan aplikasi ini sepenuhnya tanggung jawab pengguna. Data akademik yang
  ditampilkan berasal dari backend adapter yang dikelola masing-masing pengguna.
- Jangan pernah membagikan kredensial/kartu mahasiswa kamu ke pihak lain.
- Aplikasi ini bukan pengganti kanal resmi kampus untuk hal-hal yang bersifat mengikat.

## 📄 Lisensi

Didistribusikan di bawah lisensi [MIT](LICENSE).