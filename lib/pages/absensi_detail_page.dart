import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/absensi.dart';
import '../services/absensi_service.dart';
import '../widgets/glass_card.dart';

class AbsensiDetailPage extends StatefulWidget {
  final String idPresensi;
  const AbsensiDetailPage({super.key, required this.idPresensi});

  @override
  State<AbsensiDetailPage> createState() => _AbsensiDetailPageState();
}

class _AbsensiDetailPageState extends State<AbsensiDetailPage> {
  final _service = AbsensiService();
  PresensiDetail? _detail;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final _kesesuaianPerkuliahan = TextEditingController(text: '1');
  final _kesesuaianMateri = TextEditingController(text: '1');
  final _penilaianMhs = TextEditingController(text: '4');
  final _kritikSaran = TextEditingController();

  final Map<String, String> _asdosPenilaian = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _kesesuaianPerkuliahan.dispose();
    _kesesuaianMateri.dispose();
    _penilaianMhs.dispose();
    _kritikSaran.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getPresensiDetail(widget.idPresensi);
      if (!mounted) return;
      setState(() {
        _detail = data;
        _error = null;
        for (final k in data.kriterias) {
          final best = k.nilai.isNotEmpty
              ? k.nilai.reduce((a, b) => a.nilai >= b.nilai ? a : b)
              : null;
          if (best != null) _asdosPenilaian[k.id] = best.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitValidasi() async {
    if (_detail == null) return;
    setState(() => _submitting = true);
    try {
      await _service.validasi({
        'jenispilih': _detail!.keterangan == 'H' ? 'teori' : _detail!.keterangan,
        'idpresensimhstexs': _detail!.idPresensiMhs,
        'idpresensidosen': _detail!.idPresensiDosen,
        'kuliahteori': _detail!.kuliahTpId,
        'kesesuaian_perkuliahan': _kesesuaianPerkuliahan.text,
        'kesesuaian_materi': _kesesuaianMateri.text,
        'penilaianmhs': _penilaianMhs.text,
        'kritiksaran': _kritikSaran.text,
        'asdos_npms': [],
        'asdospenilaian': _asdosPenilaian,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Validasi berhasil', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF501F66),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Detail Presensi', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAFCFF), Color(0xFFE3F2FD)], // Pearl White to Ice Blue
          ),
        ),
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: const CircularProgressIndicator(color: Color(0xFFBBDEFB))
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
            const SizedBox(height: 16),
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
    
    final d = _detail!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTile(CupertinoIcons.person_fill, 'Dosen', d.nama),
                const SizedBox(height: 12),
                _infoTile(CupertinoIcons.creditcard, 'NIK', d.nik),
                const SizedBox(height: 12),
                _infoTile(CupertinoIcons.calendar, 'Tanggal', d.tanggal),
                const SizedBox(height: 12),
                _infoTile(CupertinoIcons.book_fill, 'Materi', d.judulMateri),
                const SizedBox(height: 12),
                _infoTile(CupertinoIcons.clock_fill, 'Jam', d.jam),
                const SizedBox(height: 12),
                _infoTile(CupertinoIcons.checkmark_seal_fill, 'Status', _statusLabel(d.keterangan)),
                if (d.validasi != null) ...[
                  const SizedBox(height: 12),
                  _infoTile(CupertinoIcons.check_mark_circled_solid, 'Validasi', d.validasi!),
                ]
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          
          if (d.validasi == null) ...[
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'Form Validasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildGlassDropdown(
                    'Kesesuaian Perkuliahan',
                    _kesesuaianPerkuliahan,
                    ['1 (Sesuai)'],
                    ['1'],
                  ),
                  _buildGlassDropdown(
                    'Kesesuaian Materi',
                    _kesesuaianMateri,
                    ['1 (Ya)', '2 (Tidak)'],
                    ['1', '2'],
                  ),
                  _buildGlassDropdown(
                    'Penilaian Mahasiswa',
                    _penilaianMhs,
                    ['4 (Sangat Baik)', '3 (Baik)', '2 (Cukup)', '1 (Kurang)'],
                    ['4', '3', '2', '1'],
                  ),
                  for (final k in d.kriterias) ...[
                    const SizedBox(height: 12),
                    _buildApiDropdown(k),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _kritikSaran,
                    decoration: InputDecoration(
                      labelText: 'Kritik & Saran (opsional)',
                      labelStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submitValidasi,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF501F66)),
                      )
                    : const Icon(CupertinoIcons.check_mark_circled_solid),
                label: Text(
                  _submitting ? 'Memvalidasi...' : 'Validasi Presensi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBBDEFB),
                  foregroundColor: const Color(0xFF501F66),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF501F66)),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _buildGlassDropdown(
      String label, TextEditingController controller, List<String> labels, List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: ValueKey('${label}_${controller.text}'),
                value: controller.text,
                isExpanded: true,
                icon: const Icon(CupertinoIcons.chevron_down, color: Color(0xFF501F66), size: 16),
                items: List.generate(
                  labels.length,
                  (i) => DropdownMenuItem(
                    value: values[i],
                    child: Text(labels[i], style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) setState(() => controller.text = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiDropdown(Kriteria k) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(k.isi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: ValueKey('krit_${k.id}_${_asdosPenilaian[k.id]}'),
              value: _asdosPenilaian[k.id],
              isExpanded: true,
              icon: const Icon(CupertinoIcons.chevron_down, color: Color(0xFF501F66), size: 16),
              items: k.nilai.map((n) => DropdownMenuItem(
                value: n.id,
                child: Text('${n.isi} (${n.nilai})', style: const TextStyle(fontSize: 14, color: Colors.black87)),
              )).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _asdosPenilaian[k.id] = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'H':
        return 'Hadir';
      case 'B':
        return 'Bolos';
      case 'I':
        return 'Izin';
      case 'S':
        return 'Sakit';
      default:
        return s;
    }
  }
}
