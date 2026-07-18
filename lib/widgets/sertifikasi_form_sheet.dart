import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../models/sertifikasi.dart';
import '../services/sertifikasi_service.dart';
import 'glass_card.dart';

class SertifikasiFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const SertifikasiFormSheet({super.key, required this.onSuccess});

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

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
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
      final formData = FormData.fromMap({
        'judul': _selectedJudul,
        if (_selectedJudul == 'SERTIFIKASI LAINNYA') 'judul_lainnya': _judulLainnyaController.text,
        'nilai': _nilaiController.text,
        'tahun': _selectedTahun.toString(),
        'file_sertifikat': await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        ),
      });

      await _service.tambahSertifikasi(formData);

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sertifikasi berhasil ditambahkan')),
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFCFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _loadingOptions
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF501F66))),
                )
              : _error != null
                  ? SizedBox(
                      height: 200,
                      child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Tambah Sertifikasi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF501F66),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Dropdown Judul
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Judul Sertifikasi',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            value: _selectedJudul,
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
                          const SizedBox(height: 16),

                          // Field Judul Lainnya (Conditional)
                          if (_selectedJudul == 'SERTIFIKASI LAINNYA') ...[
                            TextFormField(
                              controller: _judulLainnyaController,
                              decoration: const InputDecoration(
                                labelText: 'Masukkan Judul Sertifikasi',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Field Nilai
                          TextFormField(
                            controller: _nilaiController,
                            decoration: const InputDecoration(
                              labelText: 'Nilai / Grade',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Dropdown Tahun
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Tahun Sertifikasi',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedTahun,
                            items: _getTahunList().map((thn) {
                              return DropdownMenuItem(
                                value: thn,
                                child: Text(thn.toString()),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedTahun = val),
                            validator: (val) => val == null ? 'Wajib dipilih' : null,
                          ),
                          const SizedBox(height: 16),

                          // Pemilih File PDF
                          InkWell(
                            onTap: _pickFile,
                            borderRadius: BorderRadius.circular(12),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              borderRadius: 12,
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.doc_text_fill, color: Color(0xFF501F66)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedFile != null ? _selectedFile!.name : 'Pilih file scan sertifikat (PDF)',
                                      style: TextStyle(
                                        color: _selectedFile != null ? Colors.black87 : Colors.black54,
                                        fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_selectedFile == null)
                                    const Icon(CupertinoIcons.paperclip, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
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
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Upload Sertifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
