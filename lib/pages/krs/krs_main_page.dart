import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/krs_service.dart';
import '../../models/krs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_kit.dart';
import '../jadwal_page.dart';

class KrsMainPage extends StatefulWidget {
  final VoidCallback? onBack;
  const KrsMainPage({super.key, this.onBack});

  @override
  State<KrsMainPage> createState() => _KrsMainPageState();
}

class _KrsMainPageState extends State<KrsMainPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        title: 'Kartu Rencana Studi (KRS)',
        scrollable: false,
        padding: EdgeInsets.zero,
        body: const Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Pengajuan'),
                Tab(text: 'Daftar'),
                Tab(text: 'Pengisian'),
                Tab(text: 'Cetak & Jadwal'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _InfoPengajuanTab(),
                  _DaftarPengajuanTab(),
                  _PengisianKelasTab(),
                  JadwalPage(showDownloadKrs: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPengajuanTab extends StatefulWidget {
  const _InfoPengajuanTab();

  @override
  State<_InfoPengajuanTab> createState() => _InfoPengajuanTabState();
}

class _InfoPengajuanTabState extends State<_InfoPengajuanTab> {
  final _service = KrsService();
  bool _loading = true;
  String? _error;
  KrsInfo? _info;
  List<MatkulDitawarkan> _matkulList = [];
  int _maxSks = 0;
  int _sksSaatIni = 0;
  bool _isAnnouncementExpanded = false;

  // Set of selected KODE
  final Set<String> _selectedMakul = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final info = await _service.getInfo();
      final matkulRes = await _service.getMatkulDitawarkan();
      if (mounted) {
        setState(() {
          _info = info;
          _matkulList = matkulRes.data;
          _maxSks = matkulRes.maxSks;
          _sksSaatIni = matkulRes.sksSaatIni;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _selectedSks {
    int total = 0;
    for (var mk in _matkulList) {
      if (_selectedMakul.contains(mk.kode)) {
        total += mk.sks;
      }
    }
    return total;
  }

  void _syncKrs() async {
    setState(() => _loading = true);
    try {
      await _service.sinkronisasi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi berhasil')));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal sinkronisasi: ${e.toString()}')));
        setState(() => _loading = false);
      }
    }
  }

  void _submit() async {
    if (_selectedMakul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu mata kuliah')));
      return;
    }

    final List<String> payload = _selectedMakul.toList();

    setState(() => _loading = true);
    try {
      // 1. Submit pengajuan
      await _service.submitPengajuan(payload);

      // 2. Auto trigger sinkronisasi (sesuai sequence flow BE)
      try {
        await _service.sinkronisasi();
      } catch (_) {
        // Sinkronisasi silently non-blocking if server sync is deferred
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan & Sinkronisasi KRS berhasil disimpan')),
        );
        _selectedMakul.clear();
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: ${e.toString()}')));
        setState(() => _loading = false);
      }
    }
  }

  /// Ketentuan & informasi KRS — konten yang dibaca, jadi tetap berupa permukaan
  /// (bukan baris list), namun seluruh warnanya memakai token.
  Widget _buildAnnouncementBanner(String text) {
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.info_circle_fill, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Ketentuan & Informasi KRS',
                  style: AppText.h3.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedCrossFade(
            firstChild: Text(
              cleanText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppText.body,
            ),
            secondChild: Text(
              cleanText,
              style: AppText.body,
            ),
            crossFadeState: _isAnnouncementExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isAnnouncementExpanded = !_isAnnouncementExpanded;
                });
              },
              icon: Icon(
                _isAnnouncementExpanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: 14,
              ),
              label: Text(
                _isAnnouncementExpanded ? 'Sembunyikan' : 'Lihat Selengkapnya',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pil status per mata kuliah: sudah lulus / mengulang / nilai sebelumnya.
  Widget? _buildStatusPills(MatkulDitawarkan mk) {
    final isLulus = mk.status.toLowerCase() == 'lulus';
    final nilaiLalu = mk.nilaiSebelumnya;
    final pills = <Widget>[];

    if (isLulus) {
      pills.add(AppPill(
        'Sudah Lulus${nilaiLalu != null && nilaiLalu.isNotEmpty ? " ($nilaiLalu)" : ""}',
        tone: AppPillTone.success,
      ));
    } else {
      if (mk.isUlang) {
        pills.add(const AppPill('Mengulang', tone: AppPillTone.warning));
      }
      if (nilaiLalu != null && nilaiLalu.isNotEmpty) {
        pills.add(AppPill('Nilai Lalu: $nilaiLalu', tone: AppPillTone.info));
      }
    }

    if (pills.isEmpty) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < pills.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          pills[i],
        ],
      ],
    );
  }

  /// Satu baris mata kuliah — aksi (pilih/batal pilih) tetap sama.
  Widget _buildMatkulRow(MatkulDitawarkan mk) {
    final isLulus = mk.status.toLowerCase() == 'lulus';
    final isSelected = _selectedMakul.contains(mk.kode);

    return AppListRow(
      leading: Icon(
        isLulus
            ? CupertinoIcons.checkmark_seal_fill
            : (isSelected ? Icons.check_circle : Icons.radio_button_unchecked),
        size: 22,
        color: isLulus
            ? AppColors.success
            : (isSelected ? AppColors.primary : AppColors.borderStrong),
      ),
      title: mk.nama,
      subtitle: '${mk.kode} • ${mk.sks} SKS',
      trailing: _buildStatusPills(mk),
      onTap: isLulus
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedMakul.remove(mk.kode);
                } else {
                  _selectedMakul.add(mk.kode);
                }
              });
            },
    );
  }

  Widget _buildSemesterTile(int semester, List<MatkulDitawarkan> items) {
    return ExpansionTile(
      initiallyExpanded: false,
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: AppColors.primarySoft,
      collapsedIconColor: AppColors.textMuted,
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      childrenPadding: EdgeInsets.zero,
      title: Text(
        'Semester $semester',
        style: AppText.h3.copyWith(color: AppColors.primary),
      ),
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.border),
          _buildMatkulRow(items[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoading();
    if (_error != null) {
      return Padding(
        padding: AppSpacing.page,
        child: Align(
          alignment: Alignment.topCenter,
          child: AppErrorState(message: _error!, onRetry: _load),
        ),
      );
    }

    // Group by Semester
    Map<int, List<MatkulDitawarkan>> groupedMatkul = {};
    for (var mk in _matkulList) {
      groupedMatkul.putIfAbsent(mk.semester, () => []).add(mk);
    }
    final sortedSemesters = groupedMatkul.keys.toList()..sort();

    final bool overSks = (_selectedSks + _sksSaatIni) > _maxSks;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
            ),
            children: [
              if (_info?.periodePengajuan != null && _info!.periodePengajuan!.teksMentah.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _buildAnnouncementBanner(_info!.periodePengajuan!.teksMentah),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AppStatTile(
                      value: _maxSks.toString(),
                      label: 'Batas SKS',
                      icon: CupertinoIcons.arrow_up_right_square,
                      accent: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppStatTile(
                      value: '${_selectedSks + _sksSaatIni} SKS',
                      label: 'Terpilih',
                      icon: CupertinoIcons.checkmark_alt_circle,
                      accent: overSks ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _syncKrs,
                  icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 18),
                  label: const Text('Sinkronisasi Tagihan & KRS'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppListGroup(
                children: [
                  for (var i = 0; i < sortedSemesters.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, thickness: 1, color: AppColors.border),
                    _buildSemesterTile(
                      sortedSemesters[i],
                      groupedMatkul[sortedSemesters[i]]!,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: overSks ? null : _submit,
              child: const Text('Ajukan Mata Kuliah'),
            ),
          ),
        )
      ],
    );
  }
}

class _DaftarPengajuanTab extends StatefulWidget {
  const _DaftarPengajuanTab();
  @override
  State<_DaftarPengajuanTab> createState() => _DaftarPengajuanTabState();
}

class _DaftarPengajuanTabState extends State<_DaftarPengajuanTab> {
  final _service = KrsService();
  bool _loading = true;
  String? _error;
  List<KrsPengajuan> _list = [];
  int _totalSks = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _service.getPengajuan();
      if (mounted) {
        setState(() {
          _list = res.data;
          _totalSks = res.totalSks;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(KrsPengajuan mk) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengajuan'),
        content: Text('Apakah Anda yakin ingin menghapus mata kuliah "${mk.mkl}" dari pengajuan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _delete(mk.idKrs.toString());
    }
  }

  void _delete(String idKrs) async {
    setState(() => _loading = true);
    try {
      await _service.deletePengajuan(idKrs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mata kuliah berhasil dihapus dari pengajuan')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: ${e.toString()}')),
        );
        setState(() => _loading = false);
      }
    }
  }

  /// Baris pengajuan: kode sebagai penanda, status sebagai pil.
  Widget _buildPengajuanRow(KrsPengajuan mk) {
    final isAktif = mk.aktivasi == 1;
    final isUlang = mk.ambilKe > 1;

    return AppListRow(
      leading: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Text(
          mk.kode,
          style: AppText.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: mk.mkl,
      subtitle: '${mk.sks} SKS • ${isUlang ? 'Ambil Ulang' : 'Baru'}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPill(
            isAktif ? 'Teraktivasi' : 'Belum Teraktivasi',
            tone: isAktif ? AppPillTone.success : AppPillTone.warning,
          ),
          if (!isAktif)
            IconButton(
              onPressed: () => _confirmDelete(mk),
              icon: const Icon(CupertinoIcons.trash, size: 18, color: AppColors.danger),
              tooltip: 'Hapus',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoading();
    if (_error != null) {
      return Padding(
        padding: AppSpacing.page,
        child: Align(
          alignment: Alignment.topCenter,
          child: AppErrorState(message: _error!, onRetry: _load),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppStatTile(
                  value: '$_totalSks SKS',
                  label: 'Total SKS Diajukan',
                  icon: CupertinoIcons.book_circle_fill,
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppStatTile(
                  value: _list.length.toString(),
                  label: 'Matkul',
                  icon: CupertinoIcons.list_bullet,
                  accent: AppColors.info,
                ),
              ),
            ],
          ),
          if (_list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: AppEmptyState(
                title: 'Belum Ada Mata Kuliah Diajukan',
                message: 'Silakan pilih mata kuliah pada tab "Pengajuan" untuk mengajukan KRS.',
                icon: CupertinoIcons.doc_plaintext,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: AppListGroup.from([
                for (final mk in _list) _buildPengajuanRow(mk),
              ]),
            ),
        ],
      ),
    );
  }
}

class _PengisianKelasTab extends StatefulWidget {
  const _PengisianKelasTab();
  @override
  State<_PengisianKelasTab> createState() => _PengisianKelasTabState();
}

class _PengisianKelasTabState extends State<_PengisianKelasTab> {
  final _service = KrsService();
  bool _loading = true;
  String? _error;
  List<KrsPengisian> _listSudah = [];
  List<KrsPengisian> _listBelum = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final resSudah = await _service.getPengisian();
      final resBelum = await _service.getBelumDiisi();
      if (mounted) {
        setState(() {
          _listSudah = resSudah.data;
          _listBelum = resBelum.data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _batal(String kode) async {
    setState(() => _loading = true);
    try {
      await _service.deletePengisian(kode);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membatalkan: ${e.toString()}')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoading();
    if (_error != null) {
      return Padding(
        padding: AppSpacing.page,
        child: Align(
          alignment: Alignment.topCenter,
          child: AppErrorState(message: _error!, onRetry: _load),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
      ),
      children: [
        AppSection(
          title: 'Matkul Belum Diisi Kelasnya:',
          topGap: 0,
          child: _listBelum.isEmpty
              ? Text(
                  'Semua matkul sudah diisi kelasnya',
                  style: AppText.bodySm.copyWith(color: AppColors.success),
                )
              : AppListGroup.from([
                  for (final mk in _listBelum)
                    AppListRow(
                      title: mk.namaMataKuliah,
                      subtitle: '${mk.kodeMk} - ${mk.sks} SKS',
                      trailing: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form pengisian kelas masih menunggu penyelesaian backend adaptor')));
                        },
                        child: const Text('Pilih Kelas'),
                      ),
                    ),
                ]),
        ),
        AppSection(
          title: 'Daftar Kelas Terpilih:',
          child: _listSudah.isEmpty
              ? Text(
                  'Belum ada kelas yang dipilih',
                  style: AppText.bodySm.copyWith(color: AppColors.textMuted),
                )
              : AppListGroup.from([
                  for (final mk in _listSudah)
                    AppListRow(
                      title: '${mk.namaMataKuliah} - Ruang ${mk.ruang}',
                      subtitle: '${mk.sks} SKS\n${mk.hari}, ${mk.jam}\nDosen: ${mk.dosenKelas.isEmpty ? "-" : mk.dosenKelas}',
                      trailing: IconButton(
                        onPressed: () => _batal(mk.kodeMk),
                        icon: const Icon(CupertinoIcons.trash, size: 18, color: AppColors.danger),
                        tooltip: 'Batalkan',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: AppSpacing.xxl,
                          height: AppSpacing.xxl,
                        ),
                      ),
                    ),
                ]),
        ),
      ],
    );
  }
}
