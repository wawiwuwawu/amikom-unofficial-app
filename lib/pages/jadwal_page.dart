import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/akademik_service.dart';
import '../services/agenda_cache_service.dart';
import '../services/periode_ujian_service.dart';
import '../services/widget_jadwal_service.dart';
import '../models/agenda_terpadu.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/waktu.dart';
import '../widgets/app_kit.dart';
import 'jadwal_ujian_page.dart';

/// Jadwal perkuliahan (agenda terpadu) — fitur yang dibuka hampir tiap hari,
/// jadi disajikan dalam DUA mode tampilan:
///
///  * **Hari** (default): daftar per hari yang bisa dipindai sekejap — jam
///    (info depan) → mata kuliah (judul) → ruang/dosen (keterangan). Hari yang
///    sedang berjalan ditonjolkan lewat `AppSurface` varian `hero`.
///  * **Minggu**: grid mingguan bergaya kalender (tanpa package tambahan) —
///    kolom Senin–Minggu, sumbu jam 07:00–19:00, blok agenda diposisikan
///    proporsional dari jam mulai/selesai.
///
/// Daftar mode hari dibagi menjadi chunk ±20 baris via `ListView.builder`:
/// item jauh tidak lagi dibangun sekaligus di build pertama. Muat data memakai
/// pola stale-while-revalidate (`AgendaCacheService`): cache dirender instan,
/// fetch tetap berjalan, dan label "data terakhir" hanya muncul saat fetch
/// gagal tetapi cache masih ada.
class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

/// Satu chunk daftar mode hari: potongan baris milik satu hari. Chunk
/// pertama hari membawa judul seksi + trailing; chunk lanjutan hanya membawa
/// baris sisa. (Typedef level file — Dart melarang typedef di dalam kelas.)
typedef _ChunkHari = ({
  String? judul,
  Widget? trailing,
  bool hero,
  List<Widget> rows,
});

class _JadwalPageState extends State<JadwalPage> {
  final _akademikService = AkademikService();

  /// Kunci persistensi pilihan mode tampilan (hari/minggu).
  static const _kModeTampilan = 'jadwal_mode_tampilan';

  /// Ukuran chunk daftar mode hari (baris per `AppListGroup`).
  static const _ukuranChunk = 20;

  // ── Konstanta grid mingguan ───────────────────────────────────────────────
  static const int _jamMulaiGrid = 7; // 07:00
  static const int _jamSelesaiGrid = 19; // 19:00

  /// Tinggi 1 jam pada grid: 64px agar blok 1 jam utuh memuat jam + nama
  /// (2 baris) + ruang tanpa overflow.
  static const double _tinggiPerJam = 64;
  static const double _lebarGutterJam = 44;
  static const double _tinggiHeaderHari = 38;
  static const double _tinggiBlokMinimum = 32;

  /// Singkatan hari grid, indeks 0 = Senin (selaras `dayValue`).
  static const _singkatanHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  /// Singkatan bulan untuk label rentang minggu, indeks 0 = Januari.
  static const _bulanPendek = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  bool _loading = true;
  String? _error;
  AgendaTerpaduData? _agendaData;

  String _filterTipe = 'semua'; // 'semua', 'kuliah', 'asisten', 'ujian'

  /// Mode tampilan aktif: 'hari' (daftar) atau 'minggu' (grid mingguan).
  String _modeTampilan = 'hari';

  /// SWR: true bila konten yang tampil berasal dari cache (fetch gagal).
  bool _pakaiCache = false;

  /// Timestamp cache terakhir diperbarui, untuk label "data terakhir".
  DateTime? _cacheTerakhirDisimpan;

  /// Senin dari minggu yang sedang dilihat di mode minggu.
  DateTime _mingguDasar = _seninDari(DateTime.now());

  @override
  void initState() {
    super.initState();
    _muatModeTersimpan();
    _load();
  }

  /// Senin pukul 00:00 dari minggu yang memuat [t].
  static DateTime _seninDari(DateTime t) =>
      DateTime(t.year, t.month, t.day).subtract(Duration(days: t.weekday - 1));

  Future<void> _muatModeTersimpan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString(_kModeTampilan);
      if (mounted && (mode == 'hari' || mode == 'minggu')) {
        setState(() => _modeTampilan = mode!);
      }
    } catch (e) {
      // Prefs tidak tersedia → default 'hari' (fail-open, tanpa galat UI).
      debugPrint('JadwalPage: gagal membaca mode tampilan (${e.runtimeType})');
    }
  }

  Future<void> _simpanModeTersimpan(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kModeTampilan, mode);
    } catch (e) {
      debugPrint('JadwalPage: gagal menyimpan mode tampilan (${e.runtimeType})');
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _pakaiCache = false;
      _cacheTerakhirDisimpan = null;
    });

    // Stale-while-revalidate: cache dipakai HANYA untuk render instan —
    // setiap muat dengan koneksi tetap fetch ulang dan menimpa cache via
    // [simpan]. Cache dipasang SEBELUM fetch agar konten terlihat instan.
    final cache = await AgendaCacheService.instance.baca();
    if (!mounted) return;
    if (cache != null) {
      setState(() => _agendaData = cache);
    }

    try {
      final agenda = await _akademikService.getAgendaTerpadu();
      if (mounted) {
        setState(() {
          _agendaData = agenda;
          _error = null;
          _pakaiCache = false;
          _cacheTerakhirDisimpan = null;
        });
        // Fetch sukses → cache diperbarui (fire-and-forget; gagal simpan
        // hanya dilog di service).
        unawaited(AgendaCacheService.instance.simpan(agenda));
        // Widget home "Jadwal Hari Ini" ikut diperbarui dari cache yang baru
        // saja ditulis (fail-open di dalam service).
        unawaited(WidgetJadwalService.instance.perbaruiDariCache());
      }
    } catch (e) {
      if (mounted) {
        if (_agendaData != null) {
          // Fetch gagal tetapi data terakhir masih dirender → label kecil,
          // bukan galat penuh (pola sama dengan dashboard).
          final terakhir = await AgendaCacheService.instance
              .terakhirDisimpan();
          if (!mounted) return;
          setState(() {
            _error = null;
            _pakaiCache = true;
            _cacheTerakhirDisimpan = terakhir;
          });
        } else {
          setState(() => _error = userErrorMessage(e));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _adaJam(AgendaItem i) => jamChip(i) != '-';

  /// Gerbang tampil ujian: baris ujian (tipe uts/uas) pada tampilan campuran /
  /// hari biasa hanya dirender bila tanggal ujiannya sendiri (field `tanggal`
  /// baris, perjanjian BE) berada dalam [PeriodeUjianService.ambangHariUjian]
  /// hari ke depan (sementara sebulan sebelum ujian terbit, dulu membuat
  /// agenda bising sebulan penuh).
  ///
  /// Tab filter 'ujian' SENGAJA dikecualikan: user yang memilih tab Ujian
  /// bertindak sengaja melihat ujian, jadi di sana ujian tampil apa adanya.
  ///
  /// Mode minggu TIDAK memakai gerbang ini: user melihat kalender dengan
  /// sadar, ujian ber-tanggal muncul di minggunya meski jauh.
  ///
  /// Fail-open: tanggal null (BE lama / tak terbaca) → ujian tampil seperti
  /// semula — tidak pernah hilang diam-diam.
  bool _lolosGerbangUjian(AgendaItem item) {
    if (_filterTipe == 'ujian') return true;
    final tipe = item.tipe.trim().toLowerCase();
    if (tipe != 'uts' && tipe != 'uas') return true;
    return PeriodeUjianService.dalamJendela(
      tanggalDariPortal(item.tanggal ?? ''),
      _hariIni,
    );
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
    for (final entry in data.agenda.entries) {
      for (final item in entry.value) {
        final tipe = item.tipe.trim().toLowerCase();
        final ujian = tipe == 'uts' || tipe == 'uas';
        if (ujian &&
            _lolosAturanHari(entry.key, item) &&
            !_lolosGerbangUjian(item)) {
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

  /// Label SWR: "Menampilkan data terakhir (dd/mm hh:mm)" — format manual agar
  /// pola token waktu konsisten (ala dashboard).
  String get _labelDataTerakhir {
    final t = _cacheTerakhirDisimpan;
    if (t == null) return 'Menampilkan data terakhir';
    String dua(int n) => n.toString().padLeft(2, '0');
    return 'Menampilkan data terakhir '
        '(${dua(t.day)}/${dua(t.month)} ${dua(t.hour)}:${dua(t.minute)})';
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
    // SWR: layar penuh "memuat" hanya bila belum ada data untuk dirender —
    // bila cache sudah tampil, fetch tetap berjalan tanpa menutup konten.
    if (_loading && _agendaData == null) {
      return const AppLoading(message: 'Memuat jadwal…');
    }

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
      (sum, entry) =>
          sum +
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
        data: data,
      );
    }

    return _modeTampilan == 'minggu'
        ? _tampilanMinggu(data, jumlahTampil)
        : _tampilanHari(data, jumlahTampil);
  }

  // ── Mode hari: daftar chunked per-hari ────────────────────────────────────

  Widget _tampilanHari(AgendaTerpaduData data, int jumlahTampil) {
    final sortedDays = data.agenda.keys.toList()
      ..sort((a, b) => dayValue(a).compareTo(dayValue(b)));

    // Chunk ±20 baris per `AppListGroup`: ListView.builder hanya membangun
    // chunk yang (hampir) terlihat, bukan seluruh agenda sekaligus.
    final chunks = <_ChunkHari>[];
    for (final day in sortedDays) {
      final filteredItems = data.agenda[day]!
          .where(_sesuaiTipe)
          .where((item) => _tampil(day, item))
          .toList();
      if (filteredItems.isEmpty) continue;

      final isToday = dayValue(day) == DateTime.now().weekday;
      final trailing = _trailingSeksiHari(filteredItems.length, isToday);
      for (var i = 0; i < filteredItems.length; i += _ukuranChunk) {
        final end = (i + _ukuranChunk) < filteredItems.length
            ? i + _ukuranChunk
            : filteredItems.length;
        final pertama = i == 0;
        chunks.add((
          judul: pertama ? agendaDayLabel(day) : null,
          trailing: pertama ? trailing : null,
          hero: isToday,
          rows: [for (var j = i; j < end; j++) _agendaRow(filteredItems[j])],
        ));
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + 130,
        ),
        itemCount: chunks.length,
        itemBuilder: (context, index) {
          final chunk = chunks[index];
          final group = AppListGroup.from(chunk.rows);
          // Hari aktif dibungkus permukaan `hero` supaya paling menonjol.
          final isi = chunk.hero
              ? AppSurface(
                  variant: AppSurfaceVariant.hero,
                  radius: AppRadius.lg,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: group,
                )
              : group;

          Widget seksi;
          if (chunk.judul != null) {
            seksi = AppSection(
              title: chunk.judul!,
              trailing: chunk.trailing,
              // Chunk pertama hari sudah diberi jarak dari header/section
              // sebelumnya; chunk lanjutan mewarisi jarak default seksi.
              topGap: index == 0 ? AppSpacing.lg : AppSpacing.xl,
              child: isi,
            );
          } else {
            // Chunk lanjutan (baris ke-21 dst. hari yang sama): tetap diberi
            // jarak kecil dari chunk sebelumnya, tanpa judul seksi.
            seksi = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: index == 0 ? AppSpacing.md : AppSpacing.lg),
                isi,
              ],
            );
          }

          if (index == 0) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerAtasDaftar(total: jumlahTampil, data: data),
                const SizedBox(height: AppSpacing.lg),
                seksi,
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [seksi],
          );
        },
      ),
    );
  }

  /// Header di atas daftar (chunk pertama): chip filter, toggle mode,
  /// label SWR, dan banner periode ujian bila ada ujian tersembunyi.
  Widget _headerAtasDaftar({
    required int total,
    required AgendaTerpaduData data,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterRow(total: total),
        const SizedBox(height: AppSpacing.md),
        _modeToggle(),
        if (_pakaiCache) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _labelDataTerakhir,
            style: AppText.label.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
        if (_adaUjianTersembunyi(data)) ...[
          const SizedBox(height: AppSpacing.md),
          _bannerPeriodeUjian(data),
        ],
      ],
    );
  }

  Widget _trailingSeksiHari(int jumlah, bool isToday) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isToday) ...[
          const AppPill('Hari ini', tone: AppPillTone.info),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          '$jumlah kegiatan',
          style: AppText.label.copyWith(fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _emptyAgendaState({
    String? message,
    int? total,
    bool tampilkanBannerUjian = false,
    AgendaTerpaduData? data,
  }) {
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
            const SizedBox(height: AppSpacing.md),
            // Toggle mode ikut tampil supaya user yang sedang di mode minggu
            // tetap punya jalan pulang ke mode hari dari keadaan kosong.
            Center(child: _modeToggle()),
            const SizedBox(height: AppSpacing.sm),
          ],
          // Bila agenda "kosong" karena SEMUA barisnya ujian yang digerbang,
          // banner tetap wajib tampil — empty state "belum punya jam" saja
          // akan menyesatkan user.
          if (tampilkanBannerUjian && data != null) ...[
            _bannerPeriodeUjian(data),
            const SizedBox(height: AppSpacing.sm),
          ],
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          AppEmptyState(
            title: 'Belum ada agenda',
            message:
                message ??
                'Tidak ada jadwal agenda terpadu untuk ditampilkan. '
                    'Tarik ke bawah untuk menyegarkan.',
            icon: CupertinoIcons.calendar,
          ),
        ],
      ),
    );
  }

  // ── Baris alat: filter tipe & toggle mode ─────────────────────────────────

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
      side: isSelected
          ? BorderSide.none
          : const BorderSide(color: AppColors.border),
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

  /// Toggle mode tampilan [Hari | Minggu] — pilihan dipersist di
  /// SharedPreferences agar halaman terbuka sesuai kebiasaan pengguna.
  Widget _modeToggle() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'hari',
          label: Text('Hari'),
          icon: Icon(CupertinoIcons.list_bullet, size: 16),
        ),
        ButtonSegment(
          value: 'minggu',
          label: Text('Minggu'),
          icon: Icon(CupertinoIcons.calendar, size: 16),
        ),
      ],
      selected: {_modeTampilan},
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: Colors.white,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
      ),
      onSelectionChanged: (pilihan) {
        final mode = pilihan.first;
        if (mode == _modeTampilan) return;
        setState(() => _modeTampilan = mode);
        unawaited(_simpanModeTersimpan(mode));
      },
    );
  }

  // ── Banner periode ujian (diketuk → halaman Jadwal Ujian) ──────────────────

  /// Banner info ujian yang masih di luar jendela tampil. Gaya mengikuti
  /// banner rekomendasi SP di dashboard (AppSurface + ikon + teks token),
  /// tetap satu baris yang bisa diketuk (AppSurface.onTap = InkWell).
  /// Periode dihitung dari baris ujian agenda itu sendiri (tanpa fetch) —
  /// tidak ada ujian mendatang ber-tanggal → banner tidak dirender.
  Widget _bannerPeriodeUjian(AgendaTerpaduData data) {
    final periode = PeriodeUjianService.periodeBerikutnya(data, _hariIni);
    if (periode == null) return const SizedBox.shrink();
    final (tgl, jenis) = periode;
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

  // ── Satu baris agenda (mode hari) ─────────────────────────────────────────

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

  // ── Mode minggu: grid kalender mingguan ───────────────────────────────────

  Widget _tampilanMinggu(AgendaTerpaduData data, int jumlahTampil) {
    final mulai = _mingguDasar;
    final akhir = mulai.add(const Duration(days: 6));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _filterRow(total: jumlahTampil),
                const SizedBox(height: AppSpacing.md),
                _modeToggle(),
                if (_pakaiCache) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _labelDataTerakhir,
                    style: AppText.label.copyWith(fontWeight: FontWeight.w400),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _headerMinggu(mulai, akhir),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + 130,
              ),
              child: _gridMinggu(data, mulai),
            ),
          ),
        ],
      ),
    );
  }

  /// Label rentang minggu, mis. "20–26 Okt 2026".
  String _labelRentangMinggu(DateTime mulai) {
    final akhir = mulai.add(const Duration(days: 6));
    if (mulai.month == akhir.month && mulai.year == akhir.year) {
      return '${mulai.day}–${akhir.day} ${_bulanPendek[mulai.month - 1]} '
          '${mulai.year}';
    }
    if (mulai.year == akhir.year) {
      return '${mulai.day} ${_bulanPendek[mulai.month - 1]} – '
          '${akhir.day} ${_bulanPendek[akhir.month - 1]} ${mulai.year}';
    }
    return '${mulai.day} ${_bulanPendek[mulai.month - 1]} ${mulai.year} – '
        '${akhir.day} ${_bulanPendek[akhir.month - 1]} ${akhir.year}';
  }

  /// Navigasi minggu: panah kiri/kanan ±1 minggu + tombol "Hari ini" bila
  /// minggu yang dilihat bukan minggu berjalan.
  Widget _headerMinggu(DateTime mulai, DateTime akhir) {
    final mingguBerjalan = _seninDari(_hariIni) == mulai;
    return Row(
      children: [
        IconButton(
          onPressed: () =>
              setState(() => _mingguDasar = mulai.subtract(const Duration(days: 7))),
          icon: const Icon(CupertinoIcons.chevron_back, size: 18),
          visualDensity: VisualDensity.compact,
          tooltip: 'Minggu sebelumnya',
        ),
        Expanded(
          child: Text(
            _labelRentangMinggu(mulai),
            textAlign: TextAlign.center,
            style: AppText.h3,
          ),
        ),
        IconButton(
          onPressed: () =>
              setState(() => _mingguDasar = mulai.add(const Duration(days: 7))),
          icon: const Icon(CupertinoIcons.chevron_forward, size: 18),
          visualDensity: VisualDensity.compact,
          tooltip: 'Minggu berikutnya',
        ),
        if (!mingguBerjalan)
          TextButton(
            onPressed: () => setState(() => _mingguDasar = _seninDari(_hariIni)),
            child: const Text('Hari ini'),
          ),
      ],
    );
  }

  /// Grid mingguan: baris header 7 hari + kotak tinggi tetap berisi gutter
  /// jam (07:00–19:00) dan 7 kolom hari berisi blok agenda. Tinggi kotak
  /// DIPASTIKAN (bukan infinite) sehingga aman di dalam scrollable.
  Widget _gridMinggu(AgendaTerpaduData data, DateTime mulai) {
    final hariIni = _hariIni;
    final sekarang = DateTime.now();
    final menitSekarang = sekarang.hour * 60 + sekarang.minute;

    // Kumpulkan blok per kolom (indeks 0 = Senin … 6 = Minggu).
    final kolom = List<List<_BlokAgenda>>.generate(7, (_) => []);
    for (final entry in data.agenda.entries) {
      for (final item in entry.value) {
        final blok = _blokDari(item, mulai, entry.key);
        if (blok != null) kolom[blok.weekday - 1].add(blok);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _tinggiHeaderHari,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: _lebarGutterJam),
              for (var i = 0; i < 7; i++)
                Expanded(child: _labelHari(mulai.add(Duration(days: i)), hariIni)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: (_jamSelesaiGrid - _jamMulaiGrid) * _tinggiPerJam,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: _lebarGutterJam, child: _jamGutter()),
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Container(
                    // Jarak antar kolom mengikuti token spasi.
                    margin: EdgeInsets.only(left: d == 0 ? 0 : AppSpacing.xs),
                    clipBehavior: Clip.antiAlias,
                    decoration: AppDeco.card(radius: AppRadius.sm),
                    child: Stack(
                      children: [
                        ..._garisJamKolom(),
                        if (mulai.add(Duration(days: d)) == hariIni &&
                            menitSekarang >= _jamMulaiGrid * 60 &&
                            menitSekarang < _jamSelesaiGrid * 60)
                          _garisSekarang(menitSekarang),
                        ..._blokKolom(kolom[d]),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Label satu hari di header grid — hari berjalan di-highlight.
  Widget _labelHari(DateTime t, DateTime hariIni) {
    final hariIniYa = t == hariIni;
    final warna = hariIniYa ? AppColors.primary : AppColors.textSecondary;
    final berat = hariIniYa ? FontWeight.w800 : FontWeight.w500;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _singkatanHari[t.weekday - 1],
          style: AppText.label.copyWith(color: warna, fontWeight: berat),
        ),
        Text(
          '${t.day}',
          style: AppText.bodySm.copyWith(color: warna, fontWeight: berat),
        ),
      ],
    );
  }

  /// Sumbu jam kecil di gutter (07:00–18:00; 19:00 tepat di tepi bawah
  /// dilewatkan agar label tidak keluar kotak).
  Widget _jamGutter() {
    return Stack(
      children: [
        for (var h = _jamMulaiGrid; h < _jamSelesaiGrid; h++)
          Positioned(
            top: (h - _jamMulaiGrid) * _tinggiPerJam + 2,
            left: 0,
            right: AppSpacing.xs,
            child: Text(
              '$h:00',
              textAlign: TextAlign.right,
              style: AppText.label.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  /// Garis pemisah jam satu kolom.
  List<Widget> _garisJamKolom() => [
        for (var h = _jamMulaiGrid; h <= _jamSelesaiGrid; h++)
          Positioned(
            top: (h - _jamMulaiGrid) * _tinggiPerJam,
            left: 0,
            right: 0,
            child: Container(height: 1, color: AppColors.border),
          ),
      ];

  /// Garis "sekarang" (aksen danger) + jam kecil — hanya dipasang bila kolom
  /// ini hari ini dan minggu yang dilihat memuat hari ini.
  Widget _garisSekarang(int menitSekarang) {
    String dua(int n) => n.toString().padLeft(2, '0');
    final jam = '${dua(menitSekarang ~/ 60)}:${dua(menitSekarang % 60)}';
    final top = (menitSekarang - _jamMulaiGrid * 60).toDouble();
    return Positioned(
      top: top - 16,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Text(
              jam,
              style: AppText.label.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(height: 2, color: AppColors.danger),
        ],
      ),
    );
  }

  /// Konversi satu [AgendaItem] menjadi blok grid mingguan. Null = tidak
  /// relevan untuk minggu yang dilihat (mis. ujian di minggu lain).
  ///
  ///  * Kuliah/asisten: kolom dari bucket hari (`dayValue`); bucket tanpa
  ///    hari konkret ("Lainnya", "Tanpa Jadwal") dilewati — kalender butuh
  ///    hari konkret.
  ///  * Ujian: tanggal konkret menang (kolom dari `tanggal`, hanya bila
  ///    jatuh di minggu terlihat); tanpa tanggal → kolom dari bucket hari
  ///    (fail-open, ujian tidak pernah hilang diam-diam). Gerbang 7 hari
  ///    mode hari SENGAJA tidak dipakai di sini.
  _BlokAgenda? _blokDari(AgendaItem item, DateTime mulaiMinggu, String dayKey) {
    if (!_sesuaiTipe(item)) return null;

    final tipe = item.tipe.trim().toLowerCase();
    final ujian = tipe == 'uts' || tipe == 'uas';
    int? weekday;

    if (ujian) {
      final tgl = tanggalDariPortal(item.tanggal ?? '');
      if (tgl != null) {
        final selisih = DateTime(tgl.year, tgl.month, tgl.day)
            .difference(mulaiMinggu)
            .inDays;
        if (selisih < 0 || selisih > 6) return null;
        weekday = selisih + 1;
      } else {
        final dv = dayValue(dayKey);
        if (dv < 1 || dv > 7) return null;
        weekday = dv;
      }
    } else {
      final dv = dayValue(dayKey);
      if (dv < 1 || dv > 7) return null;
      weekday = dv;
    }

    // Rentang jam: `jamMulai/jamSelesai` (respons baru) dengan fallback parse
    // `jam` warisan; tanpa jam terbaca → blok 1 jam di awal grid (fail-open).
    final rentang = ongoingRange(item);
    var mulaiMenit = rentang?.$1 ?? _jamMulaiGrid * 60;
    var selesaiMenit = rentang?.$2 ?? mulaiMenit + 60;
    if (selesaiMenit <= mulaiMenit) selesaiMenit = mulaiMenit + 60;

    // Jepit ke jendela grid (07:00–19:00).
    if (mulaiMenit < _jamMulaiGrid * 60) mulaiMenit = _jamMulaiGrid * 60;
    if (selesaiMenit > _jamSelesaiGrid * 60) selesaiMenit = _jamSelesaiGrid * 60;
    if (mulaiMenit >= _jamSelesaiGrid * 60) mulaiMenit = _jamSelesaiGrid * 60 - 60;

    final penanda = ujian ? tipe.toUpperCase() : null;
    return _BlokAgenda(
      item: item,
      weekday: weekday,
      mulaiMenit: mulaiMenit,
      selesaiMenit: selesaiMenit,
      penanda: penanda,
    );
  }

  /// Posisikan blok satu kolom: top/height proporsional (60px per jam),
  /// agenda bertumpuk dibagi lebar kolom sama rata per klaster tumpang tindih.
  List<Widget> _blokKolom(List<_BlokAgenda> blok) {
    if (blok.isEmpty) return const [];
    blok.sort((a, b) {
      final byStart = a.mulaiMenit.compareTo(b.mulaiMenit);
      return byStart != 0 ? byStart : a.selesaiMenit.compareTo(b.selesaiMenit);
    });

    return [
      LayoutBuilder(
        builder: (context, constraints) {
          final lebar = constraints.maxWidth;
          final hasil = <Widget>[];
          var i = 0;
          while (i < blok.length) {
            // Bentangkan satu klaster tumpang tindih.
            var j = i;
            var puncakSelesai = blok[i].selesaiMenit;
            while (j + 1 < blok.length && blok[j + 1].mulaiMenit < puncakSelesai) {
              j++;
              if (blok[j].selesaiMenit > puncakSelesai) {
                puncakSelesai = blok[j].selesaiMenit;
              }
            }
            final jumlah = j - i + 1;
            final lebarBlok = lebar / jumlah;
            final tinggiGrid =
                (_jamSelesaiGrid - _jamMulaiGrid) * _tinggiPerJam;
            for (var k = i; k <= j; k++) {
              final b = blok[k];
              final top = (b.mulaiMenit - _jamMulaiGrid * 60).toDouble();
              var tinggi = (b.selesaiMenit - b.mulaiMenit).toDouble();
              if (tinggi < _tinggiBlokMinimum) tinggi = _tinggiBlokMinimum;
              // Pengaman ekstra: blok tidak boleh keluar kotak grid.
              if (top + tinggi > tinggiGrid) tinggi = tinggiGrid - top;
              hasil.add(
                Positioned(
                  left: lebarBlok * (k - i) + 2,
                  width: lebarBlok - 4,
                  top: top,
                  height: tinggi,
                  child: _blokCard(b, tinggi),
                ),
              );
            }
            i = j + 1;
          }
          return Stack(children: hasil);
        },
      ),
    ];
  }

  /// Kartu blok agenda: latar warna deterministik dari nama mata kuliah
  /// (palet token `AppBlockPalette`); ujian selalu nada danger + penanda
  /// UTS/UAS. Isi bertingkat sesuai tinggi blok agar tidak pernah overflow.
  Widget _blokCard(_BlokAgenda b, double tinggi) {
    final (bg, fg) = b.penanda != null
        ? AppPill.toneColors(AppPillTone.danger)
        : AppBlockPalette.untuk(b.item.matakuliah);
    final jamTampil = jamChip(b.item);
    final labelUtama =
        b.penanda != null ? '${b.penanda} • $jamTampil' : jamTampil;
    final barisRuang =
        b.item.ruang.isEmpty || b.item.ruang == '-' ? null : b.item.ruang;

    // Konten bertingkat sesuai tinggi blok (px == menit pada 64px/jam):
    // blok pendek hanya memuat nama, blok ≥1 jam memuat jam + nama (2 baris),
    // blok panjang menambah ruang — memastikan tidak pernah overflow.
    final anak = <Widget>[
      if (tinggi >= 38)
        Text(
          labelUtama,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(color: fg, fontWeight: FontWeight.w800),
        ),
      Text(
        b.item.matakuliah.isEmpty ? '-' : b.item.matakuliah,
        maxLines: tinggi >= 52 ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.label.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
      if (barisRuang != null && tinggi >= 68)
        Text(
          barisRuang,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(
            color: fg,
            fontWeight: FontWeight.w400,
          ),
        ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _tampilkanDetailBlok(b.item),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: fg.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: anak,
          ),
        ),
      ),
    );
  }

  /// Detail blok dalam bottom sheet ringan: jam lengkap, ruang, tipe,
  /// komponen, dan tanggal ujian bila ada.
  void _tampilkanDetailBlok(AgendaItem item) {
    final (label, tone) = _tipeStyle(item.tipe);
    final tgl = tanggalDariPortal(item.tanggal ?? '');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPill(label, tone: tone),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.matakuliah.isEmpty ? '-' : item.matakuliah,
                style: AppText.h2,
              ),
              const SizedBox(height: AppSpacing.md),
              AppKeyValue(label: 'Jam', value: item.jam.isEmpty ? '-' : item.jam),
              AppKeyValue(
                label: 'Ruang',
                value: item.ruang.isEmpty ? '-' : item.ruang,
              ),
              if (tgl != null)
                AppKeyValue(label: 'Tanggal', value: formatTanggalIndo(tgl)),
              if (item.komponen != null && item.komponen!.isNotEmpty)
                AppKeyValue(label: 'Komponen', value: item.komponen!),
              if (item.detail.isNotEmpty)
                AppKeyValue(label: 'Keterangan', value: item.detail),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu blok agenda pada grid mingguan — data posisi hasil konversi
/// [AgendaItem] via `_blokDari`.
class _BlokAgenda {
  final AgendaItem item;
  final int weekday; // 1 = Senin … 7 = Minggu
  final int mulaiMenit;
  final int selesaiMenit;

  /// 'UTS'/'UAS' untuk baris ujian; null untuk kuliah/asisten.
  final String? penanda;

  const _BlokAgenda({
    required this.item,
    required this.weekday,
    required this.mulaiMenit,
    required this.selesaiMenit,
    this.penanda,
  });
}
