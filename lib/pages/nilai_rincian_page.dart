import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/nilai_rincian.dart';
import '../services/nilai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Rincian Nilai — isinya data yang dibaca & dibandingkan (komponen penilaian
/// per mata kuliah), jadi disajikan sebagai DAFTAR, bukan tumpukan kartu:
/// satu `AppSection` per mata kuliah, satu `AppSurface` ringkas berisi
/// `AppListGroup` komponen, nilai akhir ditandai `AppGradeBadge`, dan ringkasan
/// semester di atas memakai `AppStatTile`.
class NilaiRincianPage extends StatefulWidget {

  const NilaiRincianPage({super.key});

  @override
  State<NilaiRincianPage> createState() => _NilaiRincianPageState();
}

class _NilaiRincianPageState extends State<NilaiRincianPage> {
  final _service = NilaiService();

  List<NilaiOpsiItem> _tahunList = [];
  List<NilaiOpsiItem> _semesterList = [];
  String? _selectedThn;
  String? _selectedSmt;

  RincianNilaiResponse? _rincian;
  bool _loadingOptions = true;
  bool _loadingRincian = false;
  String? _error;
  bool _isRentangExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _loadingOptions = true;
      _error = null;
    });

    try {
      // 1. Ambil opsi tahun akademik dan semester
      final tahunFuture = _service.getTahunAkademikList().catchError((_) => <NilaiOpsiItem>[]);
      final semesterFuture = _service.getSemesterList().catchError((_) => <NilaiOpsiItem>[]);
      final rincianFuture = _service.getRincianNilai().catchError((_) => const RincianNilaiResponse(
            thnAkademik: '',
            semesterId: '',
            semesterLabel: '',
            thnAktif: '',
            kelompok: [],
            rentangNilai: [],
          ));

      final results = await Future.wait([tahunFuture, semesterFuture, rincianFuture]);
      if (!mounted) return;

      final tahunResult = results[0] as List<NilaiOpsiItem>;
      final semesterResult = results[1] as List<NilaiOpsiItem>;
      final rincianResult = results[2] as RincianNilaiResponse;

      String? activeThn;
      String? activeSmt;

      if (rincianResult.thnAkademik.isNotEmpty) {
        activeThn = rincianResult.thnAkademik;
      } else if (tahunResult.isNotEmpty) {
        activeThn = tahunResult.first.value;
      }

      if (rincianResult.semesterId.isNotEmpty) {
        activeSmt = rincianResult.semesterId;
      } else if (semesterResult.isNotEmpty) {
        activeSmt = semesterResult.first.value;
      }
      if (tahunResult.isEmpty && semesterResult.isEmpty && rincianResult.thnAkademik.isEmpty) {
        setState(() {
          _error = 'Tidak dapat memuat data. Periksa koneksi internet Anda.';
          _loadingOptions = false;
        });
        return;
      }

      setState(() {
        _tahunList = tahunResult;
        _semesterList = semesterResult;
        _selectedThn = activeThn;
        _selectedSmt = activeSmt;
        _rincian = (rincianResult.kelompok.isNotEmpty || rincianResult.thnAkademik.isNotEmpty)
            ? rincianResult
            : null;
        _loadingOptions = false;
      });

      // Jika rincian awal belum termuat dan opsi ada, muat data rincian spesifik
      if (_rincian == null && _selectedThn != null && _selectedSmt != null) {
        await _fetchRincian();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingOptions = false;
      });
    }
  }

  Future<void> _fetchRincian() async {
    if (!mounted) return;
    setState(() {
      _loadingRincian = true;
      _error = null;
    });

    try {
      final res = await _service.getRincianNilai(
        thnAkademik: _selectedThn,
        semester: _selectedSmt,
      );
      if (!mounted) return;
      setState(() {
        _rincian = res;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRincian = false);
      }
    }
  }

  // ── Ringkasan & turunan data (tanpa mengubah model/service) ──────────────

  List<KelompokNilaiItem> get _kelompokList =>
      _rincian?.kelompok ?? const <KelompokNilaiItem>[];

  int get _totalMatkul {
    var total = 0;
    for (final kelompok in _kelompokList) {
      total += kelompok.matkul.length;
    }
    return total;
  }

  int get _totalKomponen {
    var total = 0;
    for (final kelompok in _kelompokList) {
      for (final matkul in kelompok.matkul) {
        total += _komponenList(matkul, kelompok.kolom).length;
      }
    }
    return total;
  }

  String get _rerataNilaiAkhir {
    final nilai = <double>[];
    for (final kelompok in _kelompokList) {
      for (final matkul in kelompok.matkul) {
        final parsed =
            double.tryParse(matkul.nilaiAkhir.trim().replaceAll(',', '.'));
        if (parsed != null) nilai.add(parsed);
      }
    }
    if (nilai.isEmpty) return '—';
    final total = nilai.fold<double>(0.0, (a, b) => a + b);
    return (total / nilai.length).toStringAsFixed(2);
  }

  /// Daftar komponen penilaian yang tampil untuk satu mata kuliah.
  List<MapEntry<String, dynamic>> _komponenList(
    MatkulNilaiItem matkul,
    List<String> kolomList,
  ) {
    final komponen = <MapEntry<String, dynamic>>[];
    if (kolomList.isNotEmpty) {
      for (final col in kolomList) {
        final val = matkul.nilai[col] ?? matkul.nilai[col.toLowerCase()] ?? '-';
        komponen.add(MapEntry(col, val));
      }
    } else if (matkul.nilai.isNotEmpty) {
      matkul.nilai.forEach((k, v) {
        komponen.add(MapEntry(k, v));
      });
    }
    return komponen;
  }

  String _gradeLabel(String grade) => grade.isNotEmpty ? grade : '-';

  // ── Lembar pedoman rentang nilai ─────────────────────────────────────────

  void _showRentangNilaiSheet(BuildContext context) {
    final rentangList = _rincian?.rentangNilai ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            MediaQuery.of(ctx).padding.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.chart_bar_square_fill,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('Pedoman Rentang Nilai', style: AppText.h2),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (rentangList.isEmpty)
                AppEmptyState(
                  title: 'Rentang nilai belum tersedia',
                  message: 'Informasi rentang nilai belum diumumkan.',
                  icon: CupertinoIcons.chart_bar_square_fill,
                )
              else
                AppListGroup.from([
                  for (final r in rentangList)
                    AppListRow(
                      leading: AppGradeBadge(grade: _gradeLabel(r.huruf), size: 30),
                      title: r.rentang,
                      subtitle: r.bobot.isNotEmpty ? 'Bobot ${r.bobot}' : null,
                    ),
                ]),
            ],
          ),
        );
      },
    );
  }

  // ── Kerangka halaman ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Rincian Nilai',
      subtitle: 'Komponen penilaian tiap mata kuliah',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.info_circle_fill),
          tooltip: 'Pedoman Rentang Nilai',
          onPressed: () => _showRentangNilaiSheet(context),
        ),
      ],
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_loadingOptions) {
      return const AppLoading(message: 'Memuat rincian nilai…');
    }

    // WAJIB menerapkan bottom padding: MediaQuery.of(context).padding.bottom + 130
    final bottomNavPadding = MediaQuery.of(context).padding.bottom + 130;

    return RefreshIndicator(
      onRefresh: _fetchRincian,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          bottomNavPadding,
        ),
        children: [
          _buildFilterSection().animate().fadeIn(duration: 220.ms),
          if (_rincian != null) ..._buildRingkasanSections(),
          _buildRincianBody(),
        ],
      ),
    );
  }

  // ── Filter semester ──────────────────────────────────────────────────────

  Widget _buildFilterSection() {
    return AppSection(
      title: 'Filter Semester',
      topGap: AppSpacing.sm,
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildDropdown(
                    value: _selectedThn,
                    items: _tahunList,
                    hint: 'Tahun Akademik',
                    onChanged: (v) {
                      setState(() => _selectedThn = v);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: _buildDropdown(
                    value: _selectedSmt,
                    items: _semesterList,
                    hint: 'Semester',
                    onChanged: (v) {
                      setState(() => _selectedSmt = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_selectedThn != null || _selectedSmt != null)
                    ? _fetchRincian
                    : null,
                icon: const Icon(CupertinoIcons.search, size: 18),
                label: const Text('Tampilkan Nilai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<NilaiOpsiItem> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.any((e) => e.value == value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: AppDeco.card(radius: AppRadius.sm),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          hint: Text(
            hint,
            style: AppText.bodySm,
            overflow: TextOverflow.ellipsis,
          ),
          isExpanded: true,
          icon: const Icon(
            CupertinoIcons.chevron_down,
            color: AppColors.primary,
            size: 14,
          ),
          items: items.map((e) {
            return DropdownMenuItem<String>(
              value: e.value,
              child: Text(
                e.label,
                style: AppText.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Ringkasan semester (stat tiles) ──────────────────────────────────────

  List<Widget> _buildRingkasanSections() {
    final rincian = _rincian;
    if (rincian == null) return const [];

    return [
      AppSection(
        title: 'Ringkasan Semester',
        child: Row(
          children: [
            Expanded(
              child: AppStatTile(
                value: '$_totalMatkul',
                label: 'Mata kuliah',
                icon: CupertinoIcons.book_fill,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppStatTile(
                value: '$_totalKomponen',
                label: 'Komponen',
                icon: CupertinoIcons.chart_bar_alt_fill,
                accent: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppStatTile(
                value: _rerataNilaiAkhir,
                label: 'Rerata NA',
                icon: CupertinoIcons.chart_bar_square_fill,
                accent: AppColors.success,
              ),
            ),
          ],
        ),
      ),
      if (rincian.rentangNilai.isNotEmpty) _buildRentangSection(rincian),
    ];
  }

  Widget _buildRentangSection(RincianNilaiResponse rincian) {
    return AppSection(
      title: 'Pedoman Rentang Nilai',
      trailing: TextButton.icon(
        onPressed: () {
          setState(() => _isRentangExpanded = !_isRentangExpanded);
        },
        icon: Icon(
          _isRentangExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
          size: 16,
        ),
        label: Text(_isRentangExpanded ? 'Tutup' : 'Lihat'),
      ),
      child: _isRentangExpanded
          ? AppListGroup.from([
              for (final r in rincian.rentangNilai)
                AppListRow(
                  leading: AppGradeBadge(grade: _gradeLabel(r.huruf), size: 30),
                  title: r.rentang,
                  subtitle: r.bobot.isNotEmpty ? 'Bobot ${r.bobot}' : null,
                ),
            ])
          : const SizedBox.shrink(),
    );
  }

  // ── Daftar rincian per mata kuliah ───────────────────────────────────────

  Widget _buildRincianBody() {
    if (_loadingRincian) {
      return const AppLoading(message: 'Memuat rincian nilai…');
    }
    if (_error != null) {
      return AppErrorState(
        message: _error!,
        onRetry: _fetchRincian,
      );
    }
    final rincian = _rincian;
    if (rincian == null) {
      return _buildEmptyState(
        'Pilih tahun akademik dan semester untuk melihat rincian nilai.',
      );
    }
    return _buildRincianList(rincian);
  }

  Widget _buildRincianList(RincianNilaiResponse rincian) {
    if (rincian.kelompok.isEmpty) {
      return _buildEmptyState('Tidak ada data rincian nilai untuk semester ini.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rincian.kelompok.map((kelompok) {
        return _buildKelompokSection(kelompok);
      }).toList(),
    );
  }

  Widget _buildKelompokSection(KelompokNilaiItem kelompok) {
    final isReguler = kelompok.jenis.toLowerCase() == 'reguler';
    final sectionTitle = isReguler ? 'Mata Kuliah Reguler' : 'Mata Kuliah MBKM';

    return AppSection(
      title: sectionTitle,
      trailing: AppPill(
        '${kelompok.matkul.length} matkul',
        tone: isReguler ? AppPillTone.neutral : AppPillTone.warning,
      ),
      child: kelompok.matkul.isEmpty
          ? AppSurface(
              child: Text(
                'Tidak ada mata kuliah pada kategori ini.',
                style: AppText.bodySm,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final matkul in kelompok.matkul)
                  _buildMatkulBlock(matkul, kelompok.kolom),
              ],
            ),
    );
  }

  Widget _buildMatkulBlock(MatkulNilaiItem matkul, List<String> kolomList) {
    final komponen = _komponenList(matkul, kolomList);

    return AppSection(
      title: matkul.nama.isNotEmpty ? matkul.nama : 'Tanpa Nama Mata Kuliah',
      topGap: AppSpacing.lg,
      trailing: AppGradeBadge(grade: _gradeLabel(matkul.nilaiHuruf)),
      child: AppSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (matkul.kode.isNotEmpty)
                    AppKeyValue(label: 'Kode MK', value: matkul.kode),
                  AppKeyValue(
                    label: 'Nilai Akhir',
                    value: matkul.nilaiAkhir.isNotEmpty ? matkul.nilaiAkhir : '—',
                    emphasize: true,
                  ),
                ],
              ),
            ),
            if (komponen.isNotEmpty)
              AppListGroup.from([
                for (final entry in komponen)
                  AppListRow(
                    title: entry.key,
                    trailing: Text(
                      entry.value?.toString() ?? '-',
                      style: AppText.h3,
                    ),
                  ),
              ])
            else ...[
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              Padding(
                padding: AppSpacing.card,
                child: Text(
                  'Komponen rincian nilai belum diumumkan.',
                  style: AppText.bodySm,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Keadaan kosong ───────────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return AppEmptyState(
      title: 'Belum ada rincian nilai',
      message: message,
      icon: CupertinoIcons.doc_text_search,
    );
  }
}
