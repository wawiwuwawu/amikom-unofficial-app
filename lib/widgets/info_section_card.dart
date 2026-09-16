import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_kit.dart';

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

    return AppSurface(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title, style: AppText.h2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...content.map((text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isList)
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: AppSpacing.md),
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
                      style: AppText.body.copyWith(height: 1.5),
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
