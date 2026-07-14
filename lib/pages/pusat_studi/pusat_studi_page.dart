import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/pusat_studi.dart';
import '../../services/pusat_studi_service.dart';
import '../../widgets/glass_card.dart';
import 'pusat_studi_detail_page.dart';
import 'pusat_studi_joined_page.dart';

class PusatStudiPage extends StatefulWidget {
  final VoidCallback? onBack;
  const PusatStudiPage({super.key, this.onBack});

  @override
  State<PusatStudiPage> createState() => _PusatStudiPageState();
}

class _PusatStudiPageState extends State<PusatStudiPage> {
  final PusatStudiService _service = PusatStudiService();
  bool _isLoading = true;
  String _error = '';
  List<PusatStudi> _listSemua = [];
  List<PusatStudi> _listJoined = [];
  String _activeTab = 'semua'; // 'semua' or 'tergabung'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Set<String> _joinedIds = {};

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      // Selalu tarik data yang sudah di-join untuk state
      final joined = await _service.getJoinedPusatStudi();
      _listJoined = joined;
      _joinedIds = joined.map((e) => e.id).toSet();

      if (_activeTab == 'semua') {
        final all = await _service.getPusatStudiList();
        
        // Gabungkan karena endpoint 'semua' mungkin mengecualikan yang sudah di-join
        final Map<String, PusatStudi> combinedMap = {};
        for (var ps in all) {
          combinedMap[ps.id] = ps;
        }
        for (var ps in joined) {
          combinedMap[ps.id] = ps;
        }
        _listSemua = combinedMap.values.toList();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          'Pusat Studi',
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
                    Expanded(child: _buildTabButton('Semua', 'semua')),
                    Expanded(child: _buildTabButton('Tergabung', 'tergabung')),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
            
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
                          child: _activeTab == 'semua' 
                              ? _buildListSemua() 
                              : _buildListJoined(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, String type) {
    final isSelected = _activeTab == type;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _activeTab = type;
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

  Widget _buildListSemua() {
    if (_listSemua.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Center(
            child: Text('Tidak ada daftar pusat studi.', style: TextStyle(color: Colors.black54)),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 120,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _listSemua.length,
      itemBuilder: (context, index) {
        final ps = _listSemua[index];
        final isJoined = _joinedIds.contains(ps.id);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            opacity: 0.8,
            child: InkWell(
              onTap: () {
                // Selalu buka Detail Page dari tab Semua, berikan parameter isJoined agar FAB di-hide
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PusatStudiDetailPage(pusatStudi: ps, isJoined: isJoined),
                )).then((joined) {
                  if (joined == true) _loadData(); // Refresh jika user barusan gabung
                });
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isJoined ? Colors.green.withOpacity(0.1) : const Color(0xFF501F66).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isJoined ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.building_2_fill, 
                      color: isJoined ? Colors.green.shade700 : const Color(0xFF501F66)
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ps.nama,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isJoined ? Colors.green.shade700 : const Color(0xFF501F66)),
                        ),
                        if (isJoined) ...[
                          const SizedBox(height: 4),
                          Text('Tergabung', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                        ]
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildListJoined() {
    if (_listJoined.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Center(
            child: Text('Anda belum tergabung di pusat studi manapun.', style: TextStyle(color: Colors.black54)),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 120,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _listJoined.length,
      itemBuilder: (context, index) {
        final ps = _listJoined[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            opacity: 0.8,
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PusatStudiJoinedPage(pusatStudi: ps),
                ));
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green.shade700),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ps.nama,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66)),
                        ),
                        if (ps.grupWa != null && ps.grupWa!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Grup WA tersedia', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                        ]
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
      },
    );
  }
}
