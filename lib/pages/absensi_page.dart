import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/absensi.dart';
import '../services/absensi_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import 'absensi_detail_page.dart';

/// Halaman presensi mahasiswa.
///
/// Presensi adalah menu yang paling sering dibuka mahasiswa, jadi urutan
/// tampilannya dioptimalkan untuk sekali lihat:
///   1. status pertemuan terakhir — paling atas, langsung terbaca;
///   2. presensi yang menunggu validasi + aksinya;
///   3. filter tahun akademik / semester / matakuliah;
///   4. ringkasan kehadiran (AppStatTile) + riwayat pertemuan (daftar).
///
/// Tombol kembali disediakan otomatis oleh [AppScaffold] mengikuti route,
/// sehingga `onBack` hanya dipertahankan untuk kompatibilitas pemanggil lama.
class AbsensiPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AbsensiPage({super.key, this.onBack});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  final _service = AbsensiService();

  List<MakulBelumValidasi> _belumValidasi = [];
  bool _loadingBelumValidasi = true;

  List<OptionItem> _semesterList = [];
  List<OptionItem> _matkulList = [];
  String? _selectedThn;
  String? _selectedSmt;
  String? _selectedMakul;
  bool _loadingSemester = false;
  bool _loadingMatkul = false;

  AbsensiMahasiswa? _mahasiswa;
  bool _loadingMahasiswa = false;

  String? _errorFilter;
  bool _validatingAll = false;

  @override
  void initState() {
    super.initState();
    _initAcademicYear();
    _loadBelumValidasi();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSemesterList());
  }

  void _initAcademicYear() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    if (month >= 8) {
      _selectedThn = '$year/${year + 1}';
    } else {
      _selectedThn = '${year - 1}/$year';
    }
  }

  Future<void> _loadBelumValidasi() async {
    if (!mounted) return;
    setState(() => _loadingBelumValidasi = true);
    try {
      final data = await _service.getMakulBelumValidasi();
      if (!mounted) return;
      setState(() {
        _belumValidasi = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingBelumValidasi = false);
    }
  }

  Future<void> _loadSemesterList() async {
    if (_selectedThn == null || _selectedThn!.isEmpty) return;
    setState(() {
      _loadingSemester = true;
      _selectedSmt = null;
      _matkulList = [];
      _selectedMakul = null;
      _mahasiswa = null;
    });
    try {
      final data = await _service.getSemester(_selectedThn!);
      if (!mounted) return;
      setState(() {
        _semesterList = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingSemester = false);
    }
  }

  Future<void> _loadMatkulList() async {
    if (_selectedThn == null || _selectedSmt == null) return;
    setState(() {
      _loadingMatkul = true;
      _selectedMakul = null;
      _mahasiswa = null;
    });
    try {
      final data = await _service.getMatkul(_selectedThn!, _selectedSmt!);
      if (!mounted) return;
      setState(() {
        _matkulList = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingMatkul = false);
    }
  }

  Future<void> _loadMahasiswa() async {
    if (_selectedThn == null || _selectedSmt == null || _selectedMakul == null) return;
    if (!mounted) return;
    setState(() => _loadingMahasiswa = true);
    try {
      final data = await _service.getMahasiswa(_selectedThn!, _selectedSmt!, _selectedMakul!);
      if (!mounted) return;
      setState(() {
        _mahasiswa = data;
        _errorFilter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorFilter = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingMahasiswa = false);
    }
  }

  Future<void> _validasiSemua(MakulBelumValidasi item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validasi Semua'),
        content: Text('Validasi ${item.count} pertemuan "${item.makul}" dengan nilai default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Validasi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _validatingAll = true);
    int success = 0;
    int failed = 0;

    for (final idPresensi in item.idPresensiMhs) {
      try {
        final detail = await _service.getPresensiDetail(idPresensi);
        await _service.validasi({
          'jenispilih': detail.keterangan == 'H' ? 'teori' : detail.keterangan,
          'idpresensimhstexs': detail.idPresensiMhs,
          'idpresensidosen': detail.idPresensiDosen,
          'kuliahteori': detail.kuliahTpId,
          'kesesuaian_perkuliahan': '1',
          'kesesuaian_materi': '1',
          'penilaianmhs': '4',
          'kritiksaran': '',
          'asdos_npms': [],
          'asdospenilaian': {
            for (final k in detail.kriterias)
              if (k.nilai.isNotEmpty)
                k.id: k.nilai.reduce((a, b) => a.nilai >= b.nilai ? a : b).id
          },
        });
        success++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validasi: $success berhasil, $failed gagal'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    _loadBelumValidasi();
    setState(() => _validatingAll = false);
  }

  // ── Turunan tampilan ───────────────────────────────────────────────────────

  /// Jumlah pertemuan yang masih menunggu validasi.
  int get _totalBelumValidasi =>
      _belumValidasi.fold(0, (sum, item) => sum + item.count);

  /// Label matakuliah yang sedang dipilih (untuk keterangan di riwayat).
  String? get _selectedMakulLabel {
    final selected = _selectedMakul;
    if (selected == null) return null;
    for (final option in _matkulList) {
      if (option.value == selected) return option.label;
    }
    return null;
  }

  static AppPillTone _statusTone(String status) {
    switch (status.toUpperCase()) {
      case 'H':
        return AppPillTone.success;
      case 'B':
        return AppPillTone.danger;
      case 'I':
        return AppPillTone.info;
      case 'S':
        return AppPillTone.warning;
      default:
        return AppPillTone.neutral;
    }
  }

  static String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'H':
        return 'Hadir';
      case 'B':
        return 'Bolos';
      case 'I':
        return 'Izin';
      case 'S':
        return 'Sakit';
      default:
        return status;
    }
  }

  /// Warna latar/teks untuk satu nada status (selaras dengan [AppPill]).
  static (Color, Color) _toneColors(AppPillTone tone) {
    switch (tone) {
      case AppPillTone.success:
        return (AppColors.successBg, AppColors.success);
      case AppPillTone.warning:
        return (AppColors.warningBg, AppColors.warning);
      case AppPillTone.danger:
        return (AppColors.dangerBg, AppColors.danger);
      case AppPillTone.info:
        return (AppColors.infoBg, AppColors.info);
      case AppPillTone.neutral:
        return (AppColors.surfaceMuted, AppColors.textSecondary);
    }
  }

  static Widget _iconBadge(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: AppDeco.softPrimary(radius: AppRadius.sm),
      child: Icon(icon, size: 20, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Absensi Mahasiswa',
      subtitle: 'Kehadiran & validasi presensi',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBelumValidasi();
          if (_selectedThn != null && _selectedSmt != null && _selectedMakul != null) {
            await _loadMahasiswa();
          }
        },
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHero(),
              _buildBelumValidasi(),
              _buildFilter(),
              if (_errorFilter != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: AppErrorState(
                    message: _errorFilter!,
                    onRetry: _loadBelumValidasi,
                  ),
                ),
              if (_loadingMahasiswa)
                const AppLoading(message: 'Memuat data kehadiran…'),
              if (_mahasiswa != null && !_loadingMahasiswa) _buildHasil(),
            ],
          ),
        ),
      ),
    );
  }

  /// Status teratas — pertemuan terakhir yang sudah tercatat (atau ajakan
  /// memilih matakuliah bila belum ada data). Sengaja ditaruh paling atas
  /// supaya status kehadiran terbaca tanpa perlu menggulir.
  Widget _buildStatusHero() {
    final m = _mahasiswa;

    if (m == null || m.riwayatPertemuan.isEmpty) {
      final belumValidasi = _totalBelumValidasi;
      return AppSurface(
        variant: AppSurfaceVariant.hero,
        child: Row(
          children: [
            _iconBadge(CupertinoIcons.qrcode_viewfinder),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status kehadiran', style: AppText.h3),
                  const SizedBox(height: 2),
                  Text(
                    'Pilih semester & matakuliah untuk melihat status dan riwayat kehadiran.',
                    style: AppText.bodySm,
                  ),
                  if (belumValidasi > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppPill('$belumValidasi perlu validasi', tone: AppPillTone.warning),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final terakhir = m.riwayatPertemuan.first;
    final tone = _statusTone(terakhir.status);
    final (bg, fg) = _toneColors(tone);
    final kehadiran = m.statistik.kehadiran;

    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PERTEMUAN TERAKHIR', style: AppText.overline),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  terakhir.status.toUpperCase(),
                  style: AppText.h3.copyWith(
                    color: fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_statusLabel(terakhir.status), style: AppText.h2),
                    const SizedBox(height: 2),
                    Text(
                      '${terakhir.tanggal} · ${terakhir.materi}',
                      style: AppText.bodySm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (kehadiran != null) ...[
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${kehadiran.toStringAsFixed(0)}%',
                      style: AppText.metric,
                    ),
                    Text('kehadiran', style: AppText.label),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBelumValidasi() {
    if (_loadingBelumValidasi) {
      return const AppLoading(message: 'Memeriksa presensi yang perlu divalidasi…');
    }
    if (_belumValidasi.isEmpty) return const SizedBox.shrink();

    return AppSection(
      title: 'Perlu validasi',
      trailing: _validatingAll
          ? const AppPill('Memvalidasi…', tone: AppPillTone.warning)
          : null,
      child: AppListGroup.from([
        for (final item in _belumValidasi)
          AppListRow(
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.warningBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${item.count}',
                style: AppText.h3.copyWith(color: AppColors.warning),
              ),
            ),
            title: item.makul,
            subtitle: item.kelasgab.isNotEmpty ? item.kelasgab[0] : item.kode,
            trailing: FilledButton(
              onPressed: _validatingAll ? null : () => _validasiSemua(item),
              child: const Text('Validasi'),
            ),
          ),
      ]),
    );
  }

  Widget _buildFilter() {
    return AppSection(
      title: 'Filter presensi',
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBadge(CupertinoIcons.calendar),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tahun akademik', style: AppText.label),
                      const SizedBox(height: 2),
                      Text(_selectedThn ?? '—', style: AppText.h3),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _initAcademicYear();
                    _loadSemesterList();
                  },
                  tooltip: 'Muat ulang semester',
                  icon: const Icon(CupertinoIcons.refresh, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loadingSemester)
              const AppLoading(message: 'Memuat semester…')
            else
              _buildDropdown(
                value: _semesterList.isNotEmpty ? _selectedSmt : null,
                items: _semesterList,
                hint: 'Semester',
                onChanged: _selectedThn != null && _selectedThn!.isNotEmpty
                    ? (v) {
                        setState(() {
                          _selectedSmt = v;
                          _matkulList = [];
                          _selectedMakul = null;
                          _mahasiswa = null;
                        });
                        if (v != null) _loadMatkulList();
                      }
                    : null,
              ),
            const SizedBox(height: AppSpacing.md),
            if (_loadingMatkul)
              const AppLoading(message: 'Memuat matakuliah…')
            else
              _buildDropdown(
                value: _matkulList.isNotEmpty ? _selectedMakul : null,
                items: _matkulList,
                hint: 'Matakuliah',
                onChanged: _selectedSmt != null
                    ? (v) {
                        setState(() => _selectedMakul = v);
                        if (v != null) _loadMahasiswa();
                      }
                    : null,
              ),
            if (_selectedThn != null && _selectedThn!.isNotEmpty && _semesterList.isEmpty && !_loadingSemester)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: OutlinedButton.icon(
                  onPressed: _loadSemesterList,
                  icon: const Icon(CupertinoIcons.search, size: 18),
                  label: const Text('Cari Semester'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<OptionItem> items,
    required String hint,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDeco.card(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: AppText.bodySm),
          isExpanded: true,
          icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.textMuted),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e.value,
                    child: Text(e.label, style: AppText.body),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHasil() {
    final m = _mahasiswa!;
    final s = m.statistik;
    final kehadiran = s.kehadiran;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSection(
          title: 'Pengajar',
          child: AppSurface(
            child: Row(
              children: [
                _iconBadge(CupertinoIcons.person_fill),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.namaDosen, style: AppText.h3),
                      const SizedBox(height: 2),
                      Text('Jenis: ${m.jenisPerkuliahan}', style: AppText.bodySm),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AppSection(
          title: 'Ringkasan kehadiran',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (kehadiran != null)
                AppStatTile(
                  value: '${kehadiran.toStringAsFixed(0)}%',
                  label: 'Kehadiran',
                  icon: Icons.pie_chart_outline,
                ),
              AppStatTile(
                value: '${s.hadir.toStringAsFixed(0)}%',
                label: 'Hadir',
                icon: Icons.check_circle_outline,
                accent: AppColors.success,
              ),
              AppStatTile(
                value: '${s.izin.toStringAsFixed(0)}%',
                label: 'Izin',
                icon: Icons.mail_outline,
                accent: AppColors.info,
              ),
              AppStatTile(
                value: '${s.sakit.toStringAsFixed(0)}%',
                label: 'Sakit',
                icon: Icons.medical_services_outlined,
                accent: AppColors.warning,
              ),
              AppStatTile(
                value: '${s.tanpaKeterangan.toStringAsFixed(0)}%',
                label: 'Bolos',
                icon: Icons.block,
                accent: AppColors.danger,
              ),
              AppStatTile(
                value: '${s.belumValidasi.toStringAsFixed(0)}%',
                label: 'Pending',
                icon: Icons.hourglass_empty,
                accent: AppColors.textMuted,
              ),
            ],
          ),
        ),
        AppSection(
          title: 'Riwayat pertemuan',
          trailing: m.riwayatPertemuan.isEmpty
              ? null
              : AppPill('${m.riwayatPertemuan.length} pertemuan'),
          child: m.riwayatPertemuan.isEmpty
              ? const AppEmptyState(
                  title: 'Belum ada riwayat pertemuan',
                  message: 'Riwayat akan muncul setelah dosen membuka presensi.',
                  icon: CupertinoIcons.time,
                )
              : AppListGroup.from([
                  for (final r in m.riwayatPertemuan) _buildRiwayatRow(r),
                ]),
        ),
      ],
    );
  }

  Widget _buildRiwayatRow(RiwayatPertemuan r) {
    final tone = _statusTone(r.status);
    final (bg, fg) = _toneColors(tone);

    return AppListRow(
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          r.status.toUpperCase(),
          style: AppText.h3.copyWith(color: fg, fontWeight: FontWeight.w800),
        ),
      ),
      title: r.tanggal,
      subtitle: _riwayatSubtitle(r),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPill(_statusLabel(r.status), tone: tone),
          if (r.idPresensi != null) ...[
            const SizedBox(width: AppSpacing.sm),
            const Icon(CupertinoIcons.chevron_forward, size: 18, color: AppColors.textMuted),
          ],
        ],
      ),
      onTap: r.idPresensi != null
          ? () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AbsensiDetailPage(idPresensi: r.idPresensi!)),
              );
              if (result == true) {
                _loadBelumValidasi();
                if (_selectedMakul != null) _loadMahasiswa();
              }
            }
          : null,
    );
  }

  /// "Matakuliah · materi" — keterangan tiap baris riwayat.
  String? _riwayatSubtitle(RiwayatPertemuan r) {
    final makul = _selectedMakulLabel;
    final parts = <String>[
      if (makul != null && makul.isNotEmpty) makul,
      if (r.materi.isNotEmpty) r.materi,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
