// Regresi label poin SKKM di widget SKPI (kontrak BE 2026-11-01 §4.2):
// sumber `portal-skkm` → pill "POIN (VALID)", `tidak-berlaku` → bar 0/100
// disembunyikan + pill "SKKM TIDAK BERLAKU", `estimasi-berkas` → seperti
// semula.

import 'package:app_amikom/models/transkrip.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/ringkasan_skpi_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SkpiData _skpi({required String sumber, int poin = 55}) => SkpiData(
      isSkpiEligible: false,
      statusSkpi: 'Belum lulus SKPI',
      skkmPoinInfo: SkkmPoinInfo.fromJson({
        'estimasi_poin_skkm': '$poin',
        'description': 'Keterangan poin dari BE.',
        'sumber': sumber,
      }),
      peringatanKekurangan: const [],
    );

Future<void> pumpSkpi(WidgetTester tester, SkpiData data) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: RingkasanSkpiWidget(data: data)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sumber portal-skkm → pill POIN (VALID)', (tester) async {
    await pumpSkpi(tester, _skpi(sumber: 'portal-skkm'));

    expect(tester.takeException(), isNull);
    expect(find.text('55 / 100 POIN (VALID)'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('sumber estimasi-berkas → pill pola lama tanpa klaim valid',
      (tester) async {
    await pumpSkpi(tester, _skpi(sumber: 'estimasi-berkas'));

    expect(tester.takeException(), isNull);
    expect(find.text('55 / 100 POIN'), findsOneWidget);
  });

  testWidgets('sumber tidak-berlaku → pill SKKM TIDAK BERLAKU, bar disembunyi',
      (tester) async {
    await pumpSkpi(tester, _skpi(sumber: 'tidak-berlaku', poin: 0));

    expect(tester.takeException(), isNull);
    expect(find.text('SKKM TIDAK BERLAKU'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing,
        reason: 'bar 0/100 menyesatkan saat SKKM tidak berlaku');
  });

  testWidgets('lulus SKPI tetap menang atas semua sumber', (tester) async {
    await pumpSkpi(
      tester,
      SkpiData(
        isSkpiEligible: true,
        statusSkpi: 'Lulus',
        skkmPoinInfo: SkkmPoinInfo.fromJson({
          'estimasi_poin_skkm': '100',
          'description': '',
          'sumber': 'portal-skkm',
        }),
        peringatanKekurangan: const [],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('LULUS SKPI'), findsOneWidget);
  });
}
