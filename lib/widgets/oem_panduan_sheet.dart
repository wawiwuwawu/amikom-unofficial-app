import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/oem_baterai_service.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

// ── Konten langkah per merek (riset dontkillmyapp.com) ──────────────────────

/// Target "Buka setelan" per langkah: [OemSetelanTarget.autostart] mencoba
/// intent autostart khas merek dulu (fail ke info aplikasi), [aplikasi]
/// membuka info aplikasi, [tidakAda] tanpa tombol (langkah manual, mis. recents).
enum OemSetelanTarget { aplikasi, autostart, tidakAda }

class OemLangkah {
  final String judul;
  final String detail;
  final OemSetelanTarget target;

  const OemLangkah(this.judul, this.detail, {this.target = OemSetelanTarget.tidakAda});
}

/// Satu catatan kecil opsional per merek (mis. Huawei tanpa Google services).
class OemPanduan {
  final String judul; // sudah termasuk label merek
  final List<OemLangkah> langkah;
  final String? catatan;

  const OemPanduan(this.judul, this.langkah, {this.catatan});
}

OemPanduan _panduanUntuk(OemMerekInfo info) {
  switch (info.merek) {
    case OemMerek.xiaomi:
      return OemPanduan(
        'Biar notifikasi & pengingat selalu muncul — ${info.label ?? 'Xiaomi'}',
        const [
          OemLangkah(
            'Aktifkan Autostart',
            'Setelan > Aplikasi > Izin > Autostart — nyalakan untuk Ini '
            'Amikom supaya app boleh jalan sendiri.',
            target: OemSetelanTarget.autostart,
          ),
          OemLangkah(
            'Hilangkan pembatas baterai',
            'Info baterai app > pilih "No restrictions".',
            target: OemSetelanTarget.aplikasi,
          ),
          OemLangkah(
            'Kunci di layar recents',
            'Buka recents, tarik kartu Ini Amikom ke bawah, ketuk ikon gembok.',
          ),
        ],
      );
    case OemMerek.oppo:
      return OemPanduan(
        'Biar notifikasi & pengingat selalu muncul — ${info.label ?? 'Oppo/Realme'}',
        const [
          OemLangkah(
            'Aktifkan App auto-launch',
            'Setelan > Baterai > More settings > App auto-launch — nyalakan '
            'untuk Ini Amikom.',
            target: OemSetelanTarget.autostart,
          ),
          OemLangkah(
            'Izinkan background activity',
            'Baterai > penggunaan app > Ini Amikom > "Allow background '
            'activity" / Don\'t optimize.',
            target: OemSetelanTarget.aplikasi,
          ),
          OemLangkah(
            'Kunci di layar recents',
            'Buka recents, kunci kartu Ini Amikom lewat ikon gembok.',
          ),
        ],
      );
    case OemMerek.vivo:
      return OemPanduan(
        'Biar notifikasi & pengingat selalu muncul — ${info.label ?? 'Vivo'}',
        const [
          OemLangkah(
            'Aktifkan Autostart',
            'i Manager > App manager > Autostart — nyalakan untuk Ini Amikom.',
            target: OemSetelanTarget.autostart,
          ),
          OemLangkah(
            'Izinkan konsumsi daya latar',
            'Baterai > High background power consumption — izinkan untuk Ini '
            'Amikom.',
            target: OemSetelanTarget.aplikasi,
          ),
          OemLangkah(
            'Kunci di layar recents',
            'Buka recents, kunci kartu Ini Amikom lewat ikon gembok.',
          ),
        ],
      );
    case OemMerek.samsung:
      return OemPanduan(
        'Biar notifikasi & pengingat selalu muncul — Samsung',
        const [
          OemLangkah(
            'Tambahkan ke Never sleeping apps',
            'Setelan > Baterai > Background usage limits > Never sleeping '
            'apps — tambahkan Ini Amikom. Tanpa ini app "ditidurkan" '
            'setelah ±3 hari.',
            target: OemSetelanTarget.aplikasi,
          ),
          OemLangkah(
            'Cegah app tak terpakai tertidur',
            'Di setelan baterai, matikan "Put unused apps to sleep".',
            target: OemSetelanTarget.aplikasi,
          ),
          OemLangkah(
            'Izinkan kategori notifikasi',
            'Setelan > Notifikasi > Ini Amikom — pastikan kategori '
            '(channel) notifikasi aktif.',
            target: OemSetelanTarget.aplikasi,
          ),
        ],
      );
    case OemMerek.infinix:
      return OemPanduan(
        'Biar notifikasi & pengingat selalu muncul — ${info.label ?? 'Infinix/Tecno'}',
        const [
          OemLangkah(
            'Izinkan background di Battery Lab / PowerMaster',
            'Battery Lab / PowerMaster > pilih Ini Amikom > izinkan '
            'berjalan di background.',
            target: OemSetelanTarget.aplikasi,
          ),
          OemLangkah(
            'Izinkan autostart di Phone Master',
            'Phone Master > App startup > Ini Amikom > izinkan autostart.',
            target: OemSetelanTarget.autostart,
          ),
          OemLangkah(
            'Kunci di layar recents',
            'Buka recents, kunci kartu Ini Amikom lewat ikon gembok.',
          ),
        ],
      );
    case OemMerek.huawei:
      return OemPanduan(
        'Biar notifikasi & pengingat selalu muncul — ${info.label ?? 'Huawei/Honor'}',
        const [
          OemLangkah(
            'Aktifkan ketiga peluncuran app',
            'Setelan > Battery > App launch > Ini Amikom > Manage manually — '
            'nyalakan Auto-launch, Secondary launch, dan Run in background.',
            target: OemSetelanTarget.aplikasi,
          ),
          OemLangkah(
            'Keluarkan dari optimasi baterai',
            'Battery optimization > Ini Amikom > pilih Not optimized.',
            target: OemSetelanTarget.aplikasi,
          ),
        ],
        catatan:
            'Tanpa Google services pun pengingat jadwal lokal tetap jalan '
            'karena diproses di perangkat — hanya push FCM yang tidak tersedia.',
      );
    case OemMerek.generik:
      return const OemPanduan(
        'Biar notifikasi & pengingat selalu muncul',
        [
          OemLangkah(
            'Izinkan autostart bila tersedia',
            'Cari opsi Autostart / Startup manager di Setelan aplikasi dan '
            'nyalakan untuk Ini Amikom bila ada.',
            target: OemSetelanTarget.autostart,
          ),
          OemLangkah(
            'Matikan optimasi baterai untuk app ini',
            'Setelan > Aplikasi > Ini Amikom > Baterai > pilih Don\'t '
            'optimize / Unrestricted.',
            target: OemSetelanTarget.aplikasi,
          ),
          OemLangkah(
            'Kunci di layar recents',
            'Buka recents, kunci kartu Ini Amikom (ikon gembok) supaya '
            'tidak ikut dibersihkan.',
          ),
        ],
      );
  }
}

// ── Launcher "Buka setelan" (intent, fail-open) ─────────────────────────────

/// Komponen autostart khas merek (best-effort — bisa berubah antar versi
/// skin; gagal otomatis jatuh ke info aplikasi).
(List<String>, String)? _komponenAutostart(OemMerek merek) {
  switch (merek) {
    case OemMerek.xiaomi:
      return (
        ['com.miui.securitycenter', 'com.miui.securitycenter'],
        'com.miui.permcenter.autostart.AutoStartManagementActivity',
      );
    case OemMerek.oppo:
      return (
        ['com.coloros.safecenter', 'com.oppo.safe'],
        'com.coloros.safecenter.permission.startup.StartupAppListActivity',
      );
    case OemMerek.vivo:
      return (
        ['com.vivo.permissionmanager'],
        'com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
      );
    default:
      return null;
  }
}

/// Buka daftar intent secara berurutan sampai ada yang sukses; semua gagal
/// → snack panduan manual. Selalu fail-open, tidak pernah melempar.
Future<void> _luncurkan(
  BuildContext context,
  List<AndroidIntent> intents,
) async {
  for (final intent in intents) {
    try {
      await intent.launch();
      return;
    } catch (e) {
      // Coba kandidat berikutnya.
    }
  }
  if (!context.mounted) return;
  AppSnack.show(
    context,
    OemBateraiService.kPesanFallbackBukaManual,
    backgroundColor: AppColors.primary,
  );
}

Future<List<AndroidIntent>> _intentAppDetail() async {
  String? paket;
  try {
    paket = (await PackageInfo.fromPlatform()).packageName;
  } catch (e) {
    // Tanpa nama paket, jatuh ke setelan umum di bawah.
  }
  return [
    if (paket != null)
      AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:$paket',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    AndroidIntent(action: 'android.settings.SETTINGS'),
  ];
}

// ── Kartu kecil di halaman Notifikasi ───────────────────────────────────────

/// Kartu kecil non-nagging antara push card dan banner pembaruan: ikon
/// baterai + ajakan sekali-baca + tombol buka panduan + tombol tutup.
class OemPanduanCard extends StatelessWidget {
  final OemMerekInfo merek;
  final VoidCallback onLihatPanduan;
  final VoidCallback onTutup;

  const OemPanduanCard({
    super.key,
    required this.merek,
    required this.onLihatPanduan,
    required this.onTutup,
  });

  String get _judul {
    final label = merek.label;
    return label == null
        ? 'Notifikasi sering hilang? Banyak HP membatasi notifikasi di '
            'latar belakang.'
        : 'Notifikasi sering hilang? HP $label punya pembatas khusus.';
  }

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      variant: AppSurfaceVariant.plain,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: AppDeco.softPrimary(),
            child: const Icon(
              CupertinoIcons.battery_75_percent,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(_judul, style: AppText.bodySm),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onLihatPanduan,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Lihat panduan'),
          ),
          IconButton(
            onPressed: onTutup,
            icon: const Icon(CupertinoIcons.xmark, size: 16),
            color: AppColors.textMuted,
            tooltip: 'Tutup panduan ini',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Sheet panduan ───────────────────────────────────────────────────────────

/// Membuka bottom sheet panduan anti-pembunuhan-proses OEM untuk merek
/// terdeteksi ([info]). Sheet hanya dibaca, tidak menyimpan apa pun.
Future<void> showOemPanduanSheet(BuildContext context, OemMerekInfo info) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => OemPanduanSheet(merek: info),
  );
}

class OemPanduanSheet extends StatelessWidget {
  final OemMerekInfo merek;

  const OemPanduanSheet({super.key, required this.merek});

  Future<void> _bukaSetelan(BuildContext context, OemLangkah langkah) async {
    switch (langkah.target) {
      case OemSetelanTarget.tidakAda:
        return;
      case OemSetelanTarget.aplikasi:
        final intents = await _intentAppDetail();
        if (!context.mounted) return;
        await _luncurkan(context, intents);
        return;
      case OemSetelanTarget.autostart:
        final intents = <AndroidIntent>[];
        // Komponen autostart khas merek — kandidat package dicoba berurutan.
        final komponen = _komponenAutostart(merek.merek);
        if (komponen != null) {
          final (packages, component) = komponen;
          for (final package in packages) {
            intents.add(
              AndroidIntent(
                package: package,
                componentName: component,
                flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
              ),
            );
          }
        }
        intents.addAll(await _intentAppDetail());
        if (!context.mounted) return;
        await _luncurkan(context, intents);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final panduan = _panduanUntuk(merek);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(panduan.judul, style: AppText.h2),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < panduan.langkah.length; i++) ...[
              _langkah(context, i + 1, panduan.langkah[i]),
              if (i < panduan.langkah.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
            if (panduan.catatan != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                panduan.catatan!,
                style: AppText.bodySm.copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Force stop dari recents tetap mematikan pengingat — '
                    'cukup swipe, jangan Force stop.',
                    style: AppText.bodySm.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _langkah(BuildContext context, int nomor, OemLangkah langkah) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 2),
          alignment: Alignment.center,
          decoration: AppDeco.softPrimary(radius: AppRadius.pill),
          child: Text(
            '$nomor',
            style: AppText.label.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(langkah.judul, style: AppText.h3),
              const SizedBox(height: 2),
              Text(langkah.detail, style: AppText.bodySm),
              if (langkah.target != OemSetelanTarget.tidakAda)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _bukaSetelan(context, langkah),
                    icon: const Icon(
                      CupertinoIcons.gear,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    label: const Text('Buka setelan'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
