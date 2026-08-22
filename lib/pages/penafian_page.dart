import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/disclaimer_view.dart';

/// Halaman "Penafian" — bisa dibuka kapan saja dari drawer/menu aplikasi.
class PenafianPage extends StatelessWidget {
  const PenafianPage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFF),
      appBar: AppBar(
        title: const Text(
          'Penafian',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF501F66),
          ),
        ),
        backgroundColor: const Color(0xFFFAFCFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(child: DisclaimerView(showAcceptButton: false)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextButton.icon(
                onPressed: openFullDisclaimer,
                icon: const Icon(
                  CupertinoIcons.arrow_up_right_square,
                  size: 16,
                  color: Color(0xFF501F66),
                ),
                label: const Text(
                  'Baca versi lengkap di Wiki proyek',
                  style: TextStyle(fontSize: 13, color: Color(0xFF501F66)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
