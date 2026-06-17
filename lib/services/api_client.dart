import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_service.dart';

const _maxRetries = 3;

int _getRetryCount(RequestOptions opts) =>
    opts.extra['retryCount'] as int? ?? 0;

Future<void> _retryDelay() =>
    Future.delayed(const Duration(seconds: 5));

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;
  String? _token;
  String? _refreshToken;
  String? _nim;
  String? _nama;

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
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
      onResponse: (response, handler) async {
        if (_token != null && _refreshToken != null) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            final msg = (data['message'] ?? '').toString().toLowerCase();
            final path = response.requestOptions.path;
            if (!path.contains('/auth/') &&
                (msg.contains('unauthorized') ||
                    msg.contains('tidak valid') ||
                    msg.contains('sesi berakhir'))) {
              final retryCount = _getRetryCount(response.requestOptions);
              if (retryCount >= _maxRetries) {
                await clearTokens();
                NavigationService.instance.navigatorKey.currentState
                    ?.pushReplacementNamed('/login');
                handler.reject(DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  message: 'Sesi berakhir. Silakan login ulang.',
                ));
                return;
              }
              response.requestOptions.extra['retryCount'] = retryCount + 1;
              await _retryDelay();
              final success = await _tryRefresh();
              if (success) {
                response.requestOptions.headers['Authorization'] =
                    'Bearer $_token';
                final retryResponse =
                    await dio.fetch(response.requestOptions);
                handler.resolve(retryResponse);
              } else {
                await clearTokens();
                NavigationService.instance.navigatorKey.currentState
                    ?.pushReplacementNamed('/login');
                handler.reject(DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  message: 'Sesi berakhir. Silakan login ulang.',
                ));
              }
              return;
            }
          }
        }
        handler.next(response);
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
          final retryCount = _getRetryCount(error.requestOptions);
          if (retryCount >= _maxRetries) {
            await clearTokens();
            NavigationService.instance.navigatorKey.currentState
                ?.pushReplacementNamed('/login');
            handler.resolve(error.response ?? Response(
              requestOptions: error.requestOptions,
              data: {'message': 'Sesi berakhir. Silakan login ulang.'},
            ));
            return;
          }
          error.requestOptions.extra['retryCount'] = retryCount + 1;
          await _retryDelay();
          final success = await _tryRefresh();
          if (success) {
            error.requestOptions.headers['Authorization'] = 'Bearer $_token';
            final retryResponse = await dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
          } else {
            await clearTokens();
            NavigationService.instance.navigatorKey.currentState
                ?.pushReplacementNamed('/login');
            handler.resolve(error.response ?? Response(
              requestOptions: error.requestOptions,
              data: {'message': 'Sesi berakhir. Silakan login ulang.'},
            ));
          }
          return;
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
  String? get nim => _nim;
  String? get nama => _nama;

  void setUserInfo(String nim, String nama) {
    _nim = nim;
    _nama = nama;
  }

  Future<void> setTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('refreshToken', refreshToken);
  }

  Future<bool> _tryRefresh() async {
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
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
  }
}
