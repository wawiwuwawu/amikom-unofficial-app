import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/dashboard.dart';
import '../models/agenda_terpadu.dart';
import '../models/sp.dart';
import '../services/api_client.dart';
import '../services/akademik_service.dart';
import '../services/sp_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import '../widgets/histori_ipk_sheet.dart';
import 'absensi_page.dart';
import 'jadwal_page.dart';
import 'sp_page.dart';
import 'keuangan_page.dart';

/// Beranda (Dashboard).
///
/// Prinsip: **beranda menampilkan INFORMASI, bukan navigasi.** Navigasi adalah
/// tugas bottom navigation.
///
/// Versi lama menaruh baris "aksi cepat" (Presensi / Jadwal / Nilai / Tagihan)
/// di sini, padahal 3 dari 4 tombolnya hanya menuju tab yang sudah ada di
/// bottom nav — dan Presensi bahkan sudah menjadi tombol QR di tengah bar.
/// Baris itu dihapus dan digantikan informasi yang benar-benar dibutuhkan saat
/// membuka aplikasi: jadwal hari ini, peringatan tagihan, dan ringkasan nilai.
class DashboardPage extends StatefulWidget {
  final int refreshTrigger;
  const DashboardPage({super.key, this.refreshTrigger = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _akademikService = AkademikService();
  final _spService = SpService();

  Dashboard? _data;
  AgendaTerpaduData? _agendaData;
  SpRekomendasiData? _spRekomendasiData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.instance.getDashboard(),
        _akademikService
            .getAgendaTerpadu()
            .catchError((_) => AgendaTerpaduData(totalAgenda: 0, agenda: {})),
        _spService.getRekomendasi().catchError((_) => SpRekomendasiData(
              hasRekomendasi: false,
              warningMessage: '',
              totalRekomendasi: 0,
              totalSks: 0,
              kategoriSangatDianjurkan: [],
              kategoriOpsionalSksBesar: [],
            )),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0] as Dashboard;
        _agendaData = results[1] as AgendaTerpaduData;
        _spRekomendasiData = results[2] as SpRekomendasiData;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Bangun halaman ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoading(message: 'Memuat beranda…');

    if (_error != null) {
      return SingleChildScrollView(
        padding: AppSpacing.page,
        child: AppErrorState(message: _error!, onRetry: _load),
      );
    }

    final d = _data;
    if (d == null) return const SizedBox.shrink();

    final perluBayar = d.status.status != 'Aktif' || d.status.status.isEmpty;
    final adaSp = _spRekomendasiData?.hasRekomendasi ?? false;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildGreeting(d.profile).animate().fadeIn(duration: 300.ms),

          // Peringatan hanya muncul bila memang ada masalah — tidak permanen.
          if (perluBayar) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildTagihanAlert().animate().fadeIn(delay: 80.ms),
          ],
          if (adaSp) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildSpRekomendasiBanner(_spRekomendasiData!)
                .animate()
                .fadeIn(delay: 120.ms),
          ],

          // Informasi paling dicari saat membuka aplikasi.
          _buildJadwalHariIni().animate().fadeIn(delay: 160.ms),

          _buildRingkasan(d).animate().fadeIn(delay: 200.ms),

          AppSection(
            title: 'Data Mahasiswa',
            child: _buildProfileCard(d.profile),
          ).animate().fadeIn(delay: 240.ms),
        ],
      ),
    );
  }

  // ── Sapaan ────────────────────────────────────────────────────────────────

  Widget _buildGreeting(Profile p) {
    final namaDepan = p.nama.split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Halo, $namaDepan', style: AppText.display),
        const SizedBox(height: AppSpacing.xs),
        Text(p.prodi, style: AppText.bodySm),
      ],
    );
  }

  // ── Peringatan tagihan ────────────────────────────────────────────────────

  Widget _buildTagihanAlert() {
    return AppSurface(
      variant: AppSurfaceVariant.warning,
      onTap: () => _push(KeuanganPage(onBack: () => Navigator.pop(context))),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaran tertunda',
                  style: AppText.h3.copyWith(color: AppColors.warning),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status akademik belum aktif. Ketuk untuk lihat tagihan.',
                  style: AppText.bodySm,
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  // ── Jadwal hari ini: daftar, bukan tombol menuju jadwal ────────────────────

  Widget _buildJadwalHariIni() {
    final todayName = _getHariIndo(DateTime.now().weekday);
    final items = _agendaData?.agenda[todayName] ?? [];
    final ongoing = _ongoingItem(items);

    return AppSection(
      title: 'Jadwal Hari Ini',
      trailing: TextButton(
        onPressed: () => _push(const JadwalPage()),
        child: const Text('Lihat semua'),
      ),
      child: items.isEmpty
          ? const AppSurface(
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    size: 18,
                    color: AppColors.success,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Tidak ada agenda kuliah atau ujian hari ini.'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (ongoing != null) ...[
                  _buildOngoingCard(ongoing),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppListGroup.from([
                  for (final item in items)
                    _agendaRow(item, isOngoing: identical(item, ongoing)),
                ]),
              ],
            ),
    );
  }

  AgendaItem? _ongoingItem(List<AgendaItem> items) {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    for (final item in items) {
      final parts = item.jam.split('-');
      if (parts.length >= 2) {
        final start = _timeToMinutes(parts[0]);
        final end = _timeToMinutes(parts[1]);
        if (nowMins >= start && nowMins <= end) return item;
      }
    }
    return null;
  }

  Widget _agendaRow(AgendaItem item, {required bool isOngoing}) {
    final tempat = [
      if (item.ruang.isNotEmpty) item.ruang,
      if (item.detail.isNotEmpty) item.detail,
    ].join(' • ');

    return AppListRow(
      leading: Container(
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Text(
          item.jam.split('-').first.trim(),
          style: AppText.h3.copyWith(
            fontSize: 12.5,
            color: AppColors.primary,
          ),
        ),
      ),
      title: item.matakuliah,
      subtitle: tempat.isEmpty ? null : tempat,
      trailing: isOngoing
          ? const AppPill('Berlangsung', tone: AppPillTone.danger)
          : null,
    );
  }

  Widget _buildOngoingCard(AgendaItem item) {
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppPill('Sedang berlangsung', tone: AppPillTone.danger),
              const Spacer(),
              Text(item.jam, style: AppText.label),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(item.matakuliah, style: AppText.h2),
          if (item.ruang.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.location_solid,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(item.ruang, style: AppText.bodySm),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  _push(AbsensiPage(onBack: () => Navigator.pop(context))),
              icon: const Icon(CupertinoIcons.qrcode_viewfinder, size: 18),
              label: const Text('Presensi Sekarang'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ringkasan statistik ───────────────────────────────────────────────────

  Widget _buildRingkasan(Dashboard d) {
    return AppSection(
      title: 'Ringkasan Studi',
      child: Row(
        children: [
          Expanded(
            child: AppStatTile(
              value: d.statistik.ipk.toStringAsFixed(2),
              label: 'IPK Kumulatif',
              icon: CupertinoIcons.rosette,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppStatTile(
              value: '${d.statistik.totalSks}',
              label: 'SKS Lulus',
              icon: CupertinoIcons.book_fill,
              accent: AppColors.info,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppSurface(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              onTap: () => showHistoriIpkBottomSheet(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.chart_bar_square,
                    size: 16,
                    color: AppColors.primarySoft,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Tren', style: AppText.metric.copyWith(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text('Grafik IPK', style: AppText.label, maxLines: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu data mahasiswa ──────────────────────────────────────────────────

  Widget _buildProfileCard(Profile p) {
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.card,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.network(
                    p.fotoUrl,
                    width: 48,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 48,
                      height: 64,
                      alignment: Alignment.center,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        CupertinoIcons.person_alt,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.nama, style: AppText.h3),
                      const SizedBox(height: 2),
                      Text('${p.npm} • ${p.prodi}', style: AppText.bodySm),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: AppSpacing.card,
            child: Column(
              children: [
                AppKeyValue(label: 'Angkatan', value: p.angkatan.toString()),
                AppKeyValue(label: 'Fakultas', value: p.fakultas),
                AppKeyValue(label: 'Email', value: p.email),
                AppKeyValue(
                  label: 'No. HP',
                  value: p.noHp.isNotEmpty ? p.noHp : '—',
                ),
                AppKeyValue(
                  label: 'Dosen PA',
                  value: p.pembimbingAkademik.isEmpty
                      ? '—'
                      : p.pembimbingAkademik,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner rekomendasi Semester Pendek ────────────────────────────────────

  Widget _buildSpRekomendasiBanner(SpRekomendasiData rekomendasi) {
    return AppSurface(
      variant: AppSurfaceVariant.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Rekomendasi Semester Pendek',
                  style: AppText.h3.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${rekomendasi.totalRekomendasi} mata kuliah • '
            '${rekomendasi.totalSks} SKS disarankan',
            style: AppText.label.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(rekomendasi.warningMessage, style: AppText.bodySm),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  _push(SpPage(onBack: () => Navigator.pop(context))),
              icon: const Icon(CupertinoIcons.arrow_right_circle_fill, size: 18),
              label: const Text('Lihat Rekomendasi'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Utilitas ──────────────────────────────────────────────────────────────

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String _getHariIndo(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return 'Senin';
    }
  }

  int _timeToMinutes(String timeStr) {
    final clean = timeStr.trim().replaceAll('.', ':');
    final parts = clean.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return 0;
  }
}
