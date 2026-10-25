import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_failure.dart';
import '../services/pembaruan_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

/// Membuka bottom sheet pembaruan: menampilkan catatan rilis, tombol unduh
/// dengan progres, verifikasi SHA-256, lalu membuka pemasang sistem.
///
/// Mengembalikan `'lewati'` bila user memilih lewati versi ini (pemanggil
/// — banner — memakai itu untuk menyembunyikan dirinya), `null` bila sheet
/// ditutup dengan cara lain.
Future<String?> showPembaruanSheet(BuildContext context, InfoPembaruan info) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PembaruanSheet(info: info),
  );
}

class PembaruanSheet extends StatefulWidget {
  final InfoPembaruan info;

  const PembaruanSheet({super.key, required this.info});

  @override
  State<PembaruanSheet> createState() => _PembaruanSheetState();
}

enum _FasePembaruan { idle, mengunduh, siapPasang, gagal }

class _PembaruanSheetState extends State<PembaruanSheet> {
  _FasePembaruan _fase = _FasePembaruan.idle;
  double? _progres; // 0..1, null = indeterminate
  String? _pesanGagal;
  String _pathApk = '';
  String _versiSekarang = '';

  @override
  void initState() {
    super.initState();
    PembaruanService.instance.versiTerpasang().then((v) {
      if (mounted) setState(() => _versiSekarang = v);
    });
  }

  Future<void> _unduh() async {
    setState(() {
      _fase = _FasePembaruan.mengunduh;
      _progres = null;
      _pesanGagal = null;
    });
    try {
      final path = await PembaruanService.instance.unduhApk(
        widget.info,
        onProgress: (terunduh, total) {
          if (!mounted) return;
          setState(() {
            _progres = total > 0 ? terunduh / total : null;
          });
        },
      );
      _pathApk = path;
      if (!mounted) return;
      setState(() => _fase = _FasePembaruan.siapPasang);
      await PembaruanService.instance.pasang(path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fase = _FasePembaruan.gagal;
        _pesanGagal = AppFailure.messageOf(
          e,
          'Gagal memperbarui aplikasi. Coba lagi.',
        );
      });
    }
  }

  /// Membuka pemasang sistem untuk APK yang sudah terverifikasi. Gagal
  /// (mis. izin "Install unknown apps" belum diberikan) ditampilkan di
  /// dalam sheet, bukan melempar dari tombol.
  Future<void> _bukaPasang() async {
    try {
      await PembaruanService.instance.pasang(_pathApk);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fase = _FasePembaruan.gagal;
        _pesanGagal = AppFailure.messageOf(
          e,
          'Gagal membuka pemasang. Coba lagi.',
        );
      });
    }
  }

  Future<void> _lewati() async {
    await PembaruanService.instance.lewatiVersi(widget.info.versi);
    if (!mounted) return;
    Navigator.of(context).pop('lewati');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pembaruan v${widget.info.versi} Tersedia', style: AppText.h2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _versiSekarang.isEmpty
                  ? 'Versi terbaru siap dipasang.'
                  : 'Versi terpasang: $_versiSekarang',
              style: AppText.bodySm,
            ),
            if (widget.info.catatan.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppSurface(
                variant: AppSurfaceVariant.plain,
                child: Text(
                  widget.info.catatan.trim(),
                  style: AppText.bodySm.copyWith(height: 1.5),
                ),
              ),
            ],
            if (_fase == _FasePembaruan.mengunduh) ...[
              const SizedBox(height: AppSpacing.lg),
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _progres == null
                    ? 'Mengunduh…'
                    : 'Mengunduh… ${(_progres! * 100).round()}%',
                style: AppText.bodySm,
              ),
            ],
            if (_fase == _FasePembaruan.siapPasang) ...[
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
            if (_fase == _FasePembaruan.gagal && _pesanGagal != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppSurface(
                variant: AppSurfaceVariant.danger,
                child: Text(_pesanGagal!, style: AppText.bodySm),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                // Sistem Android yang mengambil alih setelah ini — tombol
                // tetap aktif supaya bisa dipakai ulang bila dialog
                // pemasangan tertutup tanpa sengaja.
                onPressed: _fase == _FasePembaruan.mengunduh
                    ? null
                    : (_fase == _FasePembaruan.siapPasang && _pathApk.isNotEmpty
                          ? _bukaPasang
                          : _unduh),
                icon: Icon(
                  _fase == _FasePembaruan.siapPasang
                      ? CupertinoIcons.hammer_fill
                      : CupertinoIcons.arrow_down_circle_fill,
                  size: 18,
                ),
                label: Text(switch (_fase) {
                  _FasePembaruan.mengunduh => 'Mengunduh…',
                  _FasePembaruan.siapPasang => 'Buka Pemasang',
                  _ => 'Unduh & Perbarui',
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _fase == _FasePembaruan.mengunduh ? null : _lewati,
                child: const Text('Lewati versi ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
