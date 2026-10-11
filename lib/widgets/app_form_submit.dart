import 'package:flutter/material.dart';
import 'app_kit.dart';

/// Rangka submit form modal: tandai submitting, jalankan [save], saat sukses
/// tutup sheet + tampilkan [successMessage] + panggil [onSuccess]; saat galat
/// tampilkan pesan ramah lewat userErrorMessage. Selalu bersihkan submitting.
///
/// Varian yang dipakai sebagian sheet (prestasi, seminar, rekognisi):
/// [successBackground]/[errorBackground] mewarnai SnackBar, dan
/// [onSuccessBeforeMessage] memanggil onSuccess SEBELUM SnackBar — urutan &
/// warna asli tiap sheet dipertahankan.
class AppFormSubmit {
  static Future<void> run({
    required BuildContext context,
    required Future<void> Function() save,
    required String successMessage,
    required void Function(bool) setSubmitting,
    VoidCallback? onSuccess,
    Color? successBackground,
    Color? errorBackground,
    bool onSuccessBeforeMessage = false,
  }) async {
    setSubmitting(true);
    try {
      await save();
      if (!context.mounted) return;
      Navigator.pop(context);
      if (onSuccessBeforeMessage) onSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: successBackground,
        ),
      );
      if (!onSuccessBeforeMessage) onSuccess?.call();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userErrorMessage(e)),
          backgroundColor: errorBackground,
        ),
      );
    } finally {
      if (context.mounted) setSubmitting(false);
    }
  }
}
