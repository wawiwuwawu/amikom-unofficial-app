import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/models/notifikasi.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/app_kit.dart';
import 'package:app_amikom/widgets/notifikasi_push_card.dart';

void main() {
  setUpAll(() {
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

    expect(find.byType(AppLoading), findsOneWidget);
    expect(find.text('Memuat status notifikasi push…'), findsOneWidget);
  });

  testWidgets('render state gagal menampilkan pesan dan tombol Muat Ulang', (
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
    expect(find.text('Muat Ulang'), findsOneWidget);

    await tester.tap(find.text('Muat Ulang'));
    await tester.pump();
    expect(dicobaUlang, isTrue);
  });

  testWidgets(
    'render state aktif menampilkan pill Aktif & jumlah perangkat (baca saja)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const NotifikasiPushCard(
            status: NotifikasiOptinStatus(enabled: true, tokenCount: 2),
          ),
        ),
      );

      expect(find.text('Aktif'), findsOneWidget);
      expect(
        find.text('Notifikasi kampus aktif di perangkat ini.'),
        findsOneWidget,
      );
      expect(find.text('Android · Terhubung · 2 perangkat'), findsOneWidget);
      // Status-only: tak ada tombol Aktifkan/Matikan sama sekali.
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Matikan'), findsNothing);
      expect(find.text('Aktifkan Notifikasi Push'), findsNothing);
    },
  );

  testWidgets(
    'render state nonaktif memandu ke Pengaturan sistem, tanpa tombol aplikasi',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const NotifikasiPushCard(
            status: NotifikasiOptinStatus(enabled: false),
          ),
        ),
      );

      expect(find.text('Nonaktif'), findsOneWidget);
      expect(
        find.textContaining('dinyalakan otomatis'),
        findsOneWidget,
        reason: 'default-on: notifikasi dinyalakan app sendiri',
      );
      expect(
        find.textContaining('Pengaturan > Notifikasi > Ini Amikom?'),
        findsOneWidget,
        reason: 'panduan izin lewat Pengaturan sistem, bukan tombol in-app',
      );
      // Tak ada tombol aktivasi di kartu.
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Aktifkan Notifikasi Push'), findsNothing);
    },
  );

  testWidgets(
    'nonaktif karena server menolak registrasi: pesan server + Muat Ulang, '
    'tanpa panduan Pengaturan',
    (tester) async {
      var dimuatUlang = 0;
      await tester.pumpWidget(
        wrap(
          NotifikasiPushCard(
            status: const NotifikasiOptinStatus(enabled: false, tokenCount: 0),
            serverGagal: true,
            onMuatUlang: () => dimuatUlang += 1,
          ),
        ),
      );

      expect(find.text('Nonaktif'), findsOneWidget);
      expect(find.textContaining('server pengelola sedang'), findsOneWidget);
      expect(find.textContaining('izin di HP sudah cukup'), findsOneWidget);
      expect(
        find.textContaining('buka Pengaturan > Notifikasi'),
        findsNothing,
        reason: 'server 503 tak bisa diperbaiki lewat setelan HP',
      );

      await tester.tap(find.text('Muat Ulang'));
      expect(dimuatUlang, 1);
    },
  );

  testWidgets(
    'nonaktif dengan token tersisa memperingati server bermasalah',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const NotifikasiPushCard(
            status: NotifikasiOptinStatus(enabled: false, tokenCount: 1),
          ),
        ),
      );

      expect(find.text('Nonaktif'), findsOneWidget);
      expect(find.textContaining('server notifikasi sedang'), findsOneWidget);
    },
  );

  testWidgets(
    'nonaktif karena perangkat/gateway gagal tampil pesan khusus, '
    'bukan panduan Pengaturan',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const NotifikasiPushCard(
            status: NotifikasiOptinStatus(enabled: false, tokenCount: 0),
            perangkatGagal: true,
          ),
        ),
      );

      expect(find.text('Nonaktif'), findsOneWidget);
      expect(
        find.textContaining('tidak bisa dinyalakan di perangkat ini'),
        findsOneWidget,
      );
      expect(
        find.textContaining('buka Pengaturan > Notifikasi'),
        findsNothing,
        reason: 'kegagalan gateway tak bisa diperbaiki lewat setelan sistem',
      );
    },
  );

  testWidgets(
    'render state tidak tersedia (503) menampilkan frasa persis & Muat Ulang',
    (tester) async {
      var dimuatUlang = false;

      await tester.pumpWidget(
        wrap(
          NotifikasiPushCard(
            tidakTersedia: true,
            onMuatUlang: () => dimuatUlang = true,
          ),
        ),
      );

      expect(find.text('Tidak Tersedia'), findsOneWidget);
      expect(
        find.text('Layanan notifikasi push sedang dinonaktifkan oleh server.'),
        findsOneWidget,
      );
      expect(find.text('Muat Ulang'), findsOneWidget);

      final surface = tester.widget<AppSurface>(find.byType(AppSurface));
      expect(surface.variant, AppSurfaceVariant.warning);

      await tester.tap(find.text('Muat Ulang'));
      await tester.pump();
      expect(dimuatUlang, isTrue);
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
      find.textContaining('ketuk notifikasi untuk membuka daftar'),
      findsOneWidget,
      reason: 'langkah terakhir: notifikasi masuk & ketuk membuka daftar',
    );
    expect(
      find.textContaining('Pengingat jadwal juga aktif otomatis'),
      findsOneWidget,
      reason: 'info pengingat jadwal 30 menit mengikuti izin notifikasi',
    );
    expect(
      find.byType(FilledButton),
      findsNothing,
      reason: 'tidak ada tombol keluar aplikasi / unduh pihak ketiga',
    );
  });
}
