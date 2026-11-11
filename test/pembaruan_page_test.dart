import 'package:app_amikom/services/pembaruan_service.dart';
import 'package:app_amikom/widgets/pembaruan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CATATAN: testWidgets berjalan di FakeAsync — IO nyata (createTemp,
/// unduhan berkas) di dalamnya TIDAK PERNAH selesai. Karena itu UI diuji
/// dengan menggerakkan [PembaruanService.instance.statusUnduh] langsung;
/// alur unduhan nyata (single-flight, notif, gagal) tercakup di
/// `pembaruan_service_test.dart` (plain test, IO sah).
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PembaruanService.instance.resetUntukTest();
    PembaruanService.instance.pakaiVersiUntukTest('1.13.0');
  });

  InfoPembaruan info() => const InfoPembaruan(
        versi: '1.14.0',
        catatan: 'Perbaikan bug dan peningkatan stabilitas.',
        urlApk: 'https://github.test/download/app-release.apk',
        namaApk: 'app-release.apk',
        sha256: null,
      );

  Future<void> pompa(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: PembaruanPage(info: info())));
  }

  testWidgets('render idle: judul versi, catatan rilis, tombol unduh, lewati',
      (tester) async {
    await pompa(tester);
    // versiTerpasang() async — pump agar subtitle terpasang sebelum assert.
    await tester.pump();
    expect(find.text('Pembaruan v1.14.0 Tersedia'), findsOneWidget);
    expect(find.text('Versi terpasang: 1.13.0'), findsOneWidget);
    expect(
      find.text('Perbaikan bug dan peningkatan stabilitas.'),
      findsOneWidget,
    );
    expect(find.text('Unduh & Perbarui'), findsOneWidget);
    expect(find.text('Lewati versi ini'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('fase mengunduh: progres + tombol lewati mati', (tester) async {
    await pompa(tester);
    PembaruanService.instance.statusUnduh.value = const StatusUnduh(
      fase: FaseUnduh.mengunduh,
      progres: 0.42,
      versi: '1.14.0',
    );
    await tester.pump();

    expect(find.text('Mengunduh… 42% — boleh tinggalkan halaman ini.'),
        findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final lewati = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Lewati versi ini'),
    );
    expect(lewati.onPressed, isNull);
    final unduh = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Mengunduh…'),
    );
    expect(unduh.onPressed, isNull);
  });

  testWidgets('fase siap: kartu sukses + tombol Buka Pemasang',
      (tester) async {
    await pompa(tester);
    PembaruanService.instance.statusUnduh.value = const StatusUnduh(
      fase: FaseUnduh.siap,
      progres: 1,
      pathApk: '/cache/pembaruan/app-release.apk',
      versi: '1.14.0',
    );
    await tester.pump();

    expect(
      find.text(
        'Unduhan selesai dan terverifikasi. Dialog pemasangan '
        'seharusnya sudah terbuka; bila tidak, ketuk tombol di bawah.',
      ),
      findsOneWidget,
    );
    expect(find.text('Buka Pemasang'), findsOneWidget);
  });

  testWidgets('fase gagal: AppSurface danger tanpa jejak teknis',
      (tester) async {
    await pompa(tester);
    PembaruanService.instance.statusUnduh.value = const StatusUnduh(
      fase: FaseUnduh.gagal,
      pesanGagal: 'Gagal mengunduh pembaruan. Coba lagi nanti.',
      versi: '1.14.0',
    );
    await tester.pump();

    expect(
      find.text('Gagal mengunduh pembaruan. Coba lagi nanti.'),
      findsOneWidget,
    );
    expect(find.textContaining('DioException'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    // Tombol kembali 'Unduh & Perbarui' untuk dicoba lagi.
    expect(find.text('Unduh & Perbarui'), findsOneWidget);
  });

  testWidgets('status versi lain (basi) diperlakukan idle', (tester) async {
    await pompa(tester);
    PembaruanService.instance.statusUnduh.value = const StatusUnduh(
      fase: FaseUnduh.mengunduh,
      progres: 0.5,
      versi: '9.9.9',
    );
    await tester.pump();
    // Bukan status unduhan halaman ini → UI idle: tombol unduh normal.
    expect(find.text('Unduh & Perbarui'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('lewati versi → pop dengan hasil "lewati"', (tester) async {
    String? hasil;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () async {
                hasil = await bukaPembaruanPage(context, info());
              },
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.text('Pembaruan v1.14.0 Tersedia'), findsOneWidget);

    await tester.tap(find.text('Lewati versi ini'));
    await tester.pumpAndSettle();
    expect(hasil, 'lewati');
    expect(await PembaruanService.instance.dilewati(info()), isTrue);
  });
}
