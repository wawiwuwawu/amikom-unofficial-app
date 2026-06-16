import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final Dio _dio;

  AuthService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  Future<Map<String, dynamic>> login(String pengguna, String passw) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'pengguna': pengguna, 'passw': passw},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data?['message'] ?? 'Login gagal');
      }
      throw Exception('Tidak dapat terhubung ke server');
    }
  }
}
