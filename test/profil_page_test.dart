// Widget test ProfilPage — render biodata (kontrak "-" untuk kosong/null),
// seksi WiFi (toggle + override + tombol manual), dan status galat ramah.
//
// Pola: adapter Dio palsu + dotenv.loadFromString setUpAll + SyncTransformer
// + mock secure storage/prefs bawaan plugin.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/pages/profil_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/wifi_kampus_service.dart';
import 'package:app_amikom/widgets/app_kit.dart';

class _GatewayFake implements WifiKampusGateway {
  _GatewayFake();

  String statusLogin = 'berhasil';
  bool diWifiKampus = false;
  bool online = false;
  String? usernameTerkirim;
  String? passwordTerkirim;
  int loginCalls = 0;
  bool clearCredentialsCalled = false;
  dynamic Function()? onWifiUpSink;

  @override
  Future<void> setCredentials(String username, String password) async {
    usernameTerkirim = username;
    passwordTerkirim = password;
  }

  @override
  Future<void> clearCredentials() async {
    clearCredentialsCalled = true;
  }

  @override
  Future<String> loginIfConnected() async {
    loginCalls++;
    return statusLogin;
  }

  @override
  Future<Map<String, dynamic>> statusJaringan() async => {
        'diWifiKampus': diWifiKampus,
        'ssidTerbaca': true,
        'portalTerjangkau': true,
        'online': diWifiKampus,
      };

  @override
  void onWifiUp(dynamic callback) {}

  @override
  void mintaIzinSsidSetelahGranted(VoidCallback callback) {}

  @override
  Future<bool> mintaIzinSsid() async => true;
}

class _BiodataAdapter implements HttpClientAdapter {
  _BiodataAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/api/v1/biodata')) return handler(options);
    throw Exception('endpoint tak dikenal: ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _balasBiodata(Map<String, dynamic> data) {
  return ResponseBody.fromString(
    jsonEncode({'status': 'success', 'data': data}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Map<String, dynamic> _biodataContoh() => {
      'data_diri': {
        'nama': 'Wawan Setiawan',
        'nikktp': '3301010512070001',
        'tempat_lahir': 'Purwokerto',
        'tanggal_lahir': '2005-12-07',
        'jenis_kelamin': {'kode': 'L', 'label': 'Laki-laki'},
        'agama': {'kode': 'I', 'label': 'Islam'},
        'status_perkawinan': 'Belum Menikah',
        'jumlah_anak': '',
        'email': 'wawan@student.amikom.ac.id',
        'no_hp': '081234567890',
        'nisn': '',
      },
      'alamat': {
        'alamat': 'Jl. Jend. Sudirman No. 1',
        'rt': '02',
        'rw': '05',
        'kecamatan': 'Kembaran',
        'kabupaten': 'Banyumas',
        'propinsi': 'Jawa Tengah',
        'kode_pos': '53182',
      },
      'pendidikan': {
        'sd': {'nama': 'SD Negeri 1', 'tahun_lulus': '2018'},
        'smp': {'nama': 'SMP Negeri 2', 'tahun_lulus': '2021'},
        'sma': {'nama': 'SMA Negeri 3', 'tahun_lulus': '2024'},
      },
      'orang_tua': {
        'ayah': {'nama': 'Sugiyanto', 'pekerjaan': 'Wiraswasta'},
        'ibu': {'nama': 'Sri Wahyuni', 'pekerjaan': 'Ibu Rumah Tangga'},
      },
      'foto_url': '',
    };

/// Scroll halaman sampai seksi WiFi (ekor halaman panjang) terlihat.
Future<void> _scrollKeSeksiWifi(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Simpan manual'),
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> pompa(
    WidgetTester tester, {
    required _GatewayFake gateway,
    required ResponseBody Function(RequestOptions) handler,
  }) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.dio.httpClientAdapter = _BiodataAdapter(
      (options) => handler(options),
    );
    ApiClient.instance.dio.transformer = SyncTransformer();
    unawaited(
        ApiClient.instance.setUserInfo('2212400011', 'Tester'));
    await tester.pumpWidget(MaterialApp(
      home: ProfilPage(wifiKampus: WifiKampusService.untukTest(gateway)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('render biodata lengkap: nama, NIM sesi, nilai, dan "-" '
      'untuk field kosong', (tester) async {
    final payload = _biodataContoh();
    (payload['data_diri'] as Map)['nisn'] = '';
    await pompa(
      tester,
      gateway: _GatewayFake(),
      handler: (_) => _balasBiodata(payload),
    );

    expect(find.text('Wawan Setiawan'), findsNWidgets(2),
        reason: 'nama muncul di header DAN baris Nama Data Diri');
    expect(find.text('2212400011'), findsOneWidget,
        reason: 'NIM sesi ditampilkan di header');
    expect(find.text('Laki-laki'), findsOneWidget,
        reason: 'jenis kelamin memakai label, bukan kode');
    expect(find.text('Islam'), findsOneWidget);
    expect(find.text('7 Desember 2005'), findsOneWidget,
        reason: 'tanggal lahir ISO diformat Indonesia');
    expect(find.text('Sugiyanto'), findsOneWidget);
    expect(find.text('Sri Wahyuni'), findsOneWidget);
    // Kontrak tampil: kosong "" → "-".
    expect(find.text('-'), findsWidgets);
  });

  testWidgets('seksi WiFi kampus ada: toggle, form manual, tombol login',
      (tester) async {
    await pompa(
      tester,
      gateway: _GatewayFake(),
      handler: (_) => _balasBiodata(_biodataContoh()),
    );

    // Seksi WiFi di ekor halaman panjang — scroll sampai terlihat.
    await _scrollKeSeksiWifi(tester);

    expect(find.text('Auto-login WiFi kampus'), findsOneWidget);
    expect(find.text('Username (opsional)'), findsOneWidget);
    expect(find.text('Password (opsional)'), findsOneWidget);
    expect(find.text('Simpan manual'), findsOneWidget);
    expect(find.text('Coba login sekarang'), findsOneWidget);
    // Override belum aktif → tombol pulih tidak ada.
    expect(find.text('Gunakan kredensial server lagi'), findsNothing);
  });

  testWidgets('BE gagal → AppErrorState dengan pesan ramah + coba lagi',
      (tester) async {
    await pompa(
      tester,
      gateway: _GatewayFake(),
      handler: (_) => ResponseBody.fromString('{"status":"error"}', 500),
    );

    expect(find.byType(AppErrorState), findsOneWidget);
    // Tidak ada jejak teknis.
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('DioException'), findsNothing);
  });

  testWidgets('penjelasan kredensial default menyebut server; biodataKosong → '
      'menyebut biodata portal + kredensial manual', (tester) async {
    final gateway = _GatewayFake();
    await pompa(
      tester,
      gateway: gateway,
      handler: (_) => _balasBiodata(_biodataContoh()),
    );
    await _scrollKeSeksiWifi(tester);
    expect(
      find.textContaining('Kredensial diambil otomatis dari server'),
      findsOneWidget,
    );

    // Simulasi: BE pernah melaporkan biodata kosong (kontrak code stabil).
    final service = WifiKampusService.untukTest(gateway);
    service.biodataKosong = true;
    // ProfilPage sudah menyimpan referensi service miliknya — halaman baru
    // yang memakai flag tersebut merender penjelasan penyebab.
    await tester.pumpWidget(MaterialApp(
      home: ProfilPage(wifiKampus: service),
    ));
    await tester.pumpAndSettle();
    await _scrollKeSeksiWifi(tester);
    expect(
      find.textContaining('biodata portal (tanggal lahir) belum terisi'),
      findsOneWidget,
    );
    expect(find.textContaining('kredensial manual di bawah'), findsOneWidget);
  });

  testWidgets('simpan manual kosong → snack peringatan, override tidak '
      'aktif', (tester) async {
    await pompa(
      tester,
      gateway: _GatewayFake(),
      handler: (_) => _balasBiodata(_biodataContoh()),
    );

    await _scrollKeSeksiWifi(tester);
    await tester.tap(find.text('Simpan manual'));
    await tester.pumpAndSettle();

    expect(find.text('Username dan password harus diisi.'), findsOneWidget);
  });
  testWidgets('simpan manual terisi → override aktif, tombol pulih muncul',
      (tester) async {
    final gateway = _GatewayFake();
    await pompa(
      tester,
      gateway: gateway,
      handler: (_) => _balasBiodata(_biodataContoh()),
    );

    await _scrollKeSeksiWifi(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Username (opsional)'), '23SA21A060');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password (opsional)'), '20051207');
    // Tutup keyboard virtual lalu scroll ulang — fokus field menggeser
    // viewport sehingga tombol bisa keluar layar.
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await _scrollKeSeksiWifi(tester);
    await tester.tap(find.text('Simpan manual'));
    await tester.pumpAndSettle();

    expect(gateway.usernameTerkirim, '23SA21A060',
        reason: 'override langsung dikirim ke native');
    expect(gateway.passwordTerkirim, '20051207');
    expect(find.text('Gunakan kredensial server lagi'), findsOneWidget);
  });
}
