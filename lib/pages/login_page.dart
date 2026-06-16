import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _penggunaController = TextEditingController();
  final _passwController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _penggunaController.dispose();
    _passwController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final pengguna = _penggunaController.text.trim();
    final passw = _passwController.text.trim();

    if (pengguna.isEmpty || passw.isEmpty) {
      _showSnackbar('Isi semua field');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _authService.login(pengguna, passw);
      ApiClient.instance.setTokens(result.token, result.refreshToken);

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                'Aplikasi Amikom',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _penggunaController,
                decoration: const InputDecoration(
                  labelText: 'Pengguna',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwController,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
