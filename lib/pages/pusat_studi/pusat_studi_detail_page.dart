import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/pusat_studi.dart';
import '../../services/pusat_studi_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/expandable_html.dart';

class PusatStudiDetailPage extends StatefulWidget {
  final PusatStudi pusatStudi;
  final bool isJoined;

  const PusatStudiDetailPage({super.key, required this.pusatStudi, this.isJoined = false});

  @override
  State<PusatStudiDetailPage> createState() => _PusatStudiDetailPageState();
}

class _PusatStudiDetailPageState extends State<PusatStudiDetailPage> {
  final PusatStudiService _service = PusatStudiService();
  bool _isLoading = true;
  bool _isJoining = false;
  String _error = '';
  PusatStudiDetail? _detail;
  String _activeTab = 'profil'; // 'profil', 'dosen', 'mahasiswa', 'tema'

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
      _detail = await _service.getDetailPusatStudi(widget.pusatStudi.detailId);
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

  Future<void> _join() async {
    setState(() {
      _isJoining = true;
    });
    try {
      await _service.joinPusatStudi(widget.pusatStudi.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil bergabung dengan Pusat Studi!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFF),
      appBar: AppBar(
        title: Text(widget.pusatStudi.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF501F66)),
      ),
      body: _isLoading
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
              : _detail == null
                  ? const Center(child: Text('Data tidak ditemukan'))
                  : Column(
                      children: [
                        _buildTabToggle(),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildActiveContent(),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: (!widget.isJoined && _detail != null)
          ? FloatingActionButton.extended(
              onPressed: _isJoining ? null : _join,
              backgroundColor: const Color(0xFF501F66),
              icon: _isJoining
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(CupertinoIcons.person_add_solid, color: Colors.white),
              label: Text(_isJoining ? 'Memproses...' : 'Gabung Pusat Studi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ).animate().slideY(begin: 1.0, duration: 300.ms).fadeIn()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTabToggle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        borderRadius: 25,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildTabButton('Profil', 'profil'),
            _buildTabButton('Dosen', 'dosen'),
            _buildTabButton('Mahasiswa', 'mahasiswa'),
            _buildTabButton('Tema', 'tema'),
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
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF501F66) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    switch (_activeTab) {
      case 'profil':
        return _buildProfilSection();
      case 'dosen':
        return _buildDosenSection();
      case 'mahasiswa':
        return _buildMahasiswaSection();
      case 'tema':
        return _buildTemaSection();
      default:
        return const SizedBox();
    }
  }

  Widget _buildProfilSection() {
    return ListView(
      key: const ValueKey('profil'),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      children: [
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF501F66)),
                  const SizedBox(width: 8),
                  const Text('Profil Pusat Studi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF501F66))),
                ],
              ),
              const Divider(),
              Text(_detail!.profil.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_detail!.profil.keterangan.isEmpty)
                const Text('Tidak ada keterangan', style: TextStyle(color: Colors.black87))
              else
                Html(
                  data: _detail!.profil.keterangan,
                  style: {
                    "body": Style(
                      margin: Margins.zero, 
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14),
                      color: Colors.black87,
                    ),
                  },
                ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildDosenSection() {
    if (_detail!.dosen.isEmpty) {
      return Center(
        key: const ValueKey('dosen-empty'),
        child: const Text('Belum ada dosen pembimbing', style: TextStyle(color: Colors.black54)),
      ).animate().fadeIn();
    }
    return ListView.builder(
      key: const ValueKey('dosen'),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: _detail!.dosen.length,
      itemBuilder: (context, index) {
        final dosen = _detail!.dosen[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            borderRadius: 12,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF501F66).withOpacity(0.1),
                child: Text(dosen.no, style: const TextStyle(color: Color(0xFF501F66))),
              ),
              title: Text(dosen.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('NIK: ${dosen.nik}', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildMahasiswaSection() {
    if (_detail!.mahasiswa.isEmpty) {
      return Center(
        key: const ValueKey('mahasiswa-empty'),
        child: const Text('Belum ada mahasiswa yang tergabung', style: TextStyle(color: Colors.black54)),
      ).animate().fadeIn();
    }
    return ListView.builder(
      key: const ValueKey('mahasiswa'),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: _detail!.mahasiswa.length,
      itemBuilder: (context, index) {
        final mhs = _detail!.mahasiswa[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            borderRadius: 12,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(CupertinoIcons.person_fill, color: Colors.blue, size: 20),
              ),
              title: Text(mhs.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('NPM: ${mhs.npm}\nJoin: ${mhs.tanggalJoin}', style: const TextStyle(fontSize: 12)),
              isThreeLine: true,
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildTemaSection() {
    if (_detail!.tema.isEmpty) {
      return Center(
        key: const ValueKey('tema-empty'),
        child: const Text('Belum ada tema riset', style: TextStyle(color: Colors.black54)),
      ).animate().fadeIn();
    }
    return ListView.builder(
      key: const ValueKey('tema'),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: _detail!.tema.length,
      itemBuilder: (context, index) {
        final tema = _detail!.tema[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tema.judulTema, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ExpandableHtml(htmlData: tema.deskripsi),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(CupertinoIcons.person_solid, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(tema.pengusul, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF501F66).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Jenis: ${tema.jenisTema}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF501F66))),
                    ),
                    Text('Kuota: ${tema.kuota}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
      },
    );
  }
}
