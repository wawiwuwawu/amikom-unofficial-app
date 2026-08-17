import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/ujian_susulan.dart';
import '../services/ujian_susulan_service.dart';
import '../widgets/glass_card.dart';

class UjianSusulanPage extends StatefulWidget {
  final VoidCallback? onBack;

  const UjianSusulanPage({super.key, this.onBack});

  @override
  State<UjianSusulanPage> createState() => _UjianSusulanPageState();
}

class _UjianSusulanPageState extends State<UjianSusulanPage> {
  final UjianSusulanService _service = UjianSusulanService();

  bool _isLoadingUts = true;
  String _errorUts = '';
  UjianSusulanData? _utsData;

  bool _isLoadingUas = true;
  String _errorUas = '';
  UjianSusulanData? _uasData;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchUts(),
      _fetchUas(),
    ]);
  }

  Future<void> _fetchUts() async {
    setState(() {
      _isLoadingUts = true;
      _errorUts = '';
    });
    try {
      final res = await _service.getUtsData();
      if (mounted) {
        setState(() {
          _utsData = res;
          _isLoadingUts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorUts = e.toString().replaceFirst('Exception: ', '');
          _isLoadingUts = false;
        });
      }
    }
  }

  Future<void> _fetchUas() async {
    setState(() {
      _isLoadingUas = true;
      _errorUas = '';
    });
    try {
      final res = await _service.getUasData();
      if (mounted) {
        setState(() {
          _uasData = res;
          _isLoadingUas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorUas = e.toString().replaceFirst('Exception: ', '');
          _isLoadingUas = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFCFF),
        appBar: AppBar(
          title: const Text(
            'Ujian Susulan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF501F66),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF501F66),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(CupertinoIcons.doc_text_search),
                text: 'UTS Susulan',
              ),
              Tab(
                icon: Icon(CupertinoIcons.doc_checkmark),
                text: 'UAS Susulan',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabContent(isUts: true),
            _buildTabContent(isUts: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent({required bool isUts}) {
    final bool isLoading = isUts ? _isLoadingUts : _isLoadingUas;
    final String error = isUts ? _errorUts : _errorUas;
    final UjianSusulanData? data = isUts ? _utsData : _uasData;
    final Future<void> Function() onRefresh = isUts ? _fetchUts : _fetchUas;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)));
    }

    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (data == null || !data.isAvailable) {
      final msg = data?.message.isNotEmpty == true
          ? data!.message
          : 'Mohon maaf, Jadwal Belum Tersedia';

      return RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFF501F66),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: const Icon(CupertinoIcons.calendar_badge_minus, size: 64, color: Color(0xFFE65100)),
              ).animate().scale(duration: 500.ms),
            ),
            const SizedBox(height: 24),
            Text(
              isUts ? 'Jadwal Ujian Susulan UTS' : 'Jadwal Ujian Susulan UAS',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
            ),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF1976D2), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pendaftaran dan jadwal ujian susulan ditentukan oleh Bagian Akademik Amikom. Silakan cek secara berkala.',
                      style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // When Available == true
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF501F66),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Available Header Card
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.message,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF501F66)),
                      ),
                    ),
                  ],
                ),
                if (data.badges.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: data.badges.map((b) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF501F66).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF501F66).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          b.value,
                          style: const TextStyle(color: Color(0xFF501F66), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),

          if (data.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('Belum ada matakuliah ujian susulan yang terdaftar', style: TextStyle(color: Colors.black54)),
              ),
            )
          else
            ...List.generate(data.items.length, (index) {
              final item = data.items[index];

              Color badgeBg;
              Color badgeText;
              IconData badgeIcon;

              switch (item.status.toLowerCase().trim()) {
                case 'diajukan':
                  badgeBg = const Color(0xFFFFF3E0);
                  badgeText = const Color(0xFFE65100);
                  badgeIcon = CupertinoIcons.clock_fill;
                  break;
                case 'diproses':
                  badgeBg = const Color(0xFFE3F2FD);
                  badgeText = const Color(0xFF1565C0);
                  badgeIcon = CupertinoIcons.gear_alt_fill;
                  break;
                case 'diterima':
                case 'disetujui':
                  badgeBg = const Color(0xFFE8F5E9);
                  badgeText = const Color(0xFF2E7D32);
                  badgeIcon = CupertinoIcons.checkmark_seal_fill;
                  break;
                case 'ditolak':
                  badgeBg = const Color(0xFFFFEBEE);
                  badgeText = const Color(0xFFC62828);
                  badgeIcon = CupertinoIcons.xmark_octagon_fill;
                  break;
                default:
                  badgeBg = Colors.grey.shade200;
                  badgeText = Colors.black87;
                  badgeIcon = CupertinoIcons.info;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.mkl,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
                            ),
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
                                  item.status,
                                  style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildDetailRow('Kode MK:', item.kode),
                      const SizedBox(height: 4),
                      _buildDetailRow('SKS & Kelas:', '${item.sks} SKS • Kelas ${item.kelas}'),
                      if (item.dosen.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildDetailRow('Dosen:', item.dosen),
                      ],
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (50 * index).ms);
            }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
      ],
    );
  }
}
