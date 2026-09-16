import 'package:flutter/cupertino.dart';

import '../pages/absensi_page.dart';
import '../pages/agenda_akademik_page.dart';
import '../pages/asisten_page.dart';
import '../pages/berita_list_page.dart';
import '../pages/keuangan_page.dart';
import '../pages/khs_page.dart';
import '../pages/izin_penelitian_page.dart';
import '../pages/jadwal_page.dart';
import '../pages/jadwal_ujian_page.dart';
import '../pages/krs/krs_main_page.dart';
import '../pages/mbkm_page.dart';
import '../pages/nilai_rincian_page.dart';
import '../pages/notifikasi_list_page.dart';
import '../pages/organisasi_page.dart';
import '../pages/panduan_list_page.dart';
import '../pages/penafian_page.dart';
import '../pages/pengumuman_list_page.dart';
import '../pages/pkl_page.dart';
import '../pages/ppks_page.dart';
import '../pages/prestasi_page.dart';
import '../pages/pusat_studi/pusat_studi_page.dart';
import '../pages/rekognisi_page.dart';
import '../pages/seminar_page.dart';
import '../pages/seminar_workshop_page.dart';
import '../pages/sertifikasi_page.dart';
import '../pages/skmk_page.dart';
import '../pages/skripsi_page.dart';
import '../pages/sp_page.dart';
import '../pages/surat_tugas_page.dart';
import '../pages/tata_krama_page.dart';
import '../pages/transkrip_page.dart';
import '../pages/ujian_susulan_page.dart';
import '../pages/visi_misi_institusi_page.dart';
import '../pages/visi_misi_page.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// KATALOG MENU — sumber tunggal untuk seluruh daftar menu aplikasi.
///
/// Dipakai oleh:
///   * Tab "Menu"  → menampilkan SEMUA menu dikelompokkan per frekuensi
///                   pemakaian (paling sering → paling jarang).
///   * Drawer      → pintasan untuk hal yang jarang dibuka TAPI perlu cepat
///                   ditemukan (pengumuman, berita, panduan, tata krama, dll).
///   * Pencarian   → mencari menu berdasarkan judul/kata kunci.
///
/// Menambah menu baru = cukup tambah satu entri di sini; tab Menu dan Drawer
/// otomatis ikut terbarui (dulu ada dua daftar terpisah yang harus disinkronkan
/// manual — sumber bug).
/// ─────────────────────────────────────────────────────────────────────────────

/// Seberapa sering mahasiswa membuka menu ini.
/// Urutan enum = urutan tampil (paling sering lebih dulu).
enum MenuFrequency {
  /// Dibuka hampir setiap hari (mis. presensi, jadwal).
  harian,

  /// Dibuka berkala: mingguan / bulanan (mis. nilai, tagihan, pengumuman).
  berkala,

  /// Dibuka per semester / saat periode tertentu (mis. KRS, surat, MBKM).
  semesteran,

  /// Jarang dibuka, umumnya sekali atau insidental (mis. visi misi, penafian).
  insidental,
}

extension MenuFrequencyX on MenuFrequency {
  String get label => switch (this) {
        MenuFrequency.harian => 'Sering Digunakan',
        MenuFrequency.berkala => 'Berkala',
        MenuFrequency.semesteran => 'Per Semester',
        MenuFrequency.insidental => 'Jarang Dibuka',
      };

  /// Keterangan singkat di bawah judul kelompok.
  String get hint => switch (this) {
        MenuFrequency.harian => 'Dibuka hampir tiap hari',
        MenuFrequency.berkala => 'Mingguan atau bulanan',
        MenuFrequency.semesteran => 'Saat periode akademik tertentu',
        MenuFrequency.insidental => 'Sesekali — penting tapi jarang',
      };

  IconData get icon => switch (this) {
        MenuFrequency.harian => CupertinoIcons.bolt_fill,
        MenuFrequency.berkala => CupertinoIcons.clock_fill,
        MenuFrequency.semesteran => CupertinoIcons.calendar,
        MenuFrequency.insidental => CupertinoIcons.archivebox_fill,
      };
}

/// Satu entri menu.
class MenuEntry {
  final String title;
  final String description;
  final IconData icon;
  final MenuFrequency frequency;

  /// Membangun halaman tujuan. `ctx` dipakai untuk tombol kembali.
  final Widget Function(BuildContext ctx) build;

  const MenuEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.frequency,
    required this.build,
  });

  /// Untuk pencarian: cocokkan judul, keterangan, dan kata kunci tambahan.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }
}

abstract final class MenuCatalog {
  /// SEMUA menu aplikasi, diurutkan per frekuensi lalu abjad.
  static final List<MenuEntry> all = [
    // ── Sering digunakan (harian) ────────────────────────────────────────────
    MenuEntry(
      title: 'Presensi',
      description: 'Absen kehadiran kuliah dengan QR',
      icon: CupertinoIcons.qrcode_viewfinder,
      frequency: MenuFrequency.harian,
      build: (ctx) => AbsensiPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Jadwal Kuliah',
      description: 'Jadwal kuliah hari ini & minggu ini',
      icon: CupertinoIcons.time,
      frequency: MenuFrequency.harian,
      build: (ctx) => const JadwalPage(),
    ),

    // ── Berkala (mingguan / bulanan) ─────────────────────────────────────────
    MenuEntry(
      title: 'Nilai & KHS',
      description: 'Kartu hasil studi per semester',
      icon: CupertinoIcons.rosette,
      frequency: MenuFrequency.berkala,
      build: (ctx) => const KhsPage(),
    ),
    MenuEntry(
      title: 'Rincian Nilai',
      description: 'Rincian komponen penilaian tiap mata kuliah',
      icon: CupertinoIcons.chart_bar_alt_fill,
      frequency: MenuFrequency.berkala,
      build: (ctx) => NilaiRincianPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Transkrip Nilai',
      description: 'Rekap nilai seluruh semester & IPK',
      icon: CupertinoIcons.doc_text_fill,
      frequency: MenuFrequency.berkala,
      build: (ctx) => TranskripPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Tagihan & Keuangan',
      description: 'Virtual account, tagihan, dan riwayat bayar',
      icon: CupertinoIcons.creditcard_fill,
      frequency: MenuFrequency.berkala,
      build: (ctx) => KeuanganPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Jadwal Ujian',
      description: 'Jadwal UTS, UAS, dan ujian susulan',
      icon: CupertinoIcons.check_mark_circled,
      frequency: MenuFrequency.berkala,
      build: (ctx) => JadwalUjianPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Agenda Akademik',
      description: 'Kalender kegiatan akademik kampus',
      icon: CupertinoIcons.calendar,
      frequency: MenuFrequency.berkala,
      build: (ctx) => AgendaAkademikPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Pengumuman Akademik',
      description: 'Pengumuman resmi dari bagian akademik',
      icon: CupertinoIcons.speaker_2_fill,
      frequency: MenuFrequency.berkala,
      build: (ctx) => const PengumumanListPage(),
    ),
    MenuEntry(
      title: 'Notifikasi',
      description: 'Pemberitahuan pribadi & status baca',
      icon: CupertinoIcons.bell_fill,
      frequency: MenuFrequency.berkala,
      build: (ctx) => NotifikasiListPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Berita Kampus',
      description: 'Kabar dan kegiatan terbaru kampus',
      icon: CupertinoIcons.news_solid,
      frequency: MenuFrequency.berkala,
      build: (ctx) => const BeritaListPage(),
    ),

    // ── Per semester ────────────────────────────────────────────────────────
    MenuEntry(
      title: 'KRS Online',
      description: 'Isi dan lihat kartu rencana studi',
      icon: CupertinoIcons.doc_text_search,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => KrsMainPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Skripsi & Tugas Akhir',
      description: 'Pengajuan judul, bimbingan, dan sidang',
      icon: CupertinoIcons.book_circle_fill,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => SkripsiPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'MBKM Internal',
      description: 'Pendaftaran dan laporan MBKM',
      icon: CupertinoIcons.building_2_fill,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => MbkmPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'PKL & Mandiri',
      description: 'Praktik kerja lapangan dan kegiatan mandiri',
      icon: CupertinoIcons.briefcase_fill,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => PklPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Surat Tugas',
      description: 'Ajukan dan unduh surat tugas kegiatan',
      icon: CupertinoIcons.doc_on_clipboard_fill,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => SuratTugasPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'SKMK',
      description: 'Surat keterangan mahasiswa aktif',
      icon: CupertinoIcons.doc_plaintext,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => SkmkPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Izin Penelitian',
      description: 'Permohonan izin penelitian tugas akhir',
      icon: CupertinoIcons.search_circle_fill,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => IzinPenelitianPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Ujian Susulan',
      description: 'Pendaftaran ujian susulan',
      icon: CupertinoIcons.calendar_badge_minus,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => UjianSusulanPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Semester Pendek',
      description: 'Pendaftaran semester antara',
      icon: CupertinoIcons.layers_alt_fill,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => SpPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Asisten Praktikum',
      description: 'Pendaftaran dan penilaian asisten',
      icon: CupertinoIcons.briefcase,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => AsistenPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Jadwal Seminar',
      description: 'Jadwal seminar proposal dan hasil',
      icon: CupertinoIcons.person_3_fill,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => SeminarPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Seminar & Workshop',
      description: 'Pendaftaran seminar dan workshop',
      icon: CupertinoIcons.rectangle_grid_2x2_fill,
      frequency: MenuFrequency.semesteran,
      build: (ctx) =>
          SeminarWorkshopPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Panduan Akademik',
      description: 'Buku panduan dan aturan akademik',
      icon: CupertinoIcons.book,
      frequency: MenuFrequency.semesteran,
      build: (ctx) => const PanduanListPage(),
    ),

    // ── Jarang dibuka (insidental) ──────────────────────────────────────────
    MenuEntry(
      title: 'Prestasi',
      description: 'Catat dan lihat prestasi mahasiswa',
      icon: CupertinoIcons.star_fill,
      frequency: MenuFrequency.insidental,
      build: (ctx) => PrestasiPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Organisasi',
      description: 'Keanggotaan dan kegiatan organisasi',
      icon: CupertinoIcons.person_3_fill,
      frequency: MenuFrequency.insidental,
      build: (ctx) => OrganisasiPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Sertifikasi',
      description: 'Sertifikat kompetensi mahasiswa',
      icon: CupertinoIcons.doc_checkmark_fill,
      frequency: MenuFrequency.insidental,
      build: (ctx) => SertifikasiPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Rekognisi Mahasiswa',
      description: 'Pengakuan kegiatan terhadap SKS',
      icon: CupertinoIcons.rosette,
      frequency: MenuFrequency.insidental,
      build: (ctx) => RekognisiPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Pusat Studi',
      description: 'Informasi pusat studi kampus',
      icon: CupertinoIcons.building_2_fill,
      frequency: MenuFrequency.insidental,
      build: (ctx) => PusatStudiPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Satgas PPKS',
      description: 'Layanan pencegahan kekerasan seksual',
      icon: CupertinoIcons.shield_fill,
      frequency: MenuFrequency.insidental,
      build: (ctx) => PpksPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Visi & Misi Program Studi',
      description: 'Visi misi program studi',
      icon: CupertinoIcons.eye_fill,
      frequency: MenuFrequency.insidental,
      build: (ctx) => VisiMisiPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Visi & Misi Institusi',
      description: 'Visi misi universitas',
      icon: CupertinoIcons.building_2_fill,
      frequency: MenuFrequency.insidental,
      build: (ctx) => VisiMisiInstitusiPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Tata Krama Mahasiswa',
      description: 'Norma dan etika mahasiswa di kampus',
      icon: CupertinoIcons.person_2_alt,
      frequency: MenuFrequency.insidental,
      build: (ctx) => TataKramaPage(onBack: () => Navigator.pop(ctx)),
    ),
    MenuEntry(
      title: 'Penafian',
      description: 'Disclaimer aplikasi tidak resmi',
      icon: CupertinoIcons.exclamationmark_shield,
      frequency: MenuFrequency.insidental,
      build: (ctx) => const PenafianPage(),
    ),
  ];

  /// Semua menu pada satu tingkat frekuensi (urut abjad di dalam kelompok).
  static List<MenuEntry> byFrequency(MenuFrequency f) {
    final list = all.where((e) => e.frequency == f).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  /// Menu dikelompokkan per frekuensi, hanya kelompok yang tidak kosong.
  static Map<MenuFrequency, List<MenuEntry>> get grouped {
    final result = <MenuFrequency, List<MenuEntry>>{};
    for (final f in MenuFrequency.values) {
      final list = byFrequency(f);
      if (list.isNotEmpty) result[f] = list;
    }
    return result;
  }

  /// Pencarian menu.
  static List<MenuEntry> search(String query) =>
      all.where((e) => e.matches(query)).toList();

  /// Cari satu menu berdasarkan judul persis (untuk deep link).
  static MenuEntry? byTitle(String title) {
    for (final e in all) {
      if (e.title == title) return e;
    }
    return null;
  }

  // ── Bagian Drawer ────────────────────────────────────────────────────────
  // Drawer = hal yang JARANG dibuka tapi perlu cepat ditemukan.
  // Sengaja hanya memuat sedikit pintasan terkurasi, bukan katalog penuh
  // (katalog lengkap ada di tab "Menu").

  /// Kelompok 1 — Informasi & pengumuman.
  static List<MenuEntry> get drawerInformasi => [
        _require('Pengumuman Akademik'),
        _require('Notifikasi'),
        _require('Berita Kampus'),
        _require('Panduan Akademik'),
      ];

  /// Kelompok 2 — Panduan & referensi kampus.
  static List<MenuEntry> get drawerReferensi => [
        _require('Tata Krama Mahasiswa'),
        _require('Visi & Misi Program Studi'),
        _require('Visi & Misi Institusi'),
        _require('Penafian'),
      ];

  /// Kelompok 3 — Layanan penting yang jarang dibuka.
  static List<MenuEntry> get drawerLayananPenting => [
        _require('Skripsi & Tugas Akhir'),
        _require('MBKM Internal'),
        _require('PKL & Mandiri'),
        _require('Surat Tugas'),
        _require('Rekognisi Mahasiswa'),
        _require('Satgas PPKS'),
      ];

  static MenuEntry _require(String title) {
    final e = byTitle(title);
    if (e == null) {
      throw StateError('MenuCatalog: entri "$title" tidak ditemukan.');
    }
    return e;
  }
}
