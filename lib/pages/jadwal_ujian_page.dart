import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../services/akademik_service.dart';
import '../models/jadwal_ujian.dart';
import '../theme/app_theme.dart';
import '../utils/waktu.dart';
import '../widgets/app_kit.dart';
import '../models/app_failure.dart';

/// Jadwal ujian (UTS/UAS) — disajikan sebagai daftar ringkas bergaya tabel:
/// tanggal (info depan) · mata kuliah · jam · ruang · nomor kursi,
/// dengan aksi "Ingatkan di Kalender" per baris dan tombol cetak kartu ujian.
class JadwalUjianPage extends StatefulWidget {
  const JadwalUjianPage({super.key});

  @override
  State<JadwalUjianPage> createState() => _JadwalUjianPageState();
}

class _JadwalUjianPageState extends State<JadwalUjianPage> {
  final AkademikService _service = AkademikService();
  bool _isLoading = true;
  bool _isDownloading = false;
  String _error = '';
  List<JadwalUjian> _jadwalList = [];
  String _jenisUjian = 'uts'; // uts or uas

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getJadwalUjian(_jenisUjian);

      // Sort by date logically if we want to ensure order, but API usually returns ordered.
      // We assume API order is good.
      setState(() {
        _jadwalList = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = userErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadKartu() async {
    setState(() => _isDownloading = true);
    try {
      final path = await _service.downloadKartuUjian(_jenisUjian);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Berhasil mengunduh kartu ujian'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'BUKA',
              textColor: Colors.white,
              onPressed: () {
                OpenFilex.open(path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _addToGoogleCalendar(JadwalUjian jadwal) async {
    // TANGGAL kini yyyy-MM-dd (BE menyeragamkan); format warisan
    // dd-MM-yyyy tetap diterima lewat tanggalDariPortal.
    final dt = tanggalDariPortal(jadwal.tanggal);
    if (dt == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal ujian belum tersedia')),
        );
      }
      return;
    }

    // YYYYMMDD
    final dateStr = '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}';
    final startTimeStr = jadwal.jamMulai.replaceAll(':', '');
    final endTimeStr = jadwal.jamSelesai.replaceAll(':', '');

    final startDateTimeStr = '${dateStr}T${startTimeStr}Z';
    final endDateTimeStr = '${dateStr}T${endTimeStr}Z';

    final title = 'Ujian ${jadwal.mkl}';
    final details = 'Ruang: ${jadwal.ruang}\\nNo Kursi: ${jadwal.noKursi}';

    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&dates=$startDateTimeStr/$endDateTimeStr'
      '&details=${Uri.encodeComponent(details)}'
      '&location=${Uri.encodeComponent(jadwal.ruang)}',
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw const AppFailure('Tidak dapat membuka kalender.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userErrorMessage(e, 'Gagal memuat jadwal ujian. Silakan coba lagi.')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Jadwal Ujian',
      subtitle: _jenisUjian == 'uts'
          ? 'Ujian Tengah Semester'
          : 'Ujian Akhir Semester',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: _buildJenisToggle(),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ── Pemilih jenis ujian (UTS / UAS) ────────────────────────────────────────

  Widget _buildJenisToggle() {
    return AppSurface(
      radius: AppRadius.pill,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('UTS', 'uts')),
          Expanded(child: _buildTabButton('UAS', 'uas')),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, String type) {
    final isSelected = _jenisUjian == type;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _jenisUjian = type;
            _loadData();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Center(
          child: Text(
            title,
            style: AppText.button.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Isi halaman ────────────────────────────────────────────────────────────

  Widget _buildContent() {
    if (_isLoading) return const AppLoading(message: 'Memuat jadwal ujian…');

    if (_error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: AppErrorState(message: _error, onRetry: _loadData),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      title: 'Belum Waktunya Ujian Nih!',
      message: 'Saat ini tidak ada jadwal ujian yang tersedia. '
          'Gunakan waktumu sebaik mungkin untuk belajar dan beristirahat.',
      icon: CupertinoIcons.sparkles,
    );
  }

  Widget _buildList() {
    if (_jadwalList.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppSection(
            topGap: AppSpacing.md,
            title: 'Daftar ujian ${_jenisUjian.toUpperCase()}',
            trailing: _buildTrailingAksi(),
            child: _buildEmptyState(),
          ),
        ],
      );
    }

    // Daftar dibangun lazy per chunk ±20 baris; judul seksi + aksi cetak
    // tetap di atas chunk pertama (padanan AppSection lama, tampilan tidak
    // berubah).
    return AppChunkedList<JadwalUjian>(
      items: _jadwalList,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'DAFTAR UJIAN ${_jenisUjian.toUpperCase()}',
                  style: AppText.overline,
                ),
              ),
              _buildTrailingAksi(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
      rowBuilder: (_, jadwal) => _buildJadwalRow(jadwal),
    );
  }

  /// Trailing seksi: hitungan + tombol cetak kartu (pola AppSection.trailing
  /// ala skripsi_page) — menggantikan FAB yang mengambang di atas bar nav.
  /// Daftar kosong → tombol disabled.
  Widget _buildTrailingAksi() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_jadwalList.length} mata kuliah',
          style: AppText.label.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed:
              (_isDownloading || _jadwalList.isEmpty) ? null : _downloadKartu,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          icon: const Icon(CupertinoIcons.printer_fill, size: 16),
          label: Text(_isDownloading ? 'Mengunduh…' : 'Cetak Kartu'),
        ),
      ],
    );
  }

  /// Satu baris ujian — ringkas seperti tabel: tanggal · mata kuliah · jam ·
  /// ruang · kursi, plus aksi tambah ke kalender.
  ///
  /// Tanggal diparse lewat [tanggalDariPortal] yang menerima format baru
  /// `yyyy-MM-dd` (TANGGAL dari BE) sekaligus format warisan `dd-MM-yyyy`
  /// (TGL_UJIAN). Dulu halaman mengasumsikan dd-MM-yyyy, sehingga dengan
  /// format baru kotak depan menampilkan TAHUN ("2026") sebagai angka hari —
  /// itulah "jadwal UTS tidak ada tanggalnya" yang dilaporkan.
  Widget _buildJadwalRow(JadwalUjian jadwal) {
    final dt = tanggalDariPortal(jadwal.tanggal);
    final tanggalIndo = dt != null ? formatTanggalIndo(dt) : null;

    return AppListRow(
      leading: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: dt == null
            // Tanpa tanggal valid → tanda tanya, bukan angka menyesatkan.
            ? Text(
                '?',
                style: AppText.h3.copyWith(
                  color: AppColors.primary,
                  fontSize: 18,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${dt.day}',
                    style: AppText.h3.copyWith(
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _bulanPendek(dt.month),
                    style: AppText.label.copyWith(color: AppColors.primarySoft),
                  ),
                ],
              ),
      ),
      title: jadwal.mkl,
      subtitle: '${jadwal.kode} • ${jadwal.hari}'
          '${tanggalIndo != null ? ' • $tanggalIndo' : ''}\n'
          '${_jamRange(jadwal)} • ${jadwal.ruang} • Kursi ${jadwal.noKursi}',
      trailing: IconButton(
        tooltip: 'Ingatkan di Kalender',
        onPressed: () => _addToGoogleCalendar(jadwal),
        icon: const Icon(
          CupertinoIcons.calendar_badge_plus,
          size: 20,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Nama bulan pendek untuk kotak tanggal (cukup 3 huruf agar muat 50 px).
  String _bulanPendek(int bulan) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ][bulan - 1];

  /// Rentang jam "HH:mm - HH:mm" (aman bila string jam lebih pendek).
  String _jamRange(JadwalUjian jadwal) {
    if (jadwal.jamMulai.isEmpty && jadwal.jamSelesai.isEmpty) return '-';
    return '${_hhmm(jadwal.jamMulai)} - ${_hhmm(jadwal.jamSelesai)}';
  }

  String _hhmm(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;
}
