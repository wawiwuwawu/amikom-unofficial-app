import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../config/menu_catalog.dart';
import '../services/api_client.dart';
import '../services/notifikasi_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';
import 'absensi_page.dart';
import 'dashboard_page.dart';
import 'jadwal_page.dart';
import 'nilai/nilai_page.dart';
import 'notifikasi_list_page.dart';

/// Kerangka utama aplikasi (hasil redesign navigasi).
///
/// Tiga permukaan navigasi, masing-masing dengan satu tugas yang jelas:
///
///  1. Bottom nav — Beranda · Jadwal · Nilai · Menu, plus tombol QR presensi
///     di tengah. Hanya untuk hal yang SERING dibuka.
///  2. Drawer — pintasan untuk hal yang JARANG dibuka tapi perlu cepat
///     ditemukan: pengumuman, berita, panduan, tata krama, visi misi, surat.
///  3. Tab Menu — SEMUA layanan, dikelompokkan dari yang paling sering
///     dipakai sampai paling jarang, dilengkapi pencarian.
///
/// Perubahan dari versi lama:
///  * Baris "aksi cepat" di beranda dihapus — dulu 3 dari 4 tombolnya hanya
///    menuju tab yang sudah ada (duplikasi).
///  * Seluruh daftar menu kini berasal dari satu sumber [MenuCatalog];
///    sebelumnya drawer & grid menu punya daftar terpisah yang harus
///    disinkronkan manual.
///  * Tab "Nilai" tidak lagi langsung membuka satu halaman panjang.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  int _refreshTrigger = 0;
  int _unreadNotifCount = 0;

  final _searchController = TextEditingController();
  String _menuQuery = '';

  static const _titles = ['Beranda', 'Jadwal', 'Nilai', 'Menu'];

  @override
  void initState() {
    super.initState();
    _checkUnreadNotif();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkUnreadNotif() async {
    try {
      final count = await NotifikasiService().getUnreadCount();
      if (mounted) setState(() => _unreadNotifCount = count);
    } catch (_) {
      // Diamkan: badge notifikasi bukan fungsi kritis.
    }
  }

  // ── Navigasi ──────────────────────────────────────────────────────────────

  void _selectTab(int index) {
    if (index == _currentIndex && index == 0) {
      setState(() => _refreshTrigger++); // ketuk ulang = segarkan
      return;
    }
    setState(() {
      _currentIndex = index;
      if (index != 3 && _menuQuery.isNotEmpty) {
        _menuQuery = '';
        _searchController.clear();
      }
    });
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _openNotifikasi() async {
    await _openPage(
      NotifikasiListPage(onBack: () => Navigator.pop(context)),
    );
    _checkUnreadNotif();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardPage(refreshTrigger: _refreshTrigger),
          const JadwalPage(),
          const NilaiPage(),
          _buildMenuPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Text(_titles[_currentIndex], style: AppText.h2),
      actions: [
        IconButton(
          tooltip: 'Notifikasi',
          icon: _unreadNotifCount > 0
              ? _notifBellWithBadge()
              : const Icon(CupertinoIcons.bell, size: 21),
          onPressed: _openNotifikasi,
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _notifBellWithBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(CupertinoIcons.bell, size: 21),
        Positioned(
          right: -5,
          top: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16),
            decoration: const BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
            ),
            child: Text(
              _unreadNotifCount > 99 ? '99+' : '$_unreadNotifCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Drawer: yang jarang dibuka, tapi perlu cepat ditemukan ───────────────

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _drawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.xl,
                ),
                children: [
                  _drawerSection(
                    'Informasi & Pengumuman',
                    CupertinoIcons.bell_fill,
                    MenuCatalog.drawerInformasi,
                  ),
                  _drawerSection(
                    'Panduan & Referensi',
                    CupertinoIcons.book_fill,
                    MenuCatalog.drawerReferensi,
                  ),
                  _drawerSection(
                    'Layanan Penting',
                    CupertinoIcons.checkmark_seal_fill,
                    MenuCatalog.drawerLayananPenting,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Divider(),
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      CupertinoIcons.square_arrow_right,
                      size: 20,
                      color: AppColors.danger,
                    ),
                    title: Text(
                      'Keluar',
                      style: AppText.h3.copyWith(
                        fontSize: 14,
                        color: AppColors.danger,
                      ),
                    ),
                    onTap: () async {
                      await ApiClient.instance.fullLogout();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Text(
                      'Aplikasi tidak resmi. Seluruh data berasal dari layanan '
                      'akademik kampus.',
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primarySoft],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              CupertinoIcons.square_grid_2x2_fill,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'AmiApp',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Layanan mahasiswa dalam satu tempat',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSection(
    String title,
    IconData icon,
    List<MenuEntry> entries,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: AppText.overline,
                ),
              ),
            ],
          ),
        ),
        for (final entry in entries)
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(entry.icon, size: 19, color: AppColors.primarySoft),
            title: Text(entry.title, style: AppText.h3.copyWith(fontSize: 13.5)),
            trailing: entry.title == 'Notifikasi' && _unreadNotifCount > 0
                ? AppPill('$_unreadNotifCount', tone: AppPillTone.danger)
                : const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
            onTap: () {
              final page = entry.build(context);
              Navigator.pop(context); // tutup drawer
              _openPage(page);
              if (entry.title == 'Notifikasi') _checkUnreadNotif();
            },
          ),
      ],
    );
  }

  // ── Tab Menu: semua menu dikelompokkan per frekuensi pemakaian ────────────

  Widget _buildMenuPage() {
    final results = _menuQuery.isEmpty ? null : MenuCatalog.search(_menuQuery);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        AppSearchField(
          controller: _searchController,
          hint: 'Cari layanan… (mis. KHS, SKMK, surat)',
          onChanged: (v) => setState(() => _menuQuery = v),
          onClear: () {
            _searchController.clear();
            setState(() => _menuQuery = '');
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        if (results != null) ...[
          Text('HASIL PENCARIAN (${results.length})', style: AppText.overline),
          const SizedBox(height: AppSpacing.sm),
          if (results.isEmpty)
            AppSurface(
              child: const Text(
                'Tidak ada layanan yang cocok. Coba kata kunci lain.',
              ),
            )
          else
            AppListGroup.from([for (final e in results) _menuRow(e)]),
        ] else
          for (final group in MenuCatalog.grouped.entries)
            AppSection(
              title: group.key.label,
              trailing: Text(
                '${group.value.length} layanan',
                style: AppText.label.copyWith(fontWeight: FontWeight.w400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.key.hint, style: AppText.bodySm),
                  const SizedBox(height: AppSpacing.md),
                  AppListGroup.from([
                    for (final e in group.value) _menuRow(e),
                  ]),
                ],
              ),
            ),
      ],
    );
  }

  Widget _menuRow(MenuEntry entry) {
    return AppListRow(
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: AppDeco.softPrimary(radius: AppRadius.sm),
        child: Icon(entry.icon, size: 19, color: AppColors.primary),
      ),
      title: entry.title,
      subtitle: entry.description,
      trailing: const Icon(
        CupertinoIcons.chevron_forward,
        size: 17,
        color: AppColors.textMuted,
      ),
      onTap: () => _openPage(entry.build(context)),
    );
  }

  // ── Bottom nav: Beranda · Jadwal · Nilai · Menu (+ tombol QR presensi) ────

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _navItem(0, CupertinoIcons.square_grid_2x2_fill, 'Beranda'),
              _navItem(1, CupertinoIcons.calendar, 'Jadwal'),
              _absensiButton(),
              _navItem(2, CupertinoIcons.doc_text_fill, 'Nilai'),
              _navItem(3, CupertinoIcons.bars, 'Menu'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label.copyWith(
                  fontSize: 10.5,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Presensi (QR) — fitur yang paling sering dibuka mahasiswa, karena itu
  /// diletakkan di tengah bar navigasi agar paling mudah dijangkau jempol.
  Widget _absensiButton() {
    return Expanded(
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _openPage(
                AbsensiPage(onBack: () => Navigator.pop(context)),
              ),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  CupertinoIcons.qrcode_viewfinder,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
