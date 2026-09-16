import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/ppks.dart';
import '../services/ppks_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Halaman Satgas PPKS Amikom (layanan & formulir pengaduan).
///
/// Redesign memakai design system dengan prioritas keterbacaan:
///   * jaminan kerahasiaan jadi [AppSection] + [AppSurface] sukses, bukan
///     `Container` berwarna mentah;
///   * formulir dipecah per topik memakai [AppSection] ("Formulir Pengaduan
///     Kekerasan Seksual", "Alasan Pengaduan", "Identifikasi Kebutuhan Korban",
///     "Detail Kejadian") sehingga tidak lagi satu kartu raksasa;
///   * daftar pilihan (alasan & kebutuhan) disajikan sebagai baris di dalam
///     [AppListGroup] — pola daftar, bukan tumpukan kartu;
///   * seluruh warna teks memakai [AppText] (line-height 1.4–1.45) agar paragraf
///     panjang tetap nyaman dibaca, dan lebar baca dibatasi 640 pada layar lebar.
/// Semua field, panggilan service, state, dan navigasi tidak berubah.
///
/// Tombol kembali disediakan otomatis oleh [AppScaffold] mengikuti route,
/// sehingga `onBack` hanya dipertahankan untuk kompatibilitas pemanggil lama.
class PpksPage extends StatefulWidget {
  final VoidCallback? onBack;

  const PpksPage({super.key, this.onBack});

  @override
  State<PpksPage> createState() => _PpksPageState();
}

class _PpksPageState extends State<PpksPage> {
  final PpksService _service = PpksService();

  bool _isLoading = true;
  String _error = '';
  PpksData? _data;

  // Form State
  String _statusPelapor = 'korban'; // 'korban' or 'saksi'

  // Fields if Saksi
  final TextEditingController _namaKorbanController = TextEditingController();
  String? _selectedJkKorban;
  String? _selectedStatusKorban;

  // General Fields
  String? _selectedDisabilitasKorban;
  final TextEditingController _namaTerlaporController = TextEditingController();
  String? _selectedJkTerlapor;
  String? _selectedStatusTerlapor;

  final Set<String> _selectedAlasan = {};
  final Set<String> _selectedKebutuhan = {};
  final TextEditingController _kebutuhanLainnyaController =
      TextEditingController();

  DateTime? _tanggalKejadian;
  final TextEditingController _lokasiKejadianController =
      TextEditingController();
  final TextEditingController _kronologiKejadianController =
      TextEditingController();
  final TextEditingController _buktiController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _namaKorbanController.dispose();
    _namaTerlaporController.dispose();
    _kebutuhanLainnyaController.dispose();
    _lokasiKejadianController.dispose();
    _kronologiKejadianController.dispose();
    _buktiController.dispose();
    _nomorHpController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getPpksData();
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateApi(DateTime dt) {
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDateDisplay(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _selectTanggalKejadian() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalKejadian ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _tanggalKejadian = picked);
    }
  }

  void _resetForm() {
    setState(() {
      _statusPelapor = 'korban';
      _namaKorbanController.clear();
      _selectedJkKorban = null;
      _selectedStatusKorban = null;
      _selectedDisabilitasKorban = null;
      _namaTerlaporController.clear();
      _selectedJkTerlapor = null;
      _selectedStatusTerlapor = null;
      _selectedAlasan.clear();
      _selectedKebutuhan.clear();
      _kebutuhanLainnyaController.clear();
      _tanggalKejadian = null;
      _lokasiKejadianController.clear();
      _kronologiKejadianController.clear();
      _buktiController.clear();
      _nomorHpController.clear();
    });
  }

  Future<void> _submitForm() async {
    if (_statusPelapor == 'saksi') {
      if (_namaKorbanController.text.trim().isEmpty ||
          _selectedJkKorban == null ||
          _selectedStatusKorban == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Harap lengkapi Nama, Jenis Kelamin, dan Status Korban'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    if (_namaTerlaporController.text.trim().isEmpty ||
        _selectedJkTerlapor == null ||
        _selectedStatusTerlapor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Harap lengkapi Nama, Jenis Kelamin, dan Status Terlapor'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedAlasan.isEmpty || _selectedKebutuhan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap pilih minimal satu Alasan Pengaduan dan Kebutuhan Korban',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedKebutuhan.contains('Lainnya') &&
        _kebutuhanLainnyaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap sebutkan Kebutuhan Lainnya'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_tanggalKejadian == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Tanggal Kejadian'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_lokasiKejadianController.text.trim().isEmpty ||
        _kronologiKejadianController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Lokasi Kejadian dan Kronologi Kejadian'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_nomorHpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Nomor HP yang dapat dihubungi'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final body = <String, dynamic>{
      'status': _statusPelapor,
      'disabilitas_korban': _selectedDisabilitasKorban ?? 'Tidak',
      'nama_terlapor': _namaTerlaporController.text.trim(),
      'jk_terlapor': _selectedJkTerlapor ?? '',
      'status_terlapor': _selectedStatusTerlapor ?? '',
      'alasan_pengaduan': _selectedAlasan.toList(),
      'kebutuhan_korban': _selectedKebutuhan.toList(),
      'tanggal_kejadian': _formatDateApi(_tanggalKejadian!),
      'lokasi_kejadian': _lokasiKejadianController.text.trim(),
      'kronologi_kejadian': _kronologiKejadianController.text.trim(),
      'bukti': _buktiController.text.trim(),
      'nomor_hp': _nomorHpController.text.trim(),
    };

    if (_selectedKebutuhan.contains('Lainnya')) {
      body['kebutuhan_korban_lainnya'] =
          _kebutuhanLainnyaController.text.trim();
    }

    if (_statusPelapor == 'saksi') {
      body['nama_korban'] = _namaKorbanController.text.trim();
      body['jk_korban'] = _selectedJkKorban ?? '';
      body['status_korban'] = _selectedStatusKorban ?? '';
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.submitPpks(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengaduan berhasil dikirim'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        _resetForm();
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Satgas PPKS Amikom',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoading();

    if (_error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AppErrorState(message: _error, onRetry: _fetchData),
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Center(
            // Batasi lebar baca agar baris teks tidak terlalu panjang.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrivacySection(data),
                  _buildIdentitasSection(data),
                  _buildCheckboxSection(
                    title: 'Alasan Pengaduan',
                    options: data.options.alasanPengaduan,
                    selected: _selectedAlasan,
                  ),
                  _buildCheckboxSection(
                    title: 'Identifikasi Kebutuhan Korban',
                    options: data.options.kebutuhanKorban,
                    selected: _selectedKebutuhan,
                    footer: _selectedKebutuhan.contains('Lainnya')
                        ? TextField(
                            controller: _kebutuhanLainnyaController,
                            decoration: const InputDecoration(
                              labelText: 'Sebutkan Kebutuhan Lainnya',
                              prefixIcon: Icon(
                                CupertinoIcons.pencil,
                                color: AppColors.primarySoft,
                              ),
                            ),
                          )
                        : null,
                  ),
                  _buildDetailKejadianSection(),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submitForm,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Icon(
                              CupertinoIcons.paperplane_fill,
                              size: 18,
                            ),
                      label: const Text('Kirim Pengaduan PPKS'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Jaminan kerahasiaan — informasi penting, jadi ditaruh paling atas.
  Widget _buildPrivacySection(PpksData data) {
    if (data.infoPrivacy.isEmpty) return const SizedBox.shrink();

    return AppSection(
      title: 'Kerahasiaan & Keamanan Dijamin',
      topGap: AppSpacing.xs,
      child: AppSurface(
        variant: AppSurfaceVariant.success,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              CupertinoIcons.shield_fill,
              color: AppColors.success,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                data.infoPrivacy,
                style: AppText.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Identitas pelapor, korban (bila saksi), dan terlapor.
  Widget _buildIdentitasSection(PpksData data) {
    final opts = data.options;

    return AppSection(
      title: 'Formulir Pengaduan Kekerasan Seksual',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anda Melapor Sebagai:', style: AppText.h3),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: opts.statusPelapor.map((opt) {
              final isSelected = _statusPelapor == opt.value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: ChoiceChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Center(child: Text(opt.label)),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: AppText.label.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _statusPelapor = opt.value);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          if (_statusPelapor == 'saksi') ...[
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              variant: AppSurfaceVariant.hero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identitas Korban (Pelapor Saksi):',
                    style: AppText.h3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _namaKorbanController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Korban',
                      prefixIcon: Icon(
                        CupertinoIcons.person,
                        color: AppColors.primarySoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedJkKorban,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Kelamin Korban',
                      prefixIcon: Icon(
                        CupertinoIcons.person_2,
                        color: AppColors.primarySoft,
                      ),
                    ),
                    items: opts.jenisKelamin.map((jk) {
                      return DropdownMenuItem<String>(
                        value: jk,
                        child: Text(
                          jk,
                          style: AppText.body,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedJkKorban = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatusKorban,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status Korban',
                      prefixIcon: Icon(
                        CupertinoIcons.briefcase,
                        color: AppColors.primarySoft,
                      ),
                    ),
                    items: opts.statusPihak.map((st) {
                      return DropdownMenuItem<String>(
                        value: st,
                        child: Text(
                          st,
                          style: AppText.body,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedStatusKorban = val),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _selectedDisabilitasKorban,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Korban Memiliki Disabilitas?',
              prefixIcon: Icon(
                CupertinoIcons.exclamationmark_circle,
                color: AppColors.primarySoft,
              ),
            ),
            items: opts.disabilitas.map((d) {
              return DropdownMenuItem<String>(
                value: d,
                child: Text(
                  d,
                  style: AppText.body,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) =>
                setState(() => _selectedDisabilitasKorban = val),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSurface(
            variant: AppSurfaceVariant.danger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identitas Terlapor (Pelaku):',
                  style: AppText.h3.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _namaTerlaporController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Terlapor',
                    prefixIcon: Icon(
                      CupertinoIcons.person_badge_minus,
                      color: AppColors.primarySoft,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _selectedJkTerlapor,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin Terlapor',
                    prefixIcon: Icon(
                      CupertinoIcons.person_2,
                      color: AppColors.primarySoft,
                    ),
                  ),
                  items: opts.jenisKelamin.map((jk) {
                    return DropdownMenuItem<String>(
                      value: jk,
                      child: Text(
                        jk,
                        style: AppText.body,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedJkTerlapor = val),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatusTerlapor,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status Terlapor',
                    prefixIcon: Icon(
                      CupertinoIcons.briefcase,
                      color: AppColors.primarySoft,
                    ),
                  ),
                  items: opts.statusPihak.map((st) {
                    return DropdownMenuItem<String>(
                      value: st,
                      child: Text(
                        st,
                        style: AppText.body,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedStatusTerlapor = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Daftar centang (alasan / kebutuhan) disajikan sebagai baris dalam satu
  /// grup sehingga mudah dipindai, bukan tumpukan kartu terpisah.
  Widget _buildCheckboxSection({
    required String title,
    required List<String> options,
    required Set<String> selected,
    Widget? footer,
  }) {
    return AppSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppListGroup.from([
            for (final option in options)
              CheckboxListTile(
                dense: true,
                value: selected.contains(option),
                activeColor: AppColors.primary,
                title: Text(option, style: AppText.body),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      selected.add(option);
                    } else {
                      selected.remove(option);
                    }
                  });
                },
              ),
          ]),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer,
          ],
        ],
      ),
    );
  }

  /// Tanggal, lokasi, kronologi, bukti, dan nomor kontak.
  Widget _buildDetailKejadianSection() {
    return AppSection(
      title: 'Detail Kejadian',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _selectTanggalKejadian,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tanggal Kejadian',
                prefixIcon: Icon(
                  CupertinoIcons.calendar,
                  color: AppColors.primarySoft,
                ),
              ),
              child: Text(
                _tanggalKejadian != null
                    ? _formatDateDisplay(_tanggalKejadian!)
                    : 'Pilih Tanggal Kejadian',
                style: AppText.body.copyWith(
                  color: _tanggalKejadian != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _lokasiKejadianController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Lokasi Kejadian',
              prefixIcon: Icon(
                CupertinoIcons.location_solid,
                color: AppColors.primarySoft,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _kronologiKejadianController,
            maxLines: 4,
            style: AppText.body,
            decoration: const InputDecoration(
              labelText: 'Kronologi Kejadian',
              alignLabelWithHint: true,
              prefixIcon: Icon(
                CupertinoIcons.text_quote,
                color: AppColors.primarySoft,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _buktiController,
            decoration: const InputDecoration(
              labelText: 'Link Bukti (Google Drive / URL)',
              prefixIcon: Icon(
                CupertinoIcons.link,
                color: AppColors.primarySoft,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nomorHpController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor HP Saksi/Korban yang Dapat Dihubungi',
              prefixIcon: Icon(
                CupertinoIcons.phone_fill,
                color: AppColors.primarySoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
