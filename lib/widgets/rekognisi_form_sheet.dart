import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'skpi_file_picker.dart';
import '../models/rekognisi.dart';
import '../services/rekognisi_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

/// Form tambah/edit rekognisi mahasiswa.
///
/// Redesign memakai design system: handlebar & judul memakai token, state
/// memuat/galat memakai [AppLoading] dan [AppErrorState], seluruh field
/// memakai `inputDecorationTheme` global (tanpa border lokal), dan tombol
/// submit memakai [FilledButton]. Field, validator, dan alur submit sama.
class RekognisiFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final RekognisiItem? itemToEdit;

  const RekognisiFormSheet({
    super.key,
    required this.onSuccess,
    this.itemToEdit,
  });

  @override
  State<RekognisiFormSheet> createState() => _RekognisiFormSheetState();
}

class _RekognisiFormSheetState extends State<RekognisiFormSheet> {
  final _service = RekognisiService();
  final _formKey = GlobalKey<FormState>();

  RekognisiOptionResponse? _optionsData;
  bool _isLoadingOptions = true;
  bool _isSubmitting = false;
  String? _error;

  String? _selectedJudul;
  String? _selectedTingkat;
  String? _selectedKontribusi;
  final _tahunController = TextEditingController(text: DateTime.now().year.toString());
  final _linkController = TextEditingController();

  PlatformFile? _selectedFile;

  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.itemToEdit!;
      _selectedJudul = item.judul;
      _selectedTingkat = item.tingkat;
      _selectedKontribusi = item.kontribusi.isNotEmpty ? item.kontribusi : null;
      _tahunController.text = item.tahun.toString();
      _linkController.text = item.link;
    }
    _loadOptions();
  }

  @override
  void dispose() {
    _tahunController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _error = null;
    });

    try {
      final options = await _service.getOptions();
      setState(() {
        _optionsData = options;
        _isLoadingOptions = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoadingOptions = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedJudul == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis rekognisi terlebih dahulu')),
      );
      return;
    }

    if (_selectedTingkat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tingkat rekognisi terlebih dahulu')),
      );
      return;
    }

    if (!_isEditing && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih berkas bukti (PDF)')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formDataMap = <String, dynamic>{
        'judul': _selectedJudul,
        'tingkat': _selectedTingkat,
        'tahun': _tahunController.text.trim(),
        if (_linkController.text.trim().isNotEmpty) 'link': _linkController.text.trim(),
        if (_selectedKontribusi != null && _selectedKontribusi!.isNotEmpty)
          'kontribusi': _selectedKontribusi,
      };

      if (_selectedFile != null && _selectedFile!.path != null) {
        formDataMap['file_dokumen'] = await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        );
      }

      final formData = FormData.fromMap(formDataMap);

      if (_isEditing) {
        await _service.editRekognisi(widget.itemToEdit!.id, formData);
      } else {
        await _service.tambahRekognisi(formData);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Rekognisi berhasil diubah'
              : 'Rekognisi berhasil ditambahkan'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Edit Rekognisi Mahasiswa'
                          : 'Tambah Rekognisi Mahasiswa',
                      style: AppText.h2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _isLoadingOptions
                  ? const AppLoading()
                  : _error != null
                      ? AppErrorState(message: _error!, onRetry: _loadOptions)
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dropdown Jenis Rekognisi (Judul)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedJudul,
                                decoration: const InputDecoration(
                                  labelText: 'Jenis Rekognisi *',
                                  prefixIcon: Icon(CupertinoIcons.rosette),
                                ),
                                isExpanded: true,
                                items: _optionsData?.jenisRekognisi.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt.value,
                                    child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedJudul = val),
                                validator: (val) => val == null ? 'Pilih jenis rekognisi' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Dropdown Tingkat
                              DropdownButtonFormField<String>(
                                initialValue: _selectedTingkat,
                                decoration: const InputDecoration(
                                  labelText: 'Tingkat *',
                                  prefixIcon: Icon(CupertinoIcons.globe),
                                ),
                                isExpanded: true,
                                items: _optionsData?.tingkat.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt.value,
                                    child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedTingkat = val),
                                validator: (val) => val == null ? 'Pilih tingkat rekognisi' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Dropdown Kontribusi (Opsional)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedKontribusi,
                                decoration: const InputDecoration(
                                  labelText: 'Kontribusi (Opsional)',
                                  prefixIcon: Icon(CupertinoIcons.person_badge_plus),
                                ),
                                isExpanded: true,
                                items: _optionsData?.kontribusi.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt.value,
                                    child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedKontribusi = val),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Input Link URL
                              TextFormField(
                                controller: _linkController,
                                keyboardType: TextInputType.url,
                                decoration: const InputDecoration(
                                  labelText: 'Tautan / Link Berita (Opsional)',
                                  hintText: 'https://...',
                                  prefixIcon: Icon(CupertinoIcons.link),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Input Tahun (Wajib)
                              TextFormField(
                                controller: _tahunController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Tahun *',
                                  prefixIcon: Icon(CupertinoIcons.calendar),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Masukkan tahun' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              SkpiFilePicker(
                                selectedFile: _selectedFile,
                                label: _isEditing
                                    ? 'File Scan Bukti (Opsional jika tidak diganti)'
                                    : 'File Scan Bukti (PDF)*',
                                allowedExtensions: const ['pdf'],
                                onFileSelected: (file) => setState(() => _selectedFile = file),
                              ),
                              if (_isEditing && _selectedFile == null && widget.itemToEdit!.file.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'File saat ini: ${widget.itemToEdit!.file}',
                                  style: AppText.label,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),

                              // Tombol Submit
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _isSubmitting ? null : _submitForm,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isEditing
                                              ? 'Simpan Perubahan'
                                              : 'Upload Rekognisi',
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
