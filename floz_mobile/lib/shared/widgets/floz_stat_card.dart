import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'floz_card.dart';

/// A compact stat/metric card with an icon chip, a label, and a value.
/// Mirrors the web `StatCard.vue` pattern.
///
/// Example:
/// ```dart
/// FlozStatCard(
///   icon: Icons.check_circle_outline,
///   label: 'Kehadiran',
///   value: '90%',
///   accent: AppColors.success500,
/// )
/// ```
class FlozStatCard extends StatelessWidget {
  const FlozStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Accent color for the icon chip + accent bar. Defaults to brand orange.
  final Color? accent;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? AppColors.primary600;
    final bg = color == AppColors.primary600
        ? AppColors.primary50
        : color.withValues(alpha: 0.08);

    return FlozCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
