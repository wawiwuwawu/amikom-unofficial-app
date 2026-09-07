import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';

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
                backgroundColor: Colors.red,
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
          SnackBar(content: Text('Gagal memilih file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF501F66)),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickFile(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedFile != null ? const Color(0xFF501F66) : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selectedFile != null ? CupertinoIcons.doc_fill : CupertinoIcons.cloud_upload_fill,
                  color: const Color(0xFF501F66),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedFile != null ? selectedFile!.name : 'Pilih file bukti...',
                    style: TextStyle(
                      color: selectedFile != null ? const Color(0xFF501F66) : Colors.grey.shade600,
                      fontWeight: selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedFile != null)
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: Colors.grey),
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
