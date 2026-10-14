# Changelog

Semua perubahan penting dicatat di sini. Format mengikuti
[Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/) dan
[Semantic Versioning](https://semver.org/lang/id/). Detail lengkap tiap
rilis ada di halaman [Releases](https://github.com/wawiwuwawu/amikom-unofficial-app/releases).

## [Unreleased]

### Added
- ✨ Notifikasi push (Android) melalui **FCM (Firebase Cloud Messaging)**: kartu status di puncak halaman Notifikasi (default-on, tanpa tombol Aktifkan/Matikan), bottom sheet panduan sekali-tampil (izin notifikasi & optimasi baterai aplikasi ini), serta kontrak token perangkat (`GET /api/v1/notifikasi/optin` → `{enabled, token_count}`, `POST|DELETE /api/v1/notifikasi/device-token`)
- 🔗 Deep link `amikomstudent://notifikasi/<id>`: ketukan pada notifikasi sistem membuka detail notifikasi langsung di aplikasi (cold start & app berjalan), tanpa dobel-buka dalam 2 detik
- ✨ Ketukan push dengan url https (siaran) kini dibuka di browser eksternal; tautan `amikomstudent://notifikasi/<id>` tetap membuka detail notifikasi di aplikasi
- 🧪 Test push: ketukan siaran (url https) dibedakan dari notifikasi privat (`amikomstudent`), https + `notif_id` jatuh ke siaran, dedupe 2 detik berlaku terpisah untuk siaran, dan id notifikasi tray siaran memakai hash url (tak tabrakan dengan notifikasi privat)
- 🩺 Kartu push memperingati "server notifikasi sedang bermasalah" bila nonaktif tapi token masih terdaftar (`enabled:false` + `token_count>0` — sesuai kontrak BE: bedakan "belum daftar" dari "server mati")
- 🔄 Status push dimuat ulang otomatis saat aplikasi dibuka kembali dari background (tak lagi menampilkan state basi setelah server diperbaiki)
- ✨ Panduan sekali-tampil (izin notifikasi & optimasi baterai aplikasi) muncul otomatis setelah push aktif, dan penolakan izin dicatat di perangkat agar dialog tidak muncul berulang
- 🧪 Test: service push (kontrak `token_count`/503/429 `Retry-After`/404, kebijakan retry 401, identitas nim di secure storage, status baca per-NIM), aktivasi default-on (guard sesi, izin ditolak, sheet sekali), dan deep link (ekstraksi id, dedupe, antrean pending)
- 🩺 Pendaftaran token ditolak server (mis. adapter 503 — FCM belum dikonfigurasi) tak lagi memandu user ke "Pengaturan > Notifikasi" (pembetulan tak bisa membuka server); kartu Nonaktif kini menampilkan pesan kegagalan server + tombol "Muat Ulang" untuk mencoba lagi setelah server diperbaiki, dan aktivasi dipaksa ulang (melewati guard sesi) saat aplikasi dibuka kembali dari background

### Changed
- ♻️ Status baca notifikasi disimpan per-NIM (`read_notification_ids_<nim>`, migrasi otomatis dari kunci lama) dan dipangkas maksimal 2000 id; identitas nim kini ikut dipulihkan saat aplikasi dibuka kembali
- ♻️ `setUserInfo` menyimpan nim/nama ke secure storage (best-effort) dan dibersihkan saat logout
- ♻️ Data push berisi url https sekaligus `notif_id` kini diperlakukan sebagai siaran dan dibuka di browser; sebelumnya `notif_id` diutamakan sehingga ketukan membuka detail notifikasi di aplikasi
- ♻️ Notifikasi push kini aktif otomatis (default-on): izin `POST_NOTIFICATIONS` diminta sekali dan token perangkat langsung didaftarkan — tombol Aktifkan/Matikan pada kartu push dihapus dan kartu hanya menampilkan status
- 🧪 Test: kartu push kini tanpa tombol (state muat/nonaktif/aktif/tidak tersedia/gagal + panduan Pengaturan), seam `PushTokenProvider` dihapus (gateway FCM langsung dipakai), dan guard aktivasi sekali per sesi

### Fixed
- 🐛 "Tandai Dibaca" tidak berefek & item yang baru dibaca balik jadi "Baru" saat daftar notifikasi > 200: batas penyimpanan id dibaca dinaikkan 200 → 2000 (yang terbuang sebelumnya justru id terbaru), plus test regresi (daftar 325 id, tandai-semua berulang)
- 🐛 Id notifikasi tray untuk siaran (url https) memakai hash url, bukan `notif_id` mentah — mencegah siaran dan notifikasi privat dengan id numerik sama saling menimpa di panel notifikasi
- 🐛 Dialog izin notifikasi tidak lagi muncul ganda saat login pertama (guard sekali per sesi); bila izin ditolak permanen, push tak lagi mati tanpa petunjuk — kartu Nonaktif kini memandu ke Pengaturan > Notifikasi > Ini Amikom?

## [v1.11.1] - 2026-10-12

Rilis ini untuk menguji alur pembuatan APK otomatis — bukan menambah atau mengubah fitur. Yang dibuktikan: APK dari proses rilis otomatis memakai pengaturan server yang benar, dan catatan rilis bisa diambil sendiri dari CHANGELOG di tag yang sama. Fungsinya sama persis dengan v1.11.0; tidak ada perubahan apa pun di aplikasi.

### Fixed
- 🐛 APK hasil build GitHub Actions kini memakai `API_BASE_URL` asli dari repository variables, bukan `http://localhost:3000` dari `.env.example` — APK rilis CI sebelumnya memakai URL placeholder sehingga tidak bisa terhubung ke server (login dan data gagal)

### Changed
- ♻️ Catatan rilis GitHub diambil dari CHANGELOG sesuai tag; build gagal dengan pesan jelas bila bagian rilis untuk tag tersebut belum ditulis di CHANGELOG

## [v1.11.0] - 2026-10-12

### Added
- ✨ Kontrak "tiga besaran SKS": `total_sks_diambil` dari `progress-kelulusan`, `histori-ipk`, dan `cumlaude` — SKS lulus final (basis IPK), SKS berjalan, dan SKS terkumpul (gate kelulusan) kini terpisah jelas
- 🧪 Test transkrip: render `ProgressKelulusanCard` (penuh/belum/clamp 100%/desync), sheet cumlaude & histori IPK, plus render 360dp tanpa overflow
- ✨ Jadwal KRS: dukungan `komponen` (teori/praktek) dari agenda portal — baris berjadwal berpil "Praktikum"/"Kuliah Teori", seksi "Tanpa Praktikum" & "Tanpa Kelas" (dengan penjelasan), serta seksi "Ringkasan Mata Kuliah" (satu baris per mata kuliah + status) di tab "Cetak & Jadwal" KRS
- ✨ Validasi otomatis absensi: alur inspeksi → konfirmasi → kirim (`POST /api/v1/absensi/auto-validasi`, mode `inspeksi`/`tulis`), hasil tampil inline (sukses / gagal / dilewati) tanpa menutup halaman
- ✨ Dukungan penilaian asdos pada validasi praktikum: parse `asdoss[]`, key `asdospenilaian` `{indexAsdos}_{kritId}`, dan `asdos_npms` sesuai urutan
- ✨ Agenda terpadu: field baru `jam_mulai`/`jam_selesai` + bucket "Tanpa Jadwal" (matkul belum dijadwalkan) berlabel "Belum ada jadwal"
- ♻️ Helper `api_client` (guard/unwrapList/mutationRoot/forceJsonMap/extensionFromHeaders) + tab "Cetak & Jadwal" KRS (`KrsJadwalTab`): daftar mata kuliah KRS per hari + unduh/bagikan KRS

### Changed
- ♻️ Progress kelulusan memakai besaran baru **SKS Terkumpul**: gate `diambil` (lulus + berjalan), pill `100% (146/144)` dengan persen diklamp maksimal 100, cabang sisa 0 tampil "SKS terpenuhi" + "126 final • 20 berjalan", cabang sisa tampil "146 / 144 SKS Terkumpul" + "Sisa N SKS belum diambil"; jalur kelulusan (skripsi, technopreneur 140 SKS) otomatis mengikuti nilai baru backend
- ♻️ Beranda, sheet histori IPK, dan sheet cumlaude menampilkan "SKS Terkumpul"; transkrip menampilkan tile "SKS Lulus Final" + kalimat jembatan "126 SKS final + 20 SKS berjalan = 146 SKS terkumpul" saat kedua angka tersedia
- ♻️ Kalkulator target IPK memperjelas "Sisa SKS belum lulus" — beda basis matematis dari progress kelulusan, sengaja tidak disamakan
- ♻️ Halaman Jadwal Perkuliahan: baris kuliah tanpa jam tidak lagi dirender di hari biasa (bising secara visual); bucket "Belum ada jadwal" (Skripsi) dipertahankan sebagai pengingat tapi praktikum yang belum berjam dibuang; chip "Semua (N)" kini menghitung baris yang benar-benar tampil; keadaan kosong memakai pesan jujur dan tetap menyediakan chip filter
- ♻️ Jadwal KRS: dukungan `komponen` (teori/praktikum) — seksi "Tanpa Praktikum"/"Tanpa Kelas" + "Ringkasan Mata Kuliah", chip jam memakai `jam_mulai`

### Fixed
- 🐛 Tab "Cetak & Jadwal" KRS kini menghitung **mata kuliah unik**, bukan baris (matkul teori+praktikum sebelumnya dihitung dua kali), dan chip jam memakai `jam_mulai` dengan fallback `jam` lama
- 🐛 Deteksi "sedang berlangsung" di beranda memakai `jam_mulai`/`jam_selesai` — tak lagi rusak untuk ujian (`"12:30:00"`) maupun matkul tanpa jam
- 🐛 `jenispilih` tidak lagi ditebak dari keterangan huruf kehadiran; memakai jenis pertemuan dari BE dengan fallback `kuliah_tp_id` + `kuliahpraktek`
- 🐛 Validasi massal tak lagi bisa melaporkan "berhasil" palsu: envelope galat portal (`status:'error'`/`success:false`) kini dilempar sebagai `AppFailure` ramah
- 🐛 Hasil validasi menyegarkan badge "perlu validasi" DAN riwayat/statistik terpilih (sebelumnya data basi)
- 🐛 `_renewSessionWithLock` tidak lagi mencoba refresh dua kali — refresh token single-use; percobaan kedua hanya membakar token

### Refactor
- ♻️ Konsolidasi layanan: guard galat terpusat `ApiClient.guard`, `unwrapList`, `mutationRoot`, `forceJsonMap`, `extensionFromHeaders`; hapus 126 blok try/catch duplikat
- ♻️ Konsolidasi 11 kelas opsi dropdown kembar menjadi `ValueLabelOption`
- ♻️ Helper bersama: `AppSnack.show`, `AppConfirm.ask`, `AppPill.toneColors`, `AppFormSubmit.run`, `isAktivitasTerkunci`, `lib/utils/format.dart` (rupiah, semester, tanggal, opsi tahun)
- ♻️ Hapus kode mati: 11 route tak terpakai, method tanpa caller, field model tak terbaca, parameter widget tak dipakai
- ♻️ Hapus test duplikat/tautologi; tambah test nyata untuk kunci verifikasi aktivitas

## [v1.9.0] - 2026-08

- ✨ Rekomendasi Matakuliah Semester Pendek (SP)
- ✨ Evaluasi Cumlaude & progress kelulusan
- ✨ Ringkasan SKPI + simulator target IPK

## [v1.8.0] - 2026-08

- ✨ Modul Semester Pendek (3 tab: MK Pilihan, MK Dipilih, Jadwal SP)
- ✨ Modul SKMK, Izin Penelitian, Surat Tugas, PKL, dan Ujian Susulan

## [v1.7.0] - 2026-08

- ✨ Modul Keuangan: cek & bayar langsung dari aplikasi
- 💳 Pembuatan VA, pilih bank, multi-select bill, riwayat & detail pembayaran
- 📄 Download bukti PDF + halaman panduan pembayaran
- 🎨 Penanda VA aktif dengan nominal, tampilan semester Ganjil/Genap

## [v1.6.0] - 2026-07

- ✨ Fitur Prestasi Mahasiswa

## [v1.5.0] - 2026-07

- ✨ Modul Organisasi Mahasiswa
- 🩺 Cek status server offline di splash screen

## [v1.4.0] - 2026-07

- ✨ Modul Pusat Studi (layout expandable + navigasi grup WhatsApp)

## [v1.3.0] - 2026-07

- ✨ Fitur Asisten Praktikum

## [v1.2.0] - 2026-07

- 🔐 Auth: refresh token otomatis + simpan kredensial di secure storage
- 🧹 Hapus penyimpanan password di SharedPreferences

## [v1.1.0] - 2026-07

- 🎨 Redesign total Ice Blue & Liquid Glass
- ✨ Rebranding aplikasi

## [v1.0.0] - 2026-06

- 🚀 Rilis pertama
- 🔐 Login/logout, dashboard, berita kampus, KHS (pilih semester, tabel nilai, download PDF, share), pengumuman akademik

[Belum Dirilis]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.11.1...HEAD
[v1.11.1]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.11.0...v1.11.1
[v1.11.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.10.0...v1.11.0
[v1.9.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.8.0...v1.9.0
[v1.8.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.7.0...v1.8.0
[v1.7.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.6.0...v1.7.0
[v1.6.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.5.0...v1.6.0
[v1.5.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.4.0...v1.5.0
[v1.4.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.3.0...v1.4.0
[v1.3.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.2.0...v1.3.0
[v1.2.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.1.0...v1.2.0
[v1.1.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/wawiwuwawu/amikom-unofficial-app/releases/tag/v1.0.0