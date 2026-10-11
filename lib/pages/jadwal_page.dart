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

  /// Chip jam: utamakan `jam_mulai` (marker kosong portal adalah '-', bukan
  /// string kosong), jatuh ke `jam` warisan. Satu sumber untuk predikat
  /// "berjam" supaya tak ada divergensi antara aturan tampil dan tampilan.
  String _jamChip(AgendaItem i) {
    final m = i.jamMulai.trim();
    if (m.isNotEmpty && m != '-') return m;
    final j = i.jam.trim();
    return j.isEmpty || j == '-' ? '-' : j;
  }

  bool _adaJam(AgendaItem i) => _jamChip(i) != '-';

  /// Baris lolos filter tipe yang sedang aktif.
  bool _sesuaiTipe(AgendaItem item) {
    switch (_filterTipe) {
      case 'kuliah':
        return item.tipe == 'kuliah';
      case 'asisten':
        return item.tipe == 'asisten';
      case 'ujian':
        return item.tipe == 'uts' || item.tipe == 'uas';
      default:
        return true;
    }
  }

  /// Aturan tampil per bucket: hari biasa wajib berjam (sisanya jadi bising),
  /// "Tanpa Jadwal" tetap pengingat Skripsi tapi buang praktikum yang belum
  /// berjam, dan "Lainnya" dibiarkan utuh.
  bool _tampil(String day, AgendaItem i) {
    final key = day.trim().toLowerCase();
    if (key == 'tanpa jadwal') {
      // Baris yang memang sudah berjam jangan sampai hilang karena bucket.
      if (_adaJam(i)) return true;
      return (i.komponen ?? '').trim().toLowerCase() != 'praktek';
    }
    if (key == 'lainnya') return true;
    return _adaJam(i);
  }

  /// Jumlah baris yang benar-benar tampil setelah aturan di atas — dipakai
  /// chip "Semua (N)" supaya tidak mengumumkan lebih dari yang ada di layar.
  int _jumlahTampil(AgendaTerpaduData data) => data.agenda.entries.fold<int>(
        0,
        (sum, entry) =>
            sum + entry.value.where((item) => _tampil(entry.key, item)).length,
      );

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
    if (data == null) return _emptyAgendaState();

    // Map agenda selalu berisi semua bucket (termasuk yang kosong) — yang
    // menentukan "kosong" adalah ADA BARIS, bukan jumlah key.
    final adaBaris = data.agenda.values.any((baris) => baris.isNotEmpty);
    if (!adaBaris) return _emptyAgendaState(total: 0);

    final jumlahTampil = _jumlahTampil(data);
    final jumlahSesuaiFilter = data.agenda.entries.fold<int>(
      0,
      (sum, entry) => sum +
          entry.value
              .where((item) => _tampil(entry.key, item) && _sesuaiTipe(item))
              .length,
    );
    if (jumlahSesuaiFilter == 0) {
      // Chip filter ikut ditampilkan supaya pengguna selalu punya jalan keluar
      // (filter aktif tak bisa diubah dari state kosong tanpa ini).
      return _emptyAgendaState(
        message: _filterTipe == 'semua'
            ? 'Jadwal yang tersimpan belum punya jam, jadi belum bisa '
                'ditampilkan. Tarik ke bawah untuk menyegarkan.'
            : 'Tidak ada jadwal untuk filter ini. Pilih "Semua" untuk '
                'melihat seluruh agenda.',
        total: jumlahTampil,
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
          _filterRow(total: jumlahTampil),
          for (final day in sortedDays) _daySection(day, data.agenda[day]!),
        ],
      ),
    );
  }

  Widget _emptyAgendaState({String? message, int? total}) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 130,
        ),
        children: [
          if (total != null) ...[
            _filterRow(total: total),
            const SizedBox(height: AppSpacing.sm),
          ],
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          AppEmptyState(
            title: 'Belum ada agenda',
            message: message ??
                'Tidak ada jadwal agenda terpadu untuk ditampilkan. '
                    'Tarik ke bawah untuk menyegarkan.',
            icon: CupertinoIcons.calendar,
          ),
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
    final filteredItems = items
        .where(_sesuaiTipe)
        .where((item) => _tampil(day, item))
        .toList();

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
          _jamChip(item),
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
