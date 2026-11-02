import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Komposer teks Markdown ringan — NATIVE, tanpa WebView dan tanpa package
/// editor (keputusan 2026-11-01). Dipakai di mana pun laporan berformat
/// perlu diketik (mis. log bimbingan MBKM).
///
/// Kenapa bukan package editor kaya (flutter_quill / super_editor /
/// html-editor-enhanced — riset 2026-11-01):
///  * kebutuhan form app hanya 4 token format (tebal, judul 1-2, daftar);
///  * portal menerima HTML — Quill butuh konversi Delta→HTML tambahan,
///    editor HTML berbasis WebView berat dan rewel di keyboard mobile;
///  * komposer ini output-nya langsung HTML via [markdownKeHtml].
/// Kalau kelak form butuh editor sesungguhnya (gambar, tabel, dsb.),
/// pertimbangkan flutter_quill + konversi delta — bukan sekarang.
class AppMarkdownComposer extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;

  const AppMarkdownComposer({
    super.key,
    required this.controller,
    this.hintText,
  });

  @override
  State<AppMarkdownComposer> createState() => _AppMarkdownComposerState();
}

class _AppMarkdownComposerState extends State<AppMarkdownComposer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar format — satu pola visual (chips di kartu pucat).
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.format_bold, size: 20),
                onPressed: () => _insertMarkdown('**', '**'),
                tooltip: 'Tebal',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(AppSpacing.sm),
              ),
              IconButton(
                icon: const Icon(Icons.title, size: 20),
                onPressed: () => _insertMarkdown('# ', ''),
                tooltip: 'Judul besar',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(AppSpacing.sm),
              ),
              IconButton(
                icon: const Icon(Icons.text_fields, size: 16),
                onPressed: () => _insertMarkdown('## ', ''),
                tooltip: 'Judul kecil',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(AppSpacing.sm),
              ),
              IconButton(
                icon: const Icon(Icons.format_list_bulleted, size: 20),
                onPressed: () => _insertMarkdown('- ', ''),
                tooltip: 'Daftar',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(AppSpacing.sm),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: widget.controller,
          maxLines: 8,
          minLines: 4,
          decoration: InputDecoration(hintText: widget.hintText),
        ),
      ],
    );
  }

  /// Sisipkan token format di posisi kursor (atau di akhir bila tidak ada).
  void _insertMarkdown(String prefix, String suffix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    if (selection.start == -1) {
      widget.controller.text = '$text$prefix$suffix';
      return;
    }
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix${text.substring(selection.start, selection.end)}$suffix',
    );
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start +
            prefix.length +
            (selection.end - selection.start),
      ),
    );
  }
}

/// Konversi markdown-lite → HTML untuk portal: **tebal**, `# Judul`,
/// `## Subjudul`, `- butir daftar`. Karakter HTML di-escape lebih dulu
/// supaya isi laporan tak bisa menyuntik markup.
String markdownKeHtml(String input) {
  String escaped = input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  escaped = escaped.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (match) => '<strong>${match.group(1)}</strong>',
  );

  final lines = escaped.split(RegExp(r'\r?\n'));
  final result = <String>[];
  bool inList = false;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('## ')) {
      if (inList) {
        result.add('</ul>');
        inList = false;
      }
      result.add('<h2>${trimmed.substring(3)}</h2>');
    } else if (trimmed.startsWith('# ')) {
      if (inList) {
        result.add('</ul>');
        inList = false;
      }
      result.add('<h1>${trimmed.substring(2)}</h1>');
    } else if (trimmed.startsWith('- ')) {
      if (!inList) {
        result.add('<ul>');
        inList = true;
      }
      result.add('<li>${trimmed.substring(2)}</li>');
    } else {
      if (inList) {
        result.add('</ul>');
        inList = false;
      }
      if (trimmed.isNotEmpty) {
        result.add('<p>$trimmed</p>');
      }
    }
  }
  if (inList) {
    result.add('</ul>');
  }
  return result.join();
}
