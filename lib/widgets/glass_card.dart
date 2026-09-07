import 'package:flutter/material.dart';

/// ponytail: hardware-accelerated frosted surface without expensive live GPU Gaussian blurs
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(16.0),
    this.blur = 30.0,
    this.opacity = 0.4,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = opacity < 0.7 ? 0.90 : opacity;
    final cardContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: const Color(0xFF501F66).withValues(alpha: 0.05),
        highlightColor: const Color(0xFF501F66).withValues(alpha: 0.08),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? Colors.white.withValues(alpha: effectiveOpacity) : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF501F66).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: cardContent,
    );
  }
}
