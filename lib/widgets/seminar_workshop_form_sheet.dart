import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'skpi_file_picker.dart';
import '../models/seminar_workshop.dart';
import '../services/seminar_workshop_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

/// Form tambah/edit seminar & workshop.
///
/// Redesign memakai design system: handlebar & judul memakai token, state
/// memuat/galat memakai [AppLoading] dan [AppErrorState], seluruh field
/// memakai `inputDecorationTheme` global (tanpa border lokal), dan tombol
/// submit memakai [FilledButton]. Field, validator, dan alur submit sama.
class SeminarWorkshopFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final SeminarWorkshopItem? itemToEdit;

  const SeminarWorkshopFormSheet({
    super.key,
    required this.onSuccess,
    this.itemToEdit,
  });

  @override
  State<SeminarWorkshopFormSheet> createState() => _SeminarWorkshopFormSheetState();
}

class _SeminarWorkshopFormSheetState extends State<SeminarWorkshopFormSheet> {
  final _service = SeminarWorkshopService();
  final _formKey = GlobalKey<FormState>();

  SeminarWorkshopOptionsData? _optionsData;
  bool _isLoadingOptions = true;
  bool _isSubmitting = false;
  String? _error;

  String? _selectedJenisKegiatan;
  final _judulController = TextEditingController();
  String? _selectedSebagai;
  String? _selectedTingkatan;
  final _tahunController = TextEditingController(text: DateTime.now().year.toString());

  PlatformFile? _selectedFile;
  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.itemToEdit!;
      _judulController.text = item.judul;
      _selectedSebagai = item.sebagai;
      _tahunController.text = item.tahun;
    }
    _loadOptions();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _tahunController.dispose();
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

    if (_selectedJenisKegiatan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis kegiatan terlebih dahulu')),
      );
      return;
    }

    if (_selectedSebagai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih peran (sebagai) terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formDataMap = <String, dynamic>{
        'jenis_kegiatan': _selectedJenisKegiatan,
        'judul': _judulController.text.trim(),
        'sebagai': _selectedSebagai,
        'tahun': _tahunController.text.trim(),
      };

      if (_selectedTingkatan != null && _selectedTingkatan!.isNotEmpty) {
        formDataMap['tingkatan'] = _selectedTingkatan;
      }

      if (_selectedFile != null && _selectedFile!.path != null) {
        formDataMap['file_sertifikat'] = await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        );
      }

      final formData = FormData.fromMap(formDataMap);
      if (_isEditing) {
        await _service.editSeminarWorkshop(widget.itemToEdit!.id, formData);
      } else {
        await _service.tambahSeminarWorkshop(formData);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Seminar / Workshop berhasil diubah'
              : 'Seminar / Workshop berhasil ditambahkan'),
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
                          ? 'Edit Seminar / Workshop'
                          : 'Tambah Seminar / Workshop',
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
                              // Dropdown Jenis Kegiatan (Wajib)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedJenisKegiatan,
                                decoration: const InputDecoration(
                                  labelText: 'Jenis Kegiatan *',
                                  prefixIcon: Icon(CupertinoIcons.rectangle_grid_2x2),
                                ),
                                isExpanded: true,
                                items: _optionsData?.jenisKegiatan.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt.value,
                                    child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedJenisKegiatan = val;
                                  });
                                },
                                validator: (val) => val == null ? 'Pilih jenis kegiatan' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Judul Seminar / Workshop (Wajib)
                              TextFormField(
                                controller: _judulController,
                                decoration: const InputDecoration(
                                  labelText: 'Judul Seminar / Workshop *',
                                  hintText:
                                      'Contoh: Workshop Artificial Intelligence & Cloud',
                                  prefixIcon: Icon(CupertinoIcons.textbox),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Masukkan judul seminar/workshop' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Dropdown Sebagai (Wajib)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSebagai,
                                decoration: const InputDecoration(
                                  labelText: 'Peran / Sebagai *',
                                  prefixIcon: Icon(CupertinoIcons.person_badge_plus),
                                ),
                                isExpanded: true,
                                items: _optionsData?.sebagai.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt.value,
                                    child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedSebagai = val),
                                validator: (val) => val == null ? 'Pilih peran (sebagai)' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Dropdown Tingkatan (Opsional)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedTingkatan,
                                decoration: const InputDecoration(
                                  labelText: 'Tingkatan (Opsional)',
                                  prefixIcon: Icon(CupertinoIcons.globe),
                                ),
                                isExpanded: true,
                                items: _optionsData?.tingkatan.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt.value,
                                    child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedTingkatan = val),
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
                                    ? 'File Sertifikat/Bukti (Opsional jika tidak diganti)'
                                    : 'File Sertifikat/Bukti (PDF/Gambar)*',
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
                                              : 'Upload Seminar / Workshop',
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
