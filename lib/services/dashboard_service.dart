import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/dashboard.dart';

class DashboardService {
  final _dio = ApiClient.instance.dio;

  Future<Dashboard> getDashboard() async {
    try {
      final response = await _dio.get('/api/v1/dashboard');
      return Dashboard.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Tidak dapat terhubung ke server');
    }
  }
}
