import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard.dart';
import '../widgets/glass_card.dart';

class VisiMisiPage extends StatefulWidget {
  final VoidCallback? onBack;
  const VisiMisiPage({super.key, this.onBack});

  @override
  State<VisiMisiPage> createState() => _VisiMisiPageState();
}

class _VisiMisiPageState extends State<VisiMisiPage> {
  final _service = DashboardService();
  Dashboard? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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

  Map<String, dynamic> _getProdiData(String userProdi) {
    final prodi = userProdi.toLowerCase();
    
    if (prodi.contains('sistem informasi')) {
      return {
        'nama': 'Sistem Informasi',
        'visi': 'Menghasilkan lulusan S1 yang kompeten di bidang Manajemen Sistem Informasi dan E-business, berwawasan global, serta mampu mengembangkan inovasi teknologi yang mendukung pertumbuhan industri digital di tingkat nasional dan internasional pada tahun 2029.',
        'misi': [
          'Pendidikan Berkualitas: Menyelenggarakan pendidikan yang inovatif dan relevan dengan kebutuhan industri dalam bidang manajemen sistem informasi dan e-business, dengan pendekatan yang berfokus pada pengembangan keterampilan praktis dan analitis.',
          'Riset Inovatif: Mengembangkan dan mendukung penelitian yang berkontribusi pada pemecahan masalah aktual dalam manajemen sistem informasi dan e-business, serta mendorong lahirnya inovasi yang dapat diterapkan dalam dunia bisnis dan teknologi.',
          'Pengabdian Masyarakat: Melaksanakan kegiatan pengabdian kepada masyarakat dengan menerapkan keahlian dalam sistem informasi dan e-business untuk meningkatkan kesejahteraan masyarakat dan mendorong transformasi digital di sektor-sektor penting.',
          'Kerjasama Strategis: Meningkatkan kolaborasi dengan industri, pemerintah, dan institusi pendidikan lainnya baik di tingkat nasional maupun internasional, untuk memastikan relevansi kurikulum dan memperkuat peluang kerja bagi lulusan.'
        ],
        'tujuan': [
          'Kualitas Lulusan: Mencetak lulusan yang memiliki kompetensi tinggi dalam manajemen sistem informasi dan e-business, serta mampu bersaing di pasar kerja global dan memiliki wawasan technopreneur.',
          'Karya Penelitian: Mewujudkan karya-karya penelitian dan inovasi yang berdampak pada pengembangan teknologi informasi dan bisnis digital, yang relevan dengan kebutuhan masyarakat dan industri.',
          'Karya Pengabdian: Meningkatkan kesejahteraan masyarakat melalui penerapan teknologi informasi dan keahlian dalam e-business dalam program pengabdian masyarakat yang berkelanjutan.',
          'Kerjasama: Menjalin kemitraan strategis dengan industri, lembaga pemerintah, dan komunitas untuk memperkaya pengalaman belajar mahasiswa dan relevansi kurikulum dalam menghadapi perkembangan teknologi dan bisnis.'
        ],
        'strategi': [
          'Pengembangan Kurikulum: Secara berkala memperbarui kurikulum agar sesuai dengan perkembangan teknologi dan kebutuhan industri, dengan fokus pada manajemen sistem informasi dan e-business serta integrasi aspek technopreneur.',
          'Program Magang dan Kerjasama: Mengembangkan jejaring dengan alumni, industri, dan institusi lain untuk membuka peluang magang, penelitian kolaboratif, dan kerjasama proyek yang relevan dengan konsentrasi program studi.',
          'Penelitian dan Inovasi: Menciptakan lingkungan yang kondusif bagi penelitian dengan menyediakan fasilitas dan dukungan yang memadai, serta mendorong mahasiswa dan dosen untuk aktif dalam penelitian yang berorientasi pada solusi bisnis digital.',
          'Peningkatan Kualitas Dosen: Meningkatkan kompetensi dosen melalui pelatihan, penelitian kolaboratif, dan partisipasi dalam konferensi internasional, serta menerapkan metode pengajaran yang inovatif dan berbasis praktik nyata.',
          'Pengabdian Masyarakat: Melibatkan mahasiswa dan dosen dalam program pengabdian yang relevan dengan kebutuhan masyarakat, terutama dalam bidang transformasi digital dan penerapan teknologi informasi di sektor publik.'
        ],
      };
    } else if (prodi.contains('teknologi informasi')) {
      return {
        'nama': 'Teknologi Informasi',
        'visi': 'Menjadi Program Studi Teknologi Informasi yang unggul dalam bidang Internet of Things (IoT), Cyber Security, dan Game Development, serta berwawasan Technopreneurship di tingkat nasional pada tahun 2029.',
        'misi': [
          'Pendidikan Berkualitas: Menyelenggarakan pendidikan yang berkualitas dengan pendekatan berbasis teknologi dan Technopreneurship, serta mengintegrasikan konsentrasi IoT, Cyber Security, dan Game Development.',
          'Riset Inovatif: Mendorong penelitian dan pengembangan inovasi teknologi yang relevan dengan kebutuhan masyarakat dan industri, serta berkontribusi pada solusi masalah sosial.',
          'Pengabdian Masyarakat: Mengembangkan program pengabdian masyarakat yang berbasis teknologi informasi untuk meningkatkan kesejahteraan masyarakat dan memberdayakan komunitas lokal.',
          'Kerjasama Strategis: Meningkatkan kerjasama dengan berbagai pihak, baik dalam maupun luar negeri, untuk pengembangan pendidikan dan penelitian yang berkelanjutan untuk menciptakan ekosistem yang mendukung pengembangan technopreneurship.'
        ],
        'tujuan': [
          'Meningkatkan kualitas pendidikan dan pelatihan dalam rangka menghasilkan sumber daya manusia berkualitas berjiwa technopreneur yang berakademik unggul sesuai dengan perkembangan ilmu pengetahuan dan teknologi yang sesuai dengan kebutuhan stakeholder.',
          'Menghasilkan karya-karya yang diakui baik secara nasional maupun internasional melalui penelitian dan pengabdian masyarakat.',
          'Berperan aktif dalam kegiatan tri dharma perguruan tinggi pada tingkat lokal, nasional maupun internasional.',
          'Meningkatkan pelayanan pendidikan melalui penjaminan mutu internal maupun penjaminan mutu eksternal sehingga stakeholder memperoleh kepuasan.'
        ],
        'strategi': [
          'Mewujudkan Pendidikan yang berkualitas berwawasan technopreneur pada PS.',
          'Meningkatkan inovasi dan penyebarluasan hasil penelitian pada PS Teknologi Informasi.',
          'Peningkatan kegiatan pengabdian dan pemberdayaan masyarakat pada PS Teknologi Informasi.',
          'Meningkatkan kualitas dan implementasi kerjasama serta kemitraan yang harmonis dengan para pemangku kepentingan.',
          'Mewujudkan tata pamong dan tata kelola program studi Teknologi Informasi yang kredibel, transparan, akuntabel, bertanggung jawab dan profesional.'
        ],
      };
    } else {
      // Default to Informatika
      return {
        'nama': 'Informatika',
        'visi': 'Menjadi program studi unggul dalam pembelajaran bidang informatika yang menghasilkan mahasiswa berkemampuan merancang, membangun, dan mengevaluasi perangkat lunak dengan wawasan Technoprenuership di tahun 2024.',
        'misi': [
          'Menyelenggarakan pendidikan dalam bidang Informatika yang berkualitas dan berwawasan technoprenuer sesuai dengan perkembangan ilmu pengetahuan dan teknologi.',
          'Mengembangkan iklim penelitian dalam bidang informatika yang inovatif dan berorientasi hilir untuk kemanfaatan masyarakat luas.',
          'Mengembangkan kegiatan pengabdian masyarakat melalui penerapan ilmu pengetahuan dan teknologi di bidang informatika untuk kemanfaatan dan kesejahteraan masyarakat.',
          'Meningkatkan implementasi kerjasama dengan institusi di dalam dan luar negeri pada bidang ilmu Informatika maupun bidang ilmu lainnya.',
          'Mengembangkan tata pamong dan tata kelola program studi informatika yang kredibel, transparan, akuntabel, bertanggung jawab, dan adil.',
          'Menjalankan program kerja Fakultas Ilmu Komputer, Universitas Amikom Purwokerto.'
        ],
        'tujuan': [
          'Menyelenggarakan pendidikan dalam bidang ilmu informatika yang berkualitas berwawasan technopreneur untuk menghasilkan lulusan yang handal di bidang teknologi.',
          'Penelitian, inovasi, serta penyebarluasan pengetahuan dan teknologi dalam bidang ilmu informatika yang memberikan kemanfaatan kepada masyarakat guna meningkatkan daya saing bangsa.',
          'Pengabdian dan pemberdayaan masyarakat dengan menerapkan keilmuan bidang ilmu informatika guna mendorong pengembangan potensi masyarakat untuk mewujudkan kesejahteraan masyarakat.',
          'Kerjasama yang produktif serta kemitraan yang harmonis dengan para pemangku kepentingan dalam lingkup tri dharma perguruan tinggi untuk menghasilkan karya di bidang Ilmu informatika yang bermanfaat dan berkualitas.',
          'Tata pamong dan tata kelola Program Studi Informatika yang kredibel, transparan, akuntabel, bertanggung jawab, dan profesional.'
        ],
        'strategi': [
          'Mewujudkan Pendidikan yang berkualitas berwawasan technopreneur pada program studi Informatika.',
          'Meningkatkan inovasi dan penyebarluasan hasil penelitian pada program studi Informatika.',
          'Peningkatan kegiatan pengabdian dan pemberdayaan masyarakat pada program studi Informatika.',
          'Meningkatkan kualitas dan implementasi kerjasama serta kemitraan yang harmonis dengan para pemangku kepentingan.',
          'Mewujudkan tata pamong dan tata kelola program studi Informatika yang kredibel, transparan, akuntabel, bertanggung jawab dan profesional.'
        ],
      };
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
          'Visi & Misi',
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
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF501F66)),
              )
            : _error != null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
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
            onPressed: _load,
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

  Widget _buildContent() {
    final prodiData = _getProdiData(_data!.profile.prodi);

    return ListView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 100,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHeader(prodiData['nama']).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: 'Visi',
          icon: CupertinoIcons.eye_fill,
          color: Colors.blue,
          content: [prodiData['visi']],
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Misi',
          icon: CupertinoIcons.rocket_fill,
          color: Colors.orange,
          content: prodiData['misi'],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Tujuan',
          icon: CupertinoIcons.flag_fill,
          color: Colors.red,
          content: prodiData['tujuan'],
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Strategi',
          icon: CupertinoIcons.chart_bar_alt_fill,
          color: Colors.green,
          content: prodiData['strategi'],
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildHeader(String namaProdi) {
    return Column(
      children: [
        const Icon(CupertinoIcons.building_2_fill, size: 64, color: Color(0xFF501F66)),
        const SizedBox(height: 12),
        const Text(
          'Program Studi',
          style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        Text(
          namaProdi,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF501F66), letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> content,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      opacity: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF501F66),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final isList = content.length > 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isList) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: isList ? TextAlign.left : TextAlign.justify,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
