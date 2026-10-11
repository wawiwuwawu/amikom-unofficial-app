import 'package:dio/dio.dart';
import 'api_client.dart';
import 'aktivitas_helper.dart';
import '../models/prestasi.dart';
import '../models/app_failure.dart';

class PrestasiService {
  final _dio = ApiClient.instance.dio;

  Future<List<PrestasiItem>> getPrestasi() =>
      ApiClient.guard<List<PrestasiItem>>(() async {
        final response = await _dio.get('/api/v1/prestasi-mahasiswa');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<PrestasiItem>(data, PrestasiItem.fromJson);
      }, 'Gagal memuat data Prestasi Mahasiswa');

  Future<PrestasiOptionsData> getOptions() =>
      ApiClient.guard<PrestasiOptionsData>(() async {
        final response = await _dio.get('/api/v1/prestasi-mahasiswa/options');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        if (data is Map<String, dynamic>) {
          return PrestasiOptionsData.fromJson(data);
        } else if (data is Map) {
          return PrestasiOptionsData.fromJson(Map<String, dynamic>.from(data));
        }
        throw const AppFailure('Data opsi prestasi kosong');
      }, 'Gagal memuat pilihan Prestasi');

  Future<void> tambahPrestasi(FormData data) =>
      AktivitasHelper.submit('/api/v1/prestasi-mahasiswa', data,
          'Gagal menambahkan Prestasi Mahasiswa');

  Future<void> editPrestasi(int id, FormData data) =>
      AktivitasHelper.edit('/api/v1/prestasi-mahasiswa', id, data,
          'Gagal mengubah data Prestasi Mahasiswa');

  Future<void> hapusPrestasi(int id) => AktivitasHelper.delete(
      '/api/v1/prestasi-mahasiswa', id,
      'Gagal menghapus Prestasi Mahasiswa');

  Future<String> downloadFile(int id, String namaFile) =>
      AktivitasHelper.downloadFile('/api/v1/prestasi-mahasiswa', id, namaFile,
          'Gagal mengunduh file sertifikat');
}
