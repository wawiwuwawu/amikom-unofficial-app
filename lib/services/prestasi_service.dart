import 'package:dio/dio.dart';
import 'api_client.dart';
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

  Future<void> tambahPrestasi(FormData data) async {
    try {
      final response = await _dio.post(
        '/api/v1/prestasi-mahasiswa',
        data: data,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menambahkan Prestasi Mahasiswa');
    }
  }

  Future<void> hapusPrestasi(int id) async {
    try {
      final response = await _dio.delete('/api/v1/prestasi-mahasiswa/$id');
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus Prestasi Mahasiswa');
    }
  }

  Future<String> downloadFile(int id, String namaFile) async {
    try {
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
      final savePath = '$dir/$namaFile';
      await _dio.download(
        '/api/v1/prestasi-mahasiswa/$id/file',
        savePath,
      );
      return savePath;
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengunduh file sertifikat');
    }
  }
}
