import 'package:dio/dio.dart';
import 'api_client.dart';
import 'aktivitas_helper.dart';
import '../models/rekognisi.dart';

class RekognisiService {
  final _dio = ApiClient.instance.dio;

  Future<List<RekognisiItem>> getRekognisi() async {
    try {
      final response = await _dio.get('/api/v1/rekognisi-mahasiswa');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => RekognisiItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data Rekognisi Mahasiswa');
    }
  }

  Future<RekognisiOptionResponse> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/rekognisi-mahasiswa/options');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data != null && data is Map<String, dynamic>) {
        return RekognisiOptionResponse.fromJson(data);
      } else if (data != null && data is Map) {
        return RekognisiOptionResponse.fromJson(Map<String, dynamic>.from(data));
      }
      return RekognisiOptionResponse(
        jenisRekognisi: [],
        tingkat: [],
        kontribusi: [],
      );
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat pilihan Rekognisi');
    }
  }

  Future<void> tambahRekognisi(FormData data) =>
      AktivitasHelper.submit('/api/v1/rekognisi-mahasiswa', data, 'Gagal menambahkan Rekognisi Mahasiswa');

  Future<void> editRekognisi(int id, FormData data) =>
      AktivitasHelper.edit('/api/v1/rekognisi-mahasiswa', id, data, 'Gagal mengubah Rekognisi Mahasiswa');

  Future<void> hapusRekognisi(int id) =>
      AktivitasHelper.delete('/api/v1/rekognisi-mahasiswa', id, 'Gagal menghapus Rekognisi Mahasiswa');

  Future<String> downloadFile(int id, String namaFile) =>
      AktivitasHelper.downloadFile('/api/v1/rekognisi-mahasiswa', id, namaFile, 'Gagal mengunduh berkas');
}
