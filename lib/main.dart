import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/api_client.dart';
import 'services/deep_link_service.dart';
import 'services/pembaruan_service.dart';
import 'services/pengingat_jadwal_service.dart';
import 'services/push_service.dart';
import 'services/widget_jadwal_service.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'pages/splash_page.dart';
import 'pages/penafian_page.dart';
import 'services/navigation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Zona waktu untuk notifikasi terjadwal (pengingat jadwal). WAJIB terpisah
  // dari blok Firebase: bila inisialisasi Firebase gagal, pengingat jadwal
  // tidak boleh ikut mati. Gagal zona waktu di-skip aman — waktu lokal
  // (DateTime) tetap jadi dasar komputasi.
  try {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  } catch (e) {
    debugPrint('Zona waktu tidak terpasang, pakai default: $e');
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    await dotenv.load(fileName: '.env.example');
  }

  // Sesi dipulihkan lebih dulu agar NIM tersedia saat push diinisialisasi.
  // Gagal restore bukan fatal — halaman splash tetap menangani alur login.
  try {
    await ApiClient.instance.restoreSession();
  } catch (_) {
    // Ditangani splash (ensureSessionOrSilentLogin / clearTokens).
  }

  // Push FCM: channel + listener background/foreground. Sebelum
  // google-services.json tersedia, inisialisasi gagal dengan aman — push
  // otomatis akan dicoba lagi saat aplikasi dibuka berikutnya, bukan crash.
  try {
    await Firebase.initializeApp();
    await PushService.instance.init();
  } catch (e) {
    debugPrint('Push FCM belum aktif: $e');
  }

  // Channel pengingat jadwal — TERPISAH dari blok Firebase supaya pengingat
  // tidak mati hanya karena inisialisasi push gagal.
  try {
    await PengingatJadwalService.instance.init();
  } catch (e) {
    debugPrint('Pengingat jadwal belum aktif: $e');
  }

  await DeepLinkService.instance.initFromInitialLink();

  // Cek pembaruan otomatis (throttle 1x/24 jam, fail-open, tanpa UI): hasil
  //nya dibaca banner di halaman notifikasi. Tidak boleh menunda app start.
  unawaited(PembaruanService.instance.cekOtomatis());

  // Segarkan widget home "Jadwal Hari Ini" dari cache (fail-open): widget
  // ikut muter tanggal setiap kali app dibuka walau tanpa login.
  unawaited(WidgetJadwalService.instance.perbaruiDariCache());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.instance.navigatorKey,
      title: 'Ini Amikom?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/main': (_) => const MainPage(),
        '/penafian': (_) => const PenafianPage(),
      },
    );
  }
}
