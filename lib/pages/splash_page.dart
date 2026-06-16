import 'package:flutter/material.dart';
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
      _goToLogin();
      return;
    }

    try {
      await ApiClient.instance.dio.get('/api/v1/dashboard');
      _goToMain();
    } catch (_) {
      _goToLogin();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi Amikom',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
