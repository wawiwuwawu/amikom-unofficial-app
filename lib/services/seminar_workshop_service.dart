import 'package:dio/dio.dart';
import 'api_client.dart';
import 'aktivitas_helper.dart';
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

  Future<void> tambahSeminarWorkshop(FormData data) =>
      AktivitasHelper.submit('/api/v1/seminar-workshop', data, 'Gagal menambahkan Seminar & Workshop');

  Future<void> editSeminarWorkshop(int id, FormData data) =>
      AktivitasHelper.edit('/api/v1/seminar-workshop', id, data, 'Gagal mengubah data Seminar atau Workshop');

  Future<void> hapusSeminarWorkshop(int id) =>
      AktivitasHelper.delete('/api/v1/seminar-workshop', id, 'Gagal menghapus Seminar & Workshop');

  Future<String> downloadFile(int id, String namaFile) =>
      AktivitasHelper.downloadFile('/api/v1/seminar-workshop', id, namaFile, 'Gagal mengunduh file sertifikat');
}
