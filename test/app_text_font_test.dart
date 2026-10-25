import 'package:app_amikom/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifikasi tipografi Inter terbunding (pubspec assets/fonts/inter):
/// semua getter [AppText] memakai fontFamily 'Inter' dengan weight sesuai.
void main() {
  group('AppText memakai font Inter terbunding', () {
    test('display memakai w800', () {
      final s = AppText.display;
      expect(s.fontFamily, 'Inter');
      expect(s.fontSize, 28);
      expect(s.fontWeight, FontWeight.w800);
    });

    test('h2 memakai w700', () {
      final s = AppText.h2;
      expect(s.fontFamily, 'Inter');
      expect(s.fontSize, 17);
      expect(s.fontWeight, FontWeight.w700);
    });

    test('body memakai w400', () {
      final s = AppText.body;
      expect(s.fontFamily, 'Inter');
      expect(s.fontSize, 14);
      expect(s.fontWeight, FontWeight.w400);
    });

    test('label memakai w600', () {
      final s = AppText.label;
      expect(s.fontFamily, 'Inter');
      expect(s.fontSize, 11);
      expect(s.fontWeight, FontWeight.w600);
    });

    test('semua getter memakai Inter dan letterSpacing overline dipertahankan',
        () {
      expect(AppText.h1.fontFamily, 'Inter');
      expect(AppText.h3.fontFamily, 'Inter');
      expect(AppText.bodySm.fontFamily, 'Inter');
      expect(AppText.button.fontFamily, 'Inter');
      expect(AppText.metric.fontFamily, 'Inter');
      expect(AppText.overline.fontFamily, 'Inter');
      expect(AppText.overline.letterSpacing, 0.7);
    });

    test('AppTheme.light() memakai TextTheme Inter', () {
      final theme = AppTheme.light();
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(theme.textTheme.displayLarge?.fontFamily, 'Inter');
    });
  });
}
