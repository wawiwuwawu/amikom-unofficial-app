// Regresi layout shell utama (/main) — halaman pertama yang dilihat setelah login.
//
// Bug yang dijaga: tombol QR presensi dibungkus `Center` di dalam `Row` bottom
// nav. `Center` tanpa `heightFactor` mengisi seluruh tinggi yang ditawarkan,
// dan slot `bottomNavigationBar` Scaffold memberi tinggi loose — akibatnya bar
// navigasi setinggi layar, body Scaffold (IndexedStack) kolaps jadi 0 px, dan
// AppBar "Beranda" tertutup bar. Gejala di perangkat: setelah login layar
// kosong. Lihat `_absensiButton()` di lib/pages/main_page.dart.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/pages/dashboard_page.dart';
import 'package:app_amikom/pages/jadwal_page.dart';
import 'package:app_amikom/pages/main_page.dart';
import 'package:app_amikom/pages/nilai/nilai_page.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/app_kit.dart';

void main() {
  setUpAll(() {
    // ApiClient membaca API_BASE_URL dari dotenv saat instance pertama dibuat.
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const MainPage()),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  double screenHeight(WidgetTester tester) =>
      tester.view.physicalSize.height / tester.view.devicePixelRatio;

  double bodyHeight(WidgetTester tester) =>
      tester.getSize(find.byType(IndexedStack).first).height;

  /// Bar bawah = `SafeArea` terdekat yang membungkus tombol QR presensi.
  /// Dipakai agar pencarian ikon tab tidak tertukar dengan ikon di isi halaman.
  Finder bottomBar() => find
      .ancestor(
        of: find.byIcon(CupertinoIcons.qrcode_viewfinder),
        matching: find.byType(SafeArea),
      )
      .first;

  testWidgets('bottom nav tidak menelan tinggi body halaman', (tester) async {
    await pumpShell(tester);

    // Body Scaffold harus punya tinggi nyata (bukan 0 seperti saat regresi).
    expect(bodyHeight(tester), greaterThan(100));

    // Tombol QR harus duduk di bar bawah, bukan di tengah layar.
    final qrCenterY =
        tester.getCenter(find.byIcon(CupertinoIcons.qrcode_viewfinder)).dy;
    expect(qrCenterY, greaterThan(screenHeight(tester) * 0.8));
  });

  testWidgets('setiap tab dibangun dengan tinggi nyata', (tester) async {
    await pumpShell(tester);

    // IndexedStack membangun keempat tab sekaligus (tab non-aktif offstage,
    // jadi perlu skipOffstage: false) — tidak ada yang boleh 0 px.
    final tabs = <(String, Finder)>[
      ('Beranda', find.byType(DashboardPage, skipOffstage: false)),
      ('Jadwal', find.byType(JadwalPage, skipOffstage: false)),
      ('Nilai', find.byType(NilaiPage, skipOffstage: false)),
    ];
    for (final (label, target) in tabs) {
      expect(target, findsWidgets, reason: 'Tab $label tidak ter-mount.');
      expect(
        tester.getSize(target).height,
        greaterThan(100),
        reason: 'Tab $label tidak mendapat tinggi dari shell.',
      );
    }

    // Tab Menu: kolom pencariannya harus ikut ter-layout, bukan 0 px.
    expect(
      tester
          .getSize(find.byType(AppSearchField, skipOffstage: false))
          .height,
      greaterThan(20),
    );
  });

  testWidgets('berpindah tab menampilkan halaman terpilih dengan tinggi wajar',
      (tester) async {
    await pumpShell(tester);

    // Tab aktif harus onstage (ditemukan tanpa skipOffstage) dan punya tinggi.
    final tabs = <(IconData, Finder)>[
      (CupertinoIcons.calendar, find.byType(JadwalPage)),
      (CupertinoIcons.doc_text_fill, find.byType(NilaiPage)),
      (CupertinoIcons.square_grid_2x2_fill, find.byType(DashboardPage)),
    ];

    for (final (icon, page) in tabs) {
      await tester.tap(
        find.descendant(of: bottomBar(), matching: find.byIcon(icon)),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(page, findsOneWidget, reason: 'Tab tidak aktif setelah diketuk.');
      expect(
        tester.getSize(page).height,
        greaterThan(100),
        reason: 'Halaman tab kolaps setelah perpindahan tab.',
      );
      expect(bodyHeight(tester), greaterThan(100));
    }
  });
}
