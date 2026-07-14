import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

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
                        color: Colors.black87,
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
                            Colors.white.withOpacity(0.0),
                            Colors.white,
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
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Tampilkan Lebih Sedikit' : 'Selengkapnya',
                    style: const TextStyle(color: Color(0xFF501F66), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF501F66), size: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
