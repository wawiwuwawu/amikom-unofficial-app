import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_failure.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// UI KIT — AmiApp
///
/// Komponen primitif bersama. Semua halaman WAJIB memakai ini alih-alih
/// menulis `Scaffold` + `AppBar` + `BoxDecoration` + `CircularProgressIndicator`
/// sendiri-sendiri (pola lama yang membuat tampilan tidak konsisten).
///
/// Import tunggal:  import '../widgets/app_kit.dart';
/// ─────────────────────────────────────────────────────────────────────────────

/// Pesan galat yang aman ditampilkan ke pengguna.
///
/// WAJIB dipakai di halaman alih-alih `e.toString()` /
/// `e.toString().replaceFirst('Exception: ', '')` — supaya error non-API
/// (parsing, penyimpanan, plugin, jaringan mentah) tidak membocorkan detail
/// teknis seperti "FormatException", "type 'Null' is not a subtype…", atau
/// pesan Dio berbahasa Inggris.
///
/// Pesan asli dari `ApiClient.handleError` tetap dipakai (sudah ramah);
/// selain itu dikembalikan [fallback] yang harus juga ramah & Bahasa Indonesia.
String userErrorMessage(Object? error, [String fallback = 'Terjadi kesalahan']) =>
    AppFailure.messageOf(error, fallback);

/// Kunci verifikasi aktivitas: item yang sudah di-ACC dosen (verifikasi == 1
/// atau status valid) tidak boleh diedit/dihapus — aturan portal Amikom.
bool isAktivitasTerkunci(int verifikasi, String status) =>
    verifikasi == 1 || status.toLowerCase() == 'valid';

/// Kerangka halaman standar — menggantikan pola `Scaffold + AppBar + SafeArea`
/// yang sebelumnya ditulis ulang di 41 halaman.
class AppScaffold extends StatelessWidget {
  final String title;

  /// Keterangan kecil di bawah judul (opsional).
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;

  /// Bungkus isi dengan scroll + padding standar.
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions = const [],
    this.scrollable = true,
    this.padding,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? AppSpacing.page,
      child: body,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: subtitle == null
            ? Text(title, style: AppText.h2)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppText.h2),
                  Text(
                    subtitle!,
                    style: AppText.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
        actions: actions,
      ),
      body: SafeArea(
        child: scrollable
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: content,
              )
            : content,
      ),
    );
  }
}

/// Judul seksi + aksi opsional di kanan.
class AppSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  final double topGap;

  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.topGap = AppSpacing.xl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topGap),
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppText.overline,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

/// Permukaan kartu. `variant` menentukan bobot visual — inilah yang memberi
/// hierarki (sebelumnya semua kartu rata karena `elevation: 0` dipakai 51×).
enum AppSurfaceVariant {
  /// Kartu data biasa (garis halus).
  plain,

  /// Kartu hero / sorotan (latar brand lembut).
  hero,

  /// Kartu peringatan (latar kekuningan).
  warning,

  /// Kartu bahaya / tunggakan.
  danger,

  /// Kartu sukses.
  success,
}

class AppSurface extends StatelessWidget {
  final Widget child;
  final AppSurfaceVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const AppSurface({
    super.key,
    required this.child,
    this.variant = AppSurfaceVariant.plain,
    this.padding = AppSpacing.card,
    this.onTap,
    this.radius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border) = switch (variant) {
      AppSurfaceVariant.plain => (AppColors.surface, AppColors.border),
      AppSurfaceVariant.hero => (
          AppColors.primary.withValues(alpha: 0.07),
          AppColors.primary.withValues(alpha: 0.14),
        ),
      AppSurfaceVariant.warning => (AppColors.warningBg, const Color(0xFFFFE0B2)),
      AppSurfaceVariant.danger => (AppColors.dangerBg, const Color(0xFFF8C9C4)),
      AppSurfaceVariant.success => (AppColors.successBg, const Color(0xFFC8E6C9)),
    };

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// Wadah daftar bergaris pemisah — pola utama untuk menyajikan data
/// (nilai, jadwal, tagihan) yang perlu dipindai & dibandingkan.
class AppListGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppListGroup({super.key, required this.children, this.padding});

  /// Bungkus daftar item menjadi baris dengan pemisah tipis.
  factory AppListGroup.from(List<Widget> rows) {
    return AppListGroup(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: AppColors.border),
          rows[i],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppDeco.listGroup(),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Daftar panjang dari server (tanpa pagination) yang dirender lazy: item
/// dibagi menjadi chunk ±20 baris — satu [AppListGroup] per chunk — via
/// `ListView.builder`, sehingga hanya chunk yang (hampir) terlihat yang
/// dibangun, bukan ratusan baris sekaligus (pola sama dengan halaman
/// Notifikasi/Keuangan/Jadwal). [header] (mis. ringkasan atau judul seksi)
/// berada di atas chunk pertama dan [footer] setelah chunk terakhir —
/// keduanya tanpa jarak implisit, jarak ke daftar disertakan di dalam
/// widget pemanggil; antar chunk dipisah jarak antar kartu
/// (AppSpacing.lg). Header tetap dirender walau daftar kosong. Tampilan
/// tiap baris tetap dari [rowBuilder], identik dengan versi non-chunk.
class AppChunkedList<T> extends StatelessWidget {
  const AppChunkedList({
    super.key,
    required this.items,
    required this.rowBuilder,
    this.header,
    this.footer,
    this.padding,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.chunkSize = 20,
  }) : assert(chunkSize > 0);

  final List<T> items;
  final Widget Function(BuildContext context, T item) rowBuilder;
  final Widget? header;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;

  /// Default selalu bisa discroll agar RefreshIndicator tetap berfungsi.
  final ScrollPhysics physics;
  final int chunkSize;

  @override
  Widget build(BuildContext context) {
    final chunks = <List<Widget>>[];
    for (var i = 0; i < items.length; i += chunkSize) {
      final end =
          (i + chunkSize) < items.length ? i + chunkSize : items.length;
      chunks.add([
        for (var j = i; j < end; j++) rowBuilder(context, items[j]),
      ]);
    }

    // header → chunk → … → footer; header tetap dirender walau daftar kosong
    // (mis. dipakai bersama AppEmptyState di dalam seksi yang sama).
    Widget? itemAt(int index) {
      var i = index;
      final head = header;
      if (head != null) {
        if (i == 0) return head;
        i--;
      }
      if (i < chunks.length) {
        final group = AppListGroup.from(chunks[i]);
        return i == 0
            ? group
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [const SizedBox(height: AppSpacing.lg), group],
              );
      }
      return footer;
    }

    final total =
        chunks.length + (header != null ? 1 : 0) + (footer != null ? 1 : 0);
    return ListView.builder(
      padding: padding,
      physics: physics,
      itemCount: total,
      itemBuilder: (context, index) => itemAt(index)!,
    );
  }
}

/// Satu baris data — pengganti "1 kartu per item" yang membuat tampilan ramai.
class AppListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const AppListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.h3),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.bodySm),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      child: row,
    );
  }
}

/// Lencana nilai berwarna — A hijau, B biru, C oranye, D/E merah.
/// Membuat nilai terbaca sekejap tanpa harus membaca hurufnya.
class AppGradeBadge extends StatelessWidget {
  final String grade;
  final double size;

  const AppGradeBadge({super.key, required this.grade, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = GradeStyle.of(grade);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        grade,
        style: AppText.h3.copyWith(
          color: fg,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Pil status ringkas (Lunas, Aktif, Menunggu, …).
enum AppPillTone { neutral, success, warning, danger, info }

class AppPill extends StatelessWidget {
  final String label;
  final AppPillTone tone;

  const AppPill(this.label, {super.key, this.tone = AppPillTone.neutral});

  /// (background, foreground) untuk satu nada — sumber tunggal bersama
  /// [AppPill] dan halaman yang memakai warna nadanya sendiri (absensi,
  /// surat tugas).
  static (Color, Color) toneColors(AppPillTone tone) {
    return switch (tone) {
      AppPillTone.success => (AppColors.successBg, AppColors.success),
      AppPillTone.warning => (AppColors.warningBg, AppColors.warning),
      AppPillTone.danger => (AppColors.dangerBg, AppColors.danger),
      AppPillTone.info => (AppColors.infoBg, AppColors.info),
      AppPillTone.neutral => (AppColors.surfaceMuted, AppColors.textSecondary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.label.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Kotak angka ringkas (IPK, SKS, kehadiran) untuk beranda.
class AppStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? accent;

  const AppStatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            value,
            style: AppText.metric.copyWith(color: color, fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.label, maxLines: 1),
        ],
      ),
    );
  }
}

/// Baris beberapa [AppStatTile] — tiap tile melebar sama rata dengan jarak
/// tetap, menggantikan `Row` + `Expanded` + `SizedBox` yang ditulis ulang
/// di banyak halaman.
///
/// Memakai [CrossAxisAlignment.start], BUKAN `stretch`: baris ini berada di
/// dalam scrollable yang tingginya tak terbatas, dan `stretch` akan memaksa
/// tinggi infinity ke tiap anak (`BoxConstraints forces an infinite height`).
/// Tinggi kartu sudah seragam karena isinya sama. Baris yang butuh pembagian
/// tidak sama rata + tinggi seragam (pola flex 3/2 di `keuangan_page`) tetap
/// memakai `IntrinsicHeight` sendiri — bukan urusan komponen ini.
class AppStatRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const AppStatRow({
    super.key,
    required this.children,
    this.gap = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// Baris "label : nilai" untuk halaman detail (pengganti tabel manual).
class AppKeyValue extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const AppKeyValue({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppText.bodySm),
          ),
          Expanded(
            child: Text(
              value,
              style: emphasize
                  ? AppText.h3
                  : AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indikator memuat terpusat — menggantikan 96 `CircularProgressIndicator` mentah.
class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(message!, style: AppText.bodySm),
            ],
          ],
        ),
      ),
    );
  }
}

/// Keadaan kosong — selalu beri penjelasan + aksi, jangan layar putih.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: AppDeco.softPrimary(),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppText.h3,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppText.bodySm,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Keadaan galat + tombol coba lagi.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      variant: AppSurfaceVariant.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Gagal memuat data',
                  style: AppText.h3.copyWith(color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppText.bodySm),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pembungkus status async — satu tempat menangani memuat / galat / kosong / isi.
/// Halaman cukup menyediakan `builder` untuk kondisi sukses.
class AppAsyncView<T> extends StatelessWidget {
  final bool loading;
  final String? error;
  final T? data;
  final bool Function(T data)? isEmpty;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String? loadingMessage;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;

  const AppAsyncView({
    super.key,
    required this.loading,
    required this.builder,
    this.error,
    this.data,
    this.isEmpty,
    this.onRetry,
    this.loadingMessage,
    this.emptyTitle = 'Belum ada data',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return AppLoading(message: loadingMessage);

    if (error != null && error!.isNotEmpty) {
      return AppErrorState(message: error!, onRetry: onRetry);
    }

    final value = data;
    if (value == null) {
      return AppEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon,
      );
    }

    if (isEmpty != null && isEmpty!(value)) {
      return AppEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon,
      );
    }

    return builder(value);
  }
}

/// Kolom pencarian standar.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    required this.controller,
    this.hint = 'Cari…',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppText.body,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.textMuted,
        ),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              ),
        isDense: true,
      ),
    );
  }
}

/// Tone & label pill untuk status presensi H/B/I/S — sumber tunggal yang
/// dipakai halaman absensi dan detailnya (dulunya duplikat statis ×2).
class AppAbsensiStatus {
  const AppAbsensiStatus._();

  static AppPillTone tone(String status) {
    switch (status.toUpperCase()) {
      case 'H':
        return AppPillTone.success;
      case 'B':
        return AppPillTone.danger;
      case 'I':
        return AppPillTone.info;
      case 'S':
        return AppPillTone.warning;
      default:
        return AppPillTone.neutral;
    }
  }

  static String label(String status) {
    switch (status.toUpperCase()) {
      case 'H':
        return 'Hadir';
      case 'B':
        return 'Bolos';
      case 'I':
        return 'Izin';
      case 'S':
        return 'Sakit';
      default:
        return status;
    }
  }
}

/// Snackbar ringkas — satu baris teks + warna, melayang (floating).
class AppSnack {
  const AppSnack._();

  static void show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Dialog konfirmasi ya/batal — satu bentuk untuk semua aksi merusak.
///
/// `true` bila pengguna menekan tombol konfirmasi, `false` bila "Batal"
/// (atau dialog ditutup lewat barrier → `null`).
class AppConfirm {
  const AppConfirm._();

  static Future<bool?> ask(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    Color confirmColor = AppColors.danger,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// Satu entri pilihan untuk [AppDropdownField].
class AppDropdownEntry<T> {
  final T value;
  final String label;

  const AppDropdownEntry({required this.value, required this.label});
}

/// Dropdown trigger bergaya kartu dengan menu yang SELALU terbuka ke bawah
/// (`MenuAnchor` + `MenuStyle.alignment: topStart`).
///
/// Kenapa bukan `DropdownButton`: menu bawaan menyelaraskan pusat item
/// terpilih dengan pusat tombol, jadi begitu pilihan bukan entri pertama
/// (mis. tahun default dari server ada di tengah daftar), menu menjulur ke
/// ATAS melewati AppBar — `DropdownButton` tidak punya parameter arah.
///
/// Pengaman bawaan terhadap dua kelas crash dropdown:
///  * Entri di-**dedup by value** (yang pertama menang) — mencegah assert
///    `"There should be exactly one item with [DropdownButton]'s value"`
///    saat daftar opsi server memuat value ganda.
///  * [value] yang tidak ada di [entries] jatuh ke [hint] — mencegah crash
///    pilihan usang setelah daftar opsi dimuat ulang (mis. pull-to-refresh).
///
/// Knob tampilan sengaja minimal supaya ketiga filter puncak halaman
/// (nilai rincian, KHS, asisten) tetap tampak persis seperti sebelumnya.
class AppDropdownField<T> extends StatefulWidget {
  /// Daftar pilihan (nilai duplikat dibuang otomatis, yang pertama menang).
  final List<AppDropdownEntry<T>> entries;
  final T? value;
  final String hint;
  final ValueChanged<T?> onChanged;

  /// Tinggi maksimum panel menu (scrollable bila lebih).
  final double? maxMenuHeight;

  /// Gaya teks trigger & item (default `AppText.bodySm`).
  final TextStyle? textStyle;

  /// Warna isi kartu trigger (null = default `AppDeco.card`).
  final Color? fillColor;

  /// Ikon chevron di kanan trigger.
  final Widget icon;

  const AppDropdownField({
    super.key,
    required this.entries,
    required this.hint,
    required this.onChanged,
    this.value,
    this.maxMenuHeight,
    this.textStyle,
    this.fillColor,
    this.icon = const Icon(
      CupertinoIcons.chevron_down,
      color: AppColors.primary,
      size: 14,
    ),
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final MenuController _menuController = MenuController();

  List<AppDropdownEntry<T>> get _entries {
    final seen = <T>{};
    return [
      for (final e in widget.entries)
        if (seen.add(e.value)) e,
    ];
  }

  @override
  void dispose() {
    _menuController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final gaya = widget.textStyle ?? AppText.bodySm;
    AppDropdownEntry<T>? terpilih;
    for (final e in entries) {
      if (e.value == widget.value) terpilih = e;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final lebar = constraints.maxWidth;
        return MenuAnchor(
          controller: _menuController,
          // Paksa lebar menu = lebar trigger (bukan lebar intrinsik teks).
          crossAxisUnconstrained: false,
          style: MenuStyle(
            // Kunci perbaikan: menu selalu di BAWAH trigger (bottomStart =
            // y+1; topStart justru membuka ke atas).
            alignment: AlignmentDirectional.bottomStart,
            backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
            surfaceTintColor:
                const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(8),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            // Menu lama DropdownButton: 8 px vertikal, tanpa border.
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 8),
            ),
            minimumSize: WidgetStatePropertyAll(Size(lebar, 0)),
            maximumSize: WidgetStatePropertyAll(
              Size(lebar, widget.maxMenuHeight ?? 320),
            ),
          ),
          menuChildren: [
            for (final e in entries)
              MenuItemButton(
                onPressed: () {
                  _menuController.close();
                  widget.onChanged(e.value);
                },
                // Bentuk item meniru DropdownButton lama: 48 px, inset 16,
                // tanpa centang/sorotan — seleksi hanya terlihat di trigger.
                style: MenuItemButton.styleFrom(
                  minimumSize: Size(lebar, 48),
                  maximumSize: Size(lebar, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  e.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gaya.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
          ],
          builder: (context, controller, child) {
            return InkWell(
              onTap: entries.isEmpty
                  ? null
                  : () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                // Tinggi minimal 48 px = tinggi intrinsik DropdownButton lama
                // (tanpa ini kartu kolaps setinggi teks — pipih).
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.centerLeft,
                decoration: AppDeco.card(
                  color: widget.fillColor,
                  radius: AppRadius.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        terpilih?.label ?? widget.hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: terpilih != null
                            ? gaya.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              )
                            // Hint: netral (w400, textSecondary) — sama dengan
                            // gaya hint DropdownButton lama di kedua halaman.
                            : gaya.copyWith(
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    widget.icon,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
