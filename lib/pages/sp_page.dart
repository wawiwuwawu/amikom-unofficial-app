import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/sp.dart';
import '../services/sp_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Halaman Semester Pendek (SP).
///
/// Tiga tab: pengajuan MK, MK yang sudah diambil, dan jadwal SP. Data yang
/// dibaca & dibandingkan (kuota, rekomendasi, tawaran matakuliah, MK diambil)
/// disajikan sebagai daftar [AppListGroup] + [AppListRow] agar mudah dipindai;
/// kartu ([AppSurface]) hanya untuk banner periode, ringkasan, dan catatan.
///
/// Tombol kembali disediakan otomatis oleh [AppScaffold] mengikuti route,
/// sehingga `onBack` hanya dipertahankan untuk kompatibilitas pemanggil lama.
class SpPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SpPage({super.key, this.onBack});

  @override
  State<SpPage> createState() => _SpPageState();
}

class _SpPageState extends State<SpPage> {
  final SpService _service = SpService();

  bool _isLoadingAvailable = true;
  String _errorAvailable = '';
  SpAvailableData? _availableData;
  SpRekomendasiData? _rekomendasiData;
  final Set<String> _selectedKodes = {};

  bool _isLoadingTaken = true;
  String _errorTaken = '';
  SpTakenData? _takenData;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchAvailable(),
      _fetchTaken(),
      _fetchRekomendasi(),
    ]);
  }

  Future<void> _fetchRekomendasi() async {
    try {
      final data = await _service.getRekomendasi();
      if (mounted) {
        setState(() => _rekomendasiData = data);
      }
    } catch (_) {}
  }

  Future<void> _fetchAvailable() async {
    setState(() {
      _isLoadingAvailable = true;
      _errorAvailable = '';
    });
    try {
      final data = await _service.getAvailable();
      if (mounted) {
        setState(() {
          _availableData = data;
          _isLoadingAvailable = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorAvailable = e.toString().replaceFirst('Exception: ', '');
          _isLoadingAvailable = false;
        });
      }
    }
  }

  Future<void> _fetchTaken() async {
    setState(() {
      _isLoadingTaken = true;
      _errorTaken = '';
    });
    try {
      final data = await _service.getTaken();
      if (mounted) {
        setState(() {
          _takenData = data;
          _isLoadingTaken = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorTaken = e.toString().replaceFirst('Exception: ', '');
          _isLoadingTaken = false;
        });
      }
    }
  }

  int get _selectedTotalSks {
    if (_availableData == null) return 0;
    int total = 0;
    final allMatkul = [
      ..._availableData!.matkulTahunBerjalan,
      ..._availableData!.matkulTahunLain,
    ];
    for (var m in allMatkul) {
      if (_selectedKodes.contains(m.kode)) {
        total += m.sks;
      }
    }
    return total;
  }

  void _toggleSelection(SpMatkul item) {
    if (item.disabled) return;

    final isCurrentlySelected = _selectedKodes.contains(item.kode);
    if (!isCurrentlySelected) {
      final currentSisa = _availableData?.sisaSks ?? 0;
      if (_selectedTotalSks + item.sks > currentSisa) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Total SKS terpilih melebihi sisa kuota ($currentSisa SKS)'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      setState(() {
        _selectedKodes.add(item.kode);
      });
    } else {
      setState(() {
        _selectedKodes.remove(item.kode);
      });
    }
  }

  Future<void> _showSubmitConfirmation() async {
    if (_selectedKodes.isEmpty || _availableData == null) return;

    final allMatkul = [
      ..._availableData!.matkulTahunBerjalan,
      ..._availableData!.matkulTahunLain,
    ];
    final selectedItems = allMatkul.where((m) => _selectedKodes.contains(m.kode)).toList();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengajuan Semester Pendek'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anda akan mengajukan matakuliah berikut:'),
            const SizedBox(height: AppSpacing.md),
            ...selectedItems.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${m.mkl} (${m.kode}) - ${m.sks} SKS',
                          style: AppText.bodySm.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(height: AppSpacing.xl),
            Text(
              'Total: ${selectedItems.length} Mata Kuliah ($_selectedTotalSks SKS)',
              style: AppText.h3.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Ajukan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);
      try {
        final res = await _service.submitSp(_selectedKodes.toList());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Data mata kuliah SP berhasil ditambahkan'),
              backgroundColor: AppColors.success,
            ),
          );
          _selectedKodes.clear();
          _loadAllData();
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
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation(SpTakenItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Matakuliah SP'),
        content: Text('Apakah Anda yakin ingin menghapus matakuliah ${item.mkl} (${item.kode})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.deleteSp(item.idKrs);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Data mata kuliah SP berhasil dihapus'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadAllData();
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
      }
    }
  }

  // ── Kerangka halaman ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: 'Semester Pendek (SP)',
        subtitle: 'Pengajuan & jadwal mata kuliah SP',
        scrollable: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(
                  icon: Icon(CupertinoIcons.list_bullet),
                  text: 'MK Pilihan',
                ),
                Tab(
                  icon: Icon(CupertinoIcons.checkmark_seal_fill),
                  text: 'MK Dipilih',
                ),
                Tab(
                  icon: Icon(CupertinoIcons.calendar),
                  text: 'Jadwal SP',
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAvailableTab(),
                  _buildTakenTab(),
                  _buildJadwalTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: MK Pilihan ────────────────────────────────────────────────────

  Widget _buildAvailableTab() {
    if (_isLoadingAvailable) {
      return const AppLoading(message: 'Memuat mata kuliah SP…');
    }

    if (_errorAvailable.isNotEmpty) {
      return Padding(
        padding: AppSpacing.page,
        child: AppErrorState(
          message: _errorAvailable,
          onRetry: _fetchAvailable,
        ),
      );
    }

    final data = _availableData;
    if (data == null) {
      return const AppEmptyState(
        title: 'Data tidak tersedia',
        icon: CupertinoIcons.doc_plaintext,
      );
    }

    final rekomendasi = _rekomendasiData;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _fetchAvailable(),
              _fetchRekomendasi(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              120,
            ),
            children: [
              _buildPeriodeBanner(data),
              _buildKuotaRingkasan(data),
              if (rekomendasi != null && rekomendasi.hasRekomendasi)
                _buildRekomendasiSection(rekomendasi),
              if (!data.isOpen)
                _buildPendaftaranTutup()
              else ...[
                if (data.matkulTahunBerjalan.isNotEmpty)
                  AppSection(
                    title: 'Matakuliah Tahun Berjalan',
                    trailing: AppPill('${data.matkulTahunBerjalan.length} MK'),
                    child: AppListGroup.from([
                      for (final m in data.matkulTahunBerjalan) _buildMatkulRow(m),
                    ]),
                  ),
                if (data.matkulTahunLain.isNotEmpty)
                  AppSection(
                    title: 'Matakuliah Perbaikan / Tahun Lain',
                    trailing: AppPill('${data.matkulTahunLain.length} MK'),
                    child: AppListGroup.from([
                      for (final m in data.matkulTahunLain) _buildMatkulRow(m),
                    ]),
                  ),
                if (data.matkulTahunBerjalan.isEmpty && data.matkulTahunLain.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: AppEmptyState(
                      title: 'Tidak ada matakuliah SP yang tersedia',
                      icon: CupertinoIcons.doc_plaintext,
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (data.isOpen && _selectedKodes.isNotEmpty) _buildSubmitBar(),
      ],
    );
  }

  /// Banner status periode SP — konten yang dibaca, jadi tetap berupa kartu.
  Widget _buildPeriodeBanner(SpAvailableData data) {
    final isOpen = data.isOpen;
    return AppSurface(
      variant: isOpen ? AppSurfaceVariant.hero : AppSurfaceVariant.warning,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isOpen
                ? CupertinoIcons.info_circle_fill
                : CupertinoIcons.exclamationmark_circle_fill,
            size: 20,
            color: isOpen ? AppColors.primary : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              data.periodeInfo,
              style: AppText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOpen ? AppColors.textPrimary : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ringkasan kuota SKS sebagai angka besar, bukan tiga baris teks kecil.
  Widget _buildKuotaRingkasan(SpAvailableData data) {
    return AppSection(
      title: 'Ringkasan Kuota',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppStatTile(
              value: '${data.sisaSks} SKS',
              label: 'Sisa Kuota',
              icon: Icons.speed,
              accent: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppStatTile(
              value: '${data.maxSks} SKS',
              label: 'Batas Max',
              icon: Icons.rule,
              accent: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppStatTile(
              value: '${data.totalSksTahunIni} SKS',
              label: 'Tahun Ini',
              icon: Icons.menu_book_outlined,
              accent: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendaftaranTutup() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: AppSurface(
        variant: AppSurfaceVariant.warning,
        child: Row(
          children: [
            const Icon(CupertinoIcons.lock_fill, size: 18, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Pendaftaran SP sedang ditutup',
                style: AppText.h3.copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tawaran matakuliah SP — daftar yang dipindai, bukan tumpukan kartu.
  Widget _buildMatkulRow(SpMatkul item) {
    final isSelected = _selectedKodes.contains(item.kode);

    final row = AppListRow(
      leading: Checkbox(
        value: isSelected,
        onChanged: item.disabled ? null : (_) => _toggleSelection(item),
        activeColor: AppColors.primary,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      title: item.mkl,
      subtitle: 'Kode: ${item.kode} • TA: ${item.thnAjaran} (${item.semester})',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.nilai.isNotEmpty) ...[
            Text(
              'Nilai: ${item.nilai}',
              style: AppText.label.copyWith(color: GradeStyle.text(item.nilai)),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          AppPill('${item.sks} SKS'),
        ],
      ),
      onTap: item.disabled ? null : () => _toggleSelection(item),
    );

    return item.disabled ? Opacity(opacity: 0.55, child: row) : row;
  }

  /// Bar pengajuan melayang — hanya muncul bila ada matakuliah terpilih.
  Widget _buildSubmitBar() {
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: AppSpacing.xl,
      child: FilledButton.icon(
        onPressed: _isSubmitting ? null : _showSubmitConfirmation,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(CupertinoIcons.paperplane_fill, size: 18),
        label: Text(
          'Ajuan SP (${_selectedKodes.length} Matkul - $_selectedTotalSks SKS)',
        ),
      ),
    );
  }

  // ── Tab 2: MK Dipilih ────────────────────────────────────────────────────

  Widget _buildTakenTab() {
    if (_isLoadingTaken) {
      return const AppLoading(message: 'Memuat mata kuliah SP…');
    }

    if (_errorTaken.isNotEmpty) {
      return Padding(
        padding: AppSpacing.page,
        child: AppErrorState(
          message: _errorTaken,
          onRetry: _fetchTaken,
        ),
      );
    }

    final data = _takenData;
    if (data == null || data.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchTaken,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const AppEmptyState(
                title: 'Belum ada matakuliah SP yang diambil',
                icon: CupertinoIcons.doc_plaintext,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTaken,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          AppSection(
            title: 'Ringkasan',
            topGap: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AppStatTile(
                    value: '${data.totalSks} SKS',
                    label: 'Total SKS SP Diambil',
                    icon: Icons.menu_book_outlined,
                    accent: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppStatTile(
                    value: '${data.items.length}',
                    label: 'Mata Kuliah',
                    icon: Icons.list_alt_outlined,
                    accent: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
          AppSection(
            title: 'Matakuliah SP Diambil',
            child: AppListGroup.from([
              for (final item in data.items) _buildTakenRow(item),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTakenRow(SpTakenItem item) {
    return AppListRow(
      title: item.mkl,
      subtitle: 'Kode: ${item.kode} • ${item.sks} SKS',
      trailing: item.isActivated
          ? const AppPill('Teraktivasi', tone: AppPillTone.success)
          : item.canDelete
              ? IconButton(
                  icon: const Icon(
                    CupertinoIcons.trash,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  tooltip: 'Hapus Matakuliah',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showDeleteConfirmation(item),
                )
              : null,
    );
  }

  // ── Tab 3: Jadwal SP ─────────────────────────────────────────────────────

  Widget _buildJadwalTab() {
    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const AppEmptyState(
            icon: CupertinoIcons.calendar_today,
            title: 'Jadwal Perkuliahan SP',
            message:
                'Jadwal perkuliahan Semester Pendek akan ditampilkan di sini secara otomatis setelah mata kuliah SP yang Anda ambil teraktivasi oleh Bagian Akademik.',
          ),
          AppSection(
            title: 'Catatan Akademik',
            child: AppSurface(
              variant: AppSurfaceVariant.hero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.info_circle,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Pastikan Anda menyelesaikan pembayaran SP dan memeriksa status "Teraktivasi" pada tab Mata Kuliah Dipilih.',
                      style: AppText.bodySm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rekomendasi SP ───────────────────────────────────────────────────────

  SpMatkul? _findMatkulByKode(String kode) {
    if (_availableData == null) return null;
    final allMatkul = [
      ..._availableData!.matkulTahunBerjalan,
      ..._availableData!.matkulTahunLain,
    ];
    for (var m in allMatkul) {
      if (m.kode == kode) return m;
    }
    return null;
  }

  /// Rekomendasi dikelompokkan per kategori (AppSection) dan disajikan sebagai
  /// daftar, sehingga mata kuliah prioritas langsung terlihat.
  Widget _buildRekomendasiSection(SpRekomendasiData rekomendasi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rekomendasi.kategoriSangatDianjurkan.isNotEmpty)
          AppSection(
            title: 'Sangat Dianjurkan (Nilai D/E)',
            trailing: TextButton(
              onPressed: () {
                if (_availableData == null) return;
                final availableKodes = [
                  ..._availableData!.matkulTahunBerjalan,
                  ..._availableData!.matkulTahunLain,
                ].map((m) => m.kode).toSet();

                setState(() {
                  for (var item in rekomendasi.kategoriSangatDianjurkan) {
                    if (availableKodes.contains(item.kode)) {
                      _selectedKodes.add(item.kode);
                    }
                  }
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Pilih Semua D/E'),
            ),
            child: AppListGroup.from([
              for (final item in rekomendasi.kategoriSangatDianjurkan)
                _buildRekomendasiRow(item, isHighPriority: true),
            ]),
          ),
        if (rekomendasi.kategoriOpsionalSksBesar.isNotEmpty)
          AppSection(
            title: 'Opsional SKS Besar (Dongkrak IPK)',
            child: AppListGroup.from([
              for (final item in rekomendasi.kategoriOpsionalSksBesar)
                _buildRekomendasiRow(item, isHighPriority: false),
            ]),
          ),
      ],
    );
  }

  Widget _buildRekomendasiRow(
    SpRekomendasiItem item, {
    required bool isHighPriority,
  }) {
    final matkul = _findMatkulByKode(item.kode);
    final isSelected = _selectedKodes.contains(item.kode);
    final isDisabled = matkul?.disabled ?? false;
    final isEnabled = matkul != null && !isDisabled;

    final detail = <String>[
      'Kode: ${item.kode}',
      '${item.sks} SKS',
      if (item.nilaiSebelumnya.isNotEmpty) 'Nilai: ${item.nilaiSebelumnya}',
      if (item.alasan.isNotEmpty) item.alasan,
    ].join(' • ');

    return AppListRow(
      leading: Checkbox(
        value: isSelected,
        onChanged: isEnabled ? (_) => _toggleSelection(matkul) : null,
        activeColor: AppColors.primary,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      title: item.mkl,
      subtitle: detail,
      trailing: AppPill(
        isHighPriority ? 'Sangat dianjurkan' : 'Opsional',
        tone: isHighPriority ? AppPillTone.danger : AppPillTone.warning,
      ),
      onTap: isEnabled ? () => _toggleSelection(matkul) : null,
    );
  }
}
