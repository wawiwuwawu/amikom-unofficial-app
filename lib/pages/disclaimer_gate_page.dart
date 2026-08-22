import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/disclaimer_view.dart';

/// Gerbang persetujuan penafian — ditampilkan SEBELUM login pertama kali.
/// Status persetujuan disimpan lokal (flag `disclaimer_accepted_v1`);
/// jika versi ketentuan naik, ubah key agar pengguna diminta setuju ulang.
class DisclaimerGatePage extends StatefulWidget {
  const DisclaimerGatePage({super.key});

  @override
  State<DisclaimerGatePage> createState() => _DisclaimerGatePageState();
}

class _DisclaimerGatePageState extends State<DisclaimerGatePage> {
  bool _agree = false;
  bool _saving = false;

  Future<void> _accept() async {
    if (!_agree || _saving) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted_v1', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penafian & Ketentuan',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF501F66),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Baca sebelum menggunakan aplikasi.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            Expanded(child: DisclaimerView(showAcceptButton: false)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF501F66),
                      title: const Text(
                        'Saya sudah membaca dan memahami Penafian ini, '
                        'dan akan menggunakan aplikasi dengan risiko sendiri.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _agree ? _accept : null,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(CupertinoIcons.checkmark_circle_fill),
                        label: const Text(
                          'Setuju & Lanjut ke Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF501F66),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE0E0E0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
