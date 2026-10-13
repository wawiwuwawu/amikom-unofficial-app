import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_amikom/models/notifikasi.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/app_kit.dart';
import 'package:app_amikom/widgets/notifikasi_push_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  testWidgets('render state memuat menampilkan indikator loading', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const NotifikasiPushCard(loading: true)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Memuat status notifikasi push…'), findsOneWidget);
  });

  testWidgets('render state gagal menampilkan pesan dan tombol Coba Lagi', (
    tester,
  ) async {
    var dicobaUlang = false;

    await tester.pumpWidget(
      wrap(
        NotifikasiPushCard(
          pesanGagal: 'Gagal memuat status notifikasi push',
          onMuatUlang: () => dicobaUlang = true,
        ),
      ),
    );

    expect(find.text('Gagal memuat status notifikasi push'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    expect(dicobaUlang, isTrue);
  });

  testWidgets(
    'render state nonaktif menampilkan pill Nonaktif dan tombol aktifkan',
    (tester) async {
      var diaktifkan = false;

      await tester.pumpWidget(
        wrap(
          NotifikasiPushCard(
            status: const NotifikasiOptinStatus(enabled: false),
            onAktifkan: () => diaktifkan = true,
          ),
        ),
      );

      expect(find.text('Nonaktif'), findsOneWidget);
      expect(find.text('Aktifkan Notifikasi Push'), findsOneWidget);

      await tester.tap(find.text('Aktifkan Notifikasi Push'));
      await tester.pump();
      expect(diaktifkan, isTrue);
    },
  );

  testWidgets(
    'render state aktif menampilkan pill Aktif, tombol Matikan',
    (tester) async {
      var dimatikan = false;

      await tester.pumpWidget(
        wrap(
          NotifikasiPushCard(
            status: const NotifikasiOptinStatus(enabled: true, tokenCount: 2),
            onMatikan: () => dimatikan = true,
          ),
        ),
      );

      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('Matikan'), findsOneWidget);
      expect(
        find.text('Android · Terhubung · 2 perangkat'),
        findsOneWidget,
        reason: 'status aktif menampilkan platform & jumlah token terdaftar',
      );

      await tester.tap(find.text('Matikan'));
      await tester.pump();
      expect(dimatikan, isTrue);
    },
  );

  testWidgets(
    'render state aktif terkunci 429 menonaktifkan Matikan dan menampilkan hitungan mundur',
    (tester) async {
      var dimatikan = false;

      await tester.pumpWidget(
        wrap(
          NotifikasiPushCard(
            status: const NotifikasiOptinStatus(enabled: true, tokenCount: 1),
            retryAfterSeconds: 30,
            onMatikan: () => dimatikan = true,
          ),
        ),
      );

      expect(find.text('Coba lagi dalam 30s'), findsOneWidget);
      final btn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(btn.onPressed, isNull);

      await tester.tap(find.text('Coba lagi dalam 30s'));
      await tester.pump();
      expect(dimatikan, isFalse);
    },
  );

  testWidgets(
    'render state tidak tersedia (503) menampilkan pill warning dan tombol disabled',
    (tester) async {
      var diaktifkan = false;

      await tester.pumpWidget(
        wrap(
          NotifikasiPushCard(
            tidakTersedia: true,
            onAktifkan: () => diaktifkan = true,
          ),
        ),
      );

      expect(find.text('Tidak Tersedia'), findsOneWidget);
      expect(
        find.text('Layanan notifikasi push sedang dinonaktifkan oleh server.'),
        findsOneWidget,
      );

      final surface = tester.widget<AppSurface>(find.byType(AppSurface));
      expect(surface.variant, AppSurfaceVariant.warning);

      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);

      await tester.tap(find.text('Aktifkan Notifikasi Push'));
      await tester.pump();
      expect(diaktifkan, isFalse);
    },
  );

  testWidgets('tombol disabled dan menampilkan spinner saat busy', (
    tester,
  ) async {
    var diaktifkan = false;

    await tester.pumpWidget(
      wrap(
        NotifikasiPushCard(
          status: const NotifikasiOptinStatus(enabled: false),
          busy: true,
          onAktifkan: () => diaktifkan = true,
        ),
      ),
    );

    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Aktifkan Notifikasi Push'));
    await tester.pump();
    expect(diaktifkan, isFalse);
  });

  testWidgets(
    'hitung mundur rate limit 429 menampilkan Coba lagi dalam Ns dan tombol disabled',
    (tester) async {
      var diaktifkan = false;

      await tester.pumpWidget(
        wrap(
          NotifikasiPushCard(
            status: const NotifikasiOptinStatus(enabled: false),
            retryAfterSeconds: 45,
            onAktifkan: () => diaktifkan = true,
          ),
        ),
      );

      expect(find.text('Coba lagi dalam 45s'), findsOneWidget);
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);

      await tester.tap(find.text('Coba lagi dalam 45s'));
      await tester.pump();
      expect(diaktifkan, isFalse);
    },
  );

  testWidgets('NotifikasiPushSheet memuat panduan sistem tanpa tautan luar', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const NotifikasiPushSheet()));

    expect(find.text('Agar Notifikasi Kampus Masuk'), findsOneWidget);
    expect(
      find.textContaining('tidak perlu memasang aplikasi lain'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Jangan optimalkan'),
      findsOneWidget,
      reason: 'panduan pengecualian optimasi baterai aplikasi ini',
    );
    expect(
      find.textContaining('Ini Amikom?'),
      findsNWidgets(2),
      reason: 'langkah izin & optimasi baterai menyebut nama aplikasi ini',
    );
    expect(
      find.textContaining('ketuk notifikasi untuk membuka detail'),
      findsOneWidget,
      reason: 'langkah terakhir: notifikasi masuk & ketuk membuka detail',
    );
    expect(
      find.byType(FilledButton),
      findsNothing,
      reason: 'tidak ada tombol keluar aplikasi / unduh pihak ketiga',
    );
  });
}
