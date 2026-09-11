import 'package:dio/dio.dart';
import 'api_client.dart';
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

  Future<void> tambahSertifikasi(FormData data) async {
    try {
      final response = await _dio.post(
        '/api/v1/sertifikasi-kompetensi',
        data: data,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menambahkan Sertifikasi Kompetensi');
    }
  }

  Future<void> hapusSertifikasi(int id) async {
    try {
      final response = await _dio.delete('/api/v1/sertifikasi-kompetensi/$id');
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus Sertifikasi Kompetensi');
    }
  }

  Future<String> downloadFile(int id, String namaFile) async {
    try {
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
      final savePath = '$dir/$namaFile';
      await _dio.download(
        '/api/v1/sertifikasi-kompetensi/$id/file',
        savePath,
      );
      return savePath;
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengunduh file sertifikat');
    }
  }
}
