import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/dashboard.dart';
import '../models/agenda_terpadu.dart';
import '../models/sp.dart';
import '../services/dashboard_service.dart';
import '../services/agenda_service.dart';
import '../services/sp_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/histori_ipk_sheet.dart';
import 'absensi_page.dart';
import 'jadwal_page.dart';
import 'sp_page.dart';

class DashboardPage extends StatefulWidget {
  final int refreshTrigger;
  const DashboardPage({super.key, this.refreshTrigger = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _service = DashboardService();
  final _agendaService = AgendaService();
  final _spService = SpService();

  Dashboard? _data;
  AgendaTerpaduData? _agendaData;
  SpRekomendasiData? _spRekomendasiData;
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
      final results = await Future.wait([
        _service.getDashboard(),
        _agendaService.getAgendaTerpadu().catchError((_) => AgendaTerpaduData(totalAgenda: 0, agenda: {})),
        _spService.getRekomendasi().catchError((_) => SpRekomendasiData(
          hasRekomendasi: false,
          warningMessage: '',
          totalRekomendasi: 0,
          totalSks: 0,
          kategoriSangatDianjurkan: [],
          kategoriOpsionalSksBesar: [],
        )),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0] as Dashboard;
        _agendaData = results[1] as AgendaTerpaduData;
        _spRekomendasiData = results[2] as SpRekomendasiData;
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
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 120),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          _buildGreeting(d.profile).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          _buildProfileCard(d.profile).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          if (_spRekomendasiData != null && _spRekomendasiData!.hasRekomendasi) ...[
            _buildSpRekomendasiBanner(_spRekomendasiData!).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
          ],
          _buildQuickPresensiBanner().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          _buildNextAgendaCard().animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          _buildInfoPenting(d).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'IPK',
                  d.statistik.ipk.toStringAsFixed(2),
                  CupertinoIcons.rosette,
                  subtitle: 'Grafik Analitik >',
                  onTap: () => showHistoriIpkBottomSheet(context),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total SKS',
                  d.statistik.totalSks.toString(),
                  CupertinoIcons.book_fill,
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
              ),
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
                  color: const Color(0xFF501F66).withValues(alpha: 0.1),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                if (onTap != null)
                  const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFF501F66)),
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
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getHariIndo(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return 'Senin';
    }
  }

  int _timeToMinutes(String timeStr) {
    final clean = timeStr.trim().replaceAll('.', ':');
    final parts = clean.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return 0;
  }

  Widget _buildNextAgendaCard() {
    if (_agendaData == null || _agendaData!.agenda.isEmpty) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final todayName = _getHariIndo(now.weekday);
    final todayItems = _agendaData!.agenda[todayName] ?? [];
    final nowMins = now.hour * 60 + now.minute;

    AgendaItem? activeItem;
    AgendaItem? nextItem;

    for (var item in todayItems) {
      final parts = item.jam.split('-');
      if (parts.length >= 2) {
        final startMins = _timeToMinutes(parts[0]);
        final endMins = _timeToMinutes(parts[1]);

        if (nowMins >= startMins && nowMins <= endMins) {
          activeItem = item;
          break;
        } else if (startMins > nowMins) {
          nextItem ??= item;
        }
      }
    }

    final displayItem = activeItem ?? nextItem;
    final isOngoing = activeItem != null;

    Color statusBg = isOngoing ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD);
    Color statusColor = isOngoing ? const Color(0xFFC62828) : const Color(0xFF1565C0);
    String statusTitle = isOngoing
        ? '🔴 Sedang Berlangsung'
        : (nextItem != null
            ? '⏰ Agenda Selanjutnya Hari Ini'
            : (todayItems.isNotEmpty
                ? '🎉 Semua Agenda Hari Ini Selesai'
                : '📅 Tidak Ada Agenda Hari Ini'));

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JadwalPage()),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusTitle,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Row(
                  children: const [
                    Text('Lihat Semua', style: TextStyle(fontSize: 11, color: Color(0xFF501F66), fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(CupertinoIcons.chevron_right, size: 12, color: Color(0xFF501F66)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (displayItem != null) ...[
              Text(
                displayItem.matakuliah,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(CupertinoIcons.time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(displayItem.jam, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(width: 12),
                  const Icon(CupertinoIcons.location_solid, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(displayItem.ruang, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ),
              if (displayItem.detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  displayItem.detail,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ] else ...[
              const Text(
                'Tidak ada jadwal perkuliahan atau ujian aktif untuk saat ini.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
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
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                p.fotoUrl,
                width: 48,
                height: 64, // 3:4 ratio
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 64,
                  color: const Color(0xFF501F66).withValues(alpha: 0.1),
                  child: const Icon(CupertinoIcons.person_alt, size: 32, color: Color(0xFF501F66)),
                ),
              ),
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
                    color: Colors.white.withValues(alpha: 0.4),
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

  Widget _buildSpRekomendasiBanner(SpRekomendasiData rekomendasi) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      opacity: 0.8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF3E0),
              const Color(0xFFFFE0B2).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.orange.shade400, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.deepOrange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekomendasi Semester Pendek (SP)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${rekomendasi.totalRekomendasi} Matakuliah • ${rekomendasi.totalSks} SKS Disarankan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepOrange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rekomendasi.warningMessage,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SpPage(onBack: () => Navigator.pop(context)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(CupertinoIcons.arrow_right_circle_fill, size: 18),
                label: const Text(
                  'Lihat Rekomendasi & Daftar SP',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
