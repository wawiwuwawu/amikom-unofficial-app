import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'pages/splash_page.dart';
import 'pages/keuangan_page.dart';
import 'pages/sp_page.dart';
import 'pages/skmk_page.dart';
import 'pages/izin_penelitian_page.dart';
import 'pages/surat_tugas_page.dart';
import 'pages/pkl_page.dart';
import 'pages/ujian_susulan_page.dart';
import 'pages/ppks_page.dart';
import 'pages/skripsi_page.dart';
import 'pages/penafian_page.dart';
import 'services/navigation_service.dart';

void main() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    await dotenv.load(fileName: '.env.example');
  }
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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFBBDEFB), // Ice Blue
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFAFCFF), // Pearl White
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/main': (_) => const MainPage(),
        '/keuangan': (_) => const KeuanganPage(),
        '/sp': (_) => const SpPage(),
        '/skmk': (_) => const SkmkPage(),
        '/izin-penelitian': (_) => const IzinPenelitianPage(),
        '/surat-tugas': (_) => const SuratTugasPage(),
        '/pkl': (_) => const PklPage(),
        '/ujian-susulan': (_) => const UjianSusulanPage(),
        '/ppks': (_) => const PpksPage(),
        '/skripsi': (_) => const SkripsiPage(),
        '/penafian': (_) => const PenafianPage(),
      },
    );
  }
}
