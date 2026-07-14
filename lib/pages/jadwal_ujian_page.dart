import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../services/akademik_service.dart';
import '../models/jadwal_ujian.dart';
import '../widgets/glass_card.dart';

class JadwalUjianPage extends StatefulWidget {
  final VoidCallback? onBack;
  const JadwalUjianPage({super.key, this.onBack});

  @override
  State<JadwalUjianPage> createState() => _JadwalUjianPageState();
}

class _JadwalUjianPageState extends State<JadwalUjianPage> {
  final AkademikService _service = AkademikService();
  bool _isLoading = true;
  bool _isDownloading = false;
  String _error = '';
  List<JadwalUjian> _jadwalList = [];
  String _jenisUjian = 'uts'; // uts or uas

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
      final res = await _service.getJadwalUjian(_jenisUjian);
      
      // Sort by date logically if we want to ensure order, but API usually returns ordered.
      // We assume API order is good.
      setState(() {
        _jadwalList = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadKartu() async {
    setState(() => _isDownloading = true);
    try {
      final path = await _service.downloadKartuUjian(_jenisUjian);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Berhasil mengunduh kartu ujian'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'BUKA',
              textColor: Colors.white,
              onPressed: () {
                OpenFilex.open(path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _addToGoogleCalendar(JadwalUjian jadwal) async {
    // TANGGAL format: "08-07-2026"
    final parts = jadwal.tanggal.split('-');
    if (parts.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Format tanggal tidak valid')));
      return;
    }
    
    // YYYYMMDD
    final dateStr = '${parts[2]}${parts[1]}${parts[0]}';
    final startTimeStr = jadwal.jamMulai.replaceAll(':', '');
    final endTimeStr = jadwal.jamSelesai.replaceAll(':', '');
    
    final startDateTimeStr = '${dateStr}T${startTimeStr}Z';
    final endDateTimeStr = '${dateStr}T${endTimeStr}Z';

    final title = 'Ujian ${jadwal.mkl}';
    final details = 'Ruang: ${jadwal.ruang}\\nNo Kursi: ${jadwal.noKursi}';

    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&dates=$startDateTimeStr/$endDateTimeStr'
      '&details=${Uri.encodeComponent(details)}'
      '&location=${Uri.encodeComponent(jadwal.ruang)}'
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Tidak dapat membuka kalender');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
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
        title: const Text(
          'Jadwal Ujian',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withOpacity(0.5),
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
            // Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GlassCard(
                borderRadius: 25,
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(child: _buildTabButton('UTS', 'uts')),
                    Expanded(child: _buildTabButton('UAS', 'uas')),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
            
            // Content
            Expanded(
              child: _isLoading
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
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF501F66),
                          child: _jadwalList.isEmpty ? _buildEmptyState() : _buildList(),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _jadwalList.isNotEmpty && !_isLoading
          ? Padding(
              padding: const EdgeInsets.only(bottom: 140.0), // Ekstra padding yang lebih tinggi
              child: FloatingActionButton.extended(
                onPressed: _isDownloading ? null : _downloadKartu,
                backgroundColor: const Color(0xFF501F66),
                icon: _isDownloading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(CupertinoIcons.printer_fill, color: Colors.white),
                label: Text(
                  _isDownloading ? 'Mengunduh...' : 'Cetak Kartu Ujian',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn().scale(),
            )
          : null,
    );
  }

  Widget _buildTabButton(String title, String type) {
    final isSelected = _jenisUjian == type;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _jenisUjian = type;
            _loadData();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF501F66) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.sparkles, size: 64, color: Colors.green),
              ).animate().fadeIn().scale().then().shake(hz: 2, duration: 1000.ms),
              const SizedBox(height: 24),
              const Text(
                'Belum Waktunya Ujian Nih!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF501F66),
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Saat ini tidak ada jadwal ujian yang tersedia. Gunakan waktumu sebaik mungkin untuk belajar dan beristirahat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 200, // padding extra for FAB and Nav
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _jadwalList.length,
      itemBuilder: (context, index) {
        final jadwal = _jadwalList[index];
        return _buildJadwalCard(jadwal, index).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildJadwalCard(JadwalUjian jadwal, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        opacity: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF501F66).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        jadwal.tanggal.split('-')[0], // Day part
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF501F66)),
                      ),
                      Text(
                        jadwal.tanggal.split('-')[1], // Month part
                        style: const TextStyle(fontSize: 12, color: Color(0xFF501F66)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jadwal.mkl,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${jadwal.kode} • ${jadwal.hari}',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(CupertinoIcons.time, '${jadwal.jamMulai.substring(0, 5)} - ${jadwal.jamSelesai.substring(0, 5)}'),
                  ),
                  Expanded(
                    child: _buildInfoItem(CupertinoIcons.location, jadwal.ruang),
                  ),
                  Expanded(
                    child: _buildInfoItem(CupertinoIcons.number_circle, 'Kursi ${jadwal.noKursi}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToGoogleCalendar(jadwal),
                icon: const Icon(CupertinoIcons.calendar_badge_plus, size: 18),
                label: const Text('Ingatkan di Kalender'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF501F66),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF501F66), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF501F66)),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }
}
