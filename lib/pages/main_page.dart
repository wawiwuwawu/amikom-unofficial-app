import 'dart:ui';
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
import 'placeholder_page.dart';
import 'transkrip_page.dart';
import 'panduan_list_page.dart';
import 'jadwal_page.dart';
import 'krs/krs_main_page.dart';
import 'asisten_page.dart';
import 'seminar_page.dart';
import 'mbkm_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  int _refreshTrigger = 0;

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
        currentWidget = TranskripPage(onBack: () => setState(() => _currentIndex = 0));
        break;
      case 3:
        currentWidget = const PlaceholderPage(title: 'Menu Lainnya', icon: CupertinoIcons.ellipsis);
        showMainAppBar = true;
        appBarTitle = 'Menu Lainnya';
        break;
      case 4:
        currentWidget = AbsensiPage(onBack: () => setState(() => _currentIndex = 0));
        break;
      case 5:
        currentWidget = KrsMainPage(onBack: () => setState(() => _currentIndex = 0));
        break;
      case 6:
        currentWidget = AsistenPage(onBack: () => setState(() => _currentIndex = 0));
        break;
      case 7:
        currentWidget = SeminarPage(onBack: () => setState(() => _currentIndex = 0));
        break;
      case 8:
        currentWidget = MbkmPage(onBack: () => setState(() => _currentIndex = 0));
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
              backgroundColor: Colors.white.withOpacity(0.5),
              leading: _currentIndex != 0
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                      onPressed: () => setState(() => _currentIndex = 0),
                    )
                  : null,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              actions: [
                if (_currentIndex == 0)
                  IconButton(
                    icon: const Icon(CupertinoIcons.refresh),
                    onPressed: () => setState(() => _refreshTrigger++),
                  ).animate().rotate(),
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
    return Container(
      margin: const EdgeInsets.only(top: 32), 
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF501F66).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => setState(() => _currentIndex = 4), // Changed from Navigator.push
        backgroundColor: const Color(0xFFBBDEFB), // Ice Blue Deep
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(CupertinoIcons.qrcode_viewfinder, color: Color(0xFF501F66), size: 32), 
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .scaleXY(end: 1.05, duration: 1500.ms, curve: Curves.easeInOut), 
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 32,
          opacity: 0.75,
          blur: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(0, CupertinoIcons.square_grid_2x2_fill, 'Home'),
              _navItem(1, CupertinoIcons.calendar, 'Jadwal'),
              const SizedBox(width: 48), // Space for FAB
              _navItem(2, CupertinoIcons.doc_text_fill, 'Nilai'),
              _navItem(3, CupertinoIcons.bars, 'Menu'),
            ],
          ),
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutExpo),
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
            Icon(
              icon, 
              size: selected ? 28 : 24, 
              color: color,
            ),
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
                  colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // Ice Blue gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(CupertinoIcons.book_fill, size: 48, color: Color(0xFF501F66)),
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
            _drawerItem(0, CupertinoIcons.square_grid_2x2_fill, 'Dashboard'),
            _drawerItem(1, CupertinoIcons.calendar, 'Jadwal Perkuliahan'),
            _drawerItem(2, CupertinoIcons.doc_text_fill, 'Transkrip Nilai'),
            const Divider(),
            ListTile(
              leading: const Icon(CupertinoIcons.news_solid),
              title: const Text('Berita Kampus'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BeritaListPage()));
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.rosette),
              title: const Text('KHS'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KhsPage()));
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.speaker_2_fill),
              title: const Text('Pengumuman Akademik'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PengumumanListPage()));
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.book),
              title: const Text('Panduan Akademik'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PanduanListPage()));
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.doc_text_search),
              title: const Text('KRS'),
              onTap: () {
                setState(() => _currentIndex = 5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.briefcase),
              title: const Text('Asisten Praktikum'),
              onTap: () {
                setState(() => _currentIndex = 6);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.person_3_fill),
              title: const Text('Jadwal Seminar 🎓'),
              onTap: () {
                setState(() => _currentIndex = 7);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.building_2_fill),
              title: const Text('MBKM Internal'),
              onTap: () {
                setState(() => _currentIndex = 8);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            _drawerItem(3, CupertinoIcons.ellipsis, 'Lainnya'),
            const Divider(),
            ListTile(
              leading: const Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                await ApiClient.instance.fullLogout();
                if (!context.mounted) return;
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
      leading: Icon(icon, color: selected ? const Color(0xFF501F66) : Colors.grey.shade600),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? const Color(0xFF501F66) : Colors.black87,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFF501F66).withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
