import 'package:dio/dio.dart';
import '../models/agenda_terpadu.dart';
import 'api_client.dart';

class AgendaService {
  final Dio _dio;

  AgendaService() : _dio = ApiClient.instance.dio;

  Future<AgendaTerpaduData> getAgendaTerpadu() async {
    try {
      final response = await _dio.get('/api/v1/agenda/terpadu');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return AgendaTerpaduData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat agenda terpadu');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat agenda terpadu');
    }
  }
}
