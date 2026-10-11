import 'api_client.dart';
import '../models/absensi.dart';
import '../models/absensi_validasi.dart';
import '../models/app_failure.dart';
import '../models/value_label_option.dart';

class AbsensiService {
  final _dio = ApiClient.instance.dio;

  Future<List<MakulBelumValidasi>> getMakulBelumValidasi() =>
      ApiClient.guard<List<MakulBelumValidasi>>(() async {
        final response = await _dio.get('/api/v1/absensi/makul-belum-validasi');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        if (data is Map) {
          return data.entries
              .map((e) => MakulBelumValidasi.fromJson(
                  MapEntry<String, dynamic>(e.key.toString(), e.value)))
              .toList();
        }
        return [];
      }, 'Gagal memuat data absensi');

  Future<List<ValueLabelOption>> getSemester(String thnAkademik) =>
      ApiClient.guard<List<ValueLabelOption>>(() async {
        final response = await _dio.post(
          '/api/v1/absensi/semester',
          data: {'thn_akademik': thnAkademik},
        );
        final data = ApiClient.unwrapData<List>(response.data);
        return ApiClient.unwrapList<ValueLabelOption>(
            data, ValueLabelOption.fromJson);
      }, 'Gagal memuat semester');

  Future<List<ValueLabelOption>> getMatkul(String thnAkademik, String semester) =>
      ApiClient.guard<List<ValueLabelOption>>(() async {
        final response = await _dio.post(
          '/api/v1/absensi/matkul',
          data: {'thn_akademik': thnAkademik, 'semester': semester},
        );
        final data = ApiClient.unwrapData<List>(response.data);
        return ApiClient.unwrapList<ValueLabelOption>(
            data, ValueLabelOption.fromJson);
      }, 'Gagal memuat matakuliah');

  Future<AbsensiMahasiswa> getMahasiswa(
          String thnAkademik, String semester, String makul) =>
      ApiClient.guard<AbsensiMahasiswa>(() async {
        final response = await _dio.post(
          '/api/v1/absensi/mahasiswa',
          data: {
            'thn_akademik': thnAkademik,
            'semester': semester,
            'makul': makul,
          },
        );
        return AbsensiMahasiswa.fromJson(
            ApiClient.unwrapData<Map<String, dynamic>>(response.data));
      }, 'Gagal memuat data mahasiswa');

  Future<PresensiDetail> getPresensiDetail(String id) =>
      ApiClient.guard<PresensiDetail>(() async {
        final response = await _dio.get('/api/v1/absensi/presensi/$id');
        return PresensiDetail.fromJson(
            ApiClient.unwrapData<Map<String, dynamic>>(response.data));
      }, 'Gagal memuat detail presensi');

  Future<void> validasi(Map<String, dynamic> data) =>
      ApiClient.guard<void>(() async {
        final response = await _dio.post('/api/v1/absensi/validasi', data: data);
        ApiClient.unwrapMutation(response.data);
        final dynamic raw = response.data;
        if (raw is Map<String, dynamic>) {
          final innerData = raw['data'];
          if (innerData is Map<String, dynamic>) {
            final nested = innerData['data'];
            if (nested is Map<String, dynamic> && nested['success'] == false) {
              throw AppFailure.fromServer(
                  nested['message'], fallback: 'Validasi presensi ditolak');
            }
            if (innerData['success'] == false) {
              throw AppFailure.fromServer(
                  innerData['message'], fallback: 'Validasi presensi ditolak');
            }
          }
        }
      }, 'Gagal melakukan validasi');

  /// Auto-validasi massal portal: `inspeksi` hanya memeriksa, `tulis` benar-
  /// benar menulis. Endpoint ini menjawab HTTP 200 dengan envelope galat
  /// ({status:'error'} atau `data.success:false`), jadi root WAJIB dipecah
  /// manual — `unwrapData` hanya akan menelan penolakan sebagai hasil nol.
  Future<AutoValidasiResult> autoValidasi(
    AutoValidasiMode mode, {
    String preset = 'wajar',
  }) =>
      ApiClient.guard<AutoValidasiResult>(() async {
        final response = await _dio.post(
          '/api/v1/absensi/auto-validasi',
          data: {'mode': mode.wire, 'preset': preset},
        );
        final root = ApiClient.unwrapRoot(response.data);
        final data = root['data'];
        if (root['status'] != 'success' || data is! Map<String, dynamic>) {
          throw AppFailure.fromServer(
            root['message'],
            fallback: 'Gagal memproses validasi otomatis',
          );
        }
        if (data['success'] == false) {
          throw AppFailure.fromServer(
            data['message'],
            fallback: 'Validasi otomatis ditolak portal',
          );
        }
        return AutoValidasiResult.fromJson(data);
      }, 'Gagal memproses validasi otomatis');
}
