import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'skpi_file_picker.dart';
import '../models/rekognisi.dart';
import '../services/rekognisi_service.dart';

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
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
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
          color: Color(0xFFFAFCFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Rekognisi Mahasiswa' : 'Tambah Rekognisi Mahasiswa',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF501F66),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isLoadingOptions
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _error != null
                      ? Column(
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadOptions,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dropdown Jenis Rekognisi (Judul)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedJudul,
                                decoration: InputDecoration(
                                  labelText: 'Jenis Rekognisi *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(CupertinoIcons.rosette),
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
                              const SizedBox(height: 16),

                              // Dropdown Tingkat
                              DropdownButtonFormField<String>(
                                initialValue: _selectedTingkat,
                                decoration: InputDecoration(
                                  labelText: 'Tingkat *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(CupertinoIcons.globe),
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
                              const SizedBox(height: 16),

                              // Dropdown Kontribusi (Opsional)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedKontribusi,
                                decoration: InputDecoration(
                                  labelText: 'Kontribusi (Opsional)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(CupertinoIcons.person_badge_plus),
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
                              const SizedBox(height: 16),

                              // Input Link URL
                              TextFormField(
                                controller: _linkController,
                                keyboardType: TextInputType.url,
                                decoration: InputDecoration(
                                  labelText: 'Tautan / Link Berita (Opsional)',
                                  hintText: 'https://...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(CupertinoIcons.link),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Input Tahun (Wajib)
                              TextFormField(
                                controller: _tahunController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Tahun *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(CupertinoIcons.calendar),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Masukkan tahun' : null,
                              ),
                              const SizedBox(height: 16),

                              SkpiFilePicker(
                                selectedFile: _selectedFile,
                                label: _isEditing
                                    ? 'File Scan Bukti (Opsional jika tidak diganti)'
                                    : 'File Scan Bukti (PDF)*',
                                allowedExtensions: const ['pdf'],
                                onFileSelected: (file) => setState(() => _selectedFile = file),
                              ),
                              if (_isEditing && _selectedFile == null && widget.itemToEdit!.file.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'File saat ini: ${widget.itemToEdit!.file}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Tombol Submit
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF501F66),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white),
                                        )
                                      : Text(
                                          _isEditing ? 'Simpan Perubahan' : 'Upload Rekognisi',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
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
