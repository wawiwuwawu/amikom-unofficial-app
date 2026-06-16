import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;
  String? _token;
  String? _refreshToken;

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 5);
      return client;
    };

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.receiveTimeout) {
          handler.next(error.copyWith(
            message: 'Koneksi terputus. Periksa jaringan Anda.',
          ));
          return;
        }

        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            final refreshDio = Dio(
              BaseOptions(
                baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
              ),
            );
            final res = await refreshDio.post(
              '/api/v1/auth/refresh',
              data: {'refreshToken': _refreshToken},
            );

            _token = res.data['token'];
            _refreshToken = res.data['refreshToken'];
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', _token!);
            await prefs.setString('refreshToken', _refreshToken!);

            error.requestOptions.headers['Authorization'] = 'Bearer $_token';
            final retryResponse = await dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
            return;
          } catch (_) {
            _token = null;
            _refreshToken = null;
            handler.next(error.copyWith(
              message: 'Sesi berakhir. Silakan login ulang.',
            ));
            return;
          }
        }

        handler.next(error);
      },
    ));
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refreshToken');
    if (token != null && refreshToken != null) {
      _token = token;
      _refreshToken = refreshToken;
    }
  }

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  void setTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('refreshToken', refreshToken);
  }

  void clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
  }
}
