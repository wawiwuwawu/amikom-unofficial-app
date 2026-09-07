import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/seminar_workshop.dart';

class SeminarWorkshopService {
  final _dio = ApiClient.instance.dio;

  Future<List<SeminarWorkshopItem>> getSeminarWorkshop() async {
    try {
      final response = await _dio.get('/api/v1/seminar-workshop');
      final data = response.data['data'] as List?;
      return data?.map((e) => SeminarWorkshopItem.fromJson(e)).toList() ?? [];
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat data Seminar & Workshop');
    }
  }

  Future<SeminarWorkshopOptionsData> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/seminar-workshop/options');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Data opsi seminar & workshop kosong');
      }
      return SeminarWorkshopOptionsData.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat pilihan Seminar & Workshop');
    }
  }

  Future<void> tambahSeminarWorkshop(FormData data) async {
    try {
      await _dio.post(
        '/api/v1/seminar-workshop',
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
      throw Exception(e.message ?? 'Gagal menambahkan Seminar & Workshop');
    }
  }

  Future<void> hapusSeminarWorkshop(int id) async {
    try {
      await _dio.delete('/api/v1/seminar-workshop/$id');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal menghapus Seminar & Workshop');
    }
  }

  Future<String> downloadFile(int id, String namaFile) async {
    try {
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
      final savePath = '$dir/$namaFile';
      await _dio.download(
        '/api/v1/seminar-workshop/$id/file',
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
