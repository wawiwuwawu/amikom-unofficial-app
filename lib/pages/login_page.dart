import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../widgets/glass_card.dart';

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
          backgroundColor: Colors.orange.shade800,
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
          backgroundColor: Colors.red,
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
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final String serverMsg = (e.response?.data is Map && e.response?.data['message'] != null)
            ? (e.response?.data['message']?.toString() ?? 'Terjadi kesalahan saat login')
            : (e.message ?? 'Terjadi kesalahan saat login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serverMsg, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
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
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errStr, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
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
      body: Stack(
        children: [
          // Background Gradient (Frosted Pearl & Ice Blue)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD), // Soft Ice Blue
                  Color(0xFFFAFCFF), // Pearl White
                  Color(0xFFBBDEFB), // Ice Blue Deep
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.book_fill, size: 64, color: Color(0xFF501F66)),
                  ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Ini Amikom?',
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF501F66),
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                  
                  const Text(
                    'Unofficial App',
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 48),
                  
                  GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nimController,
                            style: const TextStyle(color: Color(0xFF501F66), fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'NIM',
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(CupertinoIcons.person_fill, color: Color(0xFF501F66)),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            style: const TextStyle(color: Color(0xFF501F66), fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(CupertinoIcons.lock_fill, color: Color(0xFF501F66)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                                  color: const Color(0xFF501F66),
                                ),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreedToDisclaimer,
                                  activeColor: const Color(0xFF501F66),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _agreedToDisclaimer = val ?? false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'Saya menyetujui ',
                                      style: TextStyle(fontSize: 13, color: Colors.black87),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, '/penafian'),
                                      child: const Text(
                                        'Penafian & Ketentuan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF501F66),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (_loading || _retryCountdown > 0) ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBBDEFB), // Ice Blue
                                foregroundColor: const Color(0xFF501F66), // Amikom Purple text
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF501F66),
                                      ),
                                    )
                                  : Text(
                                      _retryCountdown > 0
                                          ? 'Coba lagi dalam $_retryCountdown detik'
                                          : 'Login',
                                      style: TextStyle(
                                        fontSize: _retryCountdown > 0 ? 15 : 18,
                                        fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}
