import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_kit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscureText = true;
  bool _agreedToDisclaimer = false;
  int _retryCountdown = 0;
  Timer? _countdownTimer;
  @override
  void initState() {
    super.initState();
    _loadDisclaimerAgreement();
  }

  Future<void> _loadDisclaimerAgreement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final agreed = prefs.getBool('disclaimer_accepted_v1') ?? false;
      if (mounted) setState(() => _agreedToDisclaimer = agreed);
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startRetryCountdown(int seconds) {
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() => _retryCountdown = seconds);
    } else {
      _retryCountdown = seconds;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_retryCountdown <= 1) {
        timer.cancel();
        setState(() => _retryCountdown = 0);
      } else {
        setState(() => _retryCountdown--);
      }
    });
  }

  int _parseRetryAfter(DioException e) {
    final headerVal = e.response?.headers.value('retry-after');
    if (headerVal != null) {
      final parsed = int.tryParse(headerVal.trim());
      if (parsed != null && parsed > 0) return parsed;
    }
    final data = e.response?.data;
    if (data is Map) {
      final retrySec = data['retry_after'] ?? data['retryAfter'] ?? data['retry_in'];
      if (retrySec is int && retrySec > 0) return retrySec;
      if (retrySec != null) {
        final parsed = int.tryParse(retrySec.toString().trim());
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return 60;
  }
  Future<void> _login() async {
    if (_retryCountdown > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan tunggu $_retryCountdown detik sebelum mencoba kembali.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToDisclaimer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui Penafian & Ketentuan terlebih dahulu'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.login(
        _nimController.text.trim(), 
        _passwordController.text.trim()
      );
      
      await ApiClient.instance.setTokens(res.token, res.refreshToken);
      ApiClient.instance.setUserInfo(res.nim, '');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('disclaimer_accepted_v1', true);
      } catch (_) {}

      _countdownTimer?.cancel();
      _retryCountdown = 0;

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 429) {
        final waitSeconds = _parseRetryAfter(e);
        _startRetryCountdown(waitSeconds);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terlalu banyak percobaan login. Silakan tunggu $waitSeconds detik sebelum mencoba kembali.',
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final String serverMsg = (e.response?.data is Map && e.response?.data['message'] != null)
            ? (e.response?.data['message']?.toString() ?? 'Terjadi kesalahan saat login')
            : (e.message ?? 'Terjadi kesalahan saat login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serverMsg),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().replaceFirst('Exception: ', '');
      if (errStr.contains('429') || errStr.toLowerCase().contains('terlalu banyak')) {
        _startRetryCountdown(60);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Terlalu banyak percobaan login. Silakan tunggu 60 detik sebelum mencoba kembali.',
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errStr),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Stack(
        children: [
          // Latar lembut bernuansa brand (menggantikan gradasi ice-blue lama).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    AppColors.scaffold,
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo pada bulatan brand
                      Center(
                        child: Container(
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
                        ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Text(
                        'Ini Amikom?',
                        textAlign: TextAlign.center,
                        style: AppText.display.copyWith(color: AppColors.primary),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppSpacing.sm),

                      const Center(
                        child: AppPill('Unofficial App'),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppSpacing.xxl),

                      AppSurface(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nimController,
                                textInputAction: TextInputAction.next,
                                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  labelText: 'NIM',
                                  prefixIcon: Icon(
                                    CupertinoIcons.person_fill,
                                    color: AppColors.primary,
                                  ),
                                ),
                                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscureText,
                                textInputAction: TextInputAction.done,
                                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    CupertinoIcons.lock_fill,
                                    color: AppColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => setState(() => _obscureText = !_obscureText),
                                  ),
                                ),
                                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreedToDisclaimer,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      onChanged: (val) {
                                        setState(() => _agreedToDisclaimer = val ?? false);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'Saya menyetujui ',
                                          style: AppText.bodySm.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => Navigator.pushNamed(context, '/penafian'),
                                          child: Text(
                                            'Penafian & Ketentuan',
                                            style: AppText.bodySm.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: (_loading || _retryCountdown > 0) ? null : _login,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _retryCountdown > 0
                                              ? 'Coba lagi dalam $_retryCountdown detik'
                                              : 'Login',
                                          style: AppText.button.copyWith(
                                            fontSize: _retryCountdown > 0 ? 14 : 15,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
