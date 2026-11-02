import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/models/sertifikasi.dart';
import 'package:app_amikom/widgets/app_kit.dart';
import 'package:app_amikom/widgets/sertifikasi_form_sheet.dart';

Widget _host({
  required List<AppDropdownEntry<String>> entries,
  String? value,
  ValueChanged<String?>? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            width: 280,
            child: AppDropdownField<String>(
              entries: entries,
              value: value,
              hint: 'Pilih',
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  setUp(() {
    ApiClient.instance.dio.httpClientAdapter = _SertifikasiAdapter();
  });

  testWidgets('duplikat value di-dedup — menu hanya berisi satu, memilih tetap bekerja', (
    tester,
  ) async {
    String? terpilih;
    await tester.pumpWidget(_host(
      entries: const [
        AppDropdownEntry(value: '1', label: 'Ganjil'),
        // Duplikat value — dulu memicu assert
        // "There should be exactly one item with [DropdownButton]'s value".
        AppDropdownEntry(value: '1', label: 'Ganjil (dup)'),
        AppDropdownEntry(value: '2', label: 'Genap'),
      ],
      onChanged: (v) => terpilih = v,
    ));

    await tester.tap(find.byType(AppDropdownField<String>));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ganjil'), findsOneWidget);
    expect(find.text('Ganjil (dup)'), findsNothing);

    await tester.tap(find.text('Genap'));
    await tester.pumpAndSettle();
    expect(terpilih, '2');
  });

  testWidgets('value tidak ada di entries → jatuh ke hint, tanpa crash', (tester) async {
    await tester.pumpWidget(_host(
      entries: const [
        AppDropdownEntry(value: '1', label: 'Ganjil'),
        AppDropdownEntry(value: '2', label: 'Genap'),
      ],
      value: '9',
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Pilihan usang tidak ditampilkan — hint yang tampil.
    expect(find.text('Pilih'), findsOneWidget);
    expect(find.text('9'), findsNothing);
  });

  testWidgets('menu terbuka ke BAWAH meski item terpilih bukan entri pertama', (
    tester,
  ) async {
    await tester.pumpWidget(_host(
      entries: const [
        AppDropdownEntry(value: '1', label: 'Item 1'),
        AppDropdownEntry(value: '2', label: 'Item 2'),
        AppDropdownEntry(value: '3', label: 'Item 3'),
        AppDropdownEntry(value: '4', label: 'Item 4'),
      ],
      // Pilihan di UJUNG daftar — DropdownButton lama membuka menu ke atas
      // karena menu menyelaraskan pusat item terpilih.
      value: '4',
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppDropdownField<String>));
    await tester.pumpAndSettle();

    final trigger = tester.getRect(find.byType(AppDropdownField<String>));
    final itemPertamaMenu = tester.getRect(find.text('Item 1'));

    expect(tester.takeException(), isNull);
    // Menu dimulai di bawah trigger — tidak menjulur ke atas.
    expect(itemPertamaMenu.top, greaterThanOrEqualTo(trigger.bottom - 1));
  });

  testWidgets('sheet edit sertifikasi: judul tak ada di opsi + tahun di luar jendela 5 tahun → tanpa crash', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SertifikasiFormSheet(
          onSuccess: () {},
          itemToEdit: SertifikasiItem(
            id: 1,
            npm: '241010001',
            jenisAktivitas: '',
            // Judul tersimpan TIDAK ada di daftar opsi mock.
            judul: 'Sertifikat X',
            grade: 'A',
            // Tahun 2015 di luar jendela yearOptions() (5 tahun ke belakang).
            tahun: 2015,
            file: '',
            fileUrl: '',
            verifikasi: 0,
            status: '',
            keterangan: '',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Judul lama jatuh ke fallback "SERTIFIKASI LAINNYA" + teks lainnya terisi.
    expect(find.text('Sertifikasi Lainnya'), findsOneWidget);
    expect(find.text('Sertifikat X'), findsOneWidget);
    // Tahun 2015 disisipkan ke daftar pilihan — tampil di dropdown.
    expect(find.text('2015'), findsOneWidget);
  });
}

class _SertifikasiAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/options')) {
      return ResponseBody.fromString(
        jsonEncode({
          'status': 'success',
          'data': {
            'sertifikasi': [
              {'value': 'SERTIFIKASI LAINNYA', 'label': 'Sertifikasi Lainnya'},
            ],
          },
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'status': 'success', 'data': []}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }
}
