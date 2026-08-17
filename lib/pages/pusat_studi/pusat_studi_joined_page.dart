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
  PusatStudiJoinedPageData? _pageData;

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
      final results = await Future.wait([
        _service.getJoinedDetail(widget.pusatStudi.id),
        _service.getJoinedPage(widget.pusatStudi.detailId),
      ]);
      if (mounted) {
        setState(() {
          _temaList = results[0] as List<JoinedDetailTema>;
          _pageData = results[1] as PusatStudiJoinedPageData?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _openWhatsAppGroup() async {
    final url = widget.pusatStudi.grupWa;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka link WhatsApp')),
        );
      }
    }
  }

  void _showProposeTemaDialog() {
    if (_pageData?.statusCode == 'diproses') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan Anda sedang diproses. Batalkan ajuan sebelum membuat ajuan baru.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
                        if (judulController.text.trim().isEmpty || deskripsiController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Judul dan Deskripsi wajib diisi')),
                          );
                          return;
                        }
                        setStateDialog(() => isSubmitting = true);
                        try {
                          final res = await _service.proposeTema(
                            widget.pusatStudi.id,
                            judulController.text,
                            deskripsiController.text,
                            rencanaController.text,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            final msg = res['message'] ?? 'Berhasil mengusulkan tema';
                            final isSuccess = res['success'] != false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: isSuccess ? Colors.green : Colors.red,
                              ),
                            );
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
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
    if (_pageData?.statusCode == 'diproses') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan Anda sedang diproses. Batalkan ajuan sebelum memilih tema baru.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
                        setStateDialog(() => isSubmitting = true);
                        try {
                          final res = await _service.chooseTema(
                            widget.pusatStudi.id,
                            tema.idTema,
                            tema.judulTema,
                            rencanaController.text,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            final msg = res['message'] ?? 'Berhasil memilih tema';
                            final isSuccess = res['success'] != false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: isSuccess ? Colors.green : Colors.red,
                              ),
                            );
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setStateDialog(() => isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Pilih Tema', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCancelAjuanConfirmation() async {
    final idAjuan = _pageData?.idAjuan;
    if (idAjuan == null || idAjuan.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Ajuan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
        content: const Text('Apakah Anda yakin ingin membatalkan ajuan tema ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _service.cancelAjuan(idAjuan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Ajuan tema berhasil dibatalkan'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildInfoBanner() {
    final banner = _pageData?.infoBanner;
    if (banner == null || banner.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF1976D2), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              banner,
              style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionAlert() {
    if (_pageData?.statusCode.toLowerCase().trim() != 'ditolak') return const SizedBox.shrink();
    final alasan = _pageData?.alasanDitolak;
    if (alasan == null || alasan.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFD32F2F), size: 20),
              SizedBox(width: 8),
              Text(
                'Ajuan Ditolak',
                style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alasan,
            style: const TextStyle(color: Color(0xFFC62828), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 6),
          const Text(
            'Silakan ajukan tema baru atau pilih tema yang tersedia di bawah.',
            style: TextStyle(color: Color(0xFFB71C1C), fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_pageData == null || (_pageData!.statusCode.isEmpty && _pageData!.detailPengajuan == null)) {
      return const SizedBox.shrink();
    }

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;
    final String rawStatus = _pageData!.statusCode.toLowerCase().trim();
    String statusLabel = _pageData!.statusText.isNotEmpty ? _pageData!.statusText : _pageData!.statusCode;

    if (rawStatus == 'diproses' || rawStatus == 'di proses') {
      badgeBg = const Color(0xFFE3F2FD);
      badgeText = const Color(0xFF1565C0);
      badgeIcon = CupertinoIcons.clock_fill;
    } else if (rawStatus == 'diterima' || rawStatus == 'acc') {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = const Color(0xFF2E7D32);
      badgeIcon = CupertinoIcons.checkmark_seal_fill;
    } else if (rawStatus == 'ditolak') {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = const Color(0xFFC62828);
      badgeIcon = CupertinoIcons.xmark_octagon_fill;
    } else {
      badgeBg = Colors.grey.shade200;
      badgeText = Colors.black87;
      badgeIcon = CupertinoIcons.info;
    }

    final detail = _pageData!.detailPengajuan;
    final bool isDiproses = rawStatus == 'diproses' || rawStatus == 'di proses';
    final bool isDiterima = rawStatus == 'diterima' || rawStatus == 'acc';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status Ajuan Tema',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 14, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(color: badgeText, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (detail != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (detail.rencanaJudul.isNotEmpty) ...[
                const Text('Rencana Judul:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detail.rencanaJudul, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
              ],
              if (detail.namaTema.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('Tema: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Expanded(child: Text(detail.namaTema, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (detail.jenisTema.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('Jenis: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(detail.jenisTema, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (detail.tanggalPengajuan.isNotEmpty)
                      Text(detail.tanggalPengajuan, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ],
            if (_pageData!.idAjuan != null && _pageData!.idAjuan!.isNotEmpty && isDiproses) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showCancelAjuanConfirmation,
                  icon: const Icon(CupertinoIcons.xmark_circle, color: Colors.red, size: 18),
                  label: const Text('Batalkan Ajuan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (_pageData!.canSubmitProposal && isDiterima) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status Ajuan Diterima! Silakan lanjutkan ke pengisian proposal skripsi.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.doc_text_fill, color: Colors.white, size: 18),
                  label: const Text('Pengisian Judul Proposal Skripsi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentStatus = _pageData?.statusCode.toLowerCase().trim() ?? '';
    final bool isDiprosesStatus = currentStatus == 'diproses' || currentStatus == 'di proses';
    final bool canChooseTema = !isDiprosesStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFF),
      appBar: AppBar(
        title: Text(widget.pusatStudi.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
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
              : ListView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                  children: [
                    _buildInfoBanner(),
                    _buildRejectionAlert(),
                    _buildStatusCard(),
                    if (_temaList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text('Belum ada tema tersedia', style: TextStyle(color: Colors.black54)),
                        ),
                      )
                    else
                      ...List.generate(_temaList.length, (index) {
                        final tema = _temaList[index];
                        final bool showPilihButton = tema.canChoose && !tema.isFull && canChooseTema;

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
                                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Penuh', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    else if (tema.isProposed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
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
                                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(tema.statusText, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ),
                                ],
                                if (showPilihButton) ...[
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
                      }),
                  ],
                ),
      floatingActionButton: canChooseTema
          ? FloatingActionButton.extended(
              onPressed: _showProposeTemaDialog,
              backgroundColor: const Color(0xFF501F66),
              icon: const Icon(CupertinoIcons.add, color: Colors.white),
              label: const Text('Usulkan Tema Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ).animate().slideY(begin: 1.0, duration: 300.ms).fadeIn()
          : null,
    );
  }
}
