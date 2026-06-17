import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/pengumuman.dart';

class PengumumanService {
  final _dio = ApiClient.instance.dio;

  Future<List<PengumumanItem>> getList() async {
    try {
      final response = await _dio.get('/api/v1/pengumumanAkademik');
      final data = response.data['data'] as List;
      return data.map((e) => PengumumanItem.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat pengumuman');
    }
  }

  Future<PengumumanDetail> getDetail(int id) async {
    try {
      final response = await _dio.get('/api/v1/pengumumanAkademik/$id');
      return PengumumanDetail.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat detail pengumuman');
    }
  }
}
