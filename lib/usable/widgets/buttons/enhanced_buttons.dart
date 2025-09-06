import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../containers/enhanced_containers.dart';

/// Enhanced Golden Button with neomorphic styling
class EnhancedGoldenButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isSecondary;
  final double? width;
  final double? height;

  const EnhancedGoldenButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isSecondary = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: width,
      height: height ?? 56,
      child: EnhancedGlassContainer(
        hasGoldTint: !isSecondary,
        hasGlow: isEnabled && !isSecondary,
        onTap: isEnabled ? onPressed : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSecondary ? AppColors.textPrimary : AppColors.primaryGold,
                  ),
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isSecondary
                      ? AppColors.textPrimary
                      : AppColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: AppTextStyles.button.copyWith(
                  color: isSecondary
                      ? AppColors.textPrimary
                      : AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Enhanced Floating Action Button with golden theme
class EnhancedFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isLoading;
  final String? tooltip;

  const EnhancedFAB({
    super.key,
    this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      backgroundColor: AppColors.primaryGold,
      foregroundColor: Colors.white,
      elevation: 8,
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon),
    );
  }
}

/// Enhanced Icon Button with neomorphic styling
class EnhancedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;
  final String? tooltip;
  final double size;

  const EnhancedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isActive = false,
    this.tooltip,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: SizedBox(
        width: size,
        height: size,
        child: EnhancedNeuContainer(
          hasGoldAccent: isActive,
          onTap: onPressed,
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: isActive ? AppColors.primaryGold : AppColors.textSecondary,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}
