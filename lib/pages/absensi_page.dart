import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/absensi.dart';
import '../models/absensi_validasi.dart';
import '../models/app_failure.dart';
import '../models/value_label_option.dart';
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
class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

/// Asal muatan yang bisa gagal. Dipakai untuk mengarahkan tombol "Coba lagi"
/// ke sumber yang benar-benar gagal (sebelumnya selalu memuat ulang daftar
/// belum validasi, sehingga kegagalan lain tertutup tanpa diperbaiki).
enum _SumberMuat { belumValidasi, semester, matkul, mahasiswa }

class _AbsensiPageState extends State<AbsensiPage> {
  final _service = AbsensiService();

  List<MakulBelumValidasi> _belumValidasi = [];
  bool _loadingBelumValidasi = true;

  List<ValueLabelOption> _semesterList = [];
  List<ValueLabelOption> _matkulList = [];
  String? _selectedThn;
  String? _selectedSmt;
  String? _selectedMakul;
  bool _loadingSemester = false;
  bool _loadingMatkul = false;

  AbsensiMahasiswa? _mahasiswa;
  bool _loadingMahasiswa = false;

  /// Pesan galat yang sedang tampil (selalu ramah, tanpa detail teknis).
  String? _errorFilter;

  /// Sumber galat di atas — menentukan loader mana yang dipanggil "Coba lagi".
  _SumberMuat? _errorSource;

  bool _validatingAll = false;

  /// Hasil auto-validasi terakhir (ditampilkan inline di seksi "Perlu
  /// validasi" sampai pengguna menutup/memuat ulang).
  AutoValidasiResult? _autoResult;

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

  /// Simpan galat [sumber] dengan pesan ramah; error apa pun (termasuk error
  /// parsing/non-Dio) tidak pernah ditampilkan mentah ke pengguna.
  void _setLoadError(_SumberMuat sumber, Object error, String fallback) {
    if (!mounted) return;
    setState(() {
      _errorFilter = userErrorMessage(error, fallback);
      _errorSource = sumber;
    });
  }

  /// Bersihkan galat HANYA bila memang milik [sumber]. Kegagalan sumber lain
  /// dibiarkan agar pesannya tidak hilang tanpa ikut dimuat ulang.
  void _clearLoadError(_SumberMuat sumber) {
    if (_errorSource != sumber) return;
    _errorFilter = null;
    _errorSource = null;
  }

  /// Muat ulang sumber yang gagal — dipanggil tombol "Coba lagi".
  ///
  /// Pilihan semester/matakuliah bisa terhapus saat daftar dimuat ulang; bila
  /// prasyarat sang sumber sudah kosong, prasyarat itulah yang dimuat lebih
  /// dulu supaya tombol ini selalu benar-benar memuat ulang sesuatu.
  Future<void> _retryFailedLoad() async {
    switch (_errorSource) {
      case _SumberMuat.mahasiswa:
        if (_selectedMakul != null) {
          await _loadMahasiswa();
        } else if (_selectedSmt != null) {
          await _loadMatkulList();
        } else {
          await _loadSemesterList();
        }
      case _SumberMuat.matkul:
        if (_selectedSmt != null) {
          await _loadMatkulList();
        } else {
          await _loadSemesterList();
        }
      case _SumberMuat.semester:
        await _loadSemesterList();
      case _SumberMuat.belumValidasi:
      case null:
        await _loadBelumValidasi();
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
        _clearLoadError(_SumberMuat.belumValidasi);
      });
    } catch (e) {
      if (!mounted) return;
      _setLoadError(
        _SumberMuat.belumValidasi,
        e,
        'Gagal memuat daftar presensi yang perlu divalidasi. Periksa koneksi lalu coba lagi.',
      );
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
        _clearLoadError(_SumberMuat.semester);
      });
    } catch (e) {
      if (!mounted) return;
      _setLoadError(
        _SumberMuat.semester,
        e,
        'Gagal memuat daftar semester. Periksa koneksi lalu coba lagi.',
      );
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
        _clearLoadError(_SumberMuat.matkul);
      });
    } catch (e) {
      if (!mounted) return;
      _setLoadError(
        _SumberMuat.matkul,
        e,
        'Gagal memuat daftar matakuliah. Periksa koneksi lalu coba lagi.',
      );
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
        _clearLoadError(_SumberMuat.mahasiswa);
      });
    } catch (e) {
      if (!mounted) return;
      _setLoadError(
        _SumberMuat.mahasiswa,
        e,
        'Gagal memuat data kehadiran. Periksa koneksi lalu coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _loadingMahasiswa = false);
    }
  }

  /// Auto-validasi dua langkah: INSPEKSI (lihat dulu apa yang akan ditulis)
  /// → konfirmasi → TULIS. Endpoint auto-validasi tidak menerima parameter
  /// makul, jadi cakupan sebenarnya ditampilkan eksplisit di dialog.
  ///
  /// Satu lock `_validatingAll` menutupi inspeksi → dialog → tulis agar tak
  /// ada double-submit pada operasi tulis massal.
  Future<void> _validasiSemua() async {
    if (_validatingAll) return;
    setState(() {
      _validatingAll = true;
      _autoResult = null;
    });

    AutoValidasiResult inspeksi;
    try {
      inspeksi = await _service.autoValidasi(AutoValidasiMode.inspeksi);
    } catch (e) {
      if (mounted) {
        setState(() => _validatingAll = false);
        AppSnack.show(
          context,
          userErrorMessage(e, 'Gagal memeriksa pertemuan yang perlu divalidasi.'),
          backgroundColor: AppColors.danger,
        );
      }
      return;
    }
    if (!mounted) return;

    AutoValidasiResult? hasilTulis;
    String? galatTulis;
    var dialogMenulis = false;

    final lanjut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> konfirmasi() async {
            setDialogState(() => dialogMenulis = true);
            try {
              hasilTulis = await _service.autoValidasi(AutoValidasiMode.tulis);
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              galatTulis = userErrorMessage(e, 'Validasi gagal dikirim.');
              setDialogState(() => dialogMenulis = false);
            }
          }

          return AlertDialog(
            title: Text(
              'Validasi Otomatis',
              style: AppText.h2.copyWith(color: AppColors.primary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Validasi mencakup ${inspeksi.pertemuan.length} pertemuan '
                    'yang menunggu validasi — termasuk mata kuliah lain yang '
                    'tidak Anda tekan.',
                    style: AppText.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Cakupan validasi',
                    style: AppText.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppListGroup.from([
                    for (final entry in _grupMakul(inspeksi.pertemuan).entries)
                      AppListRow(
                        title: entry.key,
                        subtitle: '${entry.value.length} pertemuan'
                            '${_labelJenis(entry.value)}',
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Nilai yang akan dikirim (preset wajar)',
                    style: AppText.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSurface(
                    variant: AppSurfaceVariant.plain,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppKeyValue(
                            label: 'Kesesuaian Perkuliahan', value: 'Sesuai'),
                        AppKeyValue(label: 'Kesesuaian Materi', value: 'Ya'),
                        AppKeyValue(
                            label: 'Penilaian Mahasiswa',
                            value: 'Sangat Baik'),
                        AppKeyValue(
                            label: 'Penilaian Asdos',
                            value: 'Pilihan terbaik otomatis'),
                        AppKeyValue(
                            label: 'Kritik & Saran', value: 'Dikosongkan'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Validasi tidak dapat dibatalkan setelah dikirim.',
                    style: AppText.bodySm.copyWith(color: AppColors.danger),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    dialogMenulis ? null : () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: dialogMenulis ? null : konfirmasi,
                child: dialogMenulis
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text('Memvalidasi…'),
                        ],
                      )
                    : const Text('Lanjut validasi'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted) return;
    if (lanjut == true && hasilTulis != null) {
      setState(() => _autoResult = hasilTulis);
    } else {
      final pesan = galatTulis;
      if (pesan != null) {
        AppSnack.show(context, pesan, backgroundColor: AppColors.danger);
      }
    }

    // Segarkan badge "perlu validasi" DAN riwayat/statistik terpilih supaya
    // angka basi tidak tertinggal setelah penulisan massal.
    await _loadBelumValidasi();
    if (_selectedThn != null && _selectedSmt != null && _selectedMakul != null) {
      await _loadMahasiswa();
    }
    if (mounted) setState(() => _validatingAll = false);
  }

  /// Pertemuan dikelompokkan per mata kuliah untuk dialog cakupan.
  Map<String, List<AutoValidasiPertemuan>> _grupMakul(
      List<AutoValidasiPertemuan> pertemuan) {
    final result = <String, List<AutoValidasiPertemuan>>{};
    for (final p in pertemuan) {
      result.putIfAbsent(p.makul.isEmpty ? '—' : p.makul, () => []).add(p);
    }
    return result;
  }

  /// Label jenis pertemuan; dikosongkan bila BE tidak mengirim jenis
  /// (respons lama), supaya tak ada klasifikasi yang salah.
  String _labelJenis(List<AutoValidasiPertemuan> pertemuan) {
    final jenis = pertemuan
        .map((p) => p.jenis.toLowerCase())
        .where((j) => j.isNotEmpty)
        .toSet();
    if (jenis.isEmpty) return '';
    if (jenis.length > 1) return ' · teori & praktek';
    return jenis.first == 'praktek' ? ' · praktek' : ' · teori';
  }

  /// Pesan dari portal selalu disaring dulu — jangan pernah tampil mentah.
  String _alasanRamah(String alasan) =>
      AppFailure.fromServer(alasan, fallback: 'Ditolak portal').message;

  /// Hasil auto-validasi terakhir, tampil inline di seksi "Perlu validasi".
  Widget _buildAutoResult() {
    final result = _autoResult;
    if (result == null) return const SizedBox.shrink();
    final r = result.ringkasan;

    // Semua pertemuan dilewati (sudah tervalidasi / tak memenuhi syarat).
    if (r.sukses == 0 && r.gagal == 0) {
      return AppSection(
        title: 'Hasil validasi',
        child: AppEmptyState(
          title: 'Tidak ada pertemuan yang perlu divalidasi.',
          message:
              'Semua pertemuan sudah divalidasi atau tidak memenuhi syarat.',
          actionLabel: 'Muat ulang',
          onAction: () {
            setState(() => _autoResult = null);
            _loadBelumValidasi();
          },
        ),
      );
    }

    // Tidak ada yang berhasil — beda dari gagal sebagian.
    if (r.sukses == 0) {
      return AppSection(
        title: 'Hasil validasi',
        child: AppSurface(
          variant: AppSurfaceVariant.danger,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Validasi gagal',
                style: AppText.h3.copyWith(color: AppColors.danger),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${r.gagal} pertemuan gagal divalidasi. '
                'Periksa koneksi lalu coba lagi.',
                style: AppText.bodySm,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _validatingAll ? null : _validasiSemua,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final gagal = result.pertemuan.where((p) => p.status == 'gagal').toList();
    return AppSection(
      title: 'Hasil validasi',
      trailing: AppPill('${r.sukses} berhasil', tone: AppPillTone.success),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSurface(
            variant: AppSurfaceVariant.success,
            child: Text(
              'Validasi selesai: ${r.sukses} berhasil, ${r.gagal} gagal, '
              '${r.dilewati} dilewati.',
              style: AppText.bodySm,
            ),
          ),
          if (gagal.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppListGroup.from([
              for (final p in gagal)
                AppListRow(
                  title: p.makul.isEmpty ? '—' : p.makul,
                  subtitle:
                      '${p.tanggal.isEmpty ? '—' : p.tanggal} · ${_alasanRamah(p.alasan)}',
                ),
            ]),
          ],
          if (r.dilewati > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${r.dilewati} pertemuan dilewati karena sudah divalidasi atau '
              'tidak memenuhi syarat.',
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
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
              _buildAutoResult(),
              _buildFilter(),
              if (_errorFilter != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: AppErrorState(
                    message: _errorFilter!,
                    onRetry: _retryFailedLoad,
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
    final (bg, fg) = AppPill.toneColors(tone);
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
              onPressed: _validatingAll ? null : _validasiSemua,
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
    required List<ValueLabelOption> items,
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
    final (bg, fg) = AppPill.toneColors(tone);

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
                MaterialPageRoute(
                  builder: (_) => AbsensiDetailPage(
                    idPresensi: r.idPresensi!,
                    pertemuan: r,
                  ),
                ),
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
