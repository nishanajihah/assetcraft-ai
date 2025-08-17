import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Neumorphic container widget for consistent styling
class NeuContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double depth;
  final Color? color;
  final bool pressed;

  const NeuContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.depth = 4,
    this.color,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: pressed
          ? NeuStyles.neuPressed(
              color: color,
              borderRadius: borderRadius,
              depth: depth,
            )
          : NeuStyles.neuContainer(
              color: color,
              borderRadius: borderRadius,
              depth: depth,
            ),
      child: child,
    );
  }
}

/// Glass morphism container widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double opacity;
  final double blurRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.opacity = 0.1,
    this.blurRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: GlassStyles.glassContainer(
        borderRadius: borderRadius,
        opacity: opacity,
        blurRadius: blurRadius,
      ),
      child: child,
    );
  }
}

/// Credit display widget
class CreditDisplay extends StatelessWidget {
  final int credits;
  final bool showBackground;

  const CreditDisplay({
    super.key,
    required this.credits,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final creditWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.account_balance_wallet,
          color: AppColors.primaryGold,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '$credits',
          style: const TextStyle(
            color: AppColors.primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (!showBackground) return creditWidget;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: NeuStyles.neuContainer(borderRadius: 20),
      child: creditWidget,
    );
  }
}

/// Loading button widget with neumorphic styling
class NeuButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const NeuButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryGold,
          foregroundColor: textColor ?? AppColors.textOnGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor ?? AppColors.textOnGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
