import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_client.dart';
import '../widgets/glass_card.dart';
import 'absensi_page.dart';
import 'berita_list_page.dart';
import 'dashboard_page.dart';
import 'khs_page.dart';
import 'pengumuman_list_page.dart';
import 'transkrip_page.dart';
import 'panduan_list_page.dart';
import 'jadwal_page.dart';
import 'krs/krs_main_page.dart';
import 'asisten_page.dart';
import 'seminar_page.dart';
import 'mbkm_page.dart';
import 'visi_misi_page.dart';
import 'visi_misi_institusi_page.dart';
import 'tata_krama_page.dart';
import 'penafian_page.dart';
import 'agenda_akademik_page.dart';
import 'jadwal_ujian_page.dart';
import 'pusat_studi/pusat_studi_page.dart';
import 'sertifikasi_page.dart';
import 'organisasi_page.dart';
import 'prestasi_page.dart';
import 'seminar_workshop_page.dart';
import 'notifikasi_list_page.dart';
import 'keuangan_page.dart';
import 'sp_page.dart';
import 'skmk_page.dart';
import 'izin_penelitian_page.dart';
import 'surat_tugas_page.dart';
import 'pkl_page.dart';
import 'ujian_susulan_page.dart';
import 'ppks_page.dart';
import 'skripsi_page.dart';
import '../services/notifikasi_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final int _refreshTrigger = 0;
  int _unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _checkUnreadNotif();
  }

  Future<void> _checkUnreadNotif() async {
    try {
      final count = await NotifikasiService().getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotifCount = count);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Determine which page to show
    Widget currentWidget;
    bool showMainAppBar = false;
    String appBarTitle = '';

    switch (_currentIndex) {
      case 0:
        currentWidget = DashboardPage(refreshTrigger: _refreshTrigger);
        showMainAppBar = true;
        appBarTitle = 'Dashboard';
        break;
      case 1:
        currentWidget = const JadwalPage();
        showMainAppBar = true;
        appBarTitle = 'Jadwal Perkuliahan';
        break;
      case 2:
        currentWidget = TranskripPage(
          onBack: () => setState(() => _currentIndex = 0),
        );
        break;
      case 3:
        currentWidget = _buildMenuGridPage();
        showMainAppBar = true;
        appBarTitle = 'Menu Layanan';
        break;
      default:
        currentWidget = DashboardPage(refreshTrigger: _refreshTrigger);
        showMainAppBar = true;
        appBarTitle = 'Dashboard';
    }

    return Scaffold(
      extendBody: true,
      appBar: showMainAppBar
          ? AppBar(
              title: Text(
                appBarTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              leading: _currentIndex != 0
                  ? IconButton(
                      icon: const Icon(
                        CupertinoIcons.back,
                        color: Color(0xFF501F66),
                      ),
                      onPressed: () => setState(() => _currentIndex = 0),
                    )
                  : null,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        CupertinoIcons.bell_fill,
                        color: Color(0xFF501F66),
                      ),
                      if (_unreadNotifCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _unreadNotifCount > 9
                                  ? '9+'
                                  : _unreadNotifCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotifikasiListPage(
                          onBack: () => Navigator.pop(context),
                        ),
                      ),
                    );
                    _checkUnreadNotif();
                  },
                ),
              ],
            )
          : null, // Hide main AppBar if the inner page (Transkrip/Absensi) has its own
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFCFF), // Pearl White
              Color(0xFFE3F2FD), // Ice Blue
            ],
          ),
        ),
        child: currentWidget,
      ),
      floatingActionButton: _buildFloatingAction(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFloatingAction() {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(top: 32),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF501F66).withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AbsensiPage(onBack: () => Navigator.pop(context)),
              ),
            );
          },
          backgroundColor: const Color(0xFFBBDEFB), // Ice Blue Deep
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(
            CupertinoIcons.qrcode_viewfinder,
            color: Color(0xFF501F66),
            size: 32,
          ),
        ).animate().scaleXY(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildBottomNav() {
    return RepaintBoundary(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 32,
            opacity: 0.88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navItem(0, CupertinoIcons.square_grid_2x2_fill, 'Beranda'),
                _navItem(1, CupertinoIcons.calendar, 'Jadwal'),
                const SizedBox(width: 48), // Space for FAB
                _navItem(2, CupertinoIcons.doc_text_fill, 'Nilai'),
                _navItem(3, CupertinoIcons.bars, 'Menu'),
              ],
            ),
          ),
        ).animate().slideY(
          begin: 1,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutExpo,
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    final color = selected ? const Color(0xFF501F66) : Colors.grey.shade500;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: selected ? 28 : 24, color: color),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: selected ? 11 : 10,
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFFAFCFF),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE3F2FD),
                    Color(0xFFBBDEFB),
                  ], // Ice Blue gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(
                    CupertinoIcons.book_fill,
                    size: 48,
                    color: Color(0xFF501F66),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ini Amikom?',
                    style: TextStyle(
                      color: Color(0xFF501F66),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(0, CupertinoIcons.square_grid_2x2_fill, 'Beranda'),
            ListTile(
              leading: const Icon(
                CupertinoIcons.bell_fill,
                color: Color(0xFF501F66),
              ),
              title: const Text('Notifikasi & Pengumuman'),
              trailing: _unreadNotifCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_unreadNotifCount baru',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotifikasiListPage(
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                );
                _checkUnreadNotif();
              },
            ),
            _drawerItem(1, CupertinoIcons.calendar, 'Jadwal Perkuliahan'),
            _drawerItem(2, CupertinoIcons.doc_text_fill, 'Transkrip Nilai'),
            const Divider(),
            // ponytail: unified categories avoiding 370 lines of duplicated ListTiles
            ..._getMenuCategories().entries.expand((entry) => [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              ...entry.value.map((item) => ListTile(
                leading: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color? ?? const Color(0xFF501F66),
                ),
                title: Text(item['title'] as String),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: item['page'] as WidgetBuilder,
                    ),
                  );
                },
              )),
            ]),
            ListTile(
              leading: const Icon(
                CupertinoIcons.square_arrow_right,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await ApiClient.instance.fullLogout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title) {
    final selected = _currentIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? const Color(0xFF501F66) : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? const Color(0xFF501F66) : Colors.black87,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFF501F66).withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _getMenuCategories() {
    return {
      'Perkuliahan & Akademik': [
        {
          'title': 'KRS Online',
          'icon': CupertinoIcons.doc_text_search,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              KrsMainPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Semester Pendek',
          'icon': CupertinoIcons.layers_alt_fill,
          'color': const Color(0xFFE65100),
          'page': (BuildContext ctx) => SpPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'KHS',
          'icon': CupertinoIcons.rosette,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) => const KhsPage(),
        },
        {
          'title': 'Skripsi & TA',
          'icon': CupertinoIcons.book_circle_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              SkripsiPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Jadwal Ujian',
          'icon': CupertinoIcons.check_mark_circled,
          'color': const Color(0xFF2E7D32),
          'page': (BuildContext ctx) =>
              JadwalUjianPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Agenda Akademik',
          'icon': CupertinoIcons.calendar,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              AgendaAkademikPage(onBack: () => Navigator.pop(ctx)),
        },
      ],
      'Persuratan & Mandiri': [
        {
          'title': 'SKMK',
          'icon': CupertinoIcons.doc_plaintext,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              SkmkPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Izin Penelitian',
          'icon': CupertinoIcons.search_circle_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              IzinPenelitianPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Surat Tugas',
          'icon': CupertinoIcons.doc_on_clipboard_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              SuratTugasPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'PKL & Mandiri',
          'icon': CupertinoIcons.briefcase_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) => PklPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Ujian Susulan',
          'icon': CupertinoIcons.calendar_badge_minus,
          'color': const Color(0xFFD32F2F),
          'page': (BuildContext ctx) =>
              UjianSusulanPage(onBack: () => Navigator.pop(ctx)),
        },
      ],
      'Kemahasiswaan & Keuangan': [
        {
          'title': 'Tagihan VA',
          'icon': CupertinoIcons.creditcard_fill,
          'color': const Color(0xFF2E7D32),
          'page': (BuildContext ctx) =>
              KeuanganPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Satgas PPKS',
          'icon': CupertinoIcons.shield_fill,
          'color': const Color(0xFFD32F2F),
          'page': (BuildContext ctx) =>
              PpksPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Asisten Praktikum',
          'icon': CupertinoIcons.briefcase,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              AsistenPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Jadwal Seminar',
          'icon': CupertinoIcons.person_3_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              SeminarPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'MBKM Internal',
          'icon': CupertinoIcons.building_2_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              MbkmPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Pusat Studi',
          'icon': CupertinoIcons.building_2_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              PusatStudiPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Sertifikasi',
          'icon': CupertinoIcons.doc_checkmark_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              SertifikasiPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Organisasi',
          'icon': CupertinoIcons.person_3_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              OrganisasiPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Prestasi',
          'icon': CupertinoIcons.star_fill,
          'color': const Color(0xFFFBC02D),
          'page': (BuildContext ctx) =>
              PrestasiPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Seminar Workshop',
          'icon': CupertinoIcons.rectangle_grid_2x2_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              SeminarWorkshopPage(onBack: () => Navigator.pop(ctx)),
        },
      ],
      'Informasi & Dokumen Kampus': [
        {
          'title': 'Berita Kampus',
          'icon': CupertinoIcons.news_solid,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) => const BeritaListPage(),
        },
        {
          'title': 'Pengumuman',
          'icon': CupertinoIcons.speaker_2_fill,
          'color': const Color(0xFFE65100),
          'page': (BuildContext ctx) => const PengumumanListPage(),
        },
        {
          'title': 'Panduan Akademik',
          'icon': CupertinoIcons.book,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) => const PanduanListPage(),
        },
        {
          'title': 'Visi Misi Prodi',
          'icon': CupertinoIcons.eye_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              VisiMisiPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Visi Misi Institusi',
          'icon': CupertinoIcons.building_2_fill,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              VisiMisiInstitusiPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Tata Krama',
          'icon': CupertinoIcons.person_2_alt,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) =>
              TataKramaPage(onBack: () => Navigator.pop(ctx)),
        },
        {
          'title': 'Penafian',
          'icon': CupertinoIcons.exclamationmark_shield,
          'color': const Color(0xFF501F66),
          'page': (BuildContext ctx) => const PenafianPage(),
        },
      ],
    };
  }

  Widget _buildMenuGridPage() {
    final categories = _getMenuCategories();
    const categoryIcons = {
      'Perkuliahan & Akademik': CupertinoIcons.book_fill,
      'Persuratan & Mandiri': CupertinoIcons.doc_on_clipboard_fill,
      'Kemahasiswaan & Keuangan': CupertinoIcons.person_3_fill,
      'Informasi & Dokumen Kampus': CupertinoIcons.info_circle_fill,
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 130,
      ),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        for (final entry in categories.entries) ...[
          _buildMenuCategorySection(
            entry.key,
            categoryIcons[entry.key] ?? CupertinoIcons.square_grid_2x2_fill,
            entry.value,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildMenuCategorySection(
    String title,
    IconData icon,
    List<Map<String, dynamic>> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF501F66)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF501F66),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, index) {
            final item = items[index];
            final Color itemColor = item['color'] as Color;
            return GlassCard(
              borderRadius: 16,
              padding: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final WidgetBuilder builder = item['page'];
                  Navigator.push(context, MaterialPageRoute(builder: builder));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: itemColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
