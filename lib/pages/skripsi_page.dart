import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/skripsi.dart';
import '../services/skripsi_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Halaman Skripsi & Tugas Akhir.
///
/// Redesign memakai design system: tiap tahapan (proposal, bimbingan, ujian,
/// plagiarisme) dipisah oleh [AppSection]; data tahapan disajikan sebagai baris
/// [AppListRow] di dalam satu [AppListGroup] per tahap; status/aktivasi
/// dipadatkan jadi [AppPill]; pasangan label-nilai memakai [AppKeyValue].
/// Kartu ([AppSurface]) hanya untuk ringkasan tahap saat ini dan banner
/// peringatan. Bagian yang belum relevan disembunyikan lewat kondisi yang sudah
/// ada (mis. `canDownload`, `tglUjian`, `isDitolak`).
///
/// Tombol kembali disediakan otomatis oleh [AppScaffold] mengikuti route,
/// sehingga `onBack` dipertahankan hanya untuk kompatibilitas pemanggil lama.
class SkripsiPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SkripsiPage({super.key, this.onBack});

  @override
  State<SkripsiPage> createState() => _SkripsiPageState();
}

class _SkripsiPageState extends State<SkripsiPage>
    with SingleTickerProviderStateMixin {
  final SkripsiService _service = SkripsiService();
  late TabController _tabController;

  // Main Info State
  bool _isLoadingMain = true;
  String? _errorMain;
  SkripsiMainData? _mainData;

  // Proposal State
  bool _isLoadingProposal = true;
  String? _errorProposal;
  List<SkripsiProposalItem> _proposals = [];

  // Bimbingan State
  bool _isLoadingBimbingan = true;
  String? _errorBimbingan;
  List<SkripsiBimbinganItem> _bimbingans = [];

  // Pendaftaran State
  bool _isLoadingPendaftaran = true;
  String? _errorPendaftaran;
  List<SkripsiPendaftaranItem> _pendaftarans = [];

  // Plagiarisme State
  bool _isLoadingPlagiarisme = true;
  String? _errorPlagiarisme;
  List<SkripsiPlagiarismeItem> _plagiarsmes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchMainInfo(),
      _fetchProposals(),
      _fetchBimbingans(),
      _fetchPendaftarans(),
      _fetchPlagiarsmes(),
    ]);
  }

  Future<void> _fetchMainInfo() async {
    setState(() {
      _isLoadingMain = true;
      _errorMain = null;
    });
    try {
      final data = await _service.getMainInfo();
      if (mounted) {
        setState(() {
          _mainData = data;
          _isLoadingMain = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMain = e.toString().replaceFirst('Exception: ', '');
          _isLoadingMain = false;
        });
      }
    }
  }

  Future<void> _fetchProposals() async {
    setState(() {
      _isLoadingProposal = true;
      _errorProposal = null;
    });
    try {
      final list = await _service.getProposals();
      if (mounted) {
        setState(() {
          _proposals = list;
          _isLoadingProposal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorProposal = e.toString().replaceFirst('Exception: ', '');
          _isLoadingProposal = false;
        });
      }
    }
  }

  Future<void> _fetchBimbingans() async {
    setState(() {
      _isLoadingBimbingan = true;
      _errorBimbingan = null;
    });
    try {
      final list = await _service.getBimbinganList();
      if (mounted) {
        setState(() {
          _bimbingans = list;
          _isLoadingBimbingan = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorBimbingan = e.toString().replaceFirst('Exception: ', '');
          _isLoadingBimbingan = false;
        });
      }
    }
  }

  Future<void> _fetchPendaftarans() async {
    setState(() {
      _isLoadingPendaftaran = true;
      _errorPendaftaran = null;
    });
    try {
      final list = await _service.getPendaftaranList();
      if (mounted) {
        setState(() {
          _pendaftarans = list;
          _isLoadingPendaftaran = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorPendaftaran = e.toString().replaceFirst('Exception: ', '');
          _isLoadingPendaftaran = false;
        });
      }
    }
  }

  Future<void> _fetchPlagiarsmes() async {
    setState(() {
      _isLoadingPlagiarisme = true;
      _errorPlagiarisme = null;
    });
    try {
      final list = await _service.getPlagiarismeList();
      if (mounted) {
        setState(() {
          _plagiarsmes = list;
          _isLoadingPlagiarisme = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorPlagiarisme = e.toString().replaceFirst('Exception: ', '');
          _isLoadingPlagiarisme = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Skripsi & Tugas Akhir 🎓',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.gear_alt_fill),
          tooltip: 'Pasca Ujian (Judul & Berkas)',
          onPressed: _showPascaUjianMenu,
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.refresh),
          onPressed: _loadAllData,
        ),
      ],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: _buildHeaderCard(),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: '📄 Proposal'),
                    Tab(text: '📝 Bimbingan'),
                    Tab(text: '🎓 Ujian Skripsi'),
                    Tab(text: '🔍 Plagiarisme'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProposalTab(),
            _buildBimbinganTab(),
            _buildPendaftaranTab(),
            _buildPlagiarismeTab(),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  /// Tinggi ruang aman bawah untuk daftar (menghindari navigasi bawah aplikasi).
  double get _listBottomPadding =>
      MediaQuery.of(context).padding.bottom + AppSpacing.xxl * 4;

  AppPillTone _proposalTone(String status) {
    final s = status.toLowerCase();
    if (s.contains('terima') || s.contains('setuju')) return AppPillTone.success;
    if (s.contains('tolak')) return AppPillTone.danger;
    return AppPillTone.warning;
  }

  Widget _tabError(String message, VoidCallback onRetry) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppErrorState(message: message, onRetry: onRetry),
      ),
    );
  }

  Widget _rowIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: AppDeco.softPrimary(radius: AppRadius.sm),
      child: Icon(icon, size: 18, color: AppColors.primary),
    );
  }

  // --- HEADER & MAIN INFO ---
  Widget _buildHeaderCard() {
    if (_isLoadingMain) {
      return const AppLoading();
    }
    if (_errorMain != null) {
      return AppErrorState(message: _errorMain!, onRetry: _fetchMainInfo);
    }

    final main = _mainData;
    if (main == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSurface(
          variant: AppSurfaceVariant.hero,
          radius: AppRadius.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: AppDeco.softPrimary(radius: AppRadius.md),
                    child: const Icon(
                      CupertinoIcons.book_circle_fill,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status Pembimbing Skripsi', style: AppText.h3),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppPill(
                            main.dospemAssigned
                                ? 'Dosen Pembimbing Terdaftar'
                                : 'Belum Ada Dosen Pembimbing',
                            tone: main.dospemAssigned
                                ? AppPillTone.success
                                : AppPillTone.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (main.informasi.isNotEmpty) ...[
                const Divider(height: AppSpacing.xl),
                Text('📢 Petunjuk & Pengumuman BAP:', style: AppText.h3),
                const SizedBox(height: AppSpacing.sm),
                ...main.informasi.map(
                  (info) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            CupertinoIcons.circle_fill,
                            size: 6,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(info, style: AppText.bodySm)),
                      ],
                    ),
                  ),
                ),
              ],
              if (main.tataCaraDownloadUrl != null &&
                  main.tataCaraDownloadUrl!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openUrl(main.tataCaraDownloadUrl!),
                    icon: const Icon(CupertinoIcons.doc_text_fill, size: 16),
                    label: const Text('Download Panduan & Tata Cara'),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (main.dospemWarning != null && main.dospemWarning!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppSurface(
            variant: AppSurfaceVariant.warning,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    main.dospemWarning!,
                    style: AppText.bodySm.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- TAB 1: PROPOSAL ---
  Widget _buildProposalTab() {
    final bottomPadding = _listBottomPadding;

    if (_isLoadingProposal) {
      return const AppLoading();
    }
    if (_errorProposal != null) {
      return _tabError(_errorProposal!, _fetchProposals);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      children: [
        AppSection(
          title: 'Riwayat Proposal Skripsi',
          topGap: 0,
          trailing: FilledButton.icon(
            onPressed: _showFormProposalBaru,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            icon: const Icon(CupertinoIcons.add, size: 16),
            label: const Text('Ajukan Proposal'),
          ),
          child: _proposals.isEmpty
              ? const AppEmptyState(
                  title: 'Belum ada riwayat pengajuan proposal',
                  icon: CupertinoIcons.doc_plaintext,
                )
              : AppListGroup.from([
                  for (final item in _proposals) _buildProposalItem(item),
                ]),
        ),
      ],
    );
  }

  Widget _buildProposalItem(SkripsiProposalItem item) {
    final isDitolak = item.status.toLowerCase().contains('tolak');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListRow(
          leading: _rowIcon(CupertinoIcons.doc_plaintext),
          title: item.judul,
          subtitle: 'Pengajuan #${item.no}',
          trailing: AppPill(item.status, tone: _proposalTone(item.status)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppKeyValue(
                label: 'Reviewer',
                value: item.dosen ?? 'Reviewer belum ditentukan',
              ),
              AppKeyValue(label: 'Tanggal', value: item.tglPengajuan),
              if (item.review != null && item.review!.isNotEmpty)
                AppKeyValue(label: 'Catatan Reviewer', value: item.review!),
              if (isDitolak) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showFormProposalUlang(item),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          textStyle: AppText.label.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Proposal Ulang'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleTemaUlang(item),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          textStyle: AppText.label.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Tema Ulang (Pusat Studi)'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 2: BIMBINGAN ---
  Widget _buildBimbinganTab() {
    final bottomPadding = _listBottomPadding;

    if (_isLoadingBimbingan) {
      return const AppLoading();
    }
    if (_errorBimbingan != null) {
      return _tabError(_errorBimbingan!, _fetchBimbingans);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      children: [
        AppSection(
          title: 'Kartu Bimbingan Skripsi',
          topGap: 0,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_bimbingans.isNotEmpty)
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_down_doc_fill),
                  tooltip: 'Cetak Kartu Bimbingan PDF',
                  onPressed: () =>
                      _handleDownloadKartuBimbingan(_bimbingans.first.id),
                ),
              FilledButton.icon(
                onPressed: _showFormBimbingan,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                icon: const Icon(CupertinoIcons.add, size: 16),
                label: const Text('Catatan Baru'),
              ),
            ],
          ),
          child: _bimbingans.isEmpty
              ? const AppEmptyState(
                  title: 'Belum ada catatan bimbingan skripsi',
                  icon: CupertinoIcons.doc_text,
                )
              : AppListGroup.from([
                  for (final item in _bimbingans) _buildBimbinganItem(item),
                ]),
        ),
      ],
    );
  }

  Widget _buildBimbinganItem(SkripsiBimbinganItem item) {
    return AppListRow(
      leading: AppPill(item.progres, tone: AppPillTone.info),
      title: 'Tanggal: ${item.tanggal}',
      subtitle: item.keterangan,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil, size: 18),
            onPressed: () => _showFormBimbingan(item: item),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_down_doc, size: 18),
            onPressed: () => _handleDownloadKartuBimbingan(item.id),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: PENDAFTARAN & UJIAN ---
  Widget _buildPendaftaranTab() {
    final bottomPadding = _listBottomPadding;

    if (_isLoadingPendaftaran) {
      return const AppLoading();
    }
    if (_errorPendaftaran != null) {
      return _tabError(_errorPendaftaran!, _fetchPendaftarans);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      children: [
        AppSection(
          title: 'Pengajuan Ujian Skripsi',
          topGap: 0,
          trailing: FilledButton.icon(
            onPressed: _showFormPendaftaranUjian,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            icon: const Icon(CupertinoIcons.add, size: 16),
            label: const Text('Daftar Ujian'),
          ),
          child: _pendaftarans.isEmpty
              ? const AppEmptyState(
                  title: 'Belum ada riwayat pendaftaran ujian skripsi',
                  icon: CupertinoIcons.person_2_square_stack,
                )
              : AppListGroup.from([
                  for (final item in _pendaftarans) _buildPendaftaranItem(item),
                ]),
        ),
      ],
    );
  }

  Widget _buildPendaftaranItem(SkripsiPendaftaranItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListRow(
          leading: _rowIcon(CupertinoIcons.person_2_square_stack),
          title: item.judul,
          subtitle: 'Tgl Daftar: ${item.tglDaftar}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppPill(
                item.aktivasi == 1
                    ? 'Terverifikasi / Aktif'
                    : 'Menunggu Verifikasi',
                tone: item.aktivasi == 1
                    ? AppPillTone.success
                    : AppPillTone.warning,
              ),
              if (item.canDelete)
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.trash,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  onPressed: () =>
                      _handleDeletePendaftaran(item.idPengajuan),
                ),
            ],
          ),
        ),
        if (item.tglUjian != null && item.tglUjian!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppKeyValue(
                  label: 'Jadwal Ujian',
                  value: '${item.tglUjian} (${item.jam ?? '-'})',
                  emphasize: true,
                ),
                if (item.ruang != null && item.ruang!.isNotEmpty)
                  AppKeyValue(label: 'Ruang', value: item.ruang!),
              ],
            ),
          ),
        if (item.canDownload)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _handleDownloadFormulirPendaftaran(item.idPengajuan),
                icon: const Icon(CupertinoIcons.arrow_down_doc, size: 16),
                label: const Text('Download Formulir Pendaftaran PDF'),
              ),
            ),
          ),
      ],
    );
  }

  // --- TAB 4: CEK PLAGIARISME ---
  Widget _buildPlagiarismeTab() {
    final bottomPadding = _listBottomPadding;

    if (_isLoadingPlagiarisme) {
      return const AppLoading();
    }
    if (_errorPlagiarisme != null) {
      return _tabError(_errorPlagiarisme!, _fetchPlagiarsmes);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      children: [
        AppSection(
          title: 'Status Cek Plagiarisme',
          topGap: 0,
          trailing: FilledButton.icon(
            onPressed: _handleUploadPlagiarisme,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            icon: const Icon(CupertinoIcons.cloud_upload_fill, size: 16),
            label: const Text('Upload File (.doc/.docx)'),
          ),
          child: _plagiarsmes.isEmpty
              ? const AppEmptyState(
                  title: 'Belum ada dokumen cek plagiarisme',
                  icon: CupertinoIcons.doc_text_search,
                )
              : AppListGroup.from([
                  for (final item in _plagiarsmes) _buildPlagiarismeItem(item),
                ]),
        ),
      ],
    );
  }

  Widget _buildPlagiarismeItem(SkripsiPlagiarismeItem item) {
    final isLolos = item.status.toLowerCase().contains('lolos');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListRow(
          leading: _rowIcon(CupertinoIcons.doc_text_search),
          title: item.judulSkripsi,
          subtitle: 'Persentase Similarity: ${item.persentase}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppPill(
                'Status: ${item.status}',
                tone: isLolos ? AppPillTone.success : AppPillTone.warning,
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.trash,
                  size: 18,
                  color: AppColors.danger,
                ),
                onPressed: () => _handleDeletePlagiarisme(item.id),
              ),
            ],
          ),
        ),
        if (item.laporanHasilCek != null && item.laporanHasilCek!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openUrl(item.laporanHasilCek!),
                icon: const Icon(CupertinoIcons.doc_text_search, size: 16),
                label: const Text('Lihat Laporan Hasil Cek Plagiarisme'),
              ),
            ),
          ),
      ],
    );
  }

  // --- ACTIONS & MODAL DIALOGS ---

  void _showFormProposalBaru() async {
    final judulCtrl = TextEditingController();
    File? pickedFile;
    String? fileName;
    int fileSize = 0;
    String? fileError;
    bool isSubmitting = false;
    double uploadProgress = 0.0;

    final hasDospemWarning = (_mainData?.dospemAssigned == false) ||
        (_mainData?.dospemWarning != null && _mainData!.dospemWarning!.isNotEmpty);

    String formatFileSize(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    String? validateFile(String name, int size) {
      if (RegExp(r'''[&\"'<>]''').hasMatch(name)) {
        return 'Nama berkas tidak boleh memuat karakter khusus (&, ", \', <, >)';
      }
      if (size > 3 * 1024 * 1024) {
        return 'Ukuran berkas melebihi batas maksimal 3 MB (${formatFileSize(size)})';
      }
      return null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBsState) {
          Future<void> pickPdfFile() async {
            try {
              final result = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (result != null &&
                  result.files.isNotEmpty &&
                  result.files.single.path != null) {
                final file = File(result.files.single.path!);
                final name = result.files.single.name;
                final size = result.files.single.size;
                final err = validateFile(name, size);
                setBsState(() {
                  pickedFile = file;
                  fileName = name;
                  fileSize = size;
                  fileError = err;
                });
              }
            } catch (e) {
              setBsState(() {
                fileError = 'Gagal memilih berkas: $e';
              });
            }
          }

          final isFormValid = judulCtrl.text.trim().isNotEmpty &&
              pickedFile != null &&
              fileError == null;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.scaffold,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ajukan Proposal Skripsi Baru',
                        style: AppText.h3.copyWith(color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (hasDospemWarning) ...[
                    AppSurface(
                      variant: AppSurfaceVariant.warning,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              (_mainData?.dospemWarning != null &&
                                      _mainData!.dospemWarning!.isNotEmpty)
                                  ? _mainData!.dospemWarning!
                                  : 'Dosen Pembimbing belum terdaftar. Pastikan Anda telah memenuhi persyaratan pengajuan proposal skripsi.',
                              style: AppText.bodySm.copyWith(
                                color: AppColors.warning,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text(
                    'Judul Proposal',
                    style: AppText.label.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: judulCtrl,
                    minLines: 2,
                    maxLines: 4,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan judul skripsi yang diajukan...',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => setBsState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Berkas Proposal (PDF)',
                    style: AppText.label.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (pickedFile == null)
                    InkWell(
                      onTap: isSubmitting ? null : pickPdfFile,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                          horizontal: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: fileError != null
                                ? AppColors.danger
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              CupertinoIcons.doc_text,
                              size: 36,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Pilih Berkas Proposal (PDF)', style: AppText.h3),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Format PDF, maksimal 3 MB',
                              style: AppText.label.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: fileError != null
                              ? AppColors.danger
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.dangerBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              CupertinoIcons.doc_text_fill,
                              color: AppColors.danger,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName ?? 'Berkas PDF',
                                  style: AppText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatFileSize(fileSize),
                                  style: AppText.label.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isSubmitting) ...[
                            IconButton(
                              tooltip: 'Ganti Berkas',
                              icon: const Icon(
                                CupertinoIcons.arrow_2_squarepath,
                                size: 18,
                              ),
                              onPressed: pickPdfFile,
                            ),
                            IconButton(
                              tooltip: 'Hapus Berkas',
                              icon: const Icon(
                                CupertinoIcons.trash,
                                size: 18,
                                color: AppColors.danger,
                              ),
                              onPressed: () {
                                setBsState(() {
                                  pickedFile = null;
                                  fileName = null;
                                  fileSize = 0;
                                  fileError = null;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (fileError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_circle,
                          color: AppColors.danger,
                          size: 14,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            fileError!,
                            style: AppText.bodySm.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isSubmitting) ...[
                    const SizedBox(height: AppSpacing.lg),
                    LinearProgressIndicator(
                      value: uploadProgress > 0 ? uploadProgress : null,
                      backgroundColor: AppColors.surfaceMuted,
                      color: AppColors.primary,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        uploadProgress > 0
                            ? 'Mengunggah: ${(uploadProgress * 100).toInt()}%'
                            : 'Menyiapkan berkas...',
                        style: AppText.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (!isFormValid || isSubmitting)
                          ? null
                          : () async {
                              setBsState(() {
                                isSubmitting = true;
                                uploadProgress = 0.0;
                              });
                              try {
                                final res = await _service.submitProposalBaru(
                                  judul: judulCtrl.text.trim(),
                                  filePdf: pickedFile!,
                                  onSendProgress: (sent, total) {
                                    if (ctx.mounted && total > 0) {
                                      setBsState(() {
                                        uploadProgress = sent / total;
                                      });
                                    }
                                  },
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                _showSnackBar(
                                  res.message.isNotEmpty
                                      ? res.message
                                      : 'Proposal berhasil diajukan',
                                  isSuccess: true,
                                );
                                _fetchProposals();
                              } catch (e) {
                                if (ctx.mounted) {
                                  setBsState(() {
                                    isSubmitting = false;
                                    uploadProgress = 0.0;
                                  });
                                }
                                _showSnackBar(
                                  e.toString().replaceFirst('Exception: ', ''),
                                  isError: true,
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kirim Pengajuan Proposal'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    judulCtrl.dispose();
  }

  void _showFormProposalUlang(SkripsiProposalItem item) {
    final reviewerCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Proposal Ulang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Judul: ${item.judul}',
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reviewerCtrl,
              decoration: const InputDecoration(
                labelText: 'ID Reviewer Baru / Pilihan',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await _service.submitProposalUlang(
                  idReviewer: reviewerCtrl.text.trim(),
                  idProposal: item.idProposal ?? '1',
                );
                _showSnackBar(res['message'] ?? 'Proposal ulang diajukan');
                _fetchProposals();
              } catch (e) {
                _showSnackBar(
                  e.toString().replaceFirst('Exception: ', ''),
                  isError: true,
                );
              }
            },
            child: const Text('Kirim Proposal Ulang'),
          ),
        ],
      ),
    );
  }

  void _handleTemaUlang(SkripsiProposalItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Tema Ulang'),
        content: const Text(
          'Apakah Anda yakin ingin mengajukan ulang tema skripsi ke Pusat Studi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Ajukan Tema Ulang'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.submitTemaUlang(idProposal: item.idProposal ?? '1');
        _showSnackBar(res['message'] ?? 'Tema ulang berhasil diajukan');
        _fetchProposals();
      } catch (e) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  void _showFormBimbingan({SkripsiBimbinganItem? item}) {
    final isEdit = item != null;
    final tanggalCtrl = TextEditingController(
      text: item?.tanggal ?? DateTime.now().toString().split(' ').first,
    );
    final progresCtrl = TextEditingController(text: item?.progres ?? '');
    final keteranganCtrl = TextEditingController(text: item?.keterangan ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Catatan Bimbingan' : 'Tambah Catatan Bimbingan',
              style: AppText.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: tanggalCtrl,
              decoration: const InputDecoration(
                labelText: 'Tanggal (YYYY-MM-DD)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: progresCtrl,
              decoration: const InputDecoration(
                labelText: 'Progres (misal: BAB 1 / BAB 2)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: keteranganCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan / Catatan Revisi',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (progresCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    if (isEdit) {
                      final res = await _service.updateBimbingan(
                        id: item.id,
                        tanggal: tanggalCtrl.text.trim(),
                        progres: progresCtrl.text.trim(),
                        keterangan: keteranganCtrl.text.trim(),
                      );
                      _showSnackBar(
                        res['message'] ?? 'Catatan bimbingan berhasil diperbarui',
                      );
                    } else {
                      final res = await _service.submitBimbingan(
                        tanggal: tanggalCtrl.text.trim(),
                        idauto: _mainData?.idauto ?? '',
                        nidn: _mainData?.nidn ?? '',
                        progres: progresCtrl.text.trim(),
                        keterangan: keteranganCtrl.text.trim(),
                      );
                      _showSnackBar(res['message'] ?? 'Catatan bimbingan disimpan');
                    }
                    _fetchBimbingans();
                  } catch (e) {
                    _showSnackBar(
                      e.toString().replaceFirst('Exception: ', ''),
                      isError: true,
                    );
                  }
                },
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Bimbingan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDownloadKartuBimbingan(String id) async {
    _showSnackBar('Mengunduh kartu bimbingan...');
    try {
      final path = await _service.downloadKartuBimbingan(id);
      _showSnackBar('Kartu bimbingan tersimpan di Download');
      await OpenFilex.open(path);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showFormPendaftaranUjian() {
    final judulCtrl = TextEditingController();
    String ukuranToga = 'L';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBsState) => Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          decoration: const BoxDecoration(
            color: AppColors.scaffold,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Form Pendaftaran Ujian Skripsi',
                style: AppText.h3.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: judulCtrl,
                decoration: const InputDecoration(labelText: 'Judul Skripsi'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: ukuranToga,
                decoration: const InputDecoration(labelText: 'Ukuran Toga'),
                items: const [
                  DropdownMenuItem(value: 'S', child: Text('S')),
                  DropdownMenuItem(value: 'M', child: Text('M')),
                  DropdownMenuItem(value: 'L', child: Text('L')),
                  DropdownMenuItem(value: 'XL', child: Text('XL')),
                  DropdownMenuItem(value: 'XXL', child: Text('XXL')),
                ],
                onChanged: (val) => setBsState(() => ukuranToga = val ?? 'L'),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (judulCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final res = await _service.submitPendaftaranUjian(
                        judul: judulCtrl.text.trim(),
                        ukuranToga: ukuranToga,
                      );
                      _showSnackBar(
                        res['message'] ??
                            'Pendaftaran ujian skripsi berhasil diajukan',
                      );
                      _fetchPendaftarans();
                    } catch (e) {
                      _showSnackBar(
                        e.toString().replaceFirst('Exception: ', ''),
                        isError: true,
                      );
                    }
                  },
                  child: const Text('Daftar Ujian Skripsi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDeletePendaftaran(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batal Pengajuan Ujian'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pengajuan ujian skripsi ini?',
        ),
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
      try {
        final res = await _service.deletePendaftaranUjian(id);
        _showSnackBar(res['message'] ?? 'Pendaftaran dibatalkan');
        _fetchPendaftarans();
      } catch (e) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  void _handleDownloadFormulirPendaftaran(String id) async {
    _showSnackBar('Mengunduh formulir pendaftaran...');
    try {
      final path = await _service.downloadFormulirPendaftaran(id);
      _showSnackBar('Formulir tersimpan di Download');
      await OpenFilex.open(path);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _handleUploadPlagiarisme() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileSize = await file.length();
      if (fileSize > 3 * 1024 * 1024) {
        _showSnackBar('Ukuran file maksimal 3MB', isError: true);
        return;
      }

      _showSnackBar('Mengunggah dokumen plagiarisme...');
      try {
        final res = await _service.uploadPlagiarisme(file);
        _showSnackBar(res['message'] ?? 'Dokumen berhasil diunggah');
        _fetchPlagiarsmes();
      } catch (e) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  void _handleDeletePlagiarisme(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen Plagiarisme'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus dokumen plagiarisme ini?',
        ),
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
      try {
        final res = await _service.deletePlagiarisme(id);
        _showSnackBar(res['message'] ?? 'Dokumen berhasil dihapus');
        _fetchPlagiarsmes();
      } catch (e) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  void _showPascaUjianMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu Pasca Ujian Skripsi',
              style: AppText.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppListGroup.from([
              AppListRow(
                leading: const Icon(
                  CupertinoIcons.text_quote,
                  color: AppColors.primary,
                ),
                title: 'Update Judul Skripsi (ID & EN)',
                onTap: () {
                  Navigator.pop(ctx);
                  _showFormUpdateJudul();
                },
              ),
              AppListRow(
                leading: const Icon(
                  CupertinoIcons.link,
                  color: AppColors.primary,
                ),
                title: 'Simpan Link Berkas Pasca Ujian',
                onTap: () {
                  Navigator.pop(ctx);
                  _showFormSubmitLink();
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showFormUpdateJudul() {
    final judulIdCtrl = TextEditingController();
    final judulEnCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Judul Skripsi (ID & EN)',
              style: AppText.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: judulIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul Bahasa Indonesia',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: judulEnCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul Bahasa Inggris (EN)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (judulIdCtrl.text.trim().isEmpty ||
                      judulEnCtrl.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    final res = await _service.updateJudulSkripsi(
                      judulId: judulIdCtrl.text.trim(),
                      judulEn: judulEnCtrl.text.trim(),
                    );
                    _showSnackBar(
                      res['message'] ?? 'Judul skripsi berhasil diperbarui',
                    );
                  } catch (e) {
                    _showSnackBar(
                      e.toString().replaceFirst('Exception: ', ''),
                      isError: true,
                    );
                  }
                },
                child: const Text('Simpan Judul'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormSubmitLink() {
    final jenisCtrl = TextEditingController(text: '1');
    final linkCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simpan Link Berkas Pasca Ujian',
              style: AppText.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: jenisCtrl,
              decoration: const InputDecoration(labelText: 'ID Jenis Berkas'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: linkCtrl,
              decoration: const InputDecoration(
                labelText: 'Link File (Drive / URL)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (linkCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final res = await _service.submitLinkBerkas(
                      idJenis: jenisCtrl.text.trim(),
                      linkFile: linkCtrl.text.trim(),
                    );
                    _showSnackBar(
                      res['message'] ?? 'Link berkas berhasil disimpan',
                    );
                  } catch (e) {
                    _showSnackBar(
                      e.toString().replaceFirst('Exception: ', ''),
                      isError: true,
                    );
                  }
                },
                child: const Text('Simpan Link Berkas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Gagal membuka link: $url', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.danger
            : (isSuccess ? AppColors.success : AppColors.primary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.scaffold,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
