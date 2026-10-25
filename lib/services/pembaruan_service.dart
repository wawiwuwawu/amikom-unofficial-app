import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_filex/open_filex.dart' show OpenFilex, ResultType;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_failure.dart';

/// Pembaruan yang tersedia di GitHub Releases (didistribusikan sideload,
/// bukan Play Store).
class InfoPembaruan {
  /// Versi terbaru tanpa prefiks "v", mis. "1.13.0".
  final String versi;

  /// Catatan rilis (isi release di GitHub).
  final String catatan;

  /// URL unduhan langsung ke asset APK.
  final String urlApk;

  final String? namaApk;

  /// SHA-256 berkas (hex kecil) dari field `digest` GitHub API; null bila
  /// release tidak menyediakan digest — unduhan tetap diizinkan tanpa cek.
  final String? sha256;

  const InfoPembaruan({
    required this.versi,
    required this.catatan,
    required this.urlApk,
    required this.namaApk,
    required this.sha256,
  });

  Map<String, dynamic> toJson() => {
    'versi': versi,
    'catatan': catatan,
    'urlApk': urlApk,
    'namaApk': namaApk,
    'sha256': sha256,
  };

  static InfoPembaruan? fromJson(Map<String, dynamic> json) {
    final url = json['urlApk'] as String?;
    final versi = json['versi'] as String?;
    if (url == null || url.isEmpty || versi == null || versi.isEmpty) {
      return null;
    }
    return InfoPembaruan(
      versi: versi,
      catatan: json['catatan'] as String? ?? '',
      urlApk: url,
      namaApk: json['namaApk'] as String?,
      sha256: json['sha256'] as String?,
    );
  }
}

/// Layanan cek + unduh pembaruan APK langsung dari GitHub Releases.
///
/// TIDAK memakai [ApiClient]: endpoint GitHub bersifat publik tanpa sesi,
/// sedangkan ApiClient membawa interceptor refresh token rotatif — satu
/// request gagal ke URL asing bisa membakar refresh token single-use.
/// (Pola yang sama seperti instance Dio terpisah pada pengambilan ICS libur.)
///
/// Throttle: cek paling sering 1x/24 jam (dipertahankan lintas restart via
/// SharedPreferences) — API GitHub tanpa token hanya 60 request/jam per IP,
/// dan mahasiswa satu kampus berbagi IP publik WiFi yang sama. Gagal cek
/// diberi TTL pendingan 30 menit agar buka-tutup app tidak meng-hammer.
///
/// Fail-open total: semua kegagalan diemankan; fitur update tidak boleh
/// pernah membuat app terasa error. "Lewati versi ini" disimpan per-versi —
/// versi baru otomatis menampilkan banner lagi.
class PembaruanService {
  PembaruanService._() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 10),
        // Cek versi kecil & jarang; unduhan APK bisa puluhan MB.
        sendTimeout: const Duration(seconds: 20),
      ),
    );
  }

  static final instance = PembaruanService._();

  late Dio _dio;

  @visibleForTesting
  void gantiDioUntukTest(Dio dio) => _dio = dio;

  String? _versiTerpasangOverride;
  String? _urlOverride;
  Directory? _direktoriUnduhOverride;
  Future<bool> Function(String)? _pembukaOverride;

  /// Uji: paksa versi terpasang (PackageInfo butuh platform channel).
  @visibleForTesting
  void pakaiVersiUntukTest(String? versi) => _versiTerpasangOverride = versi;

  /// Uji: paksa URL releases/latest (dotenv tidak ter-load di unit test).
  @visibleForTesting
  void pakaiUrlUntukTest(String? url) => _urlOverride = url;

  String get _releaseUrl {
    final override = _urlOverride;
    if (override != null) return override;
    try {
      return dotenv.env['UPDATE_RELEASE_URL'] ?? '';
    } catch (_) {
      // dotenv belum ter-load (kasus tepi startup) — fitur fail-open mati.
      return '';
    }
  }

  /// Uji: arahkan direktori unduhan (path_provider butuh platform channel).
  @visibleForTesting
  void gantiDirektoriUnduhUntukTest(Directory dir) =>
      _direktoriUnduhOverride = dir;

  /// Uji: pengganti OpenFilex.open (platform channel). Kembalikan true bila
  /// pemasang berhasil dibuka.
  @visibleForTesting
  void gantiPembukaUntukTest(Future<bool> Function(String) pembuka) =>
      _pembukaOverride = pembuka;

  static const Duration _intervalSukses = Duration(hours: 24);
  static const Duration _intervalGagal = Duration(minutes: 30);

  static const _keyCekMs = 'pembaruan_cek_terakhir_ms';
  static const _keyLewati = 'pembaruan_lewati_versi';
  static const _keyInfoJson = 'pembaruan_info_json';
  static const _keyUnduhanJson = 'pembaruan_unduhan_json';

  InfoPembaruan? _cache;
  bool _cacheTerisi = false;
  DateTime _cekTerakhir = DateTime.fromMillisecondsSinceEpoch(0);
  bool _gagalTerakhir = false;
  DateTime _gagalWaktu = DateTime.fromMillisecondsSinceEpoch(0);
  Future<InfoPembaruan?>? _cekBerjalan;

  /// Hasil cek terakhir (dari memori atau cache disk) — dipakai banner.
  InfoPembaruan? get hasilTerakhir => _cacheTerisi ? _cache : null;

  /// Versi aplikasi yang sedang berjalan, mis. "1.12.0".
  Future<String> versiTerpasang() async {
    final override = _versiTerpasangOverride;
    if (override != null) return override;
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  @visibleForTesting
  Future<void> resetUntukTest() async {
    _cache = null;
    _cacheTerisi = false;
    _cekTerakhir = DateTime.fromMillisecondsSinceEpoch(0);
    _gagalTerakhir = false;
    _gagalWaktu = DateTime.fromMillisecondsSinceEpoch(0);
    _cekBerjalan = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCekMs);
    await prefs.remove(_keyLewati);
    await prefs.remove(_keyInfoJson);
    await prefs.remove(_keyUnduhanJson);
  }

  /// Cek pembaruan dengan throttle harian; TIDAK pernah melempar — untuk
  /// pemanggilan otomatis saat app dibuka. Dipanggil dari main.dart.
  Future<InfoPembaruan?> cekOtomatis() async {
    try {
      return await cekPembaruan();
    } catch (e) {
      debugPrint('Pembaruan: cek otomatis gagal (${e.runtimeType})');
      return hasilTerakhir;
    }
  }

  /// Cek pembaruan. Throttle 24 jam berlaku kecuali [paksa] (cek manual dari
  /// drawer). Bila jaringan gagal dan [paksa], melempar [AppFailure]; bila
  /// tidak paksa, kembalikan cache terakhir (bisa null) tanpa error.
  Future<InfoPembaruan?> cekPembaruan({bool paksa = false}) async {
    if (_cekBerjalan != null) return _cekBerjalan;

    await _muatCacheDisk();

    if (!paksa) {
      final sekarang = DateTime.now();
      if (sekarang.difference(_cekTerakhir) < _intervalSukses) {
        return _cache;
      }
      if (_gagalTerakhir && sekarang.difference(_gagalWaktu) < _intervalGagal) {
        return _cache;
      }
    }

    final berjalan = _cek(paksa: paksa);
    _cekBerjalan = berjalan;
    try {
      return await berjalan;
    } finally {
      _cekBerjalan = null;
    }
  }

  Future<InfoPembaruan?> _cek({required bool paksa}) async {
    final url = _releaseUrl;
    if (url.isEmpty) {
      // Env tidak dikonfigurasi (mis. clone baru) — fitur dianggap mati.
      _tandaiSukses(null);
      return null;
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      );
      final body = response.data;
      if (body == null) throw const AppFailure('Respons server tidak valid');
      final versiSekarang = await versiTerpasang();
      final info = dariResponseJson(body, versiSekarang);
      await _bersihkanUnduhanTersimpan(info?.versi);
      _tandaiSukses(info);
      return info;
    } catch (e) {
      debugPrint('Pembaruan: fetch gagal (${e.runtimeType})');
      if (paksa) throw AppFailure(_gagalPesan(e));
      _gagalTerakhir = true;
      _gagalWaktu = DateTime.now();
      return _cache;
    }
  }

  /// Ubah respons `GET /releases/latest` menjadi info pembaruan, atau null
  /// bila versi terbaru tidak lebih baru / tidak ada asset APK. Hanya untuk
  /// pengujian.
  @visibleForTesting
  static InfoPembaruan? dariResponseJson(
    Map<String, dynamic> body,
    String versiTerpasang,
  ) {
    final tagName = body['tag_name'] as String?;
    if (tagName == null || tagName.isEmpty) return null;
    final versi = tagName.startsWith('v') ? tagName.substring(1) : tagName;
    if (bandingkanVersi(versi, versiTerpasang) <= 0) return null;

    final assets = body['assets'];
    if (assets is! List) return null;
    Map<String, dynamic>? asset;
    for (final a in assets) {
      if (a is! Map<String, dynamic>) continue;
      final nama = a['name'] as String? ?? '';
      if (!nama.toLowerCase().endsWith('.apk')) continue;
      // Prefer asset "release" (app-release.apk) di atas split APK lain.
      if (asset == null ||
          (nama.contains('release') &&
              !(asset['name'] as String? ?? '').contains('release'))) {
        asset = a;
      }
    }
    if (asset == null) return null;
    final url = asset['browser_download_url'] as String?;
    if (url == null || url.isEmpty) return null;

    return InfoPembaruan(
      versi: versi,
      catatan: body['body'] as String? ?? '',
      urlApk: url,
      namaApk: asset['name'] as String?,
      sha256: _shaDariDigest(asset['digest'] as String?),
    );
  }

  /// GitHub API mengembalikan asset.digest berbentuk "sha256:hex-kecil".
  static String? _shaDariDigest(String? digest) {
    if (digest == null) return null;
    final m = digest.split(':');
    if (m.length != 2 || m[0] != 'sha256') return null;
    return m[1].toLowerCase();
  }

  /// Bandingkan versi "1.2.10" vs "1.2.9" numerik per segmen (bukan string,
  /// supaya 10 > 9). Segmen hilang dianggap 0 sehingga "1.12" == "1.12.0";
  /// segmen tak terbaca juga diperlakukan 0. Hanya untuk pengujian.
  @visibleForTesting
  static int bandingkanVersi(String a, String b) {
    List<int> segmen(String versi) {
      final daftar = <int>[];
      for (final bagian in versi.split('.')) {
        final angka = int.tryParse(bagian.trim());
        daftar.add(angka ?? 0);
      }
      return daftar;
    }

    final ka = segmen(a);
    final kb = segmen(b);
    final panjang = ka.length > kb.length ? ka.length : kb.length;
    for (var i = 0; i < panjang; i++) {
      final va = i < ka.length ? ka[i] : 0;
      final vb = i < kb.length ? kb[i] : 0;
      if (va != vb) return va > vb ? 1 : -1;
    }
    return 0;
  }

  // ── Lewati versi ─────────────────────────────────────────────────────────

  /// User menolak versi ini — tidak tampilkan lagi untuk [versi]; versi baru
  /// berikutnya otomatis tampil (key hanya menyimpan satu versi). Cache cek
  /// dikosongkan agar banner hilang seketika tanpa menunggu cek berikutnya.
  Future<void> lewatiVersi(String versi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLewati, versi);
    _cache = null;
    _cacheTerisi = true;
    await prefs.remove(_keyInfoJson);
  }

  Future<bool> dilewati(InfoPembaruan info) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLewati) == info.versi;
  }

  // ── Unduh & pasang ───────────────────────────────────────────────────────

  /// Unduh APK ke cache app (tanpa izin storage), verifikasi SHA-256 bila
  /// tersedia, lalu kembalikan path berkas. Bila unduhan valid sebelumnya
  /// untuk versi yang sama masih ada, dipakai ulang tanpa mengunduh ulang.
  /// Melempar [AppFailure] bila gagal — pesan selalu ramah-pengguna.
  Future<String> unduhApk(
    InfoPembaruan info, {
    void Function(int terunduh, int total)? onProgress,
  }) async {
    final tersimpan = await _pathUnduhanValid(info);
    if (tersimpan != null) return tersimpan;

    final dir = _direktoriUnduhOverride ?? await getTemporaryDirectory();
    final folder = Directory('${dir.path}${Platform.pathSeparator}pembaruan');
    await folder.create(recursive: true);
    final nama = info.namaApk ?? 'app-release-${info.versi}.apk';
    final path = '${folder.path}${Platform.pathSeparator}$nama';
    final file = File(path);
    if (await file.exists()) await file.delete();

    try {
      await _dio.download(
        info.urlApk,
        path,
        onReceiveProgress: onProgress,
        options: Options(
          // Respons biner; jangan biarkan dio mencoba parse JSON.
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/octet-stream'},
        ),
      );
    } catch (e) {
      debugPrint('Pembaruan: unduh gagal (${e.runtimeType})');
      if (await file.exists()) await file.delete();
      throw AppFailure(
        e is DioException && e.type == DioExceptionType.connectionTimeout
            ? 'Unduhan batas waktu habis. Periksa koneksi lalu coba lagi.'
            : 'Gagal mengunduh pembaruan. Coba lagi nanti.',
      );
    }

    final sha = info.sha256;
    if (sha != null) {
      final aktual = sha256.convert(await file.readAsBytes()).toString();
      if (aktual != sha) {
        await file.delete();
        throw const AppFailure(
          'Berkas pembaruan rusak saat diunduh. Coba lagi.',
        );
      }
    }

    await (await SharedPreferences.getInstance()).setString(
      _keyUnduhanJson,
      jsonEncode({'versi': info.versi, 'path': path}),
    );
    return path;
  }

  /// Buka pemasang sistem untuk APK di [path]. Android selalu menampilkan
  /// dialog konfirmasi sendiri (atau memandu ke izin "Install unknown apps"
  /// per-app saat pertama kali) — tanggung jawab UI kita berhenti di sini.
  Future<void> pasang(String path) async {
    final pembuka = _pembukaOverride;
    final sukses = pembuka != null
        ? await pembuka(path)
        : (await OpenFilex.open(path)).type == ResultType.done;
    if (!sukses) {
      throw const AppFailure(
        'Izin memasang aplikasi belum diberikan. Izinkan "Install unknown '
        'apps" untuk aplikasi ini di pengaturan sistem, lalu coba lagi.',
      );
    }
  }

  /// Path APK yang sudah terunduh & terverifikasi untuk [info], atau null.
  Future<String?> _pathUnduhanValid(InfoPembaruan info) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUnduhanJson);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['versi'] != info.versi) return null;
      final path = data['path'] as String?;
      if (path == null) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      final sha = info.sha256;
      if (sha != null) {
        final aktual = sha256.convert(await file.readAsBytes()).toString();
        if (aktual != sha) {
          await file.delete();
          await prefs.remove(_keyUnduhanJson);
          return null;
        }
      }
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Hapus catatan unduhan tersimpan saat versi berubah / tidak ada update.
  Future<void> _bersihkanUnduhanTersimpan(String? versiBaru) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUnduhanJson);
    if (raw == null) return;
    if (versiBaru != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['versi'] == versiBaru) return;
      } catch (_) {}
    }
    await prefs.remove(_keyUnduhanJson);
  }

  // ── Cache & state internal ───────────────────────────────────────────────

  Future<void> _muatCacheDisk() async {
    if (_cacheTerisi) return;
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyCekMs) ?? 0;
    _cekTerakhir = DateTime.fromMillisecondsSinceEpoch(ms);
    final raw = prefs.getString(_keyInfoJson);
    if (raw != null) {
      try {
        _cache = InfoPembaruan.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        _cache = null;
      }
    }
    _cacheTerisi = true;
  }

  void _tandaiSukses(InfoPembaruan? info) {
    _cache = info;
    _cacheTerisi = true;
    _cekTerakhir = DateTime.now();
    _gagalTerakhir = false;
    _persistSukses(info);
  }

  Future<void> _persistSukses(InfoPembaruan? info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCekMs, _cekTerakhir.millisecondsSinceEpoch);
    if (info == null) {
      await prefs.remove(_keyInfoJson);
    } else {
      await prefs.setString(_keyInfoJson, jsonEncode(info.toJson()));
    }
  }

  String _gagalPesan(Object e) {
    if (e is AppFailure) return e.message;
    return 'Gagal memeriksa pembaruan. Coba lagi nanti.';
  }
}
