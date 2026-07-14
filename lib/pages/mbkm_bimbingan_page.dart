import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' as md;
import '../models/mbkm.dart';
import '../services/mbkm_service.dart';
import '../widgets/glass_card.dart';

class MbkmBimbinganPage extends StatefulWidget {
  final MbkmFakultas mbkm;
  const MbkmBimbinganPage({super.key, required this.mbkm});

  @override
  State<MbkmBimbinganPage> createState() => _MbkmBimbinganPageState();
}

class _MbkmBimbinganPageState extends State<MbkmBimbinganPage> {
  final _service = MbkmService();
  bool _loading = true;
  String? _error;
  List<MbkmBimbingan> _list = [];

  final TextEditingController _inputController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _service.getBimbingan(widget.mbkm.id);
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

  Future<void> _hapusBimbingan(String idBimbingan) async {
    // Note: The API delete endpoint requires the specific bimbingan ID.
    // In our model, we have `no` (which is often just a row number) and `aksi`.
    // Let's assume `aksi` or `no` is the id, or we might need to extract the ID from HTML.
    // For now we'll pass `idBimbingan` which might be mapped to `no`.
    
    // Show confirmation
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Bimbingan?'),
        content: const Text('Apakah Anda yakin ingin menghapus data bimbingan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.hapusBimbingan(idBimbingan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menghapus bimbingan'), backgroundColor: Colors.green),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _tambahBimbingan() {
    _inputController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInputBottomSheet(),
    );
  }

  Future<void> _submitBimbingan() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    
    // Convert Markdown to HTML
    // E.g. # Title -> <h1>Title</h1>
    // Newlines will be converted to <p> or <br> correctly by markdown package.
    final htmlContent = md.markdownToHtml(
      _inputController.text, 
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    try {
      await _service.tambahBimbingan(widget.mbkm.id, htmlContent);
      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menambah bimbingan'), backgroundColor: Colors.green),
        );
        _loadData(); // refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = _inputController.text;
    final selection = _inputController.selection;
    if (selection.start == -1) {
      _inputController.text = '$text$prefix$suffix';
      return;
    }
    final newText = text.replaceRange(selection.start, selection.end, '$prefix${text.substring(selection.start, selection.end)}$suffix');
    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + prefix.length + (selection.end - selection.start)),
    );
  }

  Widget _buildInputBottomSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambah Log Bimbingan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
              const SizedBox(height: 12),
              // Toolbar Markdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.bold, size: 20),
                      onPressed: () => _insertMarkdown('**', '**'),
                      tooltip: 'Tebal',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.textformat_size, size: 20), // H1
                      onPressed: () => _insertMarkdown('# ', ''),
                      tooltip: 'Heading 1',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.textformat_size, size: 16), // H2
                      onPressed: () => _insertMarkdown('## ', ''),
                      tooltip: 'Heading 2',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.list_bullet, size: 20),
                      onPressed: () => _insertMarkdown('- ', ''),
                      tooltip: 'List',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _inputController,
                maxLines: 8,
                minLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ketik laporan bimbingan di sini...\n(Mendukung format Markdown: **Tebal**, # Judul)',
                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF501F66), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () {
                    setSheetState(() => _isSubmitting = true);
                    _submitBimbingan().then((_) {
                      if (mounted) setSheetState(() => _isSubmitting = false);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF501F66),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kirim Bimbingan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Log Bimbingan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
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
        child: Column(
          children: [
            _buildHeaderCard(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)))
                  : _error != null
                      ? _buildErrorState()
                      : _buildList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahBimbingan,
        backgroundColor: const Color(0xFF501F66),
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.mbkm.mitra, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66))),
          const SizedBox(height: 4),
          Text(widget.mbkm.program, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text('Dosbing: ${widget.mbkm.dosbing}', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66), foregroundColor: Colors.white),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_text, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Belum ada log bimbingan', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ).animate().fadeIn(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        itemCount: _list.length,
        itemBuilder: (context, index) {
          final item = _list[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.calendar, size: 16, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(item.tanggal, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.status.toLowerCase() == 'valid' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(
                                  color: item.status.toLowerCase() == 'valid' ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        // Action menu for delete, only if status is not valid
                        if (item.no.isNotEmpty && item.status.toLowerCase() != 'valid') ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _hapusBimbingan(item.no),
                            child: const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black12),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Html(
                      data: item.bimbingan,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(14.0),
                          color: Colors.black87,
                          lineHeight: LineHeight.number(1.5),
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (50 * index).clamp(0, 500).ms).slideX(begin: 0.1, end: 0),
          );
        },
      ),
    );
  }
}
