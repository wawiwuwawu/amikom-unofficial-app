import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'skpi_file_picker.dart';
import '../models/prestasi.dart';
import '../services/prestasi_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

class PrestasiFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final PrestasiItem? itemToEdit;

  const PrestasiFormSheet({
    super.key,
    required this.onSuccess,
    this.itemToEdit,
  });

  @override
  State<PrestasiFormSheet> createState() => _PrestasiFormSheetState();
}

class _PrestasiFormSheetState extends State<PrestasiFormSheet> {
  final _service = PrestasiService();
  final _formKey = GlobalKey<FormState>();

  PrestasiOptionsData? _optionsData;
  bool _isLoadingOptions = true;
  bool _isSubmitting = false;
  String? _error;

  String? _selectedJenisPrestasi;
  final _prestasiLainnyaController = TextEditingController();

  String? _selectedPrestasiPkm;
  String? _selectedKategoriPkm;
  final _kategoriPkmLainController = TextEditingController();

  String? _selectedPrestasi;
  final _kategoriController = TextEditingController();

  String? _selectedTingkatan;
  final _tahunController = TextEditingController(text: DateTime.now().year.toString());

  PlatformFile? _selectedFile;
  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.itemToEdit!;
      _kategoriController.text = item.perolehan;
      _prestasiLainnyaController.text = item.kejuaraan;
      _tahunController.text = item.tahun;
    }
    _loadOptions();
  }
  @override
  void dispose() {
    _prestasiLainnyaController.dispose();
    _kategoriPkmLainController.dispose();
    _kategoriController.dispose();
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

    if (_selectedJenisPrestasi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis prestasi terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formDataMap = <String, dynamic>{
        'jenis_prestasi': _selectedJenisPrestasi,
        'tahun': _tahunController.text.trim(),
      };

      if (_selectedJenisPrestasi == 'KEJUARAAN LAINNYA') {
        formDataMap['prestasi_lainnya'] = _prestasiLainnyaController.text.trim();
      } else if (_selectedJenisPrestasi == 'Program Kreativitas Mahasiswa (PKM)') {
        if (_selectedPrestasiPkm != null) {
          formDataMap['prestasi_pkm'] = _selectedPrestasiPkm;
        }
        if (_selectedKategoriPkm != null) {
          formDataMap['kategori_pkm'] = _selectedKategoriPkm;
        }
        if (_selectedKategoriPkm == 'Lainnya') {
          formDataMap['kategori_pkm_lain'] = _kategoriPkmLainController.text.trim();
        }
      } else {
        if (_selectedPrestasi != null) {
          formDataMap['prestasi'] = _selectedPrestasi;
        }
        if (_kategoriController.text.trim().isNotEmpty) {
          formDataMap['kategori'] = _kategoriController.text.trim();
        }
      }

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
        await _service.editPrestasi(widget.itemToEdit!.id, formData);
      } else {
        await _service.tambahPrestasi(formData);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Prestasi Mahasiswa berhasil diubah'
              : 'Prestasi Mahasiswa berhasil ditambahkan'),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Prestasi Mahasiswa' : 'Tambah Prestasi Mahasiswa',
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
                    ? const AppLoading(message: 'Memuat pilihan…')
                    : _error != null
                        ? AppErrorState(message: _error!, onRetry: _loadOptions)
                        : Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dropdown Jenis Prestasi (Wajib)
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedJenisPrestasi,
                                  decoration: const InputDecoration(
                                    labelText: 'Jenis Prestasi *',
                                    prefixIcon: Icon(CupertinoIcons.star),
                                  ),
                                  isExpanded: true,
                                  items: _optionsData?.jenisPrestasi.map((opt) {
                                    return DropdownMenuItem<String>(
                                      value: opt.value,
                                      child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedJenisPrestasi = val;
                                    });
                                  },
                                  validator: (val) => val == null ? 'Pilih jenis prestasi' : null,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Conditional Input: KEJUARAAN LAINNYA
                                if (_selectedJenisPrestasi == 'KEJUARAAN LAINNYA') ...[
                                  TextFormField(
                                    controller: _prestasiLainnyaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nama Prestasi / Kejuaraan Lainnya *',
                                      prefixIcon: Icon(CupertinoIcons.textbox),
                                    ),
                                    validator: (val) {
                                      if (_selectedJenisPrestasi == 'KEJUARAAN LAINNYA' &&
                                          (val == null || val.trim().isEmpty)) {
                                        return 'Masukkan nama kejuaraan/prestasi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],

                                // Conditional Input: Program Kreativitas Mahasiswa (PKM)
                                if (_selectedJenisPrestasi == 'Program Kreativitas Mahasiswa (PKM)') ...[
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedPrestasiPkm,
                                    decoration: const InputDecoration(
                                      labelText: 'Capaian Prestasi PKM',
                                      prefixIcon: Icon(CupertinoIcons.star),
                                    ),
                                    isExpanded: true,
                                    items: _optionsData?.prestasiPkm.map((opt) {
                                      return DropdownMenuItem<String>(
                                        value: opt.value,
                                        child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedPrestasiPkm = val),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedKategoriPkm,
                                    decoration: const InputDecoration(
                                      labelText: 'Kategori PKM',
                                      prefixIcon: Icon(CupertinoIcons.tag),
                                    ),
                                    isExpanded: true,
                                    items: _optionsData?.kategoriPkm.map((opt) {
                                      return DropdownMenuItem<String>(
                                        value: opt.value,
                                        child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedKategoriPkm = val),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  if (_selectedKategoriPkm == 'Lainnya') ...[
                                    TextFormField(
                                      controller: _kategoriPkmLainController,
                                      decoration: const InputDecoration(
                                        labelText: 'Kategori PKM Lainnya *',
                                        prefixIcon: Icon(CupertinoIcons.pencil),
                                      ),
                                      validator: (val) {
                                        if (_selectedKategoriPkm == 'Lainnya' &&
                                            (val == null || val.trim().isEmpty)) {
                                          return 'Masukkan kategori PKM lainnya';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                ],

                                // Conditional Input: Selain PKM & Selain Kejuaraan Lainnya
                                if (_selectedJenisPrestasi != null &&
                                    _selectedJenisPrestasi != 'KEJUARAAN LAINNYA' &&
                                    _selectedJenisPrestasi != 'Program Kreativitas Mahasiswa (PKM)') ...[
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedPrestasi,
                                    decoration: const InputDecoration(
                                      labelText: 'Capaian Prestasi / Perolehan',
                                      prefixIcon: Icon(CupertinoIcons.star_fill),
                                    ),
                                    isExpanded: true,
                                    items: _optionsData?.prestasi.map((opt) {
                                      return DropdownMenuItem<String>(
                                        value: opt.value,
                                        child: Text(opt.label, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedPrestasi = val),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  TextFormField(
                                    controller: _kategoriController,
                                    decoration: const InputDecoration(
                                      labelText: 'Kategori / Bidang',
                                      hintText: 'Contoh: Pemrograman / Olahraga / Seni',
                                      prefixIcon: Icon(CupertinoIcons.bookmark),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],

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
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'File saat ini: ${widget.itemToEdit!.file}',
                                    style: AppText.bodySm,
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
                                                strokeWidth: 2, color: Colors.white),
                                          )
                                        : Text(_isEditing ? 'Simpan Perubahan' : 'Upload Prestasi'),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
