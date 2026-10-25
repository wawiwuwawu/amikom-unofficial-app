import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Merek OEM yang punya pembatas notifikasi khusus (dontkillmyapp.com).
/// Merek luar dari daftar masuk [OemMerek.generik] — langkah umum.
enum OemMerek { xiaomi, oppo, vivo, samsung, infinix, huawei, generik }

/// Hasil deteksi merek: [label] untuk teks UI ("Xiaomi", "Realme", …),
/// `null` bila generik (merek tidak dikenal / deteksi gagal).
class OemMerekInfo {
  final OemMerek merek;
  final String? label;

  const OemMerekInfo(this.merek, {this.label});

  const OemMerekInfo.generik() : merek = OemMerek.generik, label = null;
}

/// Deteksi merek HP (Android `Build.MANUFACTURER` + `Build.MODEL`) untuk
/// panduan anti-pembunuhan-proses OEM, plus status dismiss kartu panduan.
///
/// Fail-open penuh: kegagalan plugin/prefs tidak pernah dilempar — deteksi
/// gagal menghasilkan [OemMerekInfo.generik] (kartu tetap tampil versi
/// generik), gagal prefs hanya membuat kartu muncul lagi.
abstract final class OemBateraiService {
  /// Kunci SharedPreferences: kartu panduan OEM sudah ditutup user —
  /// kartu muncul lagi hanya bila user belum menutupnya.
  static const _kPanduanDitutup = 'oem_panduan_ditutup';

  /// Pesan snack bila semua intent "Buka setelan" gagal dijalankan.
  static const kPesanFallbackBukaManual =
      'Buka manual: Setelan > Aplikasi > Ini Amikom?';

  /// Deteksi merek HP saat ini. Hanya di Android (via [defaultTargetPlatform]
  /// supaya bisa di-override di test); platform lain → generik.
  static Future<OemMerekInfo> deteksiMerek() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const OemMerekInfo.generik();
    }
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return klasifikasi(info.manufacturer, info.model);
    } catch (e) {
      debugPrint('OEM: deteksi merek gagal (${e.runtimeType}) — pakai generik');
      return const OemMerekInfo.generik();
    }
  }

  /// Normalisasi manufacturer + model (lowercase, substring) ke merek
  /// terklasifikasi. Publik untuk pengujian tanpa channel.
  static OemMerekInfo klasifikasi(String manufacturer, String model) {
    final s = '${manufacturer.toLowerCase()} ${model.toLowerCase()}';

    OemMerekInfo? cari(Map<RegExp, OemMerekInfo> aturan) {
      for (final entry in aturan.entries) {
        if (entry.key.hasMatch(s)) return entry.value;
      }
      return null;
    }

    return cari({
          RegExp(r'xiaomi|redmi|poco'): const OemMerekInfo(
            OemMerek.xiaomi,
            label: 'Xiaomi',
          ),
          RegExp(r'oppo'): const OemMerekInfo(OemMerek.oppo, label: 'Oppo'),
          RegExp(r'realme'): const OemMerekInfo(OemMerek.oppo, label: 'Realme'),
          RegExp(r'oneplus'): const OemMerekInfo(
            OemMerek.oppo,
            label: 'OnePlus',
          ),
          RegExp(r'vivo'): const OemMerekInfo(OemMerek.vivo, label: 'Vivo'),
          RegExp(r'iqoo'): const OemMerekInfo(OemMerek.vivo, label: 'iQOO'),
          RegExp(r'samsung'): const OemMerekInfo(
            OemMerek.samsung,
            label: 'Samsung',
          ),
          RegExp(r'infinix'): const OemMerekInfo(
            OemMerek.infinix,
            label: 'Infinix',
          ),
          RegExp(r'tecno'): const OemMerekInfo(
            OemMerek.infinix,
            label: 'Tecno',
          ),
          RegExp(r'itel'): const OemMerekInfo(
            OemMerek.infinix,
            label: 'Itel',
          ),
          RegExp(r'huawei'): const OemMerekInfo(
            OemMerek.huawei,
            label: 'Huawei',
          ),
          RegExp(r'honor'): const OemMerekInfo(OemMerek.huawei, label: 'Honor'),
        }) ??
        const OemMerekInfo.generik();
  }

  /// Kartu panduan sudah ditutup user? Fail-open: gagal baca → false
  /// (kartu boleh muncul, bukan alasan melempar).
  static Future<bool> panduanDitutup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kPanduanDitutup) ?? false;
    } catch (e) {
      debugPrint('OEM: gagal baca status kartu (${e.runtimeType})');
      return false;
    }
  }

  /// Menandai kartu panduan sudah ditutup user. Kegagalan prefs didiamkan.
  static Future<void> tandaiPanduanDitutup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPanduanDitutup, true);
    } catch (e) {
      debugPrint('OEM: gagal menyimpan status kartu (${e.runtimeType})');
    }
  }
}
