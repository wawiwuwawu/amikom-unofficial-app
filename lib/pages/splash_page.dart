import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

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

  String? _serverError;

  Future<void> _checkSession() async {
    setState(() {
      _serverError = null;
    });

    try {
      final health = await ApiClient.instance.dio.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (health.data['status'] != 'ok') {
        if (mounted) {
          setState(() {
            _serverError = 'Maaf, Server Offline atau periksa jaringan Anda.';
          });
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverError = 'Maaf, Server Offline atau periksa jaringan Anda.';
        });
      }
      return;
    }

    await ApiClient.instance.restoreSession();


    if (ApiClient.instance.token == null ||
        ApiClient.instance.refreshToken == null) {
      // Tidak ada token tersimpan — langsung ke halaman login
      _goToLogin();
      return;
    }

    try {
      await ApiClient.instance.dio.get('/api/v1/dashboard');
      _goToMain();
    } catch (_) {
      // Token mungkin expired — coba refresh (tanpa password)
      final renewed = await ApiClient.instance.ensureSessionOrSilentLogin();
      if (renewed) {
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
      backgroundColor: AppColors.scaffold,
      body: DecoratedBox(
        decoration: BoxDecoration(
          // Gradasi lembut dari primary brand — serasi dengan native splash.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.14),
              AppColors.scaffold,
              AppColors.primary.withValues(alpha: 0.06),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.book_fill,
                      size: 52,
                      color: Colors.white,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Ini Amikom?',
                    textAlign: TextAlign.center,
                    style: AppText.display.copyWith(color: AppColors.primary),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: AppSpacing.sm),
                  const AppPill('Unofficial App').animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_serverError != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: AppSurface(
                        variant: AppSurfaceVariant.danger,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _serverError!,
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton.icon(
                              onPressed: _checkSession,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn()
                  else
                    const AppLoading().animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
