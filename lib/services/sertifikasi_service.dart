import 'package:dio/dio.dart';
import 'api_client.dart';
import 'aktivitas_helper.dart';
import '../models/sertifikasi.dart';

class SertifikasiService {
  final _dio = ApiClient.instance.dio;

  Future<List<SertifikasiItem>> getSertifikasi() async {
    try {
      final response = await _dio.get('/api/v1/sertifikasi-kompetensi');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => SertifikasiItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data Sertifikasi Kompetensi');
    }
  }

  Future<List<SertifikasiOption>> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/sertifikasi-kompetensi/options');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is Map && data['sertifikasi'] is List) {
        return (data['sertifikasi'] as List)
            .map((e) => SertifikasiOption.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else if (data is List) {
        return data
            .map((e) => SertifikasiOption.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat pilihan Sertifikasi');
    }
  }

  Future<void> tambahSertifikasi(FormData data) =>
      AktivitasHelper.submit('/api/v1/sertifikasi-kompetensi', data, 'Gagal menambahkan Sertifikasi Kompetensi');

  Future<void> editSertifikasi(int id, FormData data) =>
      AktivitasHelper.edit('/api/v1/sertifikasi-kompetensi', id, data, 'Gagal mengubah data Sertifikasi Kompetensi');

  Future<void> hapusSertifikasi(int id) =>
      AktivitasHelper.delete('/api/v1/sertifikasi-kompetensi', id, 'Gagal menghapus Sertifikasi Kompetensi');

  Future<String> downloadFile(int id, String namaFile) =>
      AktivitasHelper.downloadFile('/api/v1/sertifikasi-kompetensi', id, namaFile, 'Gagal mengunduh file sertifikat');
}
