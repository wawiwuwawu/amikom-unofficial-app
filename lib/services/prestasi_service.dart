import 'package:dio/dio.dart';
import 'api_client.dart';
import 'aktivitas_helper.dart';
import '../models/prestasi.dart';

class PrestasiService {
  final _dio = ApiClient.instance.dio;

  Future<List<PrestasiItem>> getPrestasi() async {
    try {
      final response = await _dio.get('/api/v1/prestasi-mahasiswa');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => PrestasiItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data Prestasi Mahasiswa');
    }
  }

  Future<PrestasiOptionsData> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/prestasi-mahasiswa/options');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is Map<String, dynamic>) {
        return PrestasiOptionsData.fromJson(data);
      } else if (data is Map) {
        return PrestasiOptionsData.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Data opsi prestasi kosong');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat pilihan Prestasi');
    }
  }

  Future<void> tambahPrestasi(FormData data) =>
      AktivitasHelper.submit('/api/v1/prestasi-mahasiswa', data, 'Gagal menambahkan Prestasi Mahasiswa');

  Future<void> editPrestasi(int id, FormData data) =>
      AktivitasHelper.edit('/api/v1/prestasi-mahasiswa', id, data, 'Gagal mengubah data Prestasi Mahasiswa');

  Future<void> hapusPrestasi(int id) =>
      AktivitasHelper.delete('/api/v1/prestasi-mahasiswa', id, 'Gagal menghapus Prestasi Mahasiswa');

  Future<String> downloadFile(int id, String namaFile) =>
      AktivitasHelper.downloadFile('/api/v1/prestasi-mahasiswa', id, namaFile, 'Gagal mengunduh file sertifikat');
}
