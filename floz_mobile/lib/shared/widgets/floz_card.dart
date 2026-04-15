import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'pressable.dart';

/// The canonical card surface for FLOZ mobile.
///
/// Mirrors `.floz-card` from the web design system:
/// — white background
/// — 1px slate-200 border
/// — 12px radius
/// — subtle 2-layer shadow
///
/// When [onTap] is provided, the card gets [Pressable] scale feedback
/// (0.97 scale, 160ms easeOutCubic).
class FlozCard extends StatelessWidget {
  const FlozCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderColor,
    this.borderRadius,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLG);

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Pressable(onTap: onTap, child: card);
  }
}
