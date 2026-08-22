# Kontribusi

Terima kasih sudah tertarik berkontribusi di **Aplikasi Amikom (Unofficial)**! 🎉
Repo ini terbuka untuk siapa saja: lapor bug, request fitur, perbaiki typo, sampai nambah modul baru.

## 💬 Komunikasi

- **Discord**: [https://discord.gg/INVITE_LINK](https://discord.gg/INVITE_LINK) — tempat utama diskusi & koordinasi.
  Di sini kamu bisa tanya-tanya, minta **API Key khusus development**, dan nemu teman ngoding.
  *(Ganti INVITE_LINK dengan invite Discord milikmu.)*
- **GitHub Issues**: gunakan template yang sudah disediakan untuk laporan bug & permintaan fitur.

## 🚀 Mulai Berkontribusi

1. **Fork** repo ini, lalu clone fork kamu:
   ```bash
   git clone https://github.com/<username-kamu>/amikom-unofficial-app.git
   cd amikom-unofficial-app
   ```
2. Setup environment development (lihat [README](README.md) → Cara Build & Install).
3. Cari issue berlabel [`good first issue`](https://github.com/wawiwuwawu/amikom-unofficial-app/labels/good%20first%20issue) kalau baru pertama kali.
4. Buat branch baru dari `main`:
   ```bash
   git checkout -b feat/fitur-baru
   ```
5. Kerjakan, pastikan berkualitas, lalu buat Pull Request ke `main`.

## ✅ Standar Kode

- **Dart/Flutter**: ikuti bawaan proyek (`flutter_lints`). Format dengan `dart format .`.
- **State management**: proyek ini memakai `setState` — konsisten, jangan campur pola lain tanpa diskusi dulu.
- **Pola commit** (Conventional Commits):
  ```
  feat: tambah modul jadwal
  fix(auth): perbaiki refresh token expired
  refactor(keuangan): rapikan detail billing
  docs: update README
  ```
- **Jangan commit** file `.env` atau kredensial apa pun (sudah di-`.gitignore`).

## 🧪 Sebelum Pull Request

Pastikan semua hijau:

1. `dart format --set-exit-if-changed .`
2. `flutter analyze` — tanpa error/warning baru
3. `flutter test` — semua lolos
4. (Jika ada perubahan UI) tes manual di emulator/perangkat

Setelah itu buat PR dengan mengisi [template PR](.github/PULL_REQUEST_TEMPLATE.md) — jelaskan apa yang diubah dan kenapa. Maintainer akan mereview secepatnya.

## 🤝 Kode Etik

Semua kontributor wajib mematuhi [Code of Conduct](CODE_OF_CONDUCT.md). Bersikap santun, saling menghargai, dan fokus pada kode — bukan pada orangnya.