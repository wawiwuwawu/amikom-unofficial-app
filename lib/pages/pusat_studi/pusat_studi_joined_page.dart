import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/expandable_html.dart';
import '../../models/pusat_studi.dart';
import '../../services/pusat_studi_service.dart';
import '../../widgets/glass_card.dart';
import 'pusat_studi_detail_page.dart';

class PusatStudiJoinedPage extends StatefulWidget {
  final PusatStudi pusatStudi;

  const PusatStudiJoinedPage({super.key, required this.pusatStudi});

  @override
  State<PusatStudiJoinedPage> createState() => _PusatStudiJoinedPageState();
}

class _PusatStudiJoinedPageState extends State<PusatStudiJoinedPage> {
  final PusatStudiService _service = PusatStudiService();
  bool _isLoading = true;
  String _error = '';
  List<JoinedDetailTema> _temaList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      _temaList = await _service.getJoinedDetail(widget.pusatStudi.id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openWhatsAppGroup() async {
    final url = widget.pusatStudi.grupWa;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka link WhatsApp')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link grup WhatsApp belum tersedia.')));
    }
  }

  void _showProposeTemaDialog() {
    final judulController = TextEditingController();
    final deskripsiController = TextEditingController();
    final rencanaController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Usulkan Tema Baru', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: judulController,
                    decoration: const InputDecoration(labelText: 'Judul Tema', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deskripsiController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Deskripsi Tema', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rencanaController,
                    decoration: const InputDecoration(labelText: 'Rencana Judul Anda', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (judulController.text.isEmpty || deskripsiController.text.isEmpty || rencanaController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi semua field')));
                          return;
                        }
                        setStateDialog(() => isSubmitting = true);
                        try {
                          await _service.proposeTema(
                            widget.pusatStudi.id,
                            judulController.text,
                            deskripsiController.text,
                            rencanaController.text,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil mengusulkan tema'), backgroundColor: Colors.green));
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
                          }
                        } finally {
                          if (mounted) setStateDialog(() => isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
                child: isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Usulkan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChooseTemaDialog(JoinedDetailTema tema) {
    final rencanaController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Pilih Tema', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anda akan memilih tema:\n${tema.judulTema}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: rencanaController,
                    decoration: const InputDecoration(
                      labelText: 'Rencana Judul Anda (Opsional / Wajib)', 
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (rencanaController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi rencana judul')));
                          return;
                        }
                        setStateDialog(() => isSubmitting = true);
                        try {
                          await _service.chooseTema(
                            widget.pusatStudi.id,
                            tema.idTema,
                            tema.judulTema,
                            rencanaController.text,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil memilih tema'), backgroundColor: Colors.green));
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
                          }
                        } finally {
                          if (mounted) setStateDialog(() => isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
                child: isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFF),
      appBar: AppBar(
        title: Text(widget.pusatStudi.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF501F66)),
        actions: [
          if (widget.pusatStudi.grupWa != null && widget.pusatStudi.grupWa!.isNotEmpty)
            IconButton(
              icon: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.green),
              tooltip: 'Grup WhatsApp',
              onPressed: _openWhatsAppGroup,
            ),
          IconButton(
            icon: const Icon(CupertinoIcons.info_circle_fill),
            tooltip: 'Profil Pusat Studi',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PusatStudiDetailPage(pusatStudi: widget.pusatStudi, isJoined: true),
              ));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)))
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, size: 50, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Coba Lagi'),
                      )
                    ],
                  ),
                )
              : _temaList.isEmpty
                  ? const Center(child: Text('Belum ada tema tersedia', style: TextStyle(color: Colors.black54)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                      itemCount: _temaList.length,
                      itemBuilder: (context, index) {
                        final tema = _temaList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: GlassCard(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tema.judulTema,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66)),
                                      ),
                                    ),
                                    if (tema.isFull)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Penuh', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    else if (tema.isProposed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Usulan Saya', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ExpandableHtml(htmlData: tema.deskripsi),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(CupertinoIcons.person_solid, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(tema.pengusul, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                                    const SizedBox(width: 8),
                                    Text('Kuota: ${tema.kuota}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ],
                                ),
                                if (tema.statusText.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(tema.statusText, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ),
                                ],
                                if (tema.canChoose && !tema.isFull) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showChooseTemaDialog(tema),
                                      icon: const Icon(CupertinoIcons.check_mark_circled, color: Color(0xFF501F66)),
                                      label: const Text('Pilih Tema Ini', style: TextStyle(color: Color(0xFF501F66))),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF501F66)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  )
                                ]
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1);
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showProposeTemaDialog,
        backgroundColor: const Color(0xFF501F66),
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text('Usulkan Tema Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().slideY(begin: 1.0, duration: 300.ms).fadeIn(),
    );
  }
}
