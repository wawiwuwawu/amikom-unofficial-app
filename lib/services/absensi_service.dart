import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/absensi.dart';

class AbsensiService {
  final _dio = ApiClient.instance.dio;

  Future<List<MakulBelumValidasi>> getMakulBelumValidasi() async {
    try {
      final response = await _dio.get('/api/v1/absensi/makul-belum-validasi');
      final map = response.data as Map<String, dynamic>;
      return map.entries
          .map((e) => MakulBelumValidasi.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat data absensi');
    }
  }

  Future<List<OptionItem>> getSemester(String thnAkademik) async {
    try {
      final response = await _dio.post(
        '/api/v1/absensi/semester',
        data: {'thn_akademik': thnAkademik},
      );
      return (response.data as List)
          .map((e) => OptionItem.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat semester');
    }
  }

  Future<List<OptionItem>> getMatkul(String thnAkademik, String semester) async {
    try {
      final response = await _dio.post(
        '/api/v1/absensi/matkul',
        data: {'thn_akademik': thnAkademik, 'semester': semester},
      );
      return (response.data as List)
          .map((e) => OptionItem.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat matakuliah');
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
      return AbsensiMahasiswa.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat data mahasiswa');
    }
  }

  Future<PresensiDetail> getPresensiDetail(String id) async {
    try {
      final response = await _dio.get('/api/v1/absensi/presensi/$id');
      return PresensiDetail.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat detail presensi');
    }
  }

  Future<void> validasi(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/v1/absensi/validasi', data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal melakukan validasi');
    }
  }
}
