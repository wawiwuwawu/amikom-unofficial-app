import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/wifi_kampus_service.dart';
import '../theme/app_theme.dart';

/// Indikator mini WiFi kampus di AppBar [MainPage].
///
/// Empat keadaan (keputusan user — ikon mini, bukan kartu dashboard):
///  - [WifiKampusFase.diLuar] → ikon disembunyikan (appbar bersih di rumah).
///  - [WifiKampusFase.terputus] → wifi redup (belum login portal).
///  - [WifiKampusFase.mencoba] → spinner mini.
///  - [WifiKampusFase.terhubung] → wifi penuh warna success ("full bar").
///
/// Ketuk → bottom sheet status + aksi "Coba login lagi".
class WifiKampusIndicator extends StatelessWidget {
  final WifiKampusService service;

  const WifiKampusIndicator({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WifiKampusFase>(
      valueListenable: service.fase,
      builder: (context, fase, _) {
        if (fase == WifiKampusFase.diLuar) return const SizedBox.shrink();
        return IconButton(
          tooltip: 'Status WiFi Kampus',
          visualDensity: VisualDensity.compact,
          onPressed: () => showWifiKampusSheet(context, service),
          icon: _ikon(fase),
        );
      },
    );
  }

  Widget _ikon(WifiKampusFase fase) {
    switch (fase) {
      case WifiKampusFase.terhubung:
        return const Icon(
          CupertinoIcons.wifi,
          size: 21,
          color: AppColors.success,
        );
      case WifiKampusFase.mencoba:
        return const SizedBox(
          width: 21,
          height: 21,
          child: Padding(
            padding: EdgeInsets.all(3),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case WifiKampusFase.terputus:
        // Redup = di jaringan kampus tapi portal belum terlewati.
        return const Icon(
          CupertinoIcons.wifi,
          size: 21,
          color: AppColors.textMuted,
        );
      case WifiKampusFase.diLuar:
        return const SizedBox.shrink();
    }
  }
}

/// Membuka bottom sheet status WiFi kampus: keadaan + SSID + aksi.
Future<void> showWifiKampusSheet(
  BuildContext context,
  WifiKampusService service,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => WifiKampusSheet(service: service),
  );
}

class WifiKampusSheet extends StatefulWidget {
  final WifiKampusService service;

  const WifiKampusSheet({super.key, required this.service});

  @override
  State<WifiKampusSheet> createState() => _WifiKampusSheetState();
}

class _WifiKampusSheetState extends State<WifiKampusSheet> {
  bool _mencoba = false;

  Future<void> _cobaLagi() async {
    setState(() => _mencoba = true);
    await widget.service.cobaLoginManual();
    if (!mounted) return;
    setState(() => _mencoba = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.wifi, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text('WiFi Kampus', style: AppText.h2),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ValueListenableBuilder<WifiKampusFase>(
              valueListenable: widget.service.fase,
              builder: (context, fase, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_judul(fase), style: AppText.h3),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_penjelasan(fase), style: AppText.body),
                ],
              ),
            ),
            if (_mencoba) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Mengirim kredensial ke portal…',
                style: AppText.label,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _mencoba ? null : _cobaLagi,
                icon: _mencoba
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.arrow_clockwise, size: 16),
                label: const Text('Coba login lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _judul(WifiKampusFase fase) => switch (fase) {
        WifiKampusFase.terhubung => 'Terhubung ke Hotspot@Amikom',
        WifiKampusFase.mencoba => 'Mencoba login ke portal…',
        WifiKampusFase.terputus => 'Belum terhubung ke internet kampus',
        WifiKampusFase.diLuar => 'Tidak berada di WiFi kampus',
      };

  String _penjelasan(WifiKampusFase fase) => switch (fase) {
        WifiKampusFase.terhubung =>
          'Login portal berhasil dan internet berjalan normal.',
        WifiKampusFase.mencoba =>
          'Aplikasi sedang mengirim kredensial ke portal kampus.',
        WifiKampusFase.terputus => _penjelasanTerputus(),
        WifiKampusFase.diLuar =>
          'Indikator ini hanya muncul saat perangkat tersambung ke Hotspot@Amikom.',
      };

  /// Penjelasan fase terputus — bila BE pernah melaporkan biodata portal
  /// kosong (kontrak `code: biodata_tanggal_lahir_kosong`), sebutkan
  /// penyebabnya + jalan keluarnya (kredensial manual di Profil).
  String _penjelasanTerputus() {
    if (widget.service.biodataKosong) {
      return 'Perangkat tersambung ke Hotspot@Amikom, tetapi kredensial WiFi '
          'belum bisa dibentuk karena biodata portal (tanggal lahir) belum '
          'terisi. Isi biodata di portal mahasiswa, atau gunakan kredensial '
          'manual di halaman Profil.';
    }
    return 'Perangkat tersambung ke Hotspot@Amikom, tetapi portal belum '
        'menerima login.';
  }
}
