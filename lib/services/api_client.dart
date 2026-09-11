import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/login_response.dart';
import '../models/dashboard.dart';
import '../models/api_response.dart';
import 'navigation_service.dart';

const _maxRetries = 2;

int _getRetryCount(RequestOptions opts) =>
    opts.extra['retryCount'] as int? ?? 0;

Future<void> _retryDelay() =>
    Future.delayed(const Duration(seconds: 1));

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;
  String? _token;
  String? _refreshToken;
  String? _nim;
  String? _nama;
  final _secureStorage = const FlutterSecureStorage();

  // Concurrency lock for silent login / refresh token
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

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
            final method = response.requestOptions.method.toUpperCase();
            final isSafeMethod = method == 'GET' || method == 'HEAD';
            if (isSafeMethod &&
                !path.contains('/auth/') &&
                (msg.contains('unauthorized') ||
                    msg.contains('sesi berakhir'))) {
              final retryCount = _getRetryCount(response.requestOptions);
              if (retryCount >= _maxRetries) {
                await _forceLogout();
                handler.reject(DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  message: 'Sesi berakhir. Silakan login ulang.',
                ));
                return;
              }

              response.requestOptions.extra['retryCount'] = retryCount + 1;
              final renewed = await _renewSessionWithLock();
              if (renewed) {
                response.requestOptions.headers['Authorization'] =
                    'Bearer $_token';
                response.requestOptions.extra['retryCount'] = 0;
                try {
                  final retryResponse =
                      await dio.fetch(response.requestOptions);
                  handler.resolve(retryResponse);
                  return;
                } catch (e) {
                  if (e is DioException) {
                    handler.reject(e);
                  } else {
                    handler.reject(DioException(
                      requestOptions: response.requestOptions,
                      error: e,
                    ));
                  }
                  return;
                }
              }

              await _forceLogout();
              handler.reject(DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                message: 'Sesi berakhir. Silakan login ulang.',
              ));
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
        final statusCode = error.response?.statusCode;
        final resData = error.response?.data;
        final serverMsg = (resData is Map<String, dynamic>
                ? (resData['message'] ?? '')
                : (resData?.toString() ?? ''))
            .toString()
            .toLowerCase();

        // 429 Rate limit detection
        if (statusCode == 429) {
          handler.next(error.copyWith(
            message: 'Terlalu banyak permintaan. Silakan tunggu sebentar.',
          ));
          return;
        }

        // 500 Upstream portal session expired detection
        if (statusCode == 500 &&
            !error.requestOptions.path.contains('/auth/') &&
            (serverMsg.contains('sesi') || serverMsg.contains('session'))) {
          final method = error.requestOptions.method.toUpperCase();
          final isSafeMethod = method == 'GET' || method == 'HEAD';
          final retryCount = _getRetryCount(error.requestOptions);

          if (isSafeMethod &&
              retryCount < _maxRetries &&
              _token != null &&
              _refreshToken != null) {
            error.requestOptions.extra['retryCount'] = retryCount + 1;
            final renewed = await _renewSessionWithLock();
            if (renewed) {
              error.requestOptions.headers['Authorization'] = 'Bearer $_token';
              try {
                final retryResponse = await dio.fetch(error.requestOptions);
                handler.resolve(retryResponse);
                return;
              } catch (_) {}
            }
          }

          await _forceLogout();
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: DioExceptionType.badResponse,
            message: 'Sesi berakhir. Silakan login ulang.',
          ));
          return;
        }

        if (statusCode == 401) {
          final method = error.requestOptions.method.toUpperCase();
          final isSafeMethod = method == 'GET' || method == 'HEAD';
          final retryCount = _getRetryCount(error.requestOptions);

          if (isSafeMethod &&
              retryCount < _maxRetries &&
              _token != null &&
              _refreshToken != null) {
            error.requestOptions.extra['retryCount'] = retryCount + 1;
            final renewed = await _renewSessionWithLock();
            if (renewed) {
              error.requestOptions.headers['Authorization'] = 'Bearer $_token';
              error.requestOptions.extra['retryCount'] = 0;
              try {
                final retryResponse = await dio.fetch(error.requestOptions);
                handler.resolve(retryResponse);
                return;
              } catch (e) {
                if (e is DioException) {
                  handler.reject(e);
                } else {
                  handler.reject(DioException(
                    requestOptions: error.requestOptions,
                    error: e,
                  ));
                }
                return;
              }
            }
          }

          await _forceLogout();
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: DioExceptionType.badResponse,
            message: 'Sesi berakhir. Silakan login ulang.',
          ));
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

  // ─── Session Restore ─────────────────────────────────
  Future<void> restoreSession() async {
    final token = await _secureStorage.read(key: 'token');
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
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
    await _secureStorage.write(key: 'token', value: token);
    await _secureStorage.write(key: 'refreshToken', value: refreshToken);
  }

  Dio _createUtilityDio() {
    final utilityDio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    (utilityDio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 5);
      return client;
    };
    return utilityDio;
  }

  // ─── Token Refresh ───────────────────────────────────
  Future<bool> _tryRefresh() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    try {
      final refreshDio = _createUtilityDio();
      final res = await refreshDio.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );
      final newToken = res.data['token'];
      final newRefresh = res.data['refreshToken'];
      if (newToken != null && newRefresh != null) {
        _token = newToken;
        _refreshToken = newRefresh;
        await _secureStorage.write(key: 'token', value: _token!);
        await _secureStorage.write(key: 'refreshToken', value: _refreshToken!);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Concurrency-locked Session Renewal ───────────────────
  Future<bool> _renewSessionWithLock() async {
    if (_isRefreshing) {
      return (await _refreshCompleter?.future) ?? false;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    bool success = false;
    try {
      // 1. Refresh token dulu (aman, tanpa password, sesuai desain backend
      //    yang me-rotate refresh token). JANGAN login ulang dengan password
      //    — password tidak pernah disimpan di perangkat.
      success = await _tryRefresh();

      // Jika server baru saja restart / refresh token gagal sementara,
      // coba sekali lagi setelah jeda singkat.
      if (!success) {
        await _retryDelay();
        success = await _tryRefresh();
      }
    } catch (_) {
      success = false;
    } finally {
      _refreshCompleter?.complete(success);
      _isRefreshing = false;
    }

    return success;
  }

  /// Memastikan sesi aktif: refresh token bila diperlukan.
  /// Tidak ada silent re-login dengan password — kalau refresh gagal,
  /// user harus login ulang manual (standar & aman).
  Future<bool> ensureSessionOrSilentLogin() async {
    if (_token == null || _token!.isEmpty || _refreshToken == null) {
      return false;
    }
    return await _renewSessionWithLock();
  }

  // ─── Force Logout ────────────────────────────────────
  Future<void> _forceLogout() async {
    await clearTokens();
    NavigationService.instance.navigatorKey.currentState
        ?.pushReplacementNamed('/login');
  }

  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    await _secureStorage.delete(key: 'token');
    await _secureStorage.delete(key: 'refreshToken');
  }

  /// Full logout: clear tokens (password tidak pernah disimpan)
  Future<void> fullLogout() async {
    await clearTokens();
  }

  /// ponytail: centralized download directory helper to avoid 12 duplicate copies
  static Future<String> getDownloadDir() async {
    if (Platform.isAndroid) {
      final download = Directory('/storage/emulated/0/Download');
      if (await download.exists()) {
        return download.path;
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  // ponytail: direct login method on ApiClient instead of redundant AuthService wrapper
  Future<LoginResponse> login(String pengguna, String passw) async {
    try {
      final response = await dio.post(
        '/api/v1/auth/login',
        data: {'pengguna': pengguna, 'passw': passw},
      );
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        rethrow;
      }
      if (e.response != null) {
        throw Exception(e.response?.data?['message'] ?? 'Login gagal');
      }
      throw Exception('Tidak dapat terhubung ke server');
    }
  }

  // ─── API Envelope Helpers ─────────────────────────────
  static T unwrapData<T>(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData['status'] == 'success' &&
        responseData.containsKey('data')) {
      return responseData['data'] as T;
    }
    return responseData as T;
  }

  static Map<String, dynamic> unwrapRoot(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final status = responseData['status'];
      if (status == 'error' || status == 'fail') {
        final message = responseData['message']?.toString() ??
            'Terjadi kesalahan pada respons server';
        throw Exception(message);
      }
      return responseData;
    }
    throw Exception('Respons server tidak valid');
  }

  static MutationResult unwrapMutation(dynamic responseData) {
    final result = MutationResult.fromJson(responseData);
    result.ensureSuccess();
    return result;
  }

  // ponytail: centralized error handler to prevent raw null/English network messages
  static Exception handleError(dynamic e, [String fallback = 'Terjadi kesalahan']) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      final serverData = e.response?.data;
      String? serverMsg;
      if (serverData is Map<String, dynamic>) {
        serverMsg = serverData['message']?.toString().trim();
      } else if (serverData is String && serverData.trim().isNotEmpty) {
        serverMsg = serverData.trim();
      }

      if (statusCode == 400) {
        if (serverMsg != null && serverMsg.isNotEmpty) {
          return Exception(serverMsg);
        }
        return Exception('Permintaan tidak valid');
      }

      if (statusCode == 401) {
        return Exception('Sesi berakhir. Silakan login ulang.');
      }

      if (statusCode == 413) {
        return Exception(serverMsg != null && serverMsg.isNotEmpty
            ? serverMsg
            : 'Ukuran berkas melebihi batas 5 MB');
      }

      if (statusCode == 429) {
        return Exception('Terlalu banyak permintaan. Silakan tunggu sebentar.');
      }

      if (statusCode == 500) {
        if (serverMsg != null &&
            (serverMsg.toLowerCase().contains('sesi') ||
                serverMsg.toLowerCase().contains('session'))) {
          return Exception('Sesi berakhir. Silakan login ulang.');
        }
        return Exception('Terjadi kendala pada server portal');
      }

      if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
        return Exception('Layanan portal Amikom sedang tidak dapat diakses');
      }

      if (serverMsg != null && serverMsg.isNotEmpty) {
        return Exception(serverMsg);
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Exception('Koneksi ke server batas waktu habis');
      }
      if (e.type == DioExceptionType.connectionError) {
        return Exception('Tidak dapat terhubung ke server');
      }
      return Exception(fallback);
    }
    return Exception(e?.toString() ?? fallback);
  }

  // ponytail: direct dashboard method on ApiClient instead of redundant DashboardService wrapper
  Future<Dashboard> getDashboard() async {
    try {
      final response = await dio.get('/api/v1/dashboard');
      final data = unwrapData<Map<String, dynamic>>(response.data);
      return Dashboard.fromJson(data);
    } catch (e) {
      throw handleError(e, 'Tidak dapat terhubung ke server');
    }
  }
}
