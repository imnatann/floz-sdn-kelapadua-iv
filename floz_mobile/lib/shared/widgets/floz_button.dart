import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum FlozButtonType { primary, secondary, outline, ghost }

class FlozButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final FlozButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const FlozButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = FlozButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = _getButtonStyle();
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.space8),
              ],
              Text(text),
            ],
          );

    Widget button;
    switch (type) {
      case FlozButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
      case FlozButtonType.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
      case FlozButtonType.primary:
      case FlozButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, height: 48, child: button);
    }
    return SizedBox(height: 48, child: button);
  }

  ButtonStyle _getButtonStyle() {
    switch (type) {
      case FlozButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary200,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
      case FlozButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.slate100,
          foregroundColor: AppColors.slate700,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
      case FlozButtonType.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate700,
          side: const BorderSide(color: AppColors.slate200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
      case FlozButtonType.ghost:
        return TextButton.styleFrom(
          foregroundColor: AppColors.slate600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }
}
