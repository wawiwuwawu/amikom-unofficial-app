import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../theme/app_theme.dart';

class ExpandableHtml extends StatefulWidget {
  final String htmlData;
  const ExpandableHtml({super.key, required this.htmlData});

  @override
  State<ExpandableHtml> createState() => _ExpandableHtmlState();
}

class _ExpandableHtmlState extends State<ExpandableHtml> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Gunakan estimasi kasar: jika teks melebihi 250 karakter, maka dianggap panjang
    final bool isLong = widget.htmlData.length > 250;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: _isExpanded || !isLong ? double.infinity : 120,
            ),
            child: Stack(
              children: [
                ClipRect(
                  child: Html(
                    data: widget.htmlData,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(13),
                        color: AppColors.textPrimary,
                      ),
                    },
                  ),
                ),
                if (!_isExpanded && isLong)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.surface.withValues(alpha: 0.0),
                            AppColors.surface,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isLong)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _isExpanded ? 'Tampilkan Lebih Sedikit' : 'Selengkapnya',
                      style: AppText.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
