import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_failure.dart';
import '../services/pembaruan_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

/// Halaman penuh pembaruan aplikasi (menggantikan bottom sheet): unduhan
/// berjalan di [PembaruanService] — menutup halaman atau app diminimalkan
/// TIDAK membatalkannya; dibuka lagi → progres masih tampil.
///
/// Mengembalikan `'lewati'` bila user memilih lewati versi ini (pemanggil
/// — banner — memakai itu untuk menyembunyikan dirinya), `null` bila ditutup
/// dengan cara lain.
Future<String?> bukaPembaruanPage(BuildContext context, InfoPembaruan info) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => PembaruanPage(info: info)),
  );
}

class PembaruanPage extends StatefulWidget {
  final InfoPembaruan info;

  const PembaruanPage({super.key, required this.info});

  @override
  State<PembaruanPage> createState() => _PembaruanPageState();
}

class _PembaruanPageState extends State<PembaruanPage> {
  String _versiSekarang = '';

  @override
  void initState() {
    super.initState();
    PembaruanService.instance.versiTerpasang().then((v) {
      if (mounted) setState(() => _versiSekarang = v);
    });
  }

  Future<void> _lewati() async {
    await PembaruanService.instance.lewatiVersi(widget.info.versi);
    if (!mounted) return;
    Navigator.of(context).pop('lewati');
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return AppScaffold(
      title: 'Pembaruan Aplikasi',
      body: ValueListenableBuilder<StatusUnduh>(
        valueListenable: PembaruanService.instance.statusUnduh,
        builder: (context, status, _) {
          // Status unduhan milik versi lain (info basi) diperlakukan idle.
          final relevan =
              status.versi == null || status.versi == info.versi;
          final fase = relevan ? status.fase : FaseUnduh.idle;
          final progres = relevan ? status.progres : null;
          final pathApk = relevan ? status.pathApk : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pembaruan v${info.versi} Tersedia', style: AppText.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _versiSekarang.isEmpty
                    ? 'Versi terbaru siap dipasang.'
                    : 'Versi terpasang: $_versiSekarang',
                style: AppText.bodySm,
              ),
              if (info.catatan.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                AppSurface(
                  variant: AppSurfaceVariant.plain,
                  child: Text(
                    info.catatan.trim(),
                    style: AppText.bodySm.copyWith(height: 1.5),
                  ),
                ),
              ],
              if (fase == FaseUnduh.mengunduh) ...[
                const SizedBox(height: AppSpacing.lg),
                LinearProgressIndicator(
                  value: progres,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  progres == null
                      ? 'Mengunduh…'
                      : 'Mengunduh… ${(progres * 100).round()}% — '
                          'boleh tinggalkan halaman ini.',
                  style: AppText.bodySm,
                ),
              ],
              if (fase == FaseUnduh.siap) ...[
                const SizedBox(height: AppSpacing.lg),
                AppSurface(
                  variant: AppSurfaceVariant.success,
                  child: Text(
                    'Unduhan selesai dan terverifikasi. Dialog pemasangan '
                    'seharusnya sudah terbuka; bila tidak, ketuk tombol '
                    'di bawah.',
                    style: AppText.bodySm,
                  ),
                ),
              ],
              if (fase == FaseUnduh.gagal && status.pesanGagal != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppSurface(
                  variant: AppSurfaceVariant.danger,
                  child: Text(status.pesanGagal!, style: AppText.bodySm),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  // Sistem Android yang mengambil alih setelah ini — tombol
                  // tetap aktif supaya bisa dipakai ulang bila dialog
                  // pemasangan tertutup tanpa sengaja.
                  onPressed: fase == FaseUnduh.mengunduh
                      ? null
                      : () {
                          if (fase == FaseUnduh.siap &&
                              pathApk != null &&
                              pathApk.isNotEmpty) {
                            _bukaPasang(pathApk);
                          } else {
                            PembaruanService.instance.mulaiUnduh(info);
                          }
                        },
                  icon: Icon(
                    fase == FaseUnduh.siap
                        ? CupertinoIcons.hammer_fill
                        : CupertinoIcons.arrow_down_circle_fill,
                    size: 18,
                  ),
                  label: Text(switch (fase) {
                    FaseUnduh.mengunduh => 'Mengunduh…',
                    FaseUnduh.siap => 'Buka Pemasang',
                    _ => 'Unduh & Perbarui',
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                      fase == FaseUnduh.mengunduh ? null : _lewati,
                  child: const Text('Lewati versi ini'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Membuka pemasang sistem untuk APK terverifikasi. Gagal (mis. izin
  /// "Install unknown apps" belum diberikan) ditampilkan di halaman, bukan
  /// melempar dari tombol.
  Future<void> _bukaPasang(String path) async {
    try {
      await PembaruanService.instance.pasang(path);
    } catch (e) {
      if (!mounted) return;
      PembaruanService.instance.statusUnduh.value = StatusUnduh(
        fase: FaseUnduh.gagal,
        pesanGagal: AppFailure.messageOf(
          e,
          'Gagal membuka pemasang. Coba lagi.',
        ),
        pathApk: path,
        versi: widget.info.versi,
      );
    }
  }
}
