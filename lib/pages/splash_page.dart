import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_client.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await ApiClient.instance.restoreSession();

    if (ApiClient.instance.token == null ||
        ApiClient.instance.refreshToken == null) {
      // No tokens, try silent re-login with saved credentials
      final reLoginSuccess = await ApiClient.instance.trySilentReLogin();
      if (reLoginSuccess) {
        _goToMain();
      } else {
        _goToLogin();
      }
      return;
    }

    try {
      await ApiClient.instance.dio.get('/api/v1/dashboard');
      _goToMain();
    } catch (_) {
      // Token invalid, try silent re-login
      final reLoginSuccess = await ApiClient.instance.trySilentReLogin();
      if (reLoginSuccess) {
        _goToMain();
      } else {
        _goToLogin();
      }
    }
  }

  void _goToMain() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _goToLogin() {
    if (!mounted) return;
    ApiClient.instance.clearTokens();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD), // Ice Blue
              Color(0xFFFAFCFF), // Pearl White
              Color(0xFFBBDEFB), // Ice Blue Deep
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.book_fill, size: 64, color: Color(0xFF501F66)),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              const Text(
                'Ini Amikom?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF501F66),
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              const Text(
                'Unofficial App',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF501F66),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
