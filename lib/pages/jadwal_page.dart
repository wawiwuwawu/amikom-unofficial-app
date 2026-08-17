import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../services/agenda_service.dart';
import '../services/krs_service.dart';
import '../models/agenda_terpadu.dart';
import '../widgets/glass_card.dart';

class JadwalPage extends StatefulWidget {
  final bool showDownloadKrs;
  const JadwalPage({super.key, this.showDownloadKrs = false});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _agendaService = AgendaService();
  final _krsService = KrsService();

  bool _loading = true;
  String? _error;
  AgendaTerpaduData? _agendaData;

  String _filterTipe = 'semua'; // 'semua', 'kuliah', 'asisten', 'ujian'
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
      final res = await _agendaService.getAgendaTerpadu();
      if (mounted) {
        setState(() {
          _agendaData = res;
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

  Future<void> _downloadKrs({bool silent = false}) async {
    setState(() => _downloading = true);
    try {
      final path = await _krsService.downloadKrs((p0, p1) {});
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

  Future<void> _shareKrs() async {
    String? path = _downloadPath;
    if (path == null) {
      await _downloadKrs(silent: true);
      path = _downloadPath;
      if (path == null) return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Jadwal & KRS Amikom'),
    );
  }

  int _dayValue(String day) {
    switch (day.toLowerCase().trim()) {
      case 'senin':
        return 1;
      case 'selasa':
        return 2;
      case 'rabu':
        return 3;
      case 'kamis':
        return 4;
      case 'jumat':
      case 'jum\'at':
        return 5;
      case 'sabtu':
        return 6;
      case 'minggu':
        return 7;
      default:
        return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFAFCFF), Color(0xFFE3F2FD)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: canPop
            ? AppBar(
                title: const Text('Jadwal Perkuliahan', style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        body: SafeArea(child: _buildBody()),
      ),
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

    final data = _agendaData;
    if (data == null || data.agenda.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF501F66),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(child: Text('Tidak ada jadwal agenda terpadu', style: TextStyle(color: Colors.black54))),
          ],
        ),
      );
    }

    final sortedDays = data.agenda.keys.toList()
      ..sort((a, b) => _dayValue(a).compareTo(_dayValue(b)));

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF501F66),
      child: ListView(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 130,
        ),
        children: [
          // Filter Chips & KRS Buttons Row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('semua', 'Semua (${data.totalAgenda})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('kuliah', 'Kuliah 📘'),
                      const SizedBox(width: 6),
                      _buildFilterChip('asisten', 'Asisten 🟣'),
                      const SizedBox(width: 6),
                      _buildFilterChip('ujian', 'Ujian 🔴'),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: _downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF501F66)),
                      )
                    : const Icon(CupertinoIcons.cloud_download, color: Color(0xFF501F66)),
                tooltip: 'Download KRS',
                onPressed: _downloading ? null : _downloadKrs,
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.share, color: Color(0xFF501F66)),
                tooltip: 'Bagikan KRS',
                onPressed: _downloading ? null : _shareKrs,
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (var day in sortedDays) ...[
            _buildDaySection(day, data.agenda[day]!),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterTipe == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF501F66),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.black87,
      ),
      onSelected: (val) {
        if (val) setState(() => _filterTipe = value);
      },
    );
  }

  Widget _buildDaySection(String day, List<AgendaItem> items) {
    final filteredItems = items.where((item) {
      if (_filterTipe == 'semua') return true;
      if (_filterTipe == 'kuliah') return item.tipe == 'kuliah';
      if (_filterTipe == 'asisten') return item.tipe == 'asisten';
      if (_filterTipe == 'ujian') return item.tipe == 'uts' || item.tipe == 'uas';
      return true;
    }).toList();

    if (filteredItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              const Icon(CupertinoIcons.calendar, size: 18, color: Color(0xFF501F66)),
              const SizedBox(width: 8),
              Text(
                day,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF501F66).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${filteredItems.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
                ),
              ),
            ],
          ),
        ),
        for (var item in filteredItems) _buildAgendaCard(item),
      ],
    );
  }

  Widget _buildAgendaCard(AgendaItem item) {
    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;
    String badgeLabel;

    switch (item.tipe.toLowerCase()) {
      case 'kuliah':
        badgeBg = const Color(0xFFE3F2FD);
        badgeText = const Color(0xFF1565C0);
        badgeIcon = CupertinoIcons.book_fill;
        badgeLabel = 'Kuliah KRS';
        break;
      case 'asisten':
        badgeBg = const Color(0xFFF3E5F5);
        badgeText = const Color(0xFF501F66);
        badgeIcon = CupertinoIcons.briefcase_fill;
        badgeLabel = 'Asisten Praktikum';
        break;
      case 'uts':
      case 'uas':
        badgeBg = const Color(0xFFFFEBEE);
        badgeText = const Color(0xFFC62828);
        badgeIcon = CupertinoIcons.doc_text_fill;
        badgeLabel = item.tipe.toUpperCase();
        break;
      default:
        badgeBg = Colors.grey.shade200;
        badgeText = Colors.black87;
        badgeIcon = CupertinoIcons.info;
        badgeLabel = item.tipe;
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 13, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(CupertinoIcons.time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item.jam.isEmpty ? '-' : item.jam,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.matakuliah,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.location_solid, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  item.ruang.isEmpty ? '-' : item.ruang,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                if (item.detail.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.detail,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
