import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_client.dart';
import 'services/deep_link_service.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'pages/splash_page.dart';
import 'pages/penafian_page.dart';
import 'services/navigation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  // google-services.json tersedia, inisialisasi gagal dengan aman — tombol
  // Aktifkan yang akan melaporkan kegagalan, bukan crash.
  try {
    await Firebase.initializeApp();
    await PushService.instance.init();
    // Daftarkan ulang token bila push sudah aktif (mis. setelah reinstall).
    unawaited(PushService.instance.daftarkanUlangJikaAktif());
  } catch (e) {
    debugPrint('Push FCM belum aktif: $e');
  }

  await DeepLinkService.instance.initFromInitialLink();

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
