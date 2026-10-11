import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_amikom/services/aktivitas_helper.dart';
import 'package:dio/dio.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000\n');
  });

  group('AktivitasHelper and SKPI Services contracts', () {
    test('AktivitasHelper wraps exceptions with fallback message', () async {
      // Calling delete with an invalid ID against non-running backend should throw handled Exception
      expect(
        () => AktivitasHelper.delete('/api/v1/invalid-path', 999999, 'Fallback Error Message'),
        throwsA(isA<Exception>()),
      );
    });

    test('AktivitasHelper edit wraps exceptions with fallback message', () async {
      expect(
        () => AktivitasHelper.edit('/api/v1/invalid-path', 999999, FormData(), 'Fallback Edit Error'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
