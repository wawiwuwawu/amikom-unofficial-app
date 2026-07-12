import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/krs_service.dart';
import '../models/krs.dart';
import 'package:share_plus/share_plus.dart';

class JadwalPage extends StatefulWidget {
  final bool showDownloadKrs;
  const JadwalPage({super.key, this.showDownloadKrs = false});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _service = KrsService();
  bool _loading = true;
  String? _error;
  List<KrsPengisian> _jadwalList = [];
  int _totalSks = 0;
  bool _downloading = false;
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _service.getJadwal();
      if (mounted) {
        setState(() {
          _jadwalList = res.data;
          _totalSks = res.totalSks;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download({bool silent = false}) async {
    setState(() => _downloading = true);
    try {
      final path = await _service.downloadKrs((p0, p1) {});
      if (mounted) {
        setState(() => _downloadPath = path);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('KRS tersimpan di $path', style: const TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF501F66),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _share() async {
    String? path = _downloadPath;
    if (path == null) {
      await _download(silent: true);
      path = _downloadPath;
      if (path == null) return;
    }
    await Share.shareXFiles([XFile(path)], text: 'Jadwal & KRS');
  }

  int _dayValue(String day) {
    switch (day.toLowerCase().trim()) {
      case 'senin': return 1;
      case 'selasa': return 2;
      case 'rabu': return 3;
      case 'kamis': return 4;
      case 'jumat': return 5;
      case 'jum\'at': return 5;
      case 'sabtu': return 6;
      case 'minggu': return 7;
      default: return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66), foregroundColor: Colors.white),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    
    // Group by Day
    Map<String, List<KrsPengisian>> grouped = {};
    for (var item in _jadwalList) {
      final day = item.hari.isEmpty ? 'Belum Ditentukan' : item.hari;
      grouped.putIfAbsent(day, () => []).add(item);
    }
    
    final sortedDays = grouped.keys.toList()..sort((a, b) => _dayValue(a).compareTo(_dayValue(b)));

    if (_jadwalList.isEmpty) {
      return const Center(child: Text('Tidak ada jadwal perkuliahan', style: TextStyle(color: Colors.black54)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF501F66),
      child: ListView(
        padding: EdgeInsets.only(
          top: 16, 
          left: 16, 
          right: 16, 
          bottom: MediaQuery.of(context).padding.bottom + 80 // Safe area for home bar
        ),
        children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: _downloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF501F66)),
                          )
                        : const Icon(CupertinoIcons.cloud_download, color: Color(0xFF501F66)),
                    tooltip: 'Download KRS',
                    onPressed: _downloading ? null : _download,
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.share, color: Color(0xFF501F66)),
                    tooltip: 'Bagikan KRS',
                    onPressed: _downloading ? null : _share,
                  ),
                ],
              ),
            ),
            
          for (var day in sortedDays) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
              child: Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
            ),
            for (var item in grouped[day]!)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF501F66).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.kodeMk,
                              style: const TextStyle(color: Color(0xFF501F66), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.sks} SKS',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.namaMataKuliah,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.person_fill, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.dosenKelas.isEmpty || item.dosenKelas == '-' ? 'Belum ditentukan' : item.dosenKelas,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.location_solid, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            item.ruang.isEmpty ? '-' : item.ruang,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          const Icon(CupertinoIcons.time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            item.jam.isEmpty ? '-' : item.jam,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Total $_totalSks SKS',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
