import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_failure.dart';
import '../models/skkm.dart';
import '../services/api_client.dart';
import '../services/skkm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Halaman SKKM (Satuan Kredit Kegiatan Mahasiswa) — angkatan 2024+.
///
/// Kontrak BE 2026-11-01 §4–§5:
///  * Daftar aktivitas + poin valid asli dari portal (`GET /api/v1/skkm`).
///  * Angkatan < 2024 → `skkm_berlaku: false` = kebijakan kampus, ditampilkan
///    sebagai penjelasan, bukan galat.
///  * URL bukti dari portal butuh sesi login — bukti ditampilkan lewat proxy
///    unduh BE (`GET /skkm/bukti/:id`), jangan buka URL-nya langsung.
///  * Alur tambah kegiatan = rantai dropdown portal (unsur → sub-unsur →
///    jenis → kredit) + surat tugas yang harus lolos cek sebelum tombol
///    Ajukan aktif (perilaku portal: tombol hanya enabled saat `exists`).
class SkkmPage extends StatefulWidget {
  const SkkmPage({super.key});

  @override
  State<SkkmPage> createState() => _SkkmPageState();
}

class _SkkmPageState extends State<SkkmPage> {
  final _service = SkkmService();
  bool _loading = true;
  String _error = '';
  SkkmData? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    // Indikator lokal (2 digit pertama NIM — aturan sama dengan BE): NIM
    // < 2024 pasti ditolak, tampilkan kebijakan kampus TANPA menyentuh
    // jaringan. NIM tak terbaca → fail-open, biarkan endpoint yang menjawab.
    if (SkkmService.berlakuDariNim(ApiClient.instance.nim) == false) {
      if (mounted) {
        setState(() {
          _data = const SkkmData(
            angkatan: null,
            skkmBerlaku: false,
            totalPoinValid: null,
            panduanUrl: '',
            jumlahAktivitas: 0,
            opsiUnsur: [],
            aktivitas: [],
          );
          _loading = false;
        });
      }
      return;
    }
    try {
      final data = await _service.getSkkm();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) _error = userErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'SKKM',
      subtitle: 'Satuan Kredit Kegiatan Mahasiswa',
      scrollable: false,
      padding: EdgeInsets.zero,
      floatingActionButton: _data?.skkmBerlaku == true
          ? FilledButton.icon(
              onPressed: _showFormSheet,
              icon: const Icon(CupertinoIcons.add, size: 18),
              label: const Text('Tambah Kegiatan'),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading(message: 'Memuat SKKM…');

    if (_error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: AppErrorState(message: _error, onRetry: _loadData),
        ),
      );
    }

    final data = _data;
    if (data == null) return const SizedBox.shrink();

    // Angkatan < 2024: kebijakan kampus, bukan galat.
    if (!data.skkmBerlaku) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppEmptyState(
            title: 'SKKM tidak berlaku untuk angkatanmu',
            message: 'SKKM hanya diikuti mahasiswa angkatan 2024 ke atas '
                '(kebijakan kampus). Pencapaian kegiatanmu tetap tercatat '
                'lewat Prestasi, Sertifikasi, dan Rekognisi.',
            icon: CupertinoIcons.info_circle,
          ),
        ],
      );
    }

    final aktivitas = data.aktivitas;
    final child = aktivitas.isEmpty
        ? ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _buildRingkasan(data),
              const SizedBox(height: AppSpacing.lg),
              const AppEmptyState(
                title: 'Belum ada kegiatan tercatat',
                message: 'Ajukan kegiatan yang kamu ikuti lewat tombol '
                    '"Tambah Kegiatan" — poin akan tervalidasi oleh prodi '
                    'atau kemahasiswaan.',
                icon: CupertinoIcons.rosette,
              ),
            ],
          )
        : AppChunkedList<SkkmAktivitas>(
            items: aktivitas,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + 96,
            ),
            header: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRingkasan(data),
                const SizedBox(height: AppSpacing.xl),
                Text('DAFTAR AKTIVITAS', style: AppText.overline),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
            rowBuilder: (_, item) => _buildItem(item),
          );

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: child,
    );
  }

  /// Ringkasan poin + aksi sekunder (panduan, kritik & saran).
  Widget _buildRingkasan(SkkmData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppStatRow(
          children: [
            AppStatTile(
              value: data.totalPoinValid == null
                  ? '—'
                  : '${data.totalPoinValid}',
              label: 'Poin Valid',
              icon: CupertinoIcons.rosette,
            ),
            AppStatTile(
              value: '${data.jumlahAktivitas}',
              label: 'Kegiatan',
              icon: CupertinoIcons.list_bullet_indent,
            ),
            AppStatTile(
              value: '${_hitungValid(data.aktivitas)}',
              label: 'Valid',
              icon: CupertinoIcons.checkmark_seal_fill,
              accent: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            if (data.panduanUrl.isNotEmpty) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _bukaPanduan,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  icon: const Icon(
                    CupertinoIcons.book,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Panduan SKKM',
                    style: AppText.label.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showKritikSaranSheet,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(
                  CupertinoIcons.chat_bubble,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  'Kritik & Saran',
                  style: AppText.label.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _bukaPanduan() async {
    final url = Uri.parse(_data?.panduanUrl ?? '');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw const AppFailure('Tidak dapat membuka tautan.');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        userErrorMessage(e, 'Gagal membuka panduan SKKM.'),
        backgroundColor: AppColors.danger,
      );
    }
  }

  /// Satu baris aktivitas: kegiatan · level/role · poin, status, komentar
  /// validator bila ada, lalu aksi (unduh bukti / hapus).
  Widget _buildItem(SkkmAktivitas item) {
    final (statusLabel, statusTone) = _statusStyle(item.status);
    final judul = item.subUnsur.isNotEmpty ? item.subUnsur : item.unsur;

    final subtitle = [
      if (item.level.isNotEmpty) item.level,
      if (item.jenisKeg.isNotEmpty)
        item.jenisKeg == 'individu' ? 'Individu' : 'Kelompok',
      if (item.role.isNotEmpty) item.role,
      if (item.suratTugas.isNotEmpty) 'ST ${item.suratTugas}',
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListRow(
          title: judul.isEmpty ? 'Kegiatan #${item.no}' : judul,
          subtitle: subtitle.isEmpty ? null : subtitle,
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: AppDeco.softPrimary(radius: AppRadius.sm),
            child: Text(
              '${item.kredit}',
              style: AppText.h3.copyWith(
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
          trailing: AppPill(statusLabel, tone: statusTone),
        ),
        if (item.komentarValidator != null &&
            item.komentarValidator!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppSurface(
              variant: AppSurfaceVariant.warning,
              radius: AppRadius.sm,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.info_circle_fill,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Validator (${item.validator}): ${item.komentarValidator}',
                      style: AppText.bodySm.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            item.komentarValidator == null ? 0 : AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (item.bukti != null)
                TextButton.icon(
                  onPressed: () => _unduhBukti(item),
                  style: _compactAction,
                  icon: const Icon(CupertinoIcons.cloud_download, size: 16),
                  label: const Text('Unduh Bukti'),
                ),
              if (item.idAktivitas != null)
                TextButton.icon(
                  onPressed: () => _hapusItem(item),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(CupertinoIcons.trash, size: 16),
                  label: const Text('Hapus'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  ButtonStyle get _compactAction => TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  /// Label & warna pil status — `status` dikirim portal apa adanya, jadi
  /// pencocokannya longgar.
  (String, AppPillTone) _statusStyle(String status) {
    final s = status.toLowerCase();
    if (s == 'valid') return ('Valid', AppPillTone.success);
    if (s.contains('tidak valid') || s.contains('ditolak')) {
      return ('Tidak Valid', AppPillTone.danger);
    }
    return (status.isEmpty ? 'Menunggu' : status, AppPillTone.warning);
  }

  // ── Aksi baris ───────────────────────────────────────────────────────────

  Future<void> _unduhBukti(SkkmAktivitas item) async {
    final bukti = item.bukti!;
    try {
      AppSnack.show(
        context,
        'Mengunduh bukti…',
        backgroundColor: AppColors.primary,
      );
      final path = await _service.unduhBukti(
        bukti.id,
        ApiClient.beriKonteksUnduh('SKKM_bukti_${bukti.id}.pdf'),
      );
      if (!mounted) return;
      // Aksi "Buka" butuh SnackBar mentah — AppSnack tidak punya param action.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bukti tersimpan: $path'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () => OpenFilex.open(path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        userErrorMessage(e, 'Gagal mengunduh berkas bukti'),
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<void> _hapusItem(SkkmAktivitas item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Hapus aktivitas "${item.subUnsur.isNotEmpty ? item.subUnsur : item.unsur}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.hapusAktivitas(item.idAktivitas!);
      if (!mounted) return;
      AppSnack.show(
        context,
        'Aktivitas SKKM dihapus',
        backgroundColor: AppColors.success,
      );
      unawaited(_loadData());
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        userErrorMessage(e),
        backgroundColor: AppColors.danger,
      );
    }
  }

  // ── Sheet tambah kegiatan & kritik saran ─────────────────────────────────

  void _showFormSheet() {
    final data = _data;
    if (data == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SkkmFormSheet(
        service: _service,
        data: data,
        onSuccess: _loadData,
      ),
    );
  }

  void _showKritikSaranSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _KritikSaranSheet(service: _service),
    );
  }
}

int _hitungValid(List<SkkmAktivitas> items) {
  var n = 0;
  for (final it in items) {
    if (it.status.toLowerCase() == 'valid') n++;
  }
  return n;
}

// ═══════════════════════════════════════════════════════════════════════════
// Sheet "Tambah Kegiatan": rantai dropdown ala portal.
// ═══════════════════════════════════════════════════════════════════════════

class _SkkmFormSheet extends StatefulWidget {
  final SkkmService service;
  final SkkmData data;
  final VoidCallback onSuccess;

  const _SkkmFormSheet({
    required this.service,
    required this.data,
    required this.onSuccess,
  });

  @override
  State<_SkkmFormSheet> createState() => _SkkmFormSheetState();
}

class _SkkmFormSheetState extends State<_SkkmFormSheet> {
  String? _unsur;
  String? _subUnsur;
  String? _jenis;
  List<SkkmOpsi> _subUnsurList = const [];
  List<SkkmOpsi> _jenisList = const [];
  SkkmKredit? _kredit;
  bool _muatSub = false;
  bool _muatJenis = false;
  bool _muatKredit = false;

  late final TextEditingController _thnKeg;
  String _jenisKeg = 'individu';
  String _role = 'ketua';
  final _jmlAnggota = TextEditingController();
  final _suratTgs = TextEditingController();
  bool? _suratTgsAda; // null = belum dicek
  bool _cekSuratLoading = false;

  String _buktiMode = 'file';
  PlatformFile? _file;
  final _buktiUrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _thnKeg = TextEditingController(text: '${DateTime.now().year}');
  }

  @override
  void dispose() {
    _thnKeg.dispose();
    _jmlAnggota.dispose();
    _suratTgs.dispose();
    _buktiUrl.dispose();
    super.dispose();
  }

  bool get _formLengkap =>
      _unsur != null &&
      _subUnsur != null &&
      _jenis != null &&
      _kredit != null &&
      _suratTgsAda == true &&
      (_buktiMode == 'file'
          ? _file?.path != null
          : _buktiUrl.text.trim().isNotEmpty);

  Future<void> _pilihUnsur(String? value) async {
    setState(() {
      _unsur = value;
      _subUnsur = null;
      _jenis = null;
      _kredit = null;
      _subUnsurList = const [];
      _jenisList = const [];
      _muatSub = value != null;
    });
    if (value == null) return;
    try {
      final list = await widget.service.subUnsur(value);
      if (mounted) setState(() => _subUnsurList = list);
    } catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          userErrorMessage(e),
          backgroundColor: AppColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _muatSub = false);
    }
  }

  Future<void> _pilihSubUnsur(String? value) async {
    setState(() {
      _subUnsur = value;
      _jenis = null;
      _kredit = null;
      _jenisList = const [];
      _muatJenis = value != null;
    });
    if (value == null) return;
    try {
      final list = await widget.service.jenis(_unsur!, value);
      if (mounted) setState(() => _jenisList = list);
    } catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          userErrorMessage(e),
          backgroundColor: AppColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _muatJenis = false);
    }
  }

  Future<void> _pilihJenis(String? value) async {
    setState(() {
      _jenis = value;
      _kredit = null;
      _muatKredit = value != null;
    });
    if (value == null) return;
    try {
      final k = await widget.service.kredit(_unsur!, _subUnsur!, value);
      if (mounted) setState(() => _kredit = k);
    } catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          userErrorMessage(e),
          backgroundColor: AppColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _muatKredit = false);
    }
  }

  Future<void> _periksaSuratTugas() async {
    final no = _suratTgs.text.trim();
    if (no.isEmpty) return;
    setState(() => _cekSuratLoading = true);
    try {
      final ada = await widget.service.cekSuratTugas(no);
      if (mounted) setState(() => _suratTgsAda = ada);
    } catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          userErrorMessage(e),
          backgroundColor: AppColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _cekSuratLoading = false);
    }
  }

  Future<void> _pilihBerkas() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return;

    // Ukuran: lengthSync dulu (tanpa I/O), length() sebagai cadangan.
    final ukuran = file.lengthSync() ?? await file.length() ?? 0;
    if (ukuran > 3 * 1024 * 1024) {
      if (mounted) {
        AppSnack.show(
          context,
          'Ukuran file maksimal 3 MB',
          backgroundColor: AppColors.danger,
        );
      }
      return;
    }
    if (mounted) setState(() => _file = file);
  }

  Future<void> _ajukan() async {
    if (_submitting || !_formLengkap) return;
    setState(() => _submitting = true);
    try {
      await widget.service.tambahAktivitas(
        unsur: _unsur!,
        subUnsur: _subUnsur!,
        jenis: _jenis!,
        idSkkm: _kredit!.idSkkm,
        thnKeg: _thnKeg.text.trim(),
        jenisKeg: _jenisKeg,
        roleKeg: _role,
        kredit: '${_kredit!.kredit}',
        jmlAnggota: _jenisKeg == 'kelompok'
            ? (_jmlAnggota.text.trim().isEmpty
                ? '0'
                : _jmlAnggota.text.trim())
            : '0',
        suratTgs: _suratTgs.text.trim(),
        buktiFile: _buktiMode == 'file' ? _file?.path : null,
        buktiUrl: _buktiMode == 'url' ? _buktiUrl.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      AppSnack.show(
        context,
        'Kegiatan SKKM berhasil diajukan',
        backgroundColor: AppColors.success,
      );
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        userErrorMessage(e),
        backgroundColor: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Ajukan Kegiatan SKKM', style: AppText.h2),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Unsur Kegiatan'),
                    _dropdown(
                      value: _unsur,
                      items: widget.data.opsiUnsur,
                      hint: 'Pilih unsur',
                      onChanged: _pilihUnsur,
                    ),
                    _label('Jenis Kegiatan'),
                    if (_muatSub)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: AppLoading(),
                      )
                    else
                      _dropdown(
                        value: _subUnsur,
                        items: _subUnsurList,
                        hint: _unsur == null
                            ? 'Pilih unsur dulu'
                            : 'Pilih jenis kegiatan',
                        onChanged: _pilihSubUnsur,
                      ),
                    _label('Tingkat (Level)'),
                    if (_muatJenis)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: AppLoading(),
                      )
                    else
                      _dropdown(
                        value: _jenis,
                        items: _jenisList,
                        hint: _subUnsur == null
                            ? 'Pilih jenis kegiatan dulu'
                            : 'Pilih tingkat',
                        onChanged: _pilihJenis,
                      ),
                    if (_muatKredit)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: AppLoading(),
                      )
                    else if (_kredit != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: AppSurface(
                          radius: AppRadius.sm,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.rosette,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Poin: ${_kredit!.kredit}',
                                style: AppText.h3.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    _label('Tahun Kegiatan'),
                    TextField(
                      controller: _thnKeg,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'mis. 2026',
                      ),
                    ),

                    _label('Bentuk Kegiatan'),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'individu', label: Text('Individu')),
                        ButtonSegment(value: 'kelompok', label: Text('Kelompok')),
                      ],
                      selected: {_jenisKeg},
                      onSelectionChanged: (v) =>
                          setState(() => _jenisKeg = v.first),
                    ),
                    if (_jenisKeg == 'kelompok') ...[
                      _label('Jumlah Anggota (tanpa ketua)'),
                      TextField(
                        controller: _jmlAnggota,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'mis. 3'),
                      ),
                    ],

                    _label('Peran'),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ketua', label: Text('Ketua')),
                        ButtonSegment(value: 'anggota', label: Text('Anggota')),
                      ],
                      selected: {_role},
                      onSelectionChanged: (v) =>
                          setState(() => _role = v.first),
                    ),

                    _label('Nomor Surat Tugas'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _suratTgs,
                            onChanged: (_) {
                              if (_suratTgsAda != null) {
                                setState(() => _suratTgsAda = null);
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'mis. 1824/AMIKOMPWT/DAKK.2/06/I/2026',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _suratTgsAda == null
                            ? FilledButton.tonal(
                                onPressed:
                                    _suratTgs.text.trim().isEmpty ||
                                        _cekSuratLoading
                                    ? null
                                    : _periksaSuratTugas,
                                child: _cekSuratLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Periksa'),
                              )
                            : Icon(
                                _suratTgsAda == true
                                    ? CupertinoIcons.check_mark_circled_solid
                                    : CupertinoIcons.xmark_circle_fill,
                                color: _suratTgsAda == true
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        _suratTgsAda == null
                            ? 'Portal hanya menerima pengajuan dengan nomor '
                                'surat tugas yang dikenal — periksa dulu.'
                            : _suratTgsAda == true
                                ? 'Surat tugas dikenali portal.'
                                : 'Nomor surat tugas tidak dikenali portal.',
                        style: AppText.bodySm.copyWith(
                          color: _suratTgsAda == true
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                    ),

                    _label('Bukti Kegiatan'),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'file', label: Text('File PDF')),
                        ButtonSegment(value: 'url', label: Text('Link URL')),
                      ],
                      selected: {_buktiMode},
                      onSelectionChanged: (v) =>
                          setState(() => _buktiMode = v.first),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_buktiMode == 'file')
                      OutlinedButton.icon(
                        onPressed: _pilihBerkas,
                        icon: const Icon(CupertinoIcons.doc, size: 16),
                        label: Text(
                          _file == null
                              ? 'Pilih PDF (maks. 3 MB)'
                              : _file!.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      TextField(
                        controller: _buktiUrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'URL publikasi kegiatan',
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _formLengkap && !_submitting ? _ajukan : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Ajukan Kegiatan'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.xs),
        child: Text(text, style: AppText.h3),
      );

  /// Dropdown rantai. `initialValue` + [key] berbasis nilai terpilih: saat
  /// nilai direset programatik (mis. ganti unsur), kunci baru memaksa
  /// form field dibangun ulang dari nol — tampilan ikut kosong kembali.
  Widget _dropdown({
    required String? value,
    required List<SkkmOpsi> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: (value != null && items.any((e) => e.value == value))
          ? value
          : null,
      isExpanded: true,
      items: [
        for (final o in items)
          DropdownMenuItem(value: o.value, child: Text(o.label)),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(hintText: hint),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sheet "Kritik & Saran".
// ═══════════════════════════════════════════════════════════════════════════

class _KritikSaranSheet extends StatefulWidget {
  final SkkmService service;

  const _KritikSaranSheet({required this.service});

  @override
  State<_KritikSaranSheet> createState() => _KritikSaranSheetState();
}

class _KritikSaranSheetState extends State<_KritikSaranSheet> {
  final _isi = TextEditingController();
  bool _mengirim = false;

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final teks = _isi.text.trim();
    if (teks.isEmpty || _mengirim) return;
    setState(() => _mengirim = true);
    try {
      await widget.service.kirimKritikSaran(teks);
      if (!mounted) return;
      Navigator.pop(context);
      AppSnack.show(
        context,
        'Kritik & saran terkirim. Terima kasih!',
        backgroundColor: AppColors.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        userErrorMessage(e),
        backgroundColor: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Kritik & Saran', style: AppText.h2)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(CupertinoIcons.xmark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sampaikan masukan soal pelayanan validasi SKKM ke tim '
              'kemahasiswaan.',
              style: AppText.bodySm,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _isi,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Tulis kritik & saranmu…',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _mengirim ? null : _kirim,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(_mengirim ? 'Mengirim…' : 'Kirim'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
