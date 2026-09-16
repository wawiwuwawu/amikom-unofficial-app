import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'skpi_file_picker.dart';
import '../models/sertifikasi.dart';
import '../services/sertifikasi_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

class SertifikasiFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final SertifikasiItem? itemToEdit;

  const SertifikasiFormSheet({
    super.key,
    required this.onSuccess,
    this.itemToEdit,
  });

  @override
  State<SertifikasiFormSheet> createState() => _SertifikasiFormSheetState();
}

class _SertifikasiFormSheetState extends State<SertifikasiFormSheet> {
  final _service = SertifikasiService();
  final _formKey = GlobalKey<FormState>();

  bool _loadingOptions = true;
  List<SertifikasiOption> _options = [];
  String? _error;

  String? _selectedJudul;
  final _judulLainnyaController = TextEditingController();
  final _nilaiController = TextEditingController();
  int? _selectedTahun;
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.itemToEdit!;
      _selectedJudul = item.judul;
      _nilaiController.text = item.grade;
      _selectedTahun = item.tahun;
    }
    _loadOptions();
  }
  @override
  void dispose() {
    _judulLainnyaController.dispose();
    _nilaiController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final opts = await _service.getOptions();
      if (mounted) {
        setState(() {
          _options = opts;
          if (_isEditing && _selectedJudul != null) {
            final exists = _options.any((o) => o.value == _selectedJudul);
            if (!exists) {
              _judulLainnyaController.text = _selectedJudul!;
              _selectedJudul = 'SERTIFIKASI LAINNYA';
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
        const SnackBar(content: Text('Silakan pilih file sertifikat (PDF)')),
      );
      return;
    }

    final String judulFinal = _selectedJudul == 'SERTIFIKASI LAINNYA' 
        ? _judulLainnyaController.text 
        : (_selectedJudul ?? '');

    if (judulFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan lengkapi judul sertifikasi')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final mapData = <String, dynamic>{
        'judul': _selectedJudul,
        if (_selectedJudul == 'SERTIFIKASI LAINNYA') 'judul_lainnya': _judulLainnyaController.text,
        'nilai': _nilaiController.text,
        'tahun': _selectedTahun.toString(),
      };

      if (_selectedFile != null && _selectedFile!.path != null) {
        mapData['file_sertifikat'] = await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        );
      }

      final formData = FormData.fromMap(mapData);

      if (_isEditing) {
        await _service.editSertifikasi(widget.itemToEdit!.id, formData);
      } else {
        await _service.tambahSertifikasi(formData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Sertifikasi berhasil diubah'
                : 'Sertifikasi berhasil ditambahkan'),
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
                              _isEditing ? 'Edit Sertifikasi' : 'Tambah Sertifikasi',
                              style: AppText.h2,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Dropdown Judul
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Judul Sertifikasi',
                              ),
                              isExpanded: true,
                              initialValue: _selectedJudul,
                              items: _options.map((opt) {
                                return DropdownMenuItem(
                                  value: opt.value,
                                  child: Text(opt.label),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedJudul = val;
                                  if (val != 'SERTIFIKASI LAINNYA') {
                                    _judulLainnyaController.clear();
                                  }
                                });
                              },
                              validator: (val) => val == null ? 'Wajib dipilih' : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Field Judul Lainnya (Conditional)
                            if (_selectedJudul == 'SERTIFIKASI LAINNYA') ...[
                              TextFormField(
                                controller: _judulLainnyaController,
                                decoration: const InputDecoration(
                                  labelText: 'Masukkan Judul Sertifikasi',
                                ),
                                validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],

                            // Field Nilai
                            TextFormField(
                              controller: _nilaiController,
                              decoration: const InputDecoration(
                                labelText: 'Nilai / Grade',
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Dropdown Tahun
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Tahun Sertifikasi',
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
                                  ? 'File Scan Sertifikat (Opsional jika tidak diganti)'
                                  : 'File Scan Sertifikat (PDF)*',
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
                                  : Text(_isEditing ? 'Simpan Perubahan' : 'Upload Sertifikasi'),
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
