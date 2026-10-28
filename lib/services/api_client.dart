import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/login_response.dart';
import '../models/dashboard.dart';
import '../models/api_response.dart';
import '../models/app_failure.dart';
import 'etag_cache_service.dart';
import 'navigation_service.dart';

const _maxRetries = 2;

/// Endpoint PUBLIK yang boleh memakai ETag/304 (kontrak BE panduan-implement-
/// fe §2.7): datanya identik untuk semua mahasiswa dan tanpa PII. Pencocokan
/// PASTI (exact / prefix berhati-hati) — `/api/v1/agenda` (kalender akademik,
/// publik) TIDAK boleh menangkap `/api/v1/agenda/terpadu` (per-NIM), dan
/// `/api/v1/panduan` tidak boleh menangkap `/api/v1/panduan/download/...`.
bool _cacheablePublikGet(String path) {
  if (path == '/api/v1/berita' || path.startsWith('/api/v1/berita/')) {
    return true;
  }
  if (path == '/api/v1/pengumumanAkademik' ||
      path.startsWith('/api/v1/pengumumanAkademik/')) {
    return true;
  }
  if (path == '/api/v1/panduan') return true;
  if (path == '/api/v1/akademik/agenda') return true;
  if (path == '/api/v1/agenda') return true;
  return false;
}

String _kunciCachePublik(RequestOptions options) =>
    '${options.uri.path}?${options.uri.query}';

/// ETag hanya disimpan untuk envelope sukses (atau list mentah) — envelope
/// galat tidak pernah di-cache supaya 304 nanti tidak memainkan ulang galat.
bool _layakSimpanEtag(dynamic data) {
  if (data is Map<String, dynamic>) return data['status'] == 'success';
  return data is List;
}

int _getRetryCount(RequestOptions opts) =>
    opts.extra['retryCount'] as int? ?? 0;

/// Method aman (GET/HEAD) serta POST/DELETE idempoten pada
/// `/api/v1/notifikasi/device-token` boleh memperbarui sesi dan mencoba ulang
/// saat 401 tanpa langsung force logout.
bool _canRenewAndRetry(RequestOptions opts) =>
    ApiClient.canRenewAndRetry(opts.method, opts.uri.path);

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

  static HttpClient _createHttpClient() {
    final client = HttpClient();
    client.idleTimeout = const Duration(seconds: 5);
    return client;
  }

  BaseOptions _baseOptions(Duration receiveTimeout) => BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: receiveTimeout,
    sendTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  );

  ApiClient._() {
    dio = Dio(_baseOptions(const Duration(seconds: 60)));

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        _createHttpClient;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          // ETag/304 endpoint publik: bila ada simpanan, minta validasi
          // bersyarat. Gagal baca cache → request jalan normal (fail-open).
          if (options.method.toUpperCase() == 'GET' &&
              _cacheablePublikGet(options.uri.path)) {
            try {
              final kunci = _kunciCachePublik(options);
              final entri = await EtagCacheService.instance.baca(kunci);
              final etag = entri?['etag']?.toString() ?? '';
              if (entri != null && etag.isNotEmpty) {
                options.headers['If-None-Match'] = etag;
                options.extra['etag_kunci'] = kunci;
              }
            } catch (_) {}
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          // Simpan ETag + body respons publik sukses untuk validasi bersyarat
          // berikutnya (fire-and-forget; gagal simpan hanya kehilangan hemat).
          // Kunci dihitung dari request apa adanya — respons pertama (masih
          // tanpa simpanan) justru yang HARUS tercatat agar cache terisi.
          final etag = response.headers.value('etag');
          final reqOpts = response.requestOptions;
          if (etag != null &&
              etag.isNotEmpty &&
              reqOpts.method.toUpperCase() == 'GET' &&
              _cacheablePublikGet(reqOpts.uri.path) &&
              _layakSimpanEtag(response.data)) {
            unawaited(
              EtagCacheService.instance.simpan(
                _kunciCachePublik(reqOpts),
                etag,
                response.data,
              ),
            );
          }
          if (_token != null && _refreshToken != null) {
            final data = response.data;
            if (data is Map<String, dynamic>) {
              final msg = (data['message'] ?? '').toString().toLowerCase();
              final path = response.requestOptions.path;
              final isSafeMethod = _canRenewAndRetry(response.requestOptions);
              if (isSafeMethod &&
                  !path.contains('/auth/') &&
                  (msg.contains('unauthorized') ||
                      msg.contains('sesi berakhir'))) {
                final retryCount = _getRetryCount(response.requestOptions);
                if (retryCount >= _maxRetries) {
                  await _forceLogout();
                  handler.reject(
                    DioException(
                      requestOptions: response.requestOptions,
                      response: response,
                      type: DioExceptionType.badResponse,
                      message: 'Sesi berakhir. Silakan login ulang.',
                    ),
                  );
                  return;
                }

                response.requestOptions.extra['retryCount'] = retryCount + 1;
                await _renewAndRetry(
                  response.requestOptions,
                  response,
                  handler.resolve,
                  handler.reject,
                );
                return;
              }
            }
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          // Pemetaan status/tipe ke pesan ramah dikelola terpusat oleh
          // ApiClient.handleError — interceptor hanya meneruskan error.
          final statusCode = error.response?.statusCode;
          final resData = error.response?.data;
          final serverMsg =
              (resData is Map<String, dynamic>
                      ? (resData['message'] ?? '')
                      : (resData?.toString() ?? ''))
                  .toString()
                  .toLowerCase();

          // 304 Not Modified pada endpoint publik: body terakhir yang
          // tersimpan dipakai ulang sebagai respons 200. Tanpa simpanan
          // (cache dibersihkan/rusak) → diteruskan sebagai galat biasa dan
          // service pemanggil memakai fallback-nya masing-masing.
          if (statusCode == 304 &&
              error.requestOptions.extra['etag_kunci'] is String) {
            try {
              final entri = await EtagCacheService.instance.baca(
                error.requestOptions.extra['etag_kunci'] as String,
              );
              if (entri != null && entri.containsKey('body')) {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: error.requestOptions,
                    data: entri['body'],
                    statusCode: 200,
                  ),
                );
                return;
              }
            } catch (_) {}
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
                error.requestOptions.headers['Authorization'] =
                    'Bearer $_token';
                try {
                  final retryResponse = await dio.fetch(error.requestOptions);
                  handler.resolve(retryResponse);
                  return;
                } catch (_) {}
              }
            }

            await _forceLogout();
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.badResponse,
                message: 'Sesi berakhir. Silakan login ulang.',
              ),
            );
            return;
          }

          if (statusCode == 401) {
            final isSafeMethod = _canRenewAndRetry(error.requestOptions);
            final retryCount = _getRetryCount(error.requestOptions);

            if (isSafeMethod &&
                retryCount < _maxRetries &&
                _token != null &&
                _refreshToken != null) {
              await _renewAndRetry(
                error.requestOptions,
                error.response,
                handler.resolve,
                handler.reject,
              );
              return;
            }

            await _forceLogout();
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.badResponse,
                message: 'Sesi berakhir. Silakan login ulang.',
              ),
            );
            return;
          }

          handler.next(error);
        },
      ),
    );
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  /// Kebijakan retry saat 401: method aman (GET/HEAD) dan mutasi IDEMPOTEN pada
  /// `/api/v1/notifikasi/device-token` boleh memperbarui sesi lalu mencoba
  /// ulang — pendaftaran/pencabutan token FCM aman diulang.
  /// Mutasi lain sengaja TIDAK diulang supaya aksi non-idempoten (mis. bayar
  /// tagihan) tidak berjalan dua kali; jalur itu tetap memaksa login ulang.
  static bool canRenewAndRetry(String method, String path) {
    final normalized = method.toUpperCase();
    if (normalized == 'GET' || normalized == 'HEAD') return true;
    return (normalized == 'POST' || normalized == 'DELETE') &&
        path == '/api/v1/notifikasi/device-token';
  }

  // ─── Session Restore ─────────────────────────────────
  Future<void> restoreSession() async {
    final token = await _secureStorage.read(key: 'token');
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
    if (token != null && refreshToken != null) {
      _token = token;
      _refreshToken = refreshToken;
    }
    // Identitas ikut dipulihkan: penyimpanan lokal yang berkunci NIM (mis. tanda
    // baca notifikasi) butuh ini setelah cold start, bukan hanya saat login.
    final nim = await _secureStorage.read(key: 'nim');
    final nama = await _secureStorage.read(key: 'nama');
    if (nim != null && nim.trim().isNotEmpty) _nim = nim;
    if (nama != null && nama.isNotEmpty) _nama = nama;
  }

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get nim => _nim;
  String? get nama => _nama;

  /// Menyimpan identitas pengguna (dipanggil setelah login berhasil). Penulisan
  /// ke secure storage best-effort: kegagalan menyimpan identitas tidak boleh
  /// menggagalkan login — efeknya hanya penyimpanan lokal berkunci NIM yang
  /// tidak tertulis.
  Future<void> setUserInfo(String nim, String nama) async {
    _nim = nim;
    _nama = nama;
    try {
      await _secureStorage.write(key: 'nim', value: nim);
      await _secureStorage.write(key: 'nama', value: nama);
    } catch (_) {}
  }

  Future<void> setTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: 'token', value: token);
    await _secureStorage.write(key: 'refreshToken', value: refreshToken);
  }

  Dio _createUtilityDio() {
    final utilityDio = Dio(_baseOptions(const Duration(seconds: 15)));
    (utilityDio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        _createHttpClient;
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
      // Satu percobaan saja: refresh token bersifat single-use (dirotasi
      // server). Percobaan kedua dengan token yang sama SELALU gagal dan
      // hanya membakar token. Password tidak pernah disimpan — kalau refresh
      // gagal, user harus login ulang manual.
      success = await _tryRefresh();
    } catch (_) {
      success = false;
    } finally {
      _refreshCompleter?.complete(success);
      _isRefreshing = false;
    }

    return success;
  }

  /// Perbarui sesi lalu ulang request [opts] dengan token baru.
  ///
  /// Selalu menuntaskan handler (resolve hasil ulang, atau reject ketika
  /// renew gagal / ulang juga gagal) — pemanggil cukup `return` setelah ini.
  /// [originResponse] diteruskan ke payload reject khusus cabang 200-body
  /// unauthorized dan 401.
  Future<void> _renewAndRetry(
    RequestOptions opts,
    Response? originResponse,
    void Function(Response) resolve,
    void Function(DioException) reject,
  ) async {
    opts.extra['retryCount'] = _getRetryCount(opts) + 1;
    final renewed = await _renewSessionWithLock();
    if (!renewed) {
      await _forceLogout();
      reject(
        DioException(
          requestOptions: opts,
          response: originResponse,
          type: DioExceptionType.badResponse,
          message: 'Sesi berakhir. Silakan login ulang.',
        ),
      );
      return;
    }

    opts.headers['Authorization'] = 'Bearer $_token';
    opts.extra['retryCount'] = 0;
    try {
      resolve(await dio.fetch(opts));
    } catch (e) {
      if (e is DioException) {
        reject(e);
      } else {
        reject(DioException(requestOptions: opts, error: e));
      }
    }
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
    NavigationService.instance.navigatorKey.currentState?.pushReplacementNamed(
      '/login',
    );
  }

  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    _nim = null;
    _nama = null;
    await _secureStorage.delete(key: 'token');
    await _secureStorage.delete(key: 'refreshToken');
    await _secureStorage.delete(key: 'nim');
    await _secureStorage.delete(key: 'nama');
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
        throw AppFailure.fromServer(
          e.response?.data?['message'],
          fallback: 'Login gagal. Periksa NIM dan kata sandi Anda.',
        );
      }
      throw AppFailure('Tidak dapat terhubung ke server');
    }
  }

  // ─── API Envelope Helpers ─────────────────────────────
  static T unwrapData<T>(dynamic responseData) {
    try {
      if (responseData is Map<String, dynamic> &&
          responseData['status'] == 'success' &&
          responseData.containsKey('data')) {
        return responseData['data'] as T;
      }
      return responseData as T;
    } on TypeError {
      // Bentuk data server berbeda dari yang diharapkan — jangan bocorkan
      // detail cast ke pengguna.
      throw AppFailure(
        'Data dari server tidak sesuai. Silakan muat ulang sebentar lagi.',
      );
    }
  }

  static Map<String, dynamic> unwrapRoot(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final status = responseData['status'];
      if (status == 'error' || status == 'fail') {
        throw AppFailure.fromServer(
          responseData['message'],
          fallback: 'Terjadi kesalahan pada respons server',
        );
      }
      return responseData;
    }
    throw const AppFailure('Respons server tidak valid');
  }

  static MutationResult unwrapMutation(dynamic responseData) {
    final result = MutationResult.fromJson(responseData);
    result.ensureSuccess();
    return result;
  }

  /// Satu guard untuk seluruh service: jalankan [body], petakan SEMUA galat
  /// (bukan hanya DioException) ke AppFailure ramah lewat [handleError].
  static Future<T> guard<T>(Future<T> Function() body, String fallback) async {
    try {
      return await body();
    } catch (e) {
      throw handleError(e, fallback);
    }
  }

  /// Ubah payload list JSON menjadi daftar model; non-list → list kosong.
  static List<T> unwrapList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) parse,
  ) => data is List
      ? data.map((e) => parse(Map<String, dynamic>.from(e as Map))).toList()
      : const [];

  /// Hasil mutasi beserta metadata root bila portal menyertakannya.
  static Map<String, dynamic> mutationRoot(dynamic responseData) {
    final result = unwrapMutation(responseData);
    return result.rawRoot ??
        {'success': result.success, 'message': result.message};
  }

  /// Koersi payload (Map / List / String JSON) menjadi map; gagal → {}.
  static Map<String, dynamic> forceJsonMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first);
    } else if (raw is String) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map) {
          return Map<String, dynamic>.from(parsed);
        } else if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
          return Map<String, dynamic>.from(parsed.first);
        }
      } catch (_) {}
    }
    return {};
  }

  /// Ekstensi berkas dari header content-disposition (fallback .pdf).
  static String extensionFromHeaders(
    Headers headers, {
    String fallback = '.pdf',
  }) {
    final contentDisposition = headers.value('content-disposition');
    if (contentDisposition != null &&
        contentDisposition.contains('filename=')) {
      final match = RegExp(
        r'filename="?([^";]+)"?',
      ).firstMatch(contentDisposition);
      final fname = match?.group(1);
      if (fname != null && fname.contains('.')) {
        return '.${fname.split('.').last}';
      }
    }
    return fallback;
  }

  // ponytail: centralized error handler to prevent raw null/English network messages
  //
  // Mengembalikan [AppFailure] yang pesannya SELALU ramah-pengguna. Non-
  // DioException tidak lagi memakai `e.toString()` (sumber kebocoran pesan
  // teknis seperti "FormatException: ..." atau "type 'Null' is not a subtype ...").
  static AppFailure handleError(
    dynamic e, [
    String fallback = 'Terjadi kesalahan',
  ]) {
    // Sudah pernah dipetakan (mis. dari unwrapData/unwrapRoot) — pertahankan.
    if (e is AppFailure) return e;

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
        return AppFailure.fromServer(
          serverMsg,
          fallback: 'Permintaan tidak valid',
        );
      }

      if (statusCode == 401) {
        return AppFailure('Sesi berakhir. Silakan login ulang.');
      }

      if (statusCode == 413) {
        return AppFailure.fromServer(
          serverMsg,
          fallback: 'Ukuran berkas melebihi batas 5 MB',
        );
      }

      if (statusCode == 429) {
        return AppFailure(
          'Terlalu banyak permintaan. Silakan tunggu sebentar.',
        );
      }

      if (statusCode == 500) {
        if (serverMsg != null &&
            (serverMsg.toLowerCase().contains('sesi') ||
                serverMsg.toLowerCase().contains('session'))) {
          return AppFailure('Sesi berakhir. Silakan login ulang.');
        }
        return AppFailure('Terjadi kendala pada server portal');
      }

      if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
        return AppFailure('Layanan portal Amikom sedang tidak dapat diakses');
      }

      if (serverMsg != null && serverMsg.isNotEmpty) {
        return AppFailure.fromServer(serverMsg, fallback: fallback);
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AppFailure('Koneksi ke server batas waktu habis');
      }
      if (e.type == DioExceptionType.connectionError) {
        return AppFailure('Tidak dapat terhubung ke server');
      }
      return AppFailure(fallback);
    }

    // Exception lain (FormatException, TypeError, PlatformException, …) tidak
    // pernah ditampilkan mentah — cukup dipetakan ke fallback ramah.
    return AppFailure(fallback);
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
