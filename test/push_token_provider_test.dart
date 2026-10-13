import 'package:app_amikom/models/app_failure.dart';
import 'package:app_amikom/services/push_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gateway palsu khusus untuk provider: hanya [getToken] yang menentukan
/// hasil. Member lain aman (tidak menyentuh Firebase asli) agar bisa
/// di-inject ke [FirebasePushTokenProvider].
class _GatewayPalsu implements MessagingGateway {
  _GatewayPalsu({this.token, this.error});

  final String? token;
  final Object? error;

  @override
  Future<String?> getToken() async {
    if (error != null) throw error!;
    return token;
  }

  @override
  Stream<Map<String, dynamic>> get tokenRefresh =>
      Stream<Map<String, dynamic>>.empty();

  @override
  Stream<Map<String, dynamic>> get onMessage =>
      Stream<Map<String, dynamic>>.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpened =>
      Stream<Map<String, dynamic>>.empty();

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => null;

  @override
  Future<bool> mintaIzin() async => false;
}

void main() {
  group('FirebasePushTokenProvider', () {
    test('const-constructible tanpa argumen & merupakan PushTokenProvider', () {
      const provider = FirebasePushTokenProvider();
      expect(provider, isA<PushTokenProvider>());
    });

    test('token sukses dari gateway diteruskan apa adanya', () async {
      final provider = FirebasePushTokenProvider(
        gateway: _GatewayPalsu(token: 'token-asli-1234'),
      );

      await expectLater(provider.ambilToken(), completion('token-asli-1234'));
    });

    test('gateway mengembalikan null → ambilToken null (bukan error)', () async {
      final provider = FirebasePushTokenProvider(
        gateway: _GatewayPalsu(token: null),
      );

      await expectLater(provider.ambilToken(), completion(isNull));
    });

    test(
      'error gateway → AppFailure berbahasa Indonesia & TANPA bocor token',
      () async {
        const bocor = 'super-rahasia-9f8e7d';
        final provider = FirebasePushTokenProvider(
          gateway: _GatewayPalsu(
            error: Exception('gagal ambil token $bocor'),
          ),
        );

        Object? tangkapan;
        try {
          await provider.ambilToken();
        } catch (e) {
          tangkapan = e;
        }

        expect(tangkapan, isA<AppFailure>());
        final pesan = (tangkapan as AppFailure).message;
        expect(
          pesan,
          'Gagal mengakses token FCM. Periksa koneksi lalu coba lagi.',
        );
        expect(
          pesan.contains(bocor),
          isFalse,
          reason: 'pesan error tidak boleh membocorkan nilai token',
        );
      },
    );
  });
}
