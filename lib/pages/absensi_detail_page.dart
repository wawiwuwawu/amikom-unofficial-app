import 'package:flutter/material.dart';
import '../models/absensi.dart';
import '../services/absensi_service.dart';

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
              ? k.nilai.reduce(
                  (a, b) => a.nilai >= b.nilai ? a : b)
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
          const SnackBar(content: Text('Validasi berhasil')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Presensi')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    final d = _detail!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoTile(Icons.person, 'Dosen', d.nama),
          _infoTile(Icons.badge, 'NIK', d.nik),
          _infoTile(Icons.calendar_today, 'Tanggal', d.tanggal),
          _infoTile(Icons.book, 'Materi', d.judulMateri),
          _infoTile(Icons.access_time, 'Jam', d.jam),
          _infoTile(Icons.check_circle, 'Status', _statusLabel(d.keterangan)),
          if (d.validasi != null)
            _infoTile(Icons.verified, 'Validasi', d.validasi!),
          if (d.validasi == null) ...[
            const Divider(height: 32),
            const Text('Form Validasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _dropdownField(
              'Kesesuaian Perkuliahan',
              _kesesuaianPerkuliahan,
              ['1 (Sesuai)'],
              ['1'],
            ),
            _dropdownField(
              'Kesesuaian Materi',
              _kesesuaianMateri,
              ['1 (Ya)', '2 (Tidak)'],
              ['1', '2'],
            ),
            _dropdownField(
              'Penilaian Mahasiswa',
              _penilaianMhs,
              ['4 (Sangat Baik)', '3 (Baik)', '2 (Cukup)', '1 (Kurang)'],
              ['4', '3', '2', '1'],
            ),
            for (final k in d.kriterias) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('krit_${k.id}_${_asdosPenilaian[k.id]}'),
                initialValue: _asdosPenilaian[k.id],
                decoration: InputDecoration(
                  labelText: k.isi,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
                items: k.nilai
                    .map((n) => DropdownMenuItem(
                          value: n.id,
                          child: Text('${n.isi} (${n.nilai})',
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _asdosPenilaian[k.id] = v);
                  }
                },
              ),
            ],
            TextField(
              controller: _kritikSaran,
              decoration: const InputDecoration(
                labelText: 'Kritik & Saran (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submitValidasi,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(_submitting ? 'Memvalidasi...' : 'Validasi'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField(
      String label, TextEditingController controller, List<String> labels,
      List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('${label}_${controller.text}'),
        initialValue: controller.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
        items: List.generate(labels.length,
            (i) => DropdownMenuItem(value: values[i], child: Text(labels[i]))),
        onChanged: (v) {
          if (v != null) controller.text = v;
        },
      ),
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
