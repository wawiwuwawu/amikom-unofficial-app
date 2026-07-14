import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mbkm.dart';
import '../services/mbkm_service.dart';
import '../widgets/glass_card.dart';
import 'mbkm_bimbingan_page.dart';

class MbkmPage extends StatefulWidget {
  final VoidCallback? onBack;
  const MbkmPage({super.key, this.onBack});

  @override
  State<MbkmPage> createState() => _MbkmPageState();
}

class _MbkmPageState extends State<MbkmPage> {
  final _service = MbkmService();
  bool _loading = true;
  String? _error;
  List<MbkmFakultas> _list = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _service.getDaftarMBKM();
      if (mounted) {
        setState(() => _list = res);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                onPressed: widget.onBack,
              )
            : null,
        title: const Text('MBKM Internal Kampus', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withValues(alpha: 0.5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)))
            : _error != null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle, size: 64, color: Colors.redAccent)
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF501F66),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_person, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Anda belum terdaftar di program MBKM',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        itemCount: _list.length,
        itemBuilder: (context, index) {
          final item = _list[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF501F66).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.program,
                          style: const TextStyle(color: Color(0xFF501F66), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${item.thnAkademik} - ${item.semester}',
                        style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.mitra,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.person_solid, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(item.nama, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.person_3_fill, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Dosbing: ${item.dosbing}',
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusBadge(
                        label: 'Komitmen',
                        isUploaded: item.komitmen == '1',
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(
                        label: 'Luaran',
                        isUploaded: item.fileLolos.isNotEmpty,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.black12),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MbkmBimbinganPage(mbkm: item))),
                      icon: const Icon(CupertinoIcons.list_bullet),
                      label: const Text('Log Bimbingan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF501F66),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: item.komitmen == '1' ? null : () => _showUploadKomitmen(item),
                          icon: const Icon(CupertinoIcons.doc_text, size: 16),
                          label: Text(item.komitmen == '1' ? 'Selesai' : 'Komitmen', style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF501F66),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: item.komitmen == '1' ? Colors.grey.shade300 : const Color(0xFF501F66).withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: item.fileLolos.isNotEmpty ? null : () => _showUploadLuaran(item),
                          icon: const Icon(CupertinoIcons.rocket, size: 16),
                          label: Text(item.fileLolos.isNotEmpty ? 'Selesai' : 'Luaran', style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF501F66),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: item.fileLolos.isNotEmpty ? Colors.grey.shade300 : const Color(0xFF501F66).withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (100 + index * 100).ms).slideY(begin: 0.1, end: 0),
          );
        },
      ),
    );
  }
  void _showUploadKomitmen(MbkmFakultas mbkm) {
    String? komitmenPath;
    String? pembayaranPath;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16, right: 16, top: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upload Dokumen Komitmen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
                const SizedBox(height: 16),
                _buildFilePicker(
                  label: 'Surat Komitmen (PDF)',
                  path: komitmenPath,
                  onPick: () async {
                    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                    if (result != null) setSheetState(() => komitmenPath = result.files.single.path);
                  },
                ),
                const SizedBox(height: 12),
                _buildFilePicker(
                  label: 'Bukti Pembayaran (PDF/JPG/PNG)',
                  path: pembayaranPath,
                  onPick: () async {
                    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
                    if (result != null) setSheetState(() => pembayaranPath = result.files.single.path);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isSubmitting || komitmenPath == null || pembayaranPath == null) ? null : () async {
                      setSheetState(() => isSubmitting = true);
                      try {
                        await _service.uploadKomitmen(mbkm.id, komitmenPath!, pembayaranPath!);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil upload dokumen komitmen'), backgroundColor: Colors.green));
                          _loadData();
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
                      } finally {
                        if (mounted) setSheetState(() => isSubmitting = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF501F66),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Upload', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUploadLuaran(MbkmFakultas mbkm) {
    String? luaranPath;
    String jenis = '';
    final linkController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16, right: 16, top: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upload File Luaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
                const SizedBox(height: 16),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(
                    labelText: 'Link Laporan (Google Drive)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: jenis.isEmpty ? null : jenis,
                  items: const [
                    DropdownMenuItem(value: 'Proposal PKM', child: Text('Proposal PKM')),
                    DropdownMenuItem(value: 'HKI', child: Text('HKI')),
                    DropdownMenuItem(value: 'Jurnal', child: Text('Jurnal')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => jenis = val);
                  },
                  decoration: InputDecoration(
                    labelText: 'Jenis Luaran',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFilePicker(
                  label: 'File Luaran (PDF)',
                  path: luaranPath,
                  onPick: () async {
                    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                    if (result != null) setSheetState(() => luaranPath = result.files.single.path);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isSubmitting || luaranPath == null) ? null : () async {
                      if (linkController.text.trim().isEmpty || jenis.trim().isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi semua field'), backgroundColor: Colors.red));
                         return;
                      }
                      setSheetState(() => isSubmitting = true);
                      try {
                        await _service.uploadLuaran(mbkm.id, linkController.text, jenis, luaranPath!);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil upload luaran'), backgroundColor: Colors.green));
                          _loadData();
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
                      } finally {
                        if (mounted) setSheetState(() => isSubmitting = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF501F66),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Upload', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilePicker({required String label, required String? path, required VoidCallback onPick}) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.folder, color: path == null ? Colors.grey : const Color(0xFF501F66)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  if (path != null)
                    Text(path.split('/').last, style: const TextStyle(color: Colors.black54, fontSize: 11), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (path != null) const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({required String label, required bool isUploaded}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUploaded ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isUploaded ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUploaded ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.clock_fill,
            size: 12,
            color: isUploaded ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ${isUploaded ? "Sudah Upload" : "Belum Upload"}',
            style: TextStyle(
              color: isUploaded ? Colors.green.shade800 : Colors.orange.shade800,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
