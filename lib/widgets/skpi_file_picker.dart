import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';

/// ponytail: reusable file picker component for SKPI activity form sheets
class SkpiFilePicker extends StatelessWidget {
  final PlatformFile? selectedFile;
  final ValueChanged<PlatformFile?> onFileSelected;
  final String label;
  final int? maxSizeBytes;
  final List<String> allowedExtensions;

  const SkpiFilePicker({
    super.key,
    required this.selectedFile,
    required this.onFileSelected,
    this.label = 'File Bukti (PDF / JPG / PNG)*',
    this.maxSizeBytes,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
  });

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (maxSizeBytes != null && file.size > maxSizeBytes!) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ukuran file maksimal ${(maxSizeBytes! / (1024 * 1024)).toStringAsFixed(0)}MB'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }
        onFileSelected(file);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih file: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = selectedFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.h3.copyWith(fontSize: 13, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () => _pickFile(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: hasFile ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasFile ? CupertinoIcons.doc_fill : CupertinoIcons.cloud_upload_fill,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    hasFile ? selectedFile!.name : 'Pilih file bukti...',
                    style: AppText.body.copyWith(
                      color: hasFile ? AppColors.primary : AppColors.textMuted,
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasFile)
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => onFileSelected(null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
