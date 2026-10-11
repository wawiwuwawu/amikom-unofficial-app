import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/akademik_service.dart';
import '../models/agenda_terpadu.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_kit.dart';

/// Jadwal perkuliahan (agenda terpadu) — fitur yang dibuka hampir tiap hari,
/// jadi disajikan sebagai DAFTAR PER HARI yang bisa dipindai sekejap:
/// jam (info depan) → mata kuliah (judul) → ruang/dosen (keterangan).
///
/// Hari yang sedang berjalan ditonjolkan lewat `AppSurface` varian `hero`
/// plus label "Hari ini", supaya kelas berikutnya langsung terlihat.
class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _akademikService = AkademikService();

  bool _loading = true;
  String? _error;
  AgendaTerpaduData? _agendaData;

  String _filterTipe = 'semua'; // 'semua', 'kuliah', 'asisten', 'ujian'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _akademikService.getAgendaTerpadu();
      if (mounted) {
        setState(() {
          _agendaData = res;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = userErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Jadwal Perkuliahan',
      subtitle: 'Kuliah, asisten, dan ujian dalam satu agenda',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading(message: 'Memuat jadwal…');

    final error = _error;
    if (error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: AppErrorState(message: error, onRetry: _load),
        ),
      );
    }

    final data = _agendaData;
    if (data == null || data.agenda.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 130,
          ),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            const AppEmptyState(
              title: 'Belum ada agenda',
              message: 'Tidak ada jadwal agenda terpadu untuk ditampilkan. '
                  'Tarik ke bawah untuk menyegarkan.',
              icon: CupertinoIcons.calendar,
            ),
          ],
        ),
      );
    }

    final sortedDays = data.agenda.keys.toList()
      ..sort((a, b) => dayValue(a).compareTo(dayValue(b)));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + 130,
        ),
        children: [
          _filterRow(total: data.totalAgenda),
          for (final day in sortedDays) _daySection(day, data.agenda[day]!),
        ],
      ),
    );
  }

  // ── Baris alat: filter tipe ────────────────────────────────────────────────

  Widget _filterRow({required int total}) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('semua', 'Semua ($total)'),
                const SizedBox(width: AppSpacing.sm),
                _filterChip('kuliah', 'Kuliah 📘'),
                const SizedBox(width: AppSpacing.sm),
                _filterChip('asisten', 'Asisten 🟣'),
                const SizedBox(width: AppSpacing.sm),
                _filterChip('ujian', 'Ujian 🔴'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filterTipe == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      side: isSelected ? BorderSide.none : const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      labelStyle: AppText.label.copyWith(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      onSelected: (val) {
        if (val) setState(() => _filterTipe = value);
      },
    );
  }

  // ── Satu seksi per hari ────────────────────────────────────────────────────

  Widget _daySection(String day, List<AgendaItem> items) {
    final filteredItems = items.where((item) {
      if (_filterTipe == 'semua') return true;
      if (_filterTipe == 'kuliah') return item.tipe == 'kuliah';
      if (_filterTipe == 'asisten') return item.tipe == 'asisten';
      if (_filterTipe == 'ujian') return item.tipe == 'uts' || item.tipe == 'uas';
      return true;
    }).toList();

    if (filteredItems.isEmpty) return const SizedBox.shrink();

    final isToday = dayValue(day) == DateTime.now().weekday;
    final rows = [for (final item in filteredItems) _agendaRow(item)];

    return AppSection(
      title: agendaDayLabel(day),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday) ...[
            const AppPill('Hari ini', tone: AppPillTone.info),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            '${filteredItems.length} kegiatan',
            style: AppText.label.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
      // Hari aktif dibungkus permukaan `hero` supaya paling menonjol.
      child: isToday
          ? AppSurface(
              variant: AppSurfaceVariant.hero,
              radius: AppRadius.lg,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: AppListGroup.from(rows),
            )
          : AppListGroup.from(rows),
    );
  }

  Widget _agendaRow(AgendaItem item) {
    final (label, tone) = _tipeStyle(item.tipe);

    final keterangan = <String>[
      item.ruang.isEmpty ? '-' : item.ruang,
      if (item.detail.isNotEmpty) item.detail,
    ];

    return AppListRow(
      // Jam jadi info depan: yang dicari pertama saat melihat jadwal.
      leading: Container(
        width: 64,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Text(
          item.jam.isEmpty ? '-' : item.jam,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: item.matakuliah.isEmpty ? '-' : item.matakuliah,
      subtitle: keterangan.join(' • '),
      trailing: AppPill(label, tone: tone),
    );
  }

  /// Label + warna pil per tipe agenda (kuliah / asisten / ujian).
  (String, AppPillTone) _tipeStyle(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'kuliah':
        return ('Kuliah', AppPillTone.info);
      case 'asisten':
        return ('Asisten', AppPillTone.neutral);
      case 'uts':
      case 'uas':
        return (tipe.toUpperCase(), AppPillTone.danger);
      default:
        return (tipe, AppPillTone.neutral);
    }
  }
}
