import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../models/organisasi.dart';
import '../services/organisasi_service.dart';
import 'glass_card.dart';

class OrganisasiFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const OrganisasiFormSheet({super.key, required this.onSuccess});

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

  @override
  void initState() {
    super.initState();
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
        const SnackBar(content: Text('Silakan pilih file pengesahan (PDF)')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final isKepanitiaan = _selectedOrganisasi?.toLowerCase() == 'kepanitiaan';
      final isJabatanLainnya = _selectedJabatan?.toLowerCase() == 'lainnya';

      final formData = FormData.fromMap({
        'organisasi': _selectedOrganisasi,
        if (isKepanitiaan) 'nama_kegiatan_kepanitiaan': _kegiatanController.text,
        'jabatan': _selectedJabatan,
        if (isJabatanLainnya) 'jabatan_lainnya': _jabatanLainnyaController.text,
        'tahun': _selectedTahun.toString(),
        'file_pengesahan': await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        ),
      });

      await _service.tambahOrganisasi(formData);

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organisasi berhasil ditambahkan')),
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
                            'Tambah Organisasi / Kepanitiaan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF501F66),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Dropdown Organisasi
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Organisasi',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            value: _selectedOrganisasi,
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
                          const SizedBox(height: 16),

                          // Field Kepanitiaan (Conditional)
                          if (_selectedOrganisasi?.toLowerCase() == 'kepanitiaan') ...[
                            TextFormField(
                              controller: _kegiatanController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Kegiatan Kepanitiaan',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Dropdown Jabatan
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Jabatan',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            value: _selectedJabatan,
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
                          const SizedBox(height: 16),

                          // Field Jabatan Lainnya (Conditional)
                          if (_selectedJabatan?.toLowerCase() == 'lainnya') ...[
                            TextFormField(
                              controller: _jabatanLainnyaController,
                              decoration: const InputDecoration(
                                labelText: 'Masukkan Jabatan Lainnya',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Dropdown Tahun
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Tahun',
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
                                      _selectedFile != null ? _selectedFile!.name : 'Pilih dokumen pengesahan (PDF)',
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
                                : const Text('Upload Dokumen', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
