import 'package:dio/dio.dart';
import '../models/login_response.dart';
import 'api_client.dart';

class AuthService {
  final _dio = ApiClient.instance.dio;

  Future<LoginResponse> login(String pengguna, String passw) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {'pengguna': pengguna, 'passw': passw},
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data?['message'] ?? 'Login gagal');
      }
      throw Exception('Tidak dapat terhubung ke server');
    }
  }
}
