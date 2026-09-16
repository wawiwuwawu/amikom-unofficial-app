import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DESIGN SYSTEM — AmiApp (amikom-unofficial-app)
///
/// SUMBER TUNGGAL untuk warna, jarak, radius, dan tipografi.
/// ATURAN: halaman/widget TIDAK BOLEH menulis `Color(0x…)`, angka jarak mentah,
/// atau `TextStyle(...)` ad-hoc. Selalu pakai token di file ini.
///
/// Palet diturunkan dari seed brand ungu Amikom `#501F66` via Material 3
/// `ColorScheme.fromSeed`, sehingga seluruh peran warna (primary, container,
/// surface, outline, …) konsisten dan otomatis siap dark mode.
/// ─────────────────────────────────────────────────────────────────────────────

/// Seed brand — satu-satunya warna mentah yang boleh ada di aplikasi.
const Color kBrandSeed = Color(0xFF501F66);

/// Warna semantik untuk status (nilai, peringatan, sukses).
/// Dipakai lewat helper [GradeStyle] dan [AppStatus] agar tidak hardcode.
abstract final class AppColors {
  // Aksen brand (turunan seed, eksplisit agar stabil di seluruh app)
  static const Color primary = kBrandSeed;
  static const Color primarySoft = Color(0xFF7E4F9C);

  // Permukaan
  static const Color scaffold = Color(0xFFFAFCFF); // Pearl White
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4F1F8);

  // Teks
  static const Color textPrimary = Color(0xFF1C1A22);
  static const Color textSecondary = Color(0xFF5C5468);
  static const Color textMuted = Color(0xFF8B8398);

  // Garis
  static const Color border = Color(0xFFE6E2EC);
  static const Color borderStrong = Color(0xFFD3CCDD);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF4E5);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerBg = Color(0xFFFDECEA);
  static const Color info = Color(0xFF1565C0);
  static const Color infoBg = Color(0xFFE3F2FD);
}

/// Skala jarak — kelipatan 4 (Material 3). Hanya pakai nilai ini.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Padding standar isi halaman.
  static const EdgeInsets page = EdgeInsets.all(lg);

  /// Padding standar isi kartu.
  static const EdgeInsets card = EdgeInsets.all(lg);
}

/// Skala radius — hanya 3 tingkat. Jangan pakai angka lain.
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

/// Skala tipografi bermakna (semantic), dipetakan ke Inter.
/// Ganti 920 `TextStyle` ad-hoc dengan style bernama di sini.
abstract final class AppText {
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: AppColors.textPrimary,
      );

  /// Judul halaman.
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  /// Judul seksi.
  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  /// Judul kartu/item.
  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  /// Isi utama.
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textPrimary,
      );

  /// Isi sekunder / keterangan.
  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  /// Label kecil (caption, badge, meta).
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textSecondary,
      );

  /// Label seksi (huruf kapital, spasi lebar).
  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.7,
        color: AppColors.textMuted,
      );

  /// Teks tombol.
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  /// Angka besar (KPI / statistik).
  static TextStyle get metric => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: AppColors.primary,
      );
}

/// Gaya lencana nilai — A hijau, B biru, C oranye, D/E merah.
/// Ini yang menggantikan "nilai sebagai teks polos" agar mata cepat menangkap.
abstract final class GradeStyle {
  static (Color bg, Color fg) of(String grade) {
    final g = grade.trim().toUpperCase();
    if (g.startsWith('A')) return (AppColors.successBg, AppColors.success);
    if (g.startsWith('B')) return (AppColors.infoBg, AppColors.info);
    if (g.startsWith('C')) return (AppColors.warningBg, AppColors.warning);
    if (g.startsWith('D') || g.startsWith('E')) {
      return (AppColors.dangerBg, AppColors.danger);
    }
    return (AppColors.surfaceMuted, AppColors.textMuted);
  }

  /// Hijau bila lulus (A/B/C), merah bila tidak.
  static Color text(String grade) => of(grade).$2;
}

/// Dekorasi siap pakai — menggantikan 253 `BoxDecoration` berulang.
abstract final class AppDeco {
  /// Permukaan kartu standar (pengganti GlassCard untuk konten data).
  static BoxDecoration card({Color? color, double radius = AppRadius.md}) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
      );

  /// Permukaan dengan sudut lebih besar (kartu hero / banner).
  static BoxDecoration panel({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      );

  /// Sorotan lembut memakai warna primary (badge, ikon bulat).
  static BoxDecoration softPrimary({double radius = AppRadius.pill}) =>
      BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      );

  /// Wadah daftar (list) tanpa jarak antar-item.
  static BoxDecoration listGroup() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      );
}

/// ThemeData aplikasi — dipakai di `main.dart`.
/// Semua component theme yang dipakai 10× ke atas didefinisikan di sini,
/// supaya halaman tidak perlu override gaya sendiri.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kBrandSeed,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.scaffold,
      textTheme: GoogleFonts.interTextTheme(),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.h2,
        iconTheme: const IconThemeData(color: AppColors.primary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primarySoft,
        titleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppText.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                )
              : AppText.label.copyWith(color: AppColors.textMuted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppText.button,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppText.button,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppText.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppText.bodySm.copyWith(color: AppColors.textMuted),
        labelStyle: AppText.bodySm,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        side: BorderSide.none,
        labelStyle: AppText.label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppText.h3.copyWith(fontSize: 14),
        unselectedLabelStyle: AppText.h3.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppText.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppText.h2,
        contentTextStyle: AppText.body,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
