import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/prestasi.dart';

class PrestasiService {
  final _dio = ApiClient.instance.dio;

  Future<List<PrestasiItem>> getPrestasi() async {
    try {
      final response = await _dio.get('/api/v1/prestasi-mahasiswa');
      final data = response.data['data'] as List?;
      return data?.map((e) => PrestasiItem.fromJson(e)).toList() ?? [];
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat data Prestasi Mahasiswa');
    }
  }

  Future<PrestasiOptionsData> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/prestasi-mahasiswa/options');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Data opsi prestasi kosong');
      }
      return PrestasiOptionsData.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat pilihan Prestasi');
    }
  }

  Future<void> tambahPrestasi(FormData data) async {
    try {
      await _dio.post(
        '/api/v1/prestasi-mahasiswa',
        data: data,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal menambahkan Prestasi Mahasiswa');
    }
  }

  Future<void> hapusPrestasi(int id) async {
    try {
      await _dio.delete('/api/v1/prestasi-mahasiswa/$id');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal menghapus Prestasi Mahasiswa');
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
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal mengunduh file sertifikat');
    }
  }
}
