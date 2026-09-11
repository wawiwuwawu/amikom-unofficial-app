import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/seminar_workshop.dart';

class SeminarWorkshopService {
  final _dio = ApiClient.instance.dio;

  Future<List<SeminarWorkshopItem>> getSeminarWorkshop() async {
    try {
      final response = await _dio.get('/api/v1/seminar-workshop');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is List) {
        return data
            .map((e) => SeminarWorkshopItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data Seminar & Workshop');
    }
  }

  Future<SeminarWorkshopOptionsData> getOptions() async {
    try {
      final response = await _dio.get('/api/v1/seminar-workshop/options');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is Map<String, dynamic>) {
        return SeminarWorkshopOptionsData.fromJson(data);
      } else if (data is Map) {
        return SeminarWorkshopOptionsData.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Data opsi seminar & workshop kosong');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat pilihan Seminar & Workshop');
    }
  }

  Future<void> tambahSeminarWorkshop(FormData data) async {
    try {
      final response = await _dio.post(
        '/api/v1/seminar-workshop',
        data: data,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menambahkan Seminar & Workshop');
    }
  }

  Future<void> hapusSeminarWorkshop(int id) async {
    try {
      final response = await _dio.delete('/api/v1/seminar-workshop/$id');
      ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus Seminar & Workshop');
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
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengunduh file sertifikat');
    }
  }
}
