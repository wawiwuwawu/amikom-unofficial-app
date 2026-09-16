import 'package:flutter/cupertino.dart';

import '../models/dashboard.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

class VisiMisiPage extends StatefulWidget {
  const VisiMisiPage({super.key});

  @override
  State<VisiMisiPage> createState() => _VisiMisiPageState();
}

class _VisiMisiPageState extends State<VisiMisiPage> {
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
      final data = await ApiClient.instance.getDashboard();
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
        'visi':
            'Menghasilkan lulusan S1 yang kompeten di bidang Manajemen Sistem Informasi dan E-business, berwawasan global, serta mampu mengembangkan inovasi teknologi yang mendukung pertumbuhan industri digital di tingkat nasional dan internasional pada tahun 2029.',
        'misi': [
          'Pendidikan Berkualitas: Menyelenggarakan pendidikan yang inovatif dan relevan dengan kebutuhan industri dalam bidang manajemen sistem informasi dan e-business, dengan pendekatan yang berfokus pada pengembangan keterampilan praktis dan analitis.',
          'Riset Inovatif: Mengembangkan dan mendukung penelitian yang berkontribusi pada pemecahan masalah aktual dalam manajemen sistem informasi dan e-business, serta mendorong lahirnya inovasi yang dapat diterapkan dalam dunia bisnis dan teknologi.',
          'Pengabdian Masyarakat: Melaksanakan kegiatan pengabdian kepada masyarakat dengan menerapkan keahlian dalam sistem informasi dan e-business untuk meningkatkan kesejahteraan masyarakat dan mendorong transformasi digital di sektor-sektor penting.',
          'Kerjasama Strategis: Meningkatkan kolaborasi dengan industri, pemerintah, dan institusi pendidikan lainnya baik di tingkat nasional maupun internasional, untuk memastikan relevansi kurikulum dan memperkuat peluang kerja bagi lulusan.',
        ],
        'tujuan': [
          'Kualitas Lulusan: Mencetak lulusan yang memiliki kompetensi tinggi dalam manajemen sistem informasi dan e-business, serta mampu bersaing di pasar kerja global dan memiliki wawasan technopreneur.',
          'Karya Penelitian: Mewujudkan karya-karya penelitian dan inovasi yang berdampak pada pengembangan teknologi informasi dan bisnis digital, yang relevan dengan kebutuhan masyarakat dan industri.',
          'Karya Pengabdian: Meningkatkan kesejahteraan masyarakat melalui penerapan teknologi informasi dan keahlian dalam e-business dalam program pengabdian masyarakat yang berkelanjutan.',
          'Kerjasama: Menjalin kemitraan strategis dengan industri, lembaga pemerintah, dan komunitas untuk memperkaya pengalaman belajar mahasiswa dan relevansi kurikulum dalam menghadapi perkembangan teknologi dan bisnis.',
        ],
        'strategi': [
          'Pengembangan Kurikulum: Secara berkala memperbarui kurikulum agar sesuai dengan perkembangan teknologi dan kebutuhan industri, dengan fokus pada manajemen sistem informasi dan e-business serta integrasi aspek technopreneur.',
          'Program Magang dan Kerjasama: Mengembangkan jejaring dengan alumni, industri, dan institusi lain untuk membuka peluang magang, penelitian kolaboratif, dan kerjasama proyek yang relevan dengan konsentrasi program studi.',
          'Penelitian dan Inovasi: Menciptakan lingkungan yang kondusif bagi penelitian dengan menyediakan fasilitas dan dukungan yang memadai, serta mendorong mahasiswa dan dosen untuk aktif dalam penelitian yang berorientasi pada solusi bisnis digital.',
          'Peningkatan Kualitas Dosen: Meningkatkan kompetensi dosen melalui pelatihan, penelitian kolaboratif, dan partisipasi dalam konferensi internasional, serta menerapkan metode pengajaran yang inovatif dan berbasis praktik nyata.',
          'Pengabdian Masyarakat: Melibatkan mahasiswa dan dosen dalam program pengabdian yang relevan dengan kebutuhan masyarakat, terutama dalam bidang transformasi digital dan penerapan teknologi informasi di sektor publik.',
        ],
      };
    } else if (prodi.contains('teknologi informasi')) {
      return {
        'nama': 'Teknologi Informasi',
        'visi':
            'Menjadi Program Studi Teknologi Informasi yang unggul dalam bidang Internet of Things (IoT), Cyber Security, dan Game Development, serta berwawasan Technopreneurship di tingkat nasional pada tahun 2029.',
        'misi': [
          'Pendidikan Berkualitas: Menyelenggarakan pendidikan yang berkualitas dengan pendekatan berbasis teknologi dan Technopreneurship, serta mengintegrasikan konsentrasi IoT, Cyber Security, dan Game Development.',
          'Riset Inovatif: Mendorong penelitian dan pengembangan inovasi teknologi yang relevan dengan kebutuhan masyarakat dan industri, serta berkontribusi pada solusi masalah sosial.',
          'Pengabdian Masyarakat: Mengembangkan program pengabdian masyarakat yang berbasis teknologi informasi untuk meningkatkan kesejahteraan masyarakat dan memberdayakan komunitas lokal.',
          'Kerjasama Strategis: Meningkatkan kerjasama dengan berbagai pihak, baik dalam maupun luar negeri, untuk pengembangan pendidikan dan penelitian yang berkelanjutan untuk menciptakan ekosistem yang mendukung pengembangan technopreneurship.',
        ],
        'tujuan': [
          'Meningkatkan kualitas pendidikan dan pelatihan dalam rangka menghasilkan sumber daya manusia berkualitas berjiwa technopreneur yang berakademik unggul sesuai dengan perkembangan ilmu pengetahuan dan teknologi yang sesuai dengan kebutuhan stakeholder.',
          'Menghasilkan karya-karya yang diakui baik secara nasional maupun internasional melalui penelitian dan pengabdian masyarakat.',
          'Berperan aktif dalam kegiatan tri dharma perguruan tinggi pada tingkat lokal, nasional maupun internasional.',
          'Meningkatkan pelayanan pendidikan melalui penjaminan mutu internal maupun penjaminan mutu eksternal sehingga stakeholder memperoleh kepuasan.',
        ],
        'strategi': [
          'Mewujudkan Pendidikan yang berkualitas berwawasan technopreneur pada PS.',
          'Meningkatkan inovasi dan penyebarluasan hasil penelitian pada PS Teknologi Informasi.',
          'Peningkatan kegiatan pengabdian dan pemberdayaan masyarakat pada PS Teknologi Informasi.',
          'Meningkatkan kualitas dan implementasi kerjasama serta kemitraan yang harmonis dengan para pemangku kepentingan.',
          'Mewujudkan tata pamong dan tata kelola program studi Teknologi Informasi yang kredibel, transparan, akuntabel, bertanggung jawab dan profesional.',
        ],
      };
    } else {
      // Default to Informatika
      return {
        'nama': 'Informatika',
        'visi':
            'Menjadi program studi unggul dalam pembelajaran bidang informatika yang menghasilkan mahasiswa berkemampuan merancang, membangun, dan mengevaluasi perangkat lunak dengan wawasan Technoprenuership di tahun 2024.',
        'misi': [
          'Menyelenggarakan pendidikan dalam bidang Informatika yang berkualitas dan berwawasan technoprenuer sesuai dengan perkembangan ilmu pengetahuan dan teknologi.',
          'Mengembangkan iklim penelitian dalam bidang informatika yang inovatif dan berorientasi hilir untuk kemanfaatan masyarakat luas.',
          'Mengembangkan kegiatan pengabdian masyarakat melalui penerapan ilmu pengetahuan dan teknologi di bidang informatika untuk kemanfaatan dan kesejahteraan masyarakat.',
          'Meningkatkan implementasi kerjasama dengan institusi di dalam dan luar negeri pada bidang ilmu Informatika maupun bidang ilmu lainnya.',
          'Mengembangkan tata pamong dan tata kelola program studi informatika yang kredibel, transparan, akuntabel, bertanggung jawab, dan adil.',
          'Menjalankan program kerja Fakultas Ilmu Komputer, Universitas Amikom Purwokerto.',
        ],
        'tujuan': [
          'Menyelenggarakan pendidikan dalam bidang ilmu informatika yang berkualitas berwawasan technopreneur untuk menghasilkan lulusan yang handal di bidang teknologi.',
          'Penelitian, inovasi, serta penyebarluasan pengetahuan dan teknologi dalam bidang ilmu informatika yang memberikan kemanfaatan kepada masyarakat guna meningkatkan daya saing bangsa.',
          'Pengabdian dan pemberdayaan masyarakat dengan menerapkan keilmuan bidang ilmu informatika guna mendorong pengembangan potensi masyarakat untuk mewujudkan kesejahteraan masyarakat.',
          'Kerjasama yang produktif serta kemitraan yang harmonis dengan para pemangku kepentingan dalam lingkup tri dharma perguruan tinggi untuk menghasilkan karya di bidang Ilmu informatika yang bermanfaat dan berkualitas.',
          'Tata pamong dan tata kelola Program Studi Informatika yang kredibel, transparan, akuntabel, bertanggung jawab, dan profesional.',
        ],
        'strategi': [
          'Mewujudkan Pendidikan yang berkualitas berwawasan technopreneur pada program studi Informatika.',
          'Meningkatkan inovasi dan penyebarluasan hasil penelitian pada program studi Informatika.',
          'Peningkatan kegiatan pengabdian dan pemberdayaan masyarakat pada program studi Informatika.',
          'Meningkatkan kualitas dan implementasi kerjasama serta kemitraan yang harmonis dengan para pemangku kepentingan.',
          'Mewujudkan tata pamong dan tata kelola program studi Informatika yang kredibel, transparan, akuntabel, bertanggung jawab dan profesional.',
        ],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Visi & Misi',
      subtitle: 'Program studi Anda',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: AppAsyncView<Dashboard>(
        loading: _loading,
        error: _error,
        data: _data,
        onRetry: _load,
        loadingMessage: 'Memuat visi & misi…',
        emptyTitle: 'Data visi & misi belum tersedia',
        emptyMessage: 'Coba muat ulang beberapa saat lagi.',
        emptyIcon: CupertinoIcons.eye,
        builder: _buildContent,
      ),
    );
  }

  Widget _buildContent(Dashboard data) {
    final prodiData = _getProdiData(data.profile.prodi);
    final visi = prodiData['visi'] as String;
    final misi = List<String>.from(prodiData['misi']);
    final tujuan = List<String>.from(prodiData['tujuan']);
    final strategi = List<String>.from(prodiData['strategi']);

    return ListView(
      padding: AppSpacing.page,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHeader(prodiData['nama'] as String),
        _contentSection(
          title: 'Visi',
          icon: CupertinoIcons.eye_fill,
          toneBg: AppColors.infoBg,
          toneFg: AppColors.info,
          child: Text(
            visi,
            style: AppText.body.copyWith(height: 1.7),
            textAlign: TextAlign.justify,
          ),
        ),
        _contentSection(
          title: 'Misi',
          icon: CupertinoIcons.rocket_fill,
          toneBg: AppColors.warningBg,
          toneFg: AppColors.warning,
          child: _numberedList(misi),
        ),
        _contentSection(
          title: 'Tujuan',
          icon: CupertinoIcons.flag_fill,
          toneBg: AppColors.dangerBg,
          toneFg: AppColors.danger,
          child: _numberedList(tujuan),
        ),
        _contentSection(
          title: 'Strategi',
          icon: CupertinoIcons.chart_bar_alt_fill,
          toneBg: AppColors.successBg,
          toneFg: AppColors.success,
          child: _numberedList(strategi),
        ),
      ],
    );
  }

  /// Kartu identitas program studi — pengikat konteks sebelum teks panjang.
  Widget _buildHeader(String namaProdi) {
    return AppSurface(
      variant: AppSurfaceVariant.hero,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: AppDeco.softPrimary(),
            child: const Icon(
              CupertinoIcons.building_2_fill,
              size: 26,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Program Studi', style: AppText.label),
          const SizedBox(height: AppSpacing.xs),
          Text(namaProdi, style: AppText.h1, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  /// Seksi teks: judul hierarkis (overline + ikon) dan kartu isi yang lapang.
  Widget _contentSection({
    required String title,
    required IconData icon,
    required Color toneBg,
    required Color toneFg,
    required Widget child,
  }) {
    return AppSection(
      title: title,
      trailing: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: toneBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 16, color: toneFg),
      ),
      child: AppSurface(child: child),
    );
  }

  /// Daftar bernomor — memudahkan merujuk butir misi/tujuan/strategi.
  Widget _numberedList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, text) in items.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: AppDeco.softPrimary(radius: AppRadius.sm),
                child: Text(
                  '${index + 1}',
                  style: AppText.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: AppText.body.copyWith(height: 1.7),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
