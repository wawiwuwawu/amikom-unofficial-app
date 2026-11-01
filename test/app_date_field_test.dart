// Regresi widget seragam 2026-11-01:
//  * AppDateField — tampilan tanggal Indonesia, dialog kalender terlokalkan,
//    clamp minDate (field Selesai tak boleh mendahului Mulai), batal tak
//    memicu onChanged.
//  * AppMarkdownComposer/markdownKeHtml — konversi 4 token + escape HTML.

import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/app_date_field.dart';
import 'package:app_amikom/widgets/app_markdown_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpField(
  WidgetTester tester,
  DateTime? value,
  ValueChanged<DateTime> onChanged, {
  DateTime? minDate,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id')],
      locale: const Locale('id'),
      home: Scaffold(
        body: AppDateField(
          label: 'Tanggal Selesai',
          value: value,
          minDate: minDate,
          onChanged: onChanged,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('belum dipilih → hint; terpilih → tanggal Indonesia',
      (tester) async {
    await pumpField(tester, null, (_) {});
    expect(find.text('Pilih Tanggal'), findsOneWidget);

    await pumpField(tester, DateTime(2026, 11, 8), (_) {});
    expect(find.text('8 November 2026'), findsOneWidget);
  });

  testWidgets('pilih tanggal di dialog → onChanged terpanggil',
      (tester) async {
    DateTime? dipilih;
    await pumpField(tester, DateTime(2026, 11, 8), (v) => dipilih = v);

    await tester.tap(find.text('8 November 2026'));
    await tester.pumpAndSettle();

    // Dialog kalender (Bahasa Indonesia) → ketuk tanggal 12 lalu konfirmasi.
    // Label tombol konfirmasi Material dalam lokalisasi 'id' adalah "OKE".
    await tester.tap(find.text('12').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OKE'));
    await tester.pumpAndSettle();

    expect(dipilih, DateTime(2026, 11, 12));
  });

  testWidgets('tutup dialog tanpa memilih → onChanged tidak terpanggil',
      (tester) async {
    var dipanggil = false;
    await pumpField(tester, DateTime(2026, 11, 8), (_) => dipanggil = true);

    await tester.tap(find.text('8 November 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(dipanggil, isFalse);
  });

  testWidgets('pilihan lebih awal dari minDate → di-clamp ke minDate',
      (tester) async {
    final minDate = DateTime(2026, 11, 10);
    DateTime? dipilih;
    await pumpField(
      tester,
      DateTime(2026, 11, 10),
      (v) => dipilih = v,
      minDate: minDate,
    );

    await tester.tap(find.text('10 November 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OKE'));
    await tester.pumpAndSettle();

    // Dialog dibuka dengan firstDate = minDate → tidak ada hari sebelum 10;
    // tanggal yang tersedia pertama tepat minDate.
    expect(dipilih, minDate);
  });

  test('markdownKeHtml: tebal, judul, daftar, dan escape HTML', () {
    final html = markdownKeHtml(
      '# Judul <b>berbahaya</b>\n\nBaris biasa & simbol\n'
      '## Subjudul\n- butir satu\n- butir dua\n\n**tebal** akhir',
    );

    expect(html, contains('<h1>Judul &lt;b&gt;berbahaya&lt;/b&gt;</h1>'));
    expect(html, contains('<p>Baris biasa &amp; simbol</p>'));
    expect(html, contains('<h2>Subjudul</h2>'));
    expect(html, contains('<ul><li>butir satu</li><li>butir dua</li></ul>'));
    expect(html, contains('<strong>tebal</strong>'));
    expect(html, isNot(contains('<b>berbahaya')));
  });
}
