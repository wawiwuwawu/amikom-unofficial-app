import 'package:flutter/material.dart';
import 'glass_card.dart';

/// ponytail: reusable card for bulleted information in Visi Misi & institutional pages
class InfoSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> content;

  const InfoSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isList = content.length > 1;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      opacity: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF501F66),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content.map((text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isList)
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: isList ? TextAlign.left : TextAlign.justify,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
