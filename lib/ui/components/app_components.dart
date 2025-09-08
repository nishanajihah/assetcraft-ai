import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Button variants for consistency across the app
enum ButtonVariant { primary, secondary, outline }

/// Wrapper functions for enhanced widgets to maintain compatibility
/// with existing code while using standard Flutter widgets

/// Gold Button - Simple elevated button with gold styling
Widget GoldButton({
  required String text,
  VoidCallback? onPressed,
  bool isLoading = false,
  IconData? icon,
  ButtonVariant variant = ButtonVariant.primary,
  double? width,
  double? height,
}) {
  Color backgroundColor;
  Color textColor;

  switch (variant) {
    case ButtonVariant.primary:
      backgroundColor = AppColors.primaryGold;
      textColor = Colors.black;
      break;
    case ButtonVariant.secondary:
      backgroundColor = AppColors.backgroundSecondary;
      textColor = AppColors.textPrimary;
      break;
    case ButtonVariant.outline:
      backgroundColor = Colors.transparent;
      textColor = AppColors.primaryGold;
      break;
  }

  return SizedBox(
    width: width,
    height: height ?? 56,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: variant == ButtonVariant.outline
              ? BorderSide(color: AppColors.primaryGold, width: 2)
              : BorderSide.none,
        ),
        elevation: variant == ButtonVariant.primary ? 4 : 2,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
    ),
  );
}

/// Neomorphic Container - Simple container with rounded corners and shadow
Widget NeomorphicContainer({
  required Widget child,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  double borderRadius = 16,
  bool hasGoldTint = false,
  bool hasGlow = false,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: hasGoldTint
            ? AppColors.primaryGold.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: hasGlow
                ? AppColors.primaryGold.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: hasGlow ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasGoldTint
            ? Border.all(color: AppColors.primaryGold.withOpacity(0.3))
            : null,
      ),
      child: child,
    ),
  );
}

/// Neomorphic TextField - Simple text field with rounded corners
Widget NeomorphicTextField({
  TextEditingController? controller,
  String? hintText,
  String? labelText,
  IconData? prefixIcon,
  IconData? suffixIcon,
  VoidCallback? onSuffixTap,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  bool enabled = true,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
  void Function(String)? onSubmitted,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    maxLines: maxLines,
    enabled: enabled,
    validator: validator,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    decoration: InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon != null
          ? IconButton(icon: Icon(suffixIcon), onPressed: onSuffixTap)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
    ),
  );
}

/// Gemstone Counter widget
class GemstoneCounter extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const GemstoneCounter({super.key, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, color: AppColors.primaryGold, size: 20),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asset Type Card widget
class AssetTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const AssetTypeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold.withOpacity(0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGold
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryGold.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? AppColors.primaryGold : Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? AppColors.textPrimary : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.textSecondary : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
