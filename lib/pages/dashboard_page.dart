import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';
import '../widgets/glass_card.dart';
import 'absensi_page.dart';

class DashboardPage extends StatefulWidget {
  final int refreshTrigger;
  const DashboardPage({super.key, this.refreshTrigger = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _service = DashboardService();
  Dashboard? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: const CircularProgressIndicator(color: Color(0xFFBBDEFB)) // Ice Blue
            .animate()
            .scale(duration: 400.ms, curve: Curves.easeOutBack),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, size: 64, color: Colors.redAccent)
                .animate()
                .shake(),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBDEFB),
                foregroundColor: const Color(0xFF501F66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    if (_data == null) return const SizedBox.shrink();

    final d = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF501F66),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // padding bottom for dock
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          _buildGreeting(d.profile).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _buildProfileCard(d.profile).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          _buildQuickPresensiBanner().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          _buildInfoPenting(d).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('IPK', d.statistik.ipk.toStringAsFixed(2), CupertinoIcons.rosette).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Total SKS', d.statistik.totalSks.toString(), CupertinoIcons.book_fill).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(Profile p) {
    final namaDepan = p.nama.split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $namaDepan!',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF501F66),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          p.prodi,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPresensiBanner() {
    return GlassCard(
      padding: EdgeInsets.zero,
      opacity: 0.8,
      gradient: const LinearGradient(
        colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // Ice Blue gradient
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: InkWell(
        onTap: () {
          // Tell user to tap the main FAB instead, or we can use Navigator.push if they really want,
          // but since they didn't like the weird presensi routing, we'll route it manually if possible.
          // Since we are inside Dashboard which is inside MainPage, we can't easily change the parent's state without a callback.
          // For now, let's just push it, or we can use the FAB. Let's just push AbsensiPage for this banner.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AbsensiPage()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF501F66).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.qrcode_viewfinder, color: Color(0xFF501F66), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Jangan Lupa Presensi!',
                      style: TextStyle(
                        color: Color(0xFF501F66),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ketuk di sini untuk scan QR kelasmu sekarang.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, color: Color(0xFF501F66)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPenting(Dashboard d) {
    if (d.status.status != 'Aktif' || d.status.status.isEmpty) {
      return _buildAlert(
          CupertinoIcons.exclamationmark_triangle, 'Pembayaran pending', Colors.orange);
    }
    return const SizedBox.shrink();
  }

  Widget _buildAlert(IconData icon, String message, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF501F66)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF501F66),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Profile p) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFBBDEFB).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.person_crop_circle_fill, size: 32, color: Color(0xFF501F66)),
            ),
            title: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('${p.npm} • ${p.prodi}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ),
          const Divider(height: 1, color: Colors.black12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _profileInfo(CupertinoIcons.calendar, 'Angkatan', p.angkatan.toString()),
                    _profileInfo(CupertinoIcons.building_2_fill, 'Fakultas', p.fakultas),
                    _profileInfo(CupertinoIcons.phone_fill, 'No HP', p.noHp.isNotEmpty ? p.noHp : '-'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.mail_solid, size: 16, color: Color(0xFF501F66)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(p.email, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.person_2_fill, size: 16, color: Color(0xFF501F66)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'DPA: ${p.pembimbingAkademik}', 
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfo(IconData icon, String title, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.black45, size: 20),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        Text(
          text, 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
