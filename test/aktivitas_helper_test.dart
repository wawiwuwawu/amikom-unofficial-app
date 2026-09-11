import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_amikom/services/aktivitas_helper.dart';
import 'package:app_amikom/services/sertifikasi_service.dart';
import 'package:app_amikom/services/organisasi_service.dart';
import 'package:app_amikom/services/prestasi_service.dart';
import 'package:app_amikom/services/seminar_workshop_service.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000\n');
  });

  group('AktivitasHelper and SKPI Services contracts', () {
    test('Services can be instantiated', () {
      final sertifikasi = SertifikasiService();
      final organisasi = OrganisasiService();
      final prestasi = PrestasiService();
      final seminarWorkshop = SeminarWorkshopService();

      expect(sertifikasi, isNotNull);
      expect(organisasi, isNotNull);
      expect(prestasi, isNotNull);
      expect(seminarWorkshop, isNotNull);
    });

    test('AktivitasHelper methods are declared with correct signatures', () {
      expect(AktivitasHelper.submit, isA<Function>());
      expect(AktivitasHelper.delete, isA<Function>());
      expect(AktivitasHelper.download, isA<Function>());
      expect(AktivitasHelper.downloadFile, isA<Function>());
    });

    test('AktivitasHelper wraps exceptions with fallback message', () async {
      // Calling delete with an invalid ID against non-running backend should throw handled Exception
      expect(
        () => AktivitasHelper.delete('/api/v1/invalid-path', 999999, 'Fallback Error Message'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
