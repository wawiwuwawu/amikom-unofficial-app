import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/notifikasi.dart';
import '../services/notifikasi_service.dart';
import '../services/api_client.dart';
import '../widgets/glass_card.dart';
import 'pengumuman_detail_page.dart';

class NotifikasiListPage extends StatefulWidget {
  final VoidCallback? onBack;

  const NotifikasiListPage({super.key, this.onBack});

  @override
  State<NotifikasiListPage> createState() => _NotifikasiListPageState();
}

class _NotifikasiListPageState extends State<NotifikasiListPage> {
  final _service = NotifikasiService();
  List<NotifikasiItem> _list = [];
  Set<String> _readIds = {};
  bool _loading = true;
  String? _error;

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
      final data = await _service.getNotifikasi();
      final readSet = await _service.getReadIds();
      if (mounted) {
        setState(() {
          _list = data;
          _readIds = readSet;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _retryWithSilentLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await ApiClient.instance.ensureSessionOrSilentLogin();
    await _loadData();
  }

  Future<void> _markAllAsRead() async {
    final allIds = _list.map((e) => e.id).toList();
    await _service.markAllAsRead(allIds);
    final readSet = await _service.getReadIds();
    setState(() {
      _readIds = readSet;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai telah dibaca'),
        backgroundColor: Color(0xFF501F66),
      ),
    );
  }

  Future<void> _onTapItem(NotifikasiItem item) async {
    await _service.markAsRead(item.id);
    final readSet = await _service.getReadIds();
    setState(() {
      _readIds = readSet;
    });

    final targetId = int.tryParse(item.id) ?? 0;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PengumumanDetailPage(id: targetId),
      ),
    );
  }

  bool get _hasUnread => _list.any((item) => !_readIds.contains(item.id));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFCFF), // Pearl White
            Color(0xFFE3F2FD), // Ice Blue
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Notifikasi & Pengumuman',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white.withOpacity(0.5),
          leading: widget.onBack != null
              ? IconButton(
                  icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                  onPressed: widget.onBack,
                )
              : (Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null),
          elevation: 0,
          actions: [
            if (_list.isNotEmpty && _hasUnread)
              TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(CupertinoIcons.checkmark_seal_fill,
                    size: 16, color: Color(0xFF501F66)),
                label: const Text(
                  'Tandai Dibaca',
                  style: TextStyle(
                    color: Color(0xFF501F66),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF501F66),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_circle,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _retryWithSilentLogin,
                              icon: const Icon(CupertinoIcons.refresh),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF501F66),
                                foregroundColor: Colors.white,
                              ),
                              label: const Text('Coba Lagi / Re-connect'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _list.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.bell_slash,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Tidak ada notifikasi saat ini',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final item = _list[index];
                            final isRead = _readIds.contains(item.id);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => _onTapItem(item),
                                borderRadius: BorderRadius.circular(16),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  borderRadius: 16,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(
                                          isRead
                                              ? CupertinoIcons.bell
                                              : CupertinoIcons.bell_fill,
                                          color: isRead
                                              ? Colors.grey.shade500
                                              : const Color(0xFF501F66),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.judul,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isRead
                                                          ? FontWeight.normal
                                                          : FontWeight.bold,
                                                      color: isRead
                                                          ? Colors.black87
                                                          : const Color(0xFF501F66),
                                                    ),
                                                  ),
                                                ),
                                                if (!isRead) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(CupertinoIcons.calendar,
                                                    size: 13, color: Colors.grey.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item.tanggal,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(CupertinoIcons.chevron_right,
                                          size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn().slideY(
                                begin: 0.1, delay: Duration(milliseconds: 40 * index));
                          },
                        ),
        ),
      ),
    );
  }
}
