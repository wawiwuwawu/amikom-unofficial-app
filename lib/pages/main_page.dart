import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'absensi_page.dart';
import 'berita_list_page.dart';
import 'dashboard_page.dart';
import 'khs_page.dart';
import 'pengumuman_list_page.dart';
import 'placeholder_page.dart';
import 'transkrip_page.dart';

class _LowerFabLocation extends FloatingActionButtonLocation {
  const _LowerFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry g) {
    final x = (g.scaffoldSize.width - g.floatingActionButtonSize.width) / 2;
    final y = g.contentBottom + g.minInsets.bottom -
        g.floatingActionButtonSize.height / 2 + 20;
    return Offset(x, y);
  }

  @override
  String toString() => 'LowerFabLocation';
}

const _fabLocation = _LowerFabLocation();

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  int _refreshTrigger = 0;

  static const _titles = [
    'Dashboard',
    'Jadwal Perkuliahan',
    'Transkrip Nilai',
    'Lainnya',
  ];

  final List<Widget> _pages = [
    PlaceholderPage(title: 'Jadwal Perkuliahan', icon: Icons.calendar_month),
    const TranskripPage(),
    PlaceholderPage(title: 'Lainnya', icon: Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Dashboard' : _titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _refreshTrigger++),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.school, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Aplikasi Amikom',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _drawerItem(0, Icons.dashboard, 'Dashboard'),
            _drawerItem(1, Icons.calendar_month, 'Jadwal Perkuliahan'),
            _drawerItem(2, Icons.assignment, 'Transkrip Nilai'),
            ListTile(
              leading: const Icon(Icons.newspaper),
              title: const Text('Berita Kampus'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BeritaListPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.grading),
              title: const Text('KHS'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KhsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('Pengumuman Akademik'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PengumumanListPage()),
                );
              },
            ),
            const Divider(),
            _drawerItem(3, Icons.more_horiz, 'Lainnya'),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                ApiClient.instance.clearTokens();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _currentIndex == 0
          ? DashboardPage(refreshTrigger: _refreshTrigger)
          : _pages[_currentIndex - 1],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AbsensiPage()),
        ),
        child: const Icon(Icons.person),
      ),
      floatingActionButtonLocation: _fabLocation,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard, 'Dashboard'),
              _navItem(1, Icons.calendar_month, 'Jadwal'),
              const SizedBox(width: 48),
              _navItem(2, Icons.assignment, 'Transkrip'),
              _navItem(3, Icons.more_horiz, 'Lainnya'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    final color = selected ? Colors.indigo : Colors.grey;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : null)),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title) {
    final selected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.indigo : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : null,
          color: selected ? Colors.indigo : null,
        ),
      ),
      selected: selected,
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
