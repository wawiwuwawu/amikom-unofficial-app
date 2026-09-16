import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// UI KIT — AmiApp
///
/// Komponen primitif bersama. Semua halaman WAJIB memakai ini alih-alih
/// menulis `Scaffold` + `AppBar` + `BoxDecoration` + `CircularProgressIndicator`
/// sendiri-sendiri (pola lama yang membuat tampilan tidak konsisten).
///
/// Import tunggal:  import '../widgets/app_kit.dart';
/// ─────────────────────────────────────────────────────────────────────────────

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
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? background;

  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions = const [],
    this.scrollable = true,
    this.padding,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? AppSpacing.page,
      child: body,
    );

    return Scaffold(
      backgroundColor: background ?? AppColors.scaffold,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
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

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AppPillTone.success => (AppColors.successBg, AppColors.success),
      AppPillTone.warning => (AppColors.warningBg, AppColors.warning),
      AppPillTone.danger => (AppColors.dangerBg, AppColors.danger),
      AppPillTone.info => (AppColors.infoBg, AppColors.info),
      AppPillTone.neutral => (AppColors.surfaceMuted, AppColors.textSecondary),
    };

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
  final bool wrapInSurface;

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
    this.wrapInSurface = false,
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

    final child = builder(value);
    return wrapInSurface ? AppSurface(child: child) : child;
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
