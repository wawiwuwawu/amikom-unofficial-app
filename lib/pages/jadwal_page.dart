import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/akademik_service.dart';
import '../services/periode_ujian_service.dart';
import '../models/agenda_terpadu.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/waktu.dart';
import '../widgets/app_kit.dart';
import 'jadwal_ujian_page.dart';

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

  /// Periode ujian terdekat (tanggal, 'UTS'/'UAS') — null bila tidak ada
  /// ujian mendatang / fetch gagal (fail-open dari [PeriodeUjianService]).
  (DateTime, String)? _periodeUjian;

  String _filterTipe = 'semua'; // 'semua', 'kuliah', 'asisten', 'ujian'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    // Agenda dimuat dulu — halaman TIDAK boleh menunggu fetch periode ujian
    // (dio yang sama, receiveTimeout 60 detik).
    try {
      final agenda = await _akademikService.getAgendaTerpadu();
      if (mounted) {
        setState(() {
          _agendaData = agenda;
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
    // Periode ujian menyusul secara non-blocking: selama belum tiba, gerbang
    // fail-open (ujian tampil); setState kedua menyaring begitu periode ada.
    final periode = await PeriodeUjianService.instance.tanggalUjianTerdekat();
    if (mounted) {
      setState(() => _periodeUjian = periode);
    }
  }

  bool _adaJam(AgendaItem i) => jamChip(i) != '-';

  /// Gerbang tampil ujian: baris ujian (tipe uts/uas) pada tampilan campuran /
  /// hari biasa hanya dirender bila tanggal ujian terdekat ada dan berada
  /// dalam [PeriodeUjianService.ambangHariUjian] hari ke depan (sementara
  /// sebulan sebelum ujian terbit, dulu membuat agenda bising sebulan penuh).
  ///
  /// Tab filter 'ujian' SENGAJA dikecualikan: user yang memilih tab Ujian
  /// bertindak sengaja melihat ujian, jadi di sana ujian tampil apa adanya.
  ///
  /// Fail-open: periode null (fetch gagal / tidak ada baris ber-tanggal) →
  /// ujian tampil seperti semula.
  bool _lolosGerbangUjian(AgendaItem item) {
    if (_filterTipe == 'ujian') return true;
    final tipe = item.tipe.trim().toLowerCase();
    if (tipe != 'uts' && tipe != 'uas') return true;
    return PeriodeUjianService.dalamJendela(_periodeUjian, _hariIni);
  }

  DateTime get _hariIni {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Ada baris ujian di agenda yang disembunyikan oleh gerbang? Hanya baris
  /// yang memang layak dirender (lolos aturan bucket hari) yang dihitung —
  /// ujian tanpa jam yang memang terbuang tidak boleh memunculkan banner.
  bool _adaUjianTersembunyi(AgendaTerpaduData data) {
    if (_filterTipe == 'ujian') return false;
    final periode = _periodeUjian;
    if (periode == null) return false; // fail-open: tidak ada yang disembunyikan
    for (final entry in data.agenda.entries) {
      for (final item in entry.value) {
        final tipe = item.tipe.trim().toLowerCase();
        final ujian = tipe == 'uts' || tipe == 'uas';
        if (ujian &&
            _lolosAturanHari(entry.key, item) &&
            !PeriodeUjianService.dalamJendela(periode, _hariIni)) {
          return true;
        }
      }
    }
    return false;
  }

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
  bool _lolosAturanHari(String day, AgendaItem i) {
    final key = day.trim().toLowerCase();
    if (key == 'tanpa jadwal') {
      // Baris yang memang sudah berjam jangan sampai hilang karena bucket.
      if (_adaJam(i)) return true;
      return (i.komponen ?? '').trim().toLowerCase() != 'praktek';
    }
    if (key == 'lainnya') return true;
    return _adaJam(i);
  }

  /// Gerbang ujian diterapkan SEBELUM aturan bucket & perhitungan chip, agar
  /// chip "Semua (N)" dan trailing hitungan hanya menghitung baris yang
  /// benar-benar tampil.
  bool _tampil(String day, AgendaItem i) =>
      _lolosGerbangUjian(i) && _lolosAturanHari(day, i);

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
        tampilkanBannerUjian: _adaUjianTersembunyi(data),
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
          if (_adaUjianTersembunyi(data)) ...[
            const SizedBox(height: AppSpacing.md),
            _bannerPeriodeUjian(),
          ],
          for (final day in sortedDays) _daySection(day, data.agenda[day]!),
        ],
      ),
    );
  }

  Widget _emptyAgendaState({String? message, int? total, bool tampilkanBannerUjian = false}) {
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
          // Bila agenda "kosong" karena SEMUA barisnya ujian yang digerbang,
          // banner tetap wajib tampil — empty state "belum punya jam" saja
          // akan menyesatkan user.
          if (tampilkanBannerUjian) ...[
            _bannerPeriodeUjian(),
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

  // ── Banner periode ujian (diketuk → halaman Jadwal Ujian) ──────────────────

  /// Banner info ujian yang masih di luar jendela tampil. Gaya mengikuti
  /// banner rekomendasi SP di dashboard (AppSurface + ikon + teks token),
  /// tetap satu baris yang bisa diketuk (AppSurface.onTap = InkWell).
  Widget _bannerPeriodeUjian() {
    final periode = _periodeUjian;
    final (tgl, jenis) = periode!;
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => _pushJadwalUjian(),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.calendar,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Jadwal ujian terbit — dimulai ${formatTanggalIndo(tgl)} '
              '($jenis), akan tampil di sini seminggu sebelumnya.',
              style: AppText.bodySm,
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _pushJadwalUjian() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JadwalUjianPage()),
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
          jamChip(item),
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
