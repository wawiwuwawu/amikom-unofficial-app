import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'skpi_file_picker.dart';
import '../models/organisasi.dart';
import '../services/organisasi_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

class OrganisasiFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final OrganisasiItem? itemToEdit;

  const OrganisasiFormSheet({
    super.key,
    required this.onSuccess,
    this.itemToEdit,
  });

  @override
  State<OrganisasiFormSheet> createState() => _OrganisasiFormSheetState();
}

class _OrganisasiFormSheetState extends State<OrganisasiFormSheet> {
  final _service = OrganisasiService();
  final _formKey = GlobalKey<FormState>();

  bool _loadingOptions = true;
  OrganisasiOptionResponse? _options;
  String? _error;

  String? _selectedOrganisasi;
  final _kegiatanController = TextEditingController();
  
  String? _selectedJabatan;
  final _jabatanLainnyaController = TextEditingController();
  
  int? _selectedTahun;

  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.itemToEdit!;
      _selectedOrganisasi = item.namaOrganisasi;
      _selectedJabatan = item.jabatan;
      _selectedTahun = item.tahun;
    }
    _loadOptions();
  }

  @override
  void dispose() {
    _kegiatanController.dispose();
    _jabatanLainnyaController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final opts = await _service.getOptions();
      if (mounted) {
        setState(() {
          _options = opts;
          if (_isEditing && _selectedOrganisasi != null && _options != null) {
            final exists = _options!.organisasi.any((o) => o.value == _selectedOrganisasi);
            if (!exists) {
              _kegiatanController.text = _selectedOrganisasi!;
              _selectedOrganisasi = 'Kepanitiaan';
            }
          }
          if (_isEditing && _selectedJabatan != null && _options != null) {
            final exists = _options!.jabatan.any((j) => j.value == _selectedJabatan);
            if (!exists) {
              _jabatanLainnyaController.text = _selectedJabatan!;
              _selectedJabatan = 'Lainnya';
            }
          }
          _loadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loadingOptions = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih file pengesahan (PDF)')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final isKepanitiaan = _selectedOrganisasi?.toLowerCase() == 'kepanitiaan';
      final isJabatanLainnya = _selectedJabatan?.toLowerCase() == 'lainnya';

      final mapData = <String, dynamic>{
        'organisasi': _selectedOrganisasi,
        if (isKepanitiaan) 'nama_kegiatan_kepanitiaan': _kegiatanController.text,
        'jabatan': _selectedJabatan,
        if (isJabatanLainnya) 'jabatan_lainnya': _jabatanLainnyaController.text,
        'tahun': _selectedTahun.toString(),
      };

      if (_selectedFile != null && _selectedFile!.path != null) {
        mapData['file_pengesahan'] = await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        );
      }

      final formData = FormData.fromMap(mapData);

      if (_isEditing) {
        await _service.editOrganisasi(widget.itemToEdit!.id, formData);
      } else {
        await _service.tambahOrganisasi(formData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Organisasi berhasil diubah'
                : 'Organisasi berhasil ditambahkan'),
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<int> _getTahunList() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _loadingOptions
                ? const SizedBox(
                    height: 200,
                    child: AppLoading(message: 'Memuat pilihan…'),
                  )
                : _error != null
                    ? SizedBox(
                        height: 200,
                        child: Center(
                          child: AppErrorState(message: _error!, onRetry: _loadOptions),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isEditing ? 'Edit Organisasi / Kepanitiaan' : 'Tambah Organisasi / Kepanitiaan',
                              style: AppText.h2,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Dropdown Organisasi
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Organisasi',
                              ),
                              isExpanded: true,
                              initialValue: _selectedOrganisasi,
                              items: _options?.organisasi.map((opt) {
                                return DropdownMenuItem(
                                  value: opt.value,
                                  child: Text(opt.label),
                                );
                              }).toList() ?? [],
                              onChanged: (val) {
                                setState(() {
                                  _selectedOrganisasi = val;
                                  if (val?.toLowerCase() != 'kepanitiaan') {
                                    _kegiatanController.clear();
                                  }
                                });
                              },
                              validator: (val) => val == null ? 'Wajib dipilih' : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Field Kepanitiaan (Conditional)
                            if (_selectedOrganisasi?.toLowerCase() == 'kepanitiaan') ...[
                              TextFormField(
                                controller: _kegiatanController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Kegiatan Kepanitiaan',
                                ),
                                validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],

                            // Dropdown Jabatan
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Jabatan',
                              ),
                              isExpanded: true,
                              initialValue: _selectedJabatan,
                              items: _options?.jabatan.map((opt) {
                                return DropdownMenuItem(
                                  value: opt.value,
                                  child: Text(opt.label),
                                );
                              }).toList() ?? [],
                              onChanged: (val) {
                                setState(() {
                                  _selectedJabatan = val;
                                  if (val?.toLowerCase() != 'lainnya') {
                                    _jabatanLainnyaController.clear();
                                  }
                                });
                              },
                              validator: (val) => val == null ? 'Wajib dipilih' : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Field Jabatan Lainnya (Conditional)
                            if (_selectedJabatan?.toLowerCase() == 'lainnya') ...[
                              TextFormField(
                                controller: _jabatanLainnyaController,
                                decoration: const InputDecoration(
                                  labelText: 'Masukkan Jabatan Lainnya',
                                ),
                                validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],

                            // Dropdown Tahun
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Tahun',
                              ),
                              initialValue: _selectedTahun,
                              items: _getTahunList().map((thn) {
                                return DropdownMenuItem(
                                  value: thn,
                                  child: Text(thn.toString()),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedTahun = val),
                              validator: (val) => val == null ? 'Wajib dipilih' : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            SkpiFilePicker(
                              selectedFile: _selectedFile,
                              label: _isEditing
                                  ? 'Dokumen Pengesahan (Opsional jika tidak diganti)'
                                  : 'Dokumen Pengesahan (PDF)*',
                              allowedExtensions: const ['pdf'],
                              onFileSelected: (file) => setState(() => _selectedFile = file),
                            ),
                            if (_isEditing && _selectedFile == null && widget.itemToEdit!.file.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'File saat ini: ${widget.itemToEdit!.file}',
                                style: AppText.bodySm,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xxl),

                            // Submit Button
                            FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(_isEditing ? 'Simpan Perubahan' : 'Upload Dokumen'),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
