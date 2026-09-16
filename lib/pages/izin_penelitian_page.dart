import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/izin_penelitian.dart';
import '../services/izin_penelitian_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

/// Izin penelitian — dua tab: form pengajuan dan riwayat pengajuan.
///
/// Riwayat disajikan sebagai satu daftar ([AppListGroup] + [AppListRow])
/// dengan pil status, bukan satu kartu per pengajuan, supaya cepat dipindai.
/// Tombol kembali disediakan otomatis oleh [AppScaffold].
class IzinPenelitianPage extends StatefulWidget {

  const IzinPenelitianPage({super.key});

  @override
  State<IzinPenelitianPage> createState() => _IzinPenelitianPageState();
}

class _IzinPenelitianPageState extends State<IzinPenelitianPage> {
  final IzinPenelitianService _service = IzinPenelitianService();

  bool _isLoading = true;
  String _error = '';
  IzinPenelitianData? _data;

  String? _selectedJenis;
  String? _selectedDitujukan;
  final TextEditingController _ditujukanLainnyaController = TextEditingController();
  final TextEditingController _instansiController = TextEditingController();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _topikController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _ditujukanLainnyaController.dispose();
    _instansiController.dispose();
    _judulController.dispose();
    _topikController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getIzinPenelitianData();
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
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$month/$day/${dt.year}';
  }

  String _formatDateDisplay(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedJenis = null;
      _selectedDitujukan = null;
      _ditujukanLainnyaController.clear();
      _instansiController.clear();
      _judulController.clear();
      _topikController.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _submitForm() async {
    if (_selectedJenis == null || _selectedDitujukan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi jenis penelitian dan penerima surat'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedDitujukan == 'Lainnya' && _ditujukanLainnyaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi spesifik penerima surat (Ditujukan Kepada)'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_instansiController.text.trim().isEmpty || _judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Instansi Tujuan dan Judul / Mata Kuliah'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedJenis == 'tugas' && _topikController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Topik Tugas / Wawancara'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Tanggal Mulai dan Tanggal Selesai'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final body = {
      'jenis_penelitian': _selectedJenis,
      'ditujukan_penelitian': _selectedDitujukan,
      'ditujukan_penelitian_lainnya': _selectedDitujukan == 'Lainnya' ? _ditujukanLainnyaController.text.trim() : '',
      'instansi': _instansiController.text.trim(),
      'start_date': _formatDateApi(_startDate!),
      'end_date': _formatDateApi(_endDate!),
      'judul_penelitian': _judulController.text.trim(),
      'topik': _selectedJenis == 'tugas' ? _topikController.text.trim() : '',
    };

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.submitIzinPenelitian(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengajuan Berhasil Ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
        _resetForm();
        _fetchData();
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

  Future<void> _showDeleteConfirmation(IzinPenelitianItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengajuan Izin Penelitian'),
        content: Text('Apakah Anda yakin ingin menghapus pengajuan izin penelitian ke ${item.instansi}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.deleteIzinPenelitian(item.idPengajuan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Pengajuan Berhasil Dihapus'),
              backgroundColor: AppColors.success,
            ),
          );
          _fetchData();
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

  /// Nada pil untuk status pengajuan (warna semantik dari design system).
  AppPillTone _statusTone(String status) {
    switch (status.toLowerCase().trim()) {
      case 'diajukan':
        return AppPillTone.warning;
      case 'diproses':
        return AppPillTone.info;
      case 'selesai':
        return AppPillTone.success;
      case 'ditolak':
        return AppPillTone.danger;
      default:
        return AppPillTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Izin Penelitian',
        subtitle: 'Pengajuan surat izin & riwayatnya',
        scrollable: false,
        padding: EdgeInsets.zero,
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(CupertinoIcons.doc_plaintext),
                    text: 'Form Pengajuan',
                  ),
                  Tab(
                    icon: Icon(CupertinoIcons.clock),
                    text: 'Riwayat Pengajuan',
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const AppLoading(message: 'Memuat data izin penelitian…');
    }

    if (_error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: AppErrorState(message: _error, onRetry: _fetchData),
        ),
      );
    }

    return TabBarView(
      children: [
        _buildFormTab(),
        _buildRiwayatTab(),
      ],
    );
  }

  Widget _buildFormTab() {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    final jenisList = data.options.jenisPenelitian;
    final ditujukanList = data.options.ditujukanPenelitian;

    String judulLabel = 'Judul Penelitian';
    if (_selectedJenis == 'tugas') {
      judulLabel = 'Mata Kuliah';
    } else if (_selectedJenis == 'mbkm') {
      judulLabel = 'Program MBKM';
    } else if (_selectedJenis != null) {
      judulLabel = 'Judul Jenis Penelitian';
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppColors.primary,
      child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppSection(
            topGap: AppSpacing.sm,
            title: 'Buat Pengajuan Izin Penelitian',
            child: AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown Jenis Penelitian
                  DropdownButtonFormField<String>(
                    initialValue: _selectedJenis,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Penelitian',
                      prefixIcon: Icon(CupertinoIcons.square_grid_2x2, color: AppColors.primary),
                    ),
                    items: [
                      for (final item in jenisList)
                        DropdownMenuItem<String>(
                          value: item.value,
                          child: Text(
                            item.label,
                            style: AppText.body,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedJenis = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Dropdown Ditujukan
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDitujukan,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ditujukan Kepada',
                      prefixIcon: Icon(CupertinoIcons.person_crop_square, color: AppColors.primary),
                    ),
                    items: [
                      for (final item in ditujukanList)
                        DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: AppText.body,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedDitujukan = val);
                    },
                  ),

                  // Input Kondisional jika ditujukan == 'Lainnya'
                  if (_selectedDitujukan == 'Lainnya') ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _ditujukanLainnyaController,
                      decoration: const InputDecoration(
                        labelText: 'Ditujukan Kepada (Spesifik)',
                        hintText: 'Contoh: Koordinator Lapangan / Supervisor',
                        prefixIcon: Icon(CupertinoIcons.person, color: AppColors.primary),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // Instansi
                  TextField(
                    controller: _instansiController,
                    decoration: const InputDecoration(
                      labelText: 'Instansi / Perusahaan Tujuan',
                      prefixIcon: Icon(CupertinoIcons.building_2_fill, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Judul / Matkul / MBKM
                  TextField(
                    controller: _judulController,
                    maxLines: _selectedJenis == 'tugas' ? 1 : 2,
                    decoration: InputDecoration(
                      labelText: judulLabel,
                      prefixIcon: const Icon(CupertinoIcons.book, color: AppColors.primary),
                    ),
                  ),

                  // Input Kondisional Topik jika jenis == 'tugas'
                  if (_selectedJenis == 'tugas') ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _topikController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Topik Tugas / Wawancara',
                        prefixIcon: Icon(CupertinoIcons.text_quote, color: AppColors.primary),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // Date Picker Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectStartDate,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Mulai',
                              prefixIcon: Icon(CupertinoIcons.calendar, color: AppColors.primary),
                            ),
                            child: Text(
                              _startDate != null ? _formatDateDisplay(_startDate!) : 'Pilih Tanggal',
                              style: AppText.bodySm.copyWith(
                                color: _startDate != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: InkWell(
                          onTap: _selectEndDate,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Selesai',
                              prefixIcon: Icon(CupertinoIcons.calendar, color: AppColors.primary),
                            ),
                            child: Text(
                              _endDate != null ? _formatDateDisplay(_endDate!) : 'Pilih Tanggal',
                              style: AppText.bodySm.copyWith(
                                color: _endDate != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submitForm,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(CupertinoIcons.paperplane_fill, size: 18),
                      label: const Text('Ajukan Izin Penelitian'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Keterangan BAA
          if (data.keteranganBaa.isNotEmpty)
            AppSection(
              title: 'Petunjuk Pengambilan Surat (BAA)',
              child: AppSurface(
                variant: AppSurfaceVariant.hero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.info_circle_fill, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(data.keteranganBaa, style: AppText.bodySm),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiwayatTab() {
    final items = _data?.items ?? [];

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            AppEmptyState(
              title: 'Belum ada riwayat pengajuan izin penelitian',
              icon: CupertinoIcons.doc_text_search,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppColors.primary,
      child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppSection(
            topGap: AppSpacing.sm,
            title: 'Riwayat Pengajuan',
            trailing: Text(
              '${items.length} pengajuan',
              style: AppText.label.copyWith(fontWeight: FontWeight.w400),
            ),
            child: AppListGroup.from([
              for (final item in items) _buildRiwayatRow(item),
            ]),
          ),
        ],
      ),
    );
  }

  /// Satu baris pengajuan: judul penelitian · instansi/tanggal/nomor · pil status.
  Widget _buildRiwayatRow(IzinPenelitianItem item) {
    return AppListRow(
      title: item.judulPenelitian.isNotEmpty ? item.judulPenelitian : item.instansi,
      subtitle: '${item.instansi}\n'
          '${item.mulai} - ${item.selesai} • ${item.thnAjaranSmt}\n'
          'No. ${item.idPengajuan} • Proses: ${item.tglProses ?? 'Proses'}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPill(item.status, tone: _statusTone(item.status)),
          if (item.canDelete) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              tooltip: 'Hapus Pengajuan',
              onPressed: () => _showDeleteConfirmation(item),
              visualDensity: VisualDensity.compact,
              icon: const Icon(CupertinoIcons.trash, size: 18, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
