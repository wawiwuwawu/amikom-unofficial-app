import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../services/akademik_service.dart';
import '../models/jadwal_ujian.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

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
        _error = e.toString().replaceFirst('Exception: ', '');
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
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _addToGoogleCalendar(JadwalUjian jadwal) async {
    // TANGGAL format: "08-07-2026"
    final parts = jadwal.tanggal.split('-');
    if (parts.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format tanggal tidak valid')),
      );
      return;
    }

    // YYYYMMDD
    final dateStr = '${parts[2]}${parts[1]}${parts[0]}';
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
        throw Exception('Tidak dapat membuka kalender');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
      floatingActionButton: _jadwalList.isNotEmpty && !_isLoading
          ? _buildCetakKartu()
          : null,
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
      child: _jadwalList.isEmpty ? _buildEmptyState() : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const AppEmptyState(
          title: 'Belum Waktunya Ujian Nih!',
          message: 'Saat ini tidak ada jadwal ujian yang tersedia. '
              'Gunakan waktumu sebaik mungkin untuk belajar dan beristirahat.',
          icon: CupertinoIcons.sparkles,
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom:
            MediaQuery.of(context).padding.bottom +
            200, // padding extra for FAB and Nav
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        AppSection(
          topGap: AppSpacing.md,
          title: 'Daftar ujian ${_jenisUjian.toUpperCase()}',
          trailing: Text(
            '${_jadwalList.length} mata kuliah',
            style: AppText.label.copyWith(fontWeight: FontWeight.w400),
          ),
          child: AppListGroup.from([
            for (final jadwal in _jadwalList) _buildJadwalRow(jadwal),
          ]),
        ),
      ],
    );
  }

  /// Satu baris ujian — ringkas seperti tabel: tanggal · mata kuliah · jam ·
  /// ruang · kursi, plus aksi tambah ke kalender.
  Widget _buildJadwalRow(JadwalUjian jadwal) {
    final parts = jadwal.tanggal.split('-');
    final tanggal = parts.isNotEmpty ? parts[0] : jadwal.tanggal;
    final bulan = parts.length > 1 ? parts[1] : '';

    return AppListRow(
      leading: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tanggal,
              style: AppText.h3.copyWith(
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
            if (bulan.isNotEmpty)
              Text(
                bulan,
                style: AppText.label.copyWith(color: AppColors.primarySoft),
              ),
          ],
        ),
      ),
      title: jadwal.mkl,
      subtitle: '${jadwal.kode} • ${jadwal.hari}\n'
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

  Widget _buildCetakKartu() {
    return Padding(
      // Ekstra padding yang lebih tinggi (FAB + bottom nav).
      padding: const EdgeInsets.only(bottom: 140.0),
      child: FloatingActionButton.extended(
        onPressed: _isDownloading ? null : _downloadKartu,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: Icon(
          _isDownloading ? CupertinoIcons.hourglass : CupertinoIcons.printer_fill,
          color: Colors.white,
        ),
        label: Text(
          _isDownloading ? 'Mengunduh...' : 'Cetak Kartu Ujian',
          style: AppText.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  /// Rentang jam "HH:mm - HH:mm" (aman bila string jam lebih pendek).
  String _jamRange(JadwalUjian jadwal) {
    if (jadwal.jamMulai.isEmpty && jadwal.jamSelesai.isEmpty) return '-';
    return '${_hhmm(jadwal.jamMulai)} - ${_hhmm(jadwal.jamSelesai)}';
  }

  String _hhmm(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;
}
