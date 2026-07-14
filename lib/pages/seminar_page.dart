import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/seminar.dart';
import '../services/seminar_service.dart';
import '../widgets/glass_card.dart';

class SeminarPage extends StatefulWidget {
  final VoidCallback? onBack;
  const SeminarPage({super.key, this.onBack});

  @override
  State<SeminarPage> createState() => _SeminarPageState();
}

class _SeminarPageState extends State<SeminarPage> with SingleTickerProviderStateMixin {
  final _service = SeminarService();
  late TabController _tabController;
  
  bool _loading = true;
  String? _error;
  
  List<Seminar> _listKP = [];
  List<Seminar> _listSkripsi = [];
  
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final kp = await _service.getJadwalKP();
      final skripsi = await _service.getJadwalSkripsi();

      if (mounted) {
        setState(() {
          _listKP = kp;
          _listSkripsi = skripsi;
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

  List<Seminar> _getFilteredList(List<Seminar> source) {
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source.where((s) {
      return s.judul.toLowerCase().contains(q) ||
             s.nama.toLowerCase().contains(q) ||
             s.npm.toLowerCase().contains(q) ||
             s.prodi.toLowerCase().contains(q);
    }).toList();
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
          'Jadwal Seminar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF501F66),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF501F66),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Kerja Praktik'),
            Tab(text: 'Skripsi'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)))
                  : _error != null
                      ? _buildErrorState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(_getFilteredList(_listKP), isSkripsi: false),
                            _buildList(_getFilteredList(_listSkripsi), isSkripsi: true),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari judul, nama, atau NPM...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF501F66)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(CupertinoIcons.clear_thick_circled, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle, size: 64, color: Colors.redAccent)
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF501F66),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Seminar> list, {required bool isSkripsi}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_text_search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'Pencarian tidak ditemukan' : 'Belum ada jadwal tersedia',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final s = list[index];
          return _buildCard(s, index, isSkripsi: isSkripsi);
        },
      ),
    );
  }

  Widget _buildCard(Seminar s, int index, {required bool isSkripsi}) {
    final typeColor = isSkripsi ? Colors.pinkAccent : Colors.blueAccent;
    final typeLabel = isSkripsi ? 'SKRIPSI' : 'KERJA PRAKTIK';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${s.idPengajuan}',
                  style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.judul,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87, height: 1.3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(CupertinoIcons.calendar, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text('${s.hari}, ${s.tglUjian}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const Spacer(),
                const Icon(CupertinoIcons.clock, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(s.jam, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.location, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(s.ruang, style: const TextStyle(color: Colors.black54, fontSize: 12), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.black12),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF501F66).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.person_solid, size: 16, color: Color(0xFF501F66)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      Text('${s.npm} • ${s.prodi}', style: const TextStyle(color: Colors.black54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: (100 + (index * 50).clamp(0, 500)).ms).slideY(begin: 0.1, end: 0),
    );
  }
}
