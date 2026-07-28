import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../models/seminar_workshop.dart';
import '../services/seminar_workshop_service.dart';
import 'glass_card.dart';

class SeminarWorkshopFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const SeminarWorkshopFormSheet({super.key, required this.onSuccess});

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

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
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
      await _service.tambahSeminarWorkshop(formData);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seminar / Workshop berhasil ditambahkan'),
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
                  const Text(
                    'Tambah Seminar / Workshop',
                    style: TextStyle(
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
                              // Dropdown Jenis Kegiatan (Wajib)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedJenisKegiatan,
                                decoration: InputDecoration(
                                  labelText: 'Jenis Kegiatan *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(CupertinoIcons.rectangle_grid_2x2),
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
                              const SizedBox(height: 16),

                              // Judul Seminar / Workshop (Wajib)
                              TextFormField(
                                controller: _judulController,
                                decoration: InputDecoration(
                                  labelText: 'Judul Seminar / Workshop *',
                                  hintText: 'Contoh: Workshop Artificial Intelligence & Cloud',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(CupertinoIcons.textbox),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Masukkan judul seminar/workshop' : null,
                              ),
                              const SizedBox(height: 16),

                              // Dropdown Sebagai (Wajib)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSebagai,
                                decoration: InputDecoration(
                                  labelText: 'Peran / Sebagai *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(CupertinoIcons.person_badge_plus),
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
                              const SizedBox(height: 16),

                              // Dropdown Tingkatan (Opsional)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedTingkatan,
                                decoration: InputDecoration(
                                  labelText: 'Tingkatan (Opsional)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(CupertinoIcons.globe),
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

                              // Picker File Sertifikat
                              GlassCard(
                                padding: const EdgeInsets.all(12),
                                borderRadius: 12,
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.doc_fill, color: Color(0xFF501F66)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedFile != null
                                            ? _selectedFile!.name
                                            : 'Pilih File Sertifikat/Bukti (PDF/Gambar)',
                                        style: TextStyle(
                                          color: _selectedFile != null
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _pickFile,
                                      child: Text(_selectedFile != null ? 'Ganti' : 'Pilih'),
                                    ),
                                  ],
                                ),
                              ),
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
                                      : const Text('Upload Seminar / Workshop',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
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
