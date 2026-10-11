import 'package:dio/dio.dart';
import 'api_client.dart';
import 'aktivitas_helper.dart';
import '../models/rekognisi.dart';

class RekognisiService {
  final _dio = ApiClient.instance.dio;

  Future<List<RekognisiItem>> getRekognisi() =>
      ApiClient.guard<List<RekognisiItem>>(() async {
        final response = await _dio.get('/api/v1/rekognisi-mahasiswa');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<RekognisiItem>(
            data, RekognisiItem.fromJson);
      }, 'Gagal memuat data Rekognisi Mahasiswa');

  Future<RekognisiOptionResponse> getOptions() =>
      ApiClient.guard<RekognisiOptionResponse>(() async {
        final response = await _dio.get('/api/v1/rekognisi-mahasiswa/options');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        if (data != null && data is Map<String, dynamic>) {
          return RekognisiOptionResponse.fromJson(data);
        } else if (data != null && data is Map) {
          return RekognisiOptionResponse.fromJson(
              Map<String, dynamic>.from(data));
        }
        return RekognisiOptionResponse(
          jenisRekognisi: [],
          tingkat: [],
          kontribusi: [],
        );
      }, 'Gagal memuat pilihan Rekognisi');

  Future<void> tambahRekognisi(FormData data) =>
      AktivitasHelper.submit('/api/v1/rekognisi-mahasiswa', data,
          'Gagal menambahkan Rekognisi Mahasiswa');

  Future<void> editRekognisi(int id, FormData data) =>
      AktivitasHelper.edit('/api/v1/rekognisi-mahasiswa', id, data,
          'Gagal mengubah Rekognisi Mahasiswa');

  Future<void> hapusRekognisi(int id) => AktivitasHelper.delete(
      '/api/v1/rekognisi-mahasiswa', id,
      'Gagal menghapus Rekognisi Mahasiswa');

  Future<String> downloadFile(int id, String namaFile) =>
      AktivitasHelper.downloadFile('/api/v1/rekognisi-mahasiswa', id, namaFile,
          'Gagal mengunduh berkas');
}
