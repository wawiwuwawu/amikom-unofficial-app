import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/skripsi.dart';
import '../services/skripsi_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/waktu.dart';
import '../widgets/app_date_field.dart';
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
class SkripsiPage extends StatefulWidget {

  const SkripsiPage({super.key});

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

  // Opsi dropdown "Progres" form bimbingan (kontrak BE 2026-11-02, dari
  // <select> asli portal). Kosong = BE lama → form jatuh ke TextField.
  List<String> _opsiProgres = [];

  // Pendaftaran State
  bool _isLoadingPendaftaran = true;
  String? _errorPendaftaran;
  List<SkripsiPendaftaranItem> _pendaftarans = [];

  // Plagiarisme State
  bool _isLoadingPlagiarisme = true;
  String? _errorPlagiarisme;
  List<SkripsiPlagiarismeItem> _plagiarsmes = [];

  // Kunci kartu bimbingan per dosbim yang DICIUTKAN user (masukan user
  // 2026-11-01: nama dosbim = judul kartunya, bisa di-minimize).
  final Set<String> _kelompokTertutup = {};

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
      // Opsi progres gagal/cosong → form jatuh ke TextField (fail-open).
      _fetchOpsiProgres(),
    ]);
  }

  Future<void> _fetchOpsiProgres() => _fetchData<List<String>>(
        load: _service.getOpsiBimbingan,
        onData: (list) => _opsiProgres = list,
        fallback: 'Opsi progres bimbingan gagal dimuat.',
        setLoading: (_) {},
        setError: (_) {},
      );

  /// Rangka pengambilan data bersama untuk kelima tab: tandai memuat dan
  /// bersihkan galat lama, jalankan [load], tandani hasil lewat [onData],
  /// lalu selalu matikan indikator memuat. Semua galat (bukan hanya
  /// DioException) dipetakan ke pesan ramah [fallback] lewat [userErrorMessage].
  Future<void> _fetchData<T>({
    required Future<T> Function() load,
    required void Function(T) onData,
    required String fallback,
    required void Function(bool) setLoading,
    required void Function(String?) setError,
  }) async {
    setState(() {
      setLoading(true);
      setError(null);
    });
    try {
      final data = await load();
      if (mounted) onData(data);
    } catch (e) {
      if (mounted) setState(() => setError(userErrorMessage(e, fallback)));
    } finally {
      if (mounted) setState(() => setLoading(false));
    }
  }

  Future<void> _fetchMainInfo() => _fetchData<SkripsiMainData>(
        load: _service.getMainInfo,
        onData: (data) => setState(() {
          _mainData = data;
          _isLoadingMain = false;
        }),
        fallback:
            'Informasi utama skripsi gagal dimuat. Periksa koneksi lalu coba lagi.',
        setLoading: (value) => _isLoadingMain = value,
        setError: (value) => _errorMain = value,
      );

  Future<void> _fetchProposals() => _fetchData<List<SkripsiProposalItem>>(
        load: _service.getProposals,
        onData: (list) => setState(() {
          _proposals = list;
          _isLoadingProposal = false;
        }),
        fallback: 'Daftar proposal skripsi gagal dimuat. Silakan coba lagi.',
        setLoading: (value) => _isLoadingProposal = value,
        setError: (value) => _errorProposal = value,
      );

  Future<void> _fetchBimbingans() => _fetchData<List<SkripsiBimbinganItem>>(
        load: _service.getBimbinganList,
        onData: (list) => setState(() {
          _bimbingans = list;
          _isLoadingBimbingan = false;
        }),
        fallback: 'Catatan bimbingan gagal dimuat. Silakan coba lagi.',
        setLoading: (value) => _isLoadingBimbingan = value,
        setError: (value) => _errorBimbingan = value,
      );

  Future<void> _fetchPendaftarans() => _fetchData<List<SkripsiPendaftaranItem>>(
        load: _service.getPendaftaranList,
        onData: (list) => setState(() {
          _pendaftarans = list;
          _isLoadingPendaftaran = false;
        }),
        fallback: 'Data pendaftaran ujian gagal dimuat. Silakan coba lagi.',
        setLoading: (value) => _isLoadingPendaftaran = value,
        setError: (value) => _errorPendaftaran = value,
      );

  Future<void> _fetchPlagiarsmes() => _fetchData<List<SkripsiPlagiarismeItem>>(
        load: _service.getPlagiarismeList,
        onData: (list) => setState(() {
          _plagiarsmes = list;
          _isLoadingPlagiarisme = false;
        }),
        fallback: 'Data plagiarisme gagal dimuat. Silakan coba lagi.',
        setLoading: (value) => _isLoadingPlagiarisme = value,
        setError: (value) => _errorPlagiarisme = value,
      );

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
    if (main == null) {
      // Header tidak boleh hilang tanpa jejak: jelaskan keadaannya dan beri
      // tombol muat ulang, bukan `SizedBox.shrink()`.
      return AppSurface(
        variant: AppSurfaceVariant.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Informasi skripsi belum bisa ditampilkan',
                    style: AppText.h3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Status pembimbing, kartu identitas, dan pengumuman belum termuat. '
              'Silakan muat ulang untuk mencoba lagi.',
              style: AppText.bodySm,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _fetchMainInfo,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Muat ulang'),
              ),
            ),
          ],
        ),
      );
    }

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
        // Kontrak BE Nov 2026 §1: status proposal. Peringatan ACC
        // ujian/plagiarisme tampil di tab pengajuannya masing-masing,
        // kartu dosbim di tab bimbingan (masukan user 2026-11-01).
        if (main.statusProposal != null) _statusProposalCard(main.statusProposal!),
      ],
    );
  }

  /// Peringatan ACC per dosbim untuk header tab pengajuannya.
  List<Widget> _peringatanBlok(List<String> daftar) => [
        for (final peringatan in daftar)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _peringatanCard(peringatan),
          ),
      ];

  Widget _peringatanCard(String teks) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppSurface(
        variant: AppSurfaceVariant.danger,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 20,
              color: AppColors.danger,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                teks,
                style: AppText.bodySm.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusProposalCard(SkripsiStatusProposal sp) {
    final adaIsi = (sp.pesan != null && sp.pesan!.isNotEmpty) ||
        (sp.komentarPusatStudi != null && sp.komentarPusatStudi!.isNotEmpty) ||
        (sp.reviewer != null && sp.reviewer!.isNotEmpty);
    if (!adaIsi) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppSurface(
        radius: AppRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Status Proposal', style: AppText.h3),
                ),
                AppPill(
                  sp.layak ? 'Layak' : 'Menunggu',
                  tone: sp.layak ? AppPillTone.success : AppPillTone.neutral,
                ),
              ],
            ),
            if (sp.pesan != null && sp.pesan!.isNotEmpty) ...[
              const Divider(height: AppSpacing.xl),
              Text(sp.pesan!, style: AppText.body),
            ],
            if (sp.komentarPusatStudi != null &&
                sp.komentarPusatStudi!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              AppKeyValue(
                label: 'Komentar Pusat Studi',
                value: sp.komentarPusatStudi!,
              ),
            ],
            if (sp.reviewer != null && sp.reviewer!.isNotEmpty) ...[
              AppKeyValue(label: 'Reviewer', value: sp.reviewer!),
            ],
          ],
        ),
      ),
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

    // Riwayat milik sendiri tapi bisa menumpuk (pengajuan ulang) — dibangun
    // lazy per chunk ±20 baris; judul seksi + aksi + keadaan kosong tetap
    // di header (padanan AppSection lama, tampilan tidak berubah).
    return AppChunkedList<SkripsiProposalItem>(
      items: _proposals,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'RIWAYAT PROPOSAL SKRIPSI',
                  style: AppText.overline,
                ),
              ),
              FilledButton.icon(
                onPressed: _showFormProposalBaru,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                icon: const Icon(CupertinoIcons.add, size: 16),
                label: const Text('Ajukan Proposal'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_proposals.isEmpty)
            const AppEmptyState(
              title: 'Belum ada riwayat pengajuan proposal',
              icon: CupertinoIcons.doc_plaintext,
            ),
        ],
      ),
      rowBuilder: (_, item) => _buildProposalItem(item),
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

    // Catatan bimbingan bertambah tiap pertemuan — dibangun lazy per chunk
    // ±20 baris. Kartu terpisah per dosbim (kontrak BE Nov 2026 §2) dengan
    // NAMA DOSBIM sebagai judul kartunya (masukan user: jangan ditulis dua
    // kali) — bisa diciutkan. Daftar entri (header + baris) jadi satu
    // AppChunkedList supaya chunking tetap jalan; kartu yang diciutkan
    // hanya menyumbang header-nya.
    final kelompok = _kelompokBimbingan();
    final entri = <_BimbinganEntri>[];
    for (final g in kelompok) {
      if (g.baris.isEmpty) continue;
      // Kelompok tunggal tanpa identitas dosbim (bentuk halaman lama)
      // dirender polos tanpa header kartu.
      final adaHeader = g.judul != null || kelompok.length > 1;
      final kunci = g.judul ?? '__tanpa_dosbim';
      if (adaHeader) {
        entri.add(_BimbinganEntri.header(
          kunci: kunci,
          judul: g.judul,
          dosbim: g.dosbim,
          jumlah: g.baris.length,
          bisaDilipat: g.judul != null,
        ));
      }
      if (!adaHeader || !_kelompokTertutup.contains(kunci)) {
        for (final b in g.baris) {
          entri.add(_BimbinganEntri.baris(b));
        }
      }
    }

    return AppChunkedList<_BimbinganEntri>(
      items: entri,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'KARTU BIMBINGAN SKRIPSI',
                  style: AppText.overline,
                ),
              ),
              Row(
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
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_bimbingans.isEmpty)
            const AppEmptyState(
              title: 'Belum ada catatan bimbingan skripsi',
              icon: CupertinoIcons.doc_text,
            ),
        ],
      ),
      rowBuilder: (_, e) => e.baris != null
          ? _buildBimbinganItem(e.baris!)
          : _headerKartuBimbingan(e),
    );
  }

  /// Kelompok bimbingan per dosbim: urutan mengikuti `pembimbing[]` dari
  /// data utama; pencocokan baris → dosbim lewat urutan, idauto, atau nama;
  /// baris bernama yang tak cocok mengikuti urutan kemunculannya; baris
  /// tanpa identitas dosbim (bentuk halaman lama) jadi kelompok terakhir.
  List<({SkripsiDosbim? dosbim, String? judul, List<SkripsiBimbinganItem> baris})>
      _kelompokBimbingan() {
    final dosbimList = _mainData?.pembimbing ?? const <SkripsiDosbim>[];
    final perDosbim = <int, List<SkripsiBimbinganItem>>{};
    final perNama = <String, List<SkripsiBimbinganItem>>{};
    final tanpaNama = <SkripsiBimbinganItem>[];

    for (final item in _bimbingans) {
      final idx = dosbimList.indexWhere((d) =>
          (item.urutanPembimbing != null && item.urutanPembimbing == d.urutan) ||
          (d.idauto != null &&
              d.idauto!.isNotEmpty &&
              item.idauto != null &&
              item.idauto == d.idauto) ||
          (item.pembimbing != null && item.pembimbing == d.nama));
      if (idx >= 0) {
        perDosbim.putIfAbsent(idx, () => []).add(item);
      } else if (item.pembimbing != null && item.pembimbing!.isNotEmpty) {
        perNama.putIfAbsent(item.pembimbing!, () => []).add(item);
      } else {
        tanpaNama.add(item);
      }
    }

    final kelompok = <({SkripsiDosbim? dosbim, String? judul,
        List<SkripsiBimbinganItem> baris})>[];
    final indeksTerurut = perDosbim.keys.toList()..sort();
    for (final i in indeksTerurut) {
      final d = dosbimList[i];
      final label = (d.label != null && d.label!.isNotEmpty)
          ? '${d.label} — ${d.nama}'
          : d.nama;
      kelompok.add((dosbim: d, judul: label, baris: perDosbim[i]!));
    }
    perNama.forEach(
      (nama, rows) => kelompok.add((dosbim: null, judul: nama, baris: rows)),
    );
    if (tanpaNama.isNotEmpty) {
      kelompok.add((dosbim: null, judul: null, baris: tanpaNama));
    }
    return kelompok;
  }

  /// Judul kartu bimbingan = dosbimnya (bukan kartu terpisah lagi) — tap
  /// untuk melipat/membuka catatan dosbim tsb. Pesan portal "belum pernah
  /// bimbingan" tampil di kartu dosbim terkait.
  Widget _headerKartuBimbingan(_BimbinganEntri e) {
    final terbuka = !e.bisaDilipat || !_kelompokTertutup.contains(e.kunci);
    final d = e.dosbim;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppSurface(
        radius: AppRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: e.bisaDilipat
                  ? () => setState(() {
                        _kelompokTertutup.contains(e.kunci)
                            ? _kelompokTertutup.remove(e.kunci)
                            : _kelompokTertutup.add(e.kunci);
                      })
                  : null,
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.person_2_fill,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      e.judul ?? 'CATATAN BIMBINGAN',
                      style: AppText.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppPill('${e.jumlah} catatan', tone: AppPillTone.info),
                  if (e.bisaDilipat) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      terbuka
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
            if (terbuka &&
                d != null &&
                d.pesanBimbingan != null &&
                d.pesanBimbingan!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  d.pesanBimbingan!,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.warning,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBimbinganItem(SkripsiBimbinganItem item) {
    // Kontrak BE Nov 2026 §2: baris kini mencakup SEMUA dosbim — label
    // dosbim wajib tampil supaya baris Pembimbing I/II tak tertukar.
    final infoBaris = <String>[
      if (item.pembimbing != null && item.pembimbing!.isNotEmpty)
        item.pembimbing!,
      if (item.status != null && item.status!.isNotEmpty) item.status!,
    ];
    final subtitle = [
      if (infoBaris.isNotEmpty) infoBaris.join(' • '),
      if (item.keterangan.isNotEmpty) item.keterangan,
      if (item.komentar != null && item.komentar!.isNotEmpty)
        'Komentar: ${item.komentar}',
    ].where((s) => s.isNotEmpty).join('\n');

    return AppListRow(
      leading: AppPill(item.progres, tone: AppPillTone.info),
      title: 'Tanggal: ${item.tanggal}',
      subtitle: subtitle.isNotEmpty ? subtitle : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.id.isNotEmpty)
            IconButton(
              icon: const Icon(CupertinoIcons.trash, size: 18),
              tooltip: 'Hapus Catatan',
              onPressed: () => _handleHapusBimbingan(item),
            ),
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

  // Kontrak BE Nov 2026 §3: DELETE /skripsi/bimbingan/:id.
  Future<void> _handleHapusBimbingan(SkripsiBimbinganItem item) async {
    final confirm = await AppConfirm.ask(
      context,
      title: 'Hapus Catatan Bimbingan',
      content:
          'Hapus catatan bimbingan${item.pembimbing != null && item.pembimbing!.isNotEmpty ? ' ${item.pembimbing}' : ''} tanggal ${item.tanggal}? Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Ya, Hapus',
      confirmColor: AppColors.danger,
    );

    if (confirm != true) return;
    try {
      final res = await _service.hapusBimbingan(item.id);
      _showSnackBar(res['message'] ?? 'Catatan bimbingan dihapus');
      _fetchBimbingans();
    } catch (e) {
      _showSnackBar(
        userErrorMessage(
          e,
          'Catatan bimbingan gagal dihapus. Silakan coba lagi.',
        ),
        isError: true,
      );
    }
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

    // Dibangun lazy per chunk ±20 baris; judul seksi + aksi + keadaan
    // kosong tetap di header (padanan AppSection lama, tampilan tidak
    // berubah).
    return AppChunkedList<SkripsiPendaftaranItem>(
      items: _pendaftarans,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Peringatan ACC Ujian hanya berlaku bila ada pengajuan ujian.
          if (_pendaftarans.isNotEmpty)
            ..._peringatanBlok(
                _mainData?.peringatanAccUjian ?? const <String>[]),
          Row(
            children: [
              Expanded(
                child: Text(
                  'PENGAJUAN UJIAN SKRIPSI',
                  style: AppText.overline,
                ),
              ),
              FilledButton.icon(
                onPressed: _showFormPendaftaranUjian,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                icon: const Icon(CupertinoIcons.add, size: 16),
                label: const Text('Daftar Ujian'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_pendaftarans.isEmpty)
            const AppEmptyState(
              title: 'Belum ada riwayat pendaftaran ujian skripsi',
              icon: CupertinoIcons.person_2_square_stack,
            ),
        ],
      ),
      rowBuilder: (_, item) => _buildPendaftaranItem(item),
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

    // Dibangun lazy per chunk ±20 baris; judul seksi + aksi + keadaan
    // kosong tetap di header (padanan AppSection lama, tampilan tidak
    // berubah).
    return AppChunkedList<SkripsiPlagiarismeItem>(
      items: _plagiarsmes,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Peringatan ACC Cek Plagiarisme hanya berlaku bila ada berkas.
          if (_plagiarsmes.isNotEmpty)
            ..._peringatanBlok(
                _mainData?.peringatanAccPlagiarisme ?? const <String>[]),
          Row(
            children: [
              Expanded(
                child: Text(
                  'STATUS CEK PLAGIARISME',
                  style: AppText.overline,
                ),
              ),
              FilledButton.icon(
                onPressed: _handleUploadPlagiarisme,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                icon: const Icon(CupertinoIcons.cloud_upload_fill, size: 16),
                label: const Text('Upload File (.doc/.docx)'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_plagiarsmes.isEmpty)
            const AppEmptyState(
              title: 'Belum ada dokumen cek plagiarisme',
              icon: CupertinoIcons.doc_text_search,
            ),
        ],
      ),
      rowBuilder: (_, item) => _buildPlagiarismeItem(item),
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

    String? validateFile(String name, int? size) {
      if (RegExp(r'''[&\"'<>]''').hasMatch(name)) {
        return 'Nama berkas tidak boleh memuat karakter khusus (&, ", \', <, >)';
      }
      // size null = picker tidak melaporkan ukuran — jangan ditudang melebihi.
      if (size != null && size > 3 * 1024 * 1024) {
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
              final file = await FilePicker.pickFile(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (file != null && file.path != null) {
                final err = validateFile(file.name, file.lengthSync());
                setBsState(() {
                  pickedFile = File(file.path!);
                  fileName = file.name;
                  fileSize = file.lengthSync() ?? 0;
                  fileError = err;
                });
              }
            } catch (e) {
              setBsState(() {
                fileError = userErrorMessage(
                  e,
                  'Berkas gagal dipilih. Silakan pilih ulang berkas PDF Anda.',
                );
              });
            }
          }

          final isFormValid = judulCtrl.text.trim().isNotEmpty &&
              pickedFile != null &&
              fileError == null;

          return _sheetKulit(
            ctx,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
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
                                  userErrorMessage(
                                    e,
                                    'Proposal gagal diajukan. Pastikan berkas PDF '
                                    'maksimal 3 MB lalu coba lagi.',
                                  ),
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
                  userErrorMessage(
                    e,
                    'Pengajuan proposal ulang gagal dikirim. Silakan coba lagi.',
                  ),
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
    final confirm = await AppConfirm.ask(
      context,
      title: 'Konfirmasi Tema Ulang',
      content: 'Apakah Anda yakin ingin mengajukan ulang tema skripsi ke Pusat Studi?',
      confirmLabel: 'Ya, Ajukan Tema Ulang',
      confirmColor: AppColors.warning,
    );

    if (confirm == true) {
      try {
        final res = await _service.submitTemaUlang(idProposal: item.idProposal ?? '1');
        _showSnackBar(res['message'] ?? 'Tema ulang berhasil diajukan');
        _fetchProposals();
      } catch (e) {
        _showSnackBar(
          userErrorMessage(
            e,
            'Pengajuan tema ulang gagal dikirim. Silakan coba lagi.',
          ),
          isError: true,
        );
      }
    }
  }

  void _showFormBimbingan({SkripsiBimbinganItem? item}) {
    final isEdit = item != null;
    // Kontrak BE Nov 2026 §1: idauto/nidn per dosbim diambil dari
    // pembimbing[] ("untuk dosbim kedua ambil dari pembimbing[]") —
    // form tambah jadi memilih dosbim, bukan mengandalkan top-level.
    final List<SkripsiDosbim> dosbimList =
        List<SkripsiDosbim>.from(_mainData?.pembimbing ?? const []);
    int dosbimIndex = 0;
    final keteranganCtrl = TextEditingController(text: item?.keterangan ?? '');
    // Kontrak BE 2026-11-02: opsi progres dari portal — nilai dipakai apa
    // adanya. Edit: nilai lama di luar daftar tetap ditampilkan. BE lama
    // (daftar kosong) → jatuh ke TextField bebas.
    final opsiProgres = List<String>.from(_opsiProgres);
    if (isEdit &&
        item.progres.isNotEmpty &&
        !opsiProgres.contains(item.progres)) {
      opsiProgres.insert(0, item.progres);
    }
    String? progresPilih = (item != null && item.progres.isNotEmpty)
        ? item.progres
        : (opsiProgres.isNotEmpty ? opsiProgres.first : null);
    final progresCtrl = TextEditingController(text: item?.progres ?? '');
    DateTime tanggalPilih =
        item != null ? (tanggalDariPortal(item.tanggal) ?? DateTime.now()) : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _sheetKulit(
        ctx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Catatan Bimbingan' : 'Tambah Catatan Bimbingan',
              style: AppText.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!isEdit && dosbimList.isNotEmpty) ...[
              DropdownButtonFormField<int>(
                initialValue: dosbimIndex,
                key: ValueKey(dosbimIndex),
                decoration: const InputDecoration(
                  labelText: 'Dosen Pembimbing',
                ),
                items: [
                  for (var i = 0; i < dosbimList.length; i++)
                    DropdownMenuItem(
                      value: i,
                      // Nama saja — "Pembimbing I — Nama" kepanjangan
                      // di lebar sheet (masukan user 2026-11-01).
                      child: Text(
                        dosbimList[i].nama,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setSheetState(() => dosbimIndex = v ?? 0),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppDateField(
              label: 'Tanggal Bimbingan',
              value: tanggalPilih,
              onChanged: (d) => setSheetState(() => tanggalPilih = d),
            ),
            const SizedBox(height: AppSpacing.md),
            if (opsiProgres.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: progresPilih,
                key: ValueKey(progresPilih),
                decoration: const InputDecoration(
                  labelText: 'Progres',
                ),
                items: [
                  for (final o in opsiProgres)
                    DropdownMenuItem(
                      value: o,
                      child: Text(o, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setSheetState(() => progresPilih = v),
              )
            else
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
                  final progresAkhir = opsiProgres.isNotEmpty
                      ? progresPilih
                      : progresCtrl.text.trim();
                  if (progresAkhir == null || progresAkhir.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    if (isEdit) {
                      final res = await _service.updateBimbingan(
                        id: item.id,
                        tanggal: formatDateApi(tanggalPilih),
                        progres: progresAkhir.trim(),
                        keterangan: keteranganCtrl.text.trim(),
                      );
                      _showSnackBar(
                        res['message'] ?? 'Catatan bimbingan berhasil diperbarui',
                      );
                    } else {
                      final dosbim =
                          dosbimList.isNotEmpty ? dosbimList[dosbimIndex] : null;
                      final res = await _service.submitBimbingan(
                        tanggal: formatDateApi(tanggalPilih),
                        idauto: dosbim?.idauto ?? _mainData?.idauto ?? '',
                        nidn: dosbim?.nidn ?? _mainData?.nidn ?? '',
                        progres: progresAkhir.trim(),
                        keterangan: keteranganCtrl.text.trim(),
                      );
                      _showSnackBar(res['message'] ?? 'Catatan bimbingan disimpan');
                    }
                    _fetchBimbingans();
                  } catch (e) {
                    _showSnackBar(
                      userErrorMessage(
                        e,
                        'Catatan bimbingan gagal disimpan. Silakan coba lagi.',
                      ),
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
      _showSnackBar(
        userErrorMessage(
          e,
          'Kartu bimbingan gagal diunduh. Periksa koneksi lalu coba lagi.',
        ),
        isError: true,
      );
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
        builder: (ctx, setBsState) => _sheetKulit(
          ctx,
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
                        userErrorMessage(
                          e,
                          'Pendaftaran ujian skripsi gagal diajukan. Silakan coba lagi.',
                        ),
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
    final confirm = await AppConfirm.ask(
      context,
      title: 'Batal Pengajuan Ujian',
      content: 'Apakah Anda yakin ingin membatalkan pengajuan ujian skripsi ini?',
      confirmLabel: 'Hapus',
    );

    if (confirm == true) {
      try {
        final res = await _service.deletePendaftaranUjian(id);
        _showSnackBar(res['message'] ?? 'Pendaftaran dibatalkan');
        _fetchPendaftarans();
      } catch (e) {
        _showSnackBar(
          userErrorMessage(
            e,
            'Pembatalan pengajuan ujian gagal diproses. Silakan coba lagi.',
          ),
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
      _showSnackBar(
        userErrorMessage(
          e,
          'Formulir pendaftaran gagal diunduh. Periksa koneksi lalu coba lagi.',
        ),
        isError: true,
      );
    }
  }

  void _handleUploadPlagiarisme() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
    );

    if (file != null && file.path != null) {
      final picked = File(file.path!);
      final fileSize = await picked.length();
      if (fileSize > 3 * 1024 * 1024) {
        _showSnackBar('Ukuran file maksimal 3MB', isError: true);
        return;
      }

      _showSnackBar('Mengunggah dokumen plagiarisme...');
      try {
        final res = await _service.uploadPlagiarisme(picked);
        _showSnackBar(res['message'] ?? 'Dokumen berhasil diunggah');
        _fetchPlagiarsmes();
      } catch (e) {
        _showSnackBar(
          userErrorMessage(
            e,
            'Dokumen plagiarisme gagal diunggah. Pastikan berkas maksimal 3 MB '
            'lalu coba lagi.',
          ),
          isError: true,
        );
      }
    }
  }

  void _handleDeletePlagiarisme(String id) async {
    final confirm = await AppConfirm.ask(
      context,
      title: 'Hapus Dokumen Plagiarisme',
      content: 'Apakah Anda yakin ingin menghapus dokumen plagiarisme ini?',
      confirmLabel: 'Hapus',
    );

    if (confirm == true) {
      try {
        final res = await _service.deletePlagiarisme(id);
        _showSnackBar(res['message'] ?? 'Dokumen berhasil dihapus');
        _fetchPlagiarsmes();
      } catch (e) {
        _showSnackBar(
          userErrorMessage(
            e,
            'Dokumen plagiarisme gagal dihapus. Silakan coba lagi.',
          ),
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
      builder: (ctx) => _sheetKulit(
        ctx,
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
                      userErrorMessage(
                        e,
                        'Judul skripsi gagal diperbarui. Silakan coba lagi.',
                      ),
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
      builder: (ctx) => _sheetKulit(
        ctx,
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
                      userErrorMessage(
                        e,
                        'Link berkas gagal disimpan. Periksa tautannya lalu coba lagi.',
                      ),
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
    // Jangan tampilkan URL mentah ke pengguna; cukup jelaskan tindakannya.
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(
          'Tautan tidak dapat dibuka. Silakan buka manual lewat browser.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        userErrorMessage(
          e,
          'Tautan tidak dapat dibuka. Silakan buka manual lewat browser.',
        ),
        isError: true,
      );
    }
  }

  /// Kulit bottom sheet form — padding viewInsets + decoration sudut atas
  /// membulat; dipakai semua sheet form di halaman ini.
  Widget _sheetKulit(
    BuildContext ctx, {
    BoxConstraints? constraints,
    required Widget child,
  }) {
    return Container(
      constraints: constraints,
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
      child: child,
    );
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

/// Satu entri daftar tab Bimbingan: judul kartu dosbim ([baris] == null)
/// atau baris catatan bimbingan. Header dan baris menyatu dalam satu
/// AppChunkedList supaya chunking tetap jalan.
class _BimbinganEntri {
  final String kunci;
  final String? judul;
  final SkripsiDosbim? dosbim;
  final int jumlah;
  final bool bisaDilipat;
  final SkripsiBimbinganItem? baris;

  const _BimbinganEntri.header({
    required this.kunci,
    required this.judul,
    required this.dosbim,
    required this.jumlah,
    required this.bisaDilipat,
  }) : baris = null;

  const _BimbinganEntri.baris(SkripsiBimbinganItem this.baris)
      : kunci = '',
        judul = null,
        dosbim = null,
        jumlah = 0,
        bisaDilipat = false;
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
