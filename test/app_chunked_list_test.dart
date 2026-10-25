// Test AppChunkedList: pembagian chunk (45 item → 3 kartu grup), render
// lazy via ListView.builder (baris jauh belum dibangun sebelum discroll),
// header/footer tetap tampil termasuk saat daftar kosong.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/app_kit.dart';

Widget _bunch(
  List<int> items, {
  Widget? header,
  Widget? footer,
  int chunkSize = 20,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: AppChunkedList<int>(
        items: items,
        chunkSize: chunkSize,
        header: header,
        footer: footer,
        rowBuilder: (_, n) => Text('Item $n'),
      ),
    ),
  );
}

void main() {
  testWidgets('45 item terbagi menjadi 3 kartu grup saat semua terlihat',
      (tester) async {
    // Viewport tinggi agar 3 chunk (45 baris) termuat serentak — chunk yang
    // sudah jauh di luar layar justru di-unmount (perilaku lazy), sehingga
    // jumlah grup hanya bisa dihitung saat semuanya terlihat.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_bunch(List.generate(45, (i) => i)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 44'), findsOneWidget);
    // 45 item / chunk 20 = 3 chunk = 3 AppListGroup.
    expect(find.byType(AppListGroup), findsNWidgets(3));
  });

  testWidgets('daftar 300 item dirender lazy: baris jauh belum dibangun',
      (tester) async {
    await tester.pumpWidget(_bunch(List.generate(300, (i) => i)));

    expect(tester.takeException(), isNull);
    expect(find.text('Item 0'), findsOneWidget);
    // Baris jauh BELUM dibangun — bukti render lazy.
    expect(find.text('Item 150'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Item 40'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Item 40'), findsOneWidget);
    expect(find.text('Item 250'), findsNothing);
  });

  testWidgets('header tampil di atas daftar dan footer setelah chunk terakhir',
      (tester) async {
    await tester.pumpWidget(_bunch(
      List.generate(10, (i) => i),
      header: const Text('HEADER'),
      footer: const Text('FOOTER'),
    ));

    expect(find.text('HEADER'), findsOneWidget);
    expect(find.text('Item 0'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('FOOTER'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('FOOTER'), findsOneWidget);
    expect(find.text('Item 9'), findsOneWidget);
  });

  testWidgets('header tetap dirender saat daftar kosong', (tester) async {
    await tester.pumpWidget(_bunch(
      const [],
      header: const Text('HEADER'),
      footer: const Text('FOOTER'),
    ));

    expect(find.text('HEADER'), findsOneWidget);
    expect(find.text('FOOTER'), findsOneWidget);
    expect(find.byType(AppListGroup), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
