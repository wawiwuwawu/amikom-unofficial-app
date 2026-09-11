import 'api_client.dart';
import '../models/absensi.dart';

class AbsensiService {
  final _dio = ApiClient.instance.dio;

  Future<List<MakulBelumValidasi>> getMakulBelumValidasi() async {
    try {
      final response = await _dio.get('/api/v1/absensi/makul-belum-validasi');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is Map) {
        return data.entries
            .map((e) => MakulBelumValidasi.fromJson(
                MapEntry<String, dynamic>(e.key.toString(), e.value)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data absensi');
    }
  }

  Future<List<OptionItem>> getSemester(String thnAkademik) async {
    try {
      final response = await _dio.post(
        '/api/v1/absensi/semester',
        data: {'thn_akademik': thnAkademik},
      );
      final data = ApiClient.unwrapData<List>(response.data);
      return data
          .map((e) => OptionItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat semester');
    }
  }

  Future<List<OptionItem>> getMatkul(String thnAkademik, String semester) async {
    try {
      final response = await _dio.post(
        '/api/v1/absensi/matkul',
        data: {'thn_akademik': thnAkademik, 'semester': semester},
      );
      final data = ApiClient.unwrapData<List>(response.data);
      return data
          .map((e) => OptionItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat matakuliah');
    }
  }

  Future<AbsensiMahasiswa> getMahasiswa(
      String thnAkademik, String semester, String makul) async {
    try {
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
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data mahasiswa');
    }
  }

  Future<PresensiDetail> getPresensiDetail(String id) async {
    try {
      final response = await _dio.get('/api/v1/absensi/presensi/$id');
      return PresensiDetail.fromJson(
          ApiClient.unwrapData<Map<String, dynamic>>(response.data));
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat detail presensi');
    }
  }

  Future<void> validasi(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/v1/absensi/validasi', data: data);
      ApiClient.unwrapMutation(response.data);
      final dynamic raw = response.data;
      if (raw is Map<String, dynamic>) {
        final innerData = raw['data'];
        if (innerData is Map<String, dynamic>) {
          final nested = innerData['data'];
          if (nested is Map<String, dynamic> && nested['success'] == false) {
            throw Exception(nested['message']?.toString() ?? 'Validasi presensi ditolak');
          }
          if (innerData['success'] == false) {
            throw Exception(innerData['message']?.toString() ?? 'Validasi presensi ditolak');
          }
        }
      }
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal melakukan validasi');
    }
  }
}
