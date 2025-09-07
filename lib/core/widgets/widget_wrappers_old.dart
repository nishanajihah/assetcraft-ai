import 'package:flutter/material.dart';
import '../../usable/widgets/buttons/enhanced_buttons.dart';
import '../../usable/widgets/containers/enhanced_containers.dart';
import '../../usable/widgets/inputs/enhanced_inputs.dart';

/// Button variants for consistency across the app
enum ButtonVariant { primary, secondary, outline }

/// Wrapper functions for enhanced widgets to maintain compatibility
/// with existing code while using the new enhanced components

/// Gold Button wrapper for EnhancedGoldenButton
Widget GoldButton({
  required String text,
  VoidCallback? onPressed,
  bool isLoading = false,
  IconData? icon,
  ButtonVariant variant = ButtonVariant.primary,
  double? width,
  double? height,
}) {
  return EnhancedGoldenButton(
    text: text,
    onPressed: onPressed,
    isLoading: isLoading,
    icon: icon,
    isSecondary:
        variant == ButtonVariant.secondary || variant == ButtonVariant.outline,
    width: width,
    height: height,
  );
}

/// Neomorphic Container wrapper for EnhancedGlassContainer
Widget NeomorphicContainer({
  required Widget child,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  double borderRadius = 16,
  bool hasGoldTint = false,
  bool hasGlow = false,
  VoidCallback? onTap,
}) {
  return EnhancedGlassContainer(
    padding: padding,
    margin: margin,
    borderRadius: borderRadius,
    hasGoldTint: hasGoldTint,
    hasGlow: hasGlow,
    onTap: onTap,
    child: child,
  );
}

/// Neomorphic TextField wrapper for EnhancedTextField
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
  return EnhancedTextField(
    controller: controller,
    hintText: hintText,
    labelText: labelText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    onSuffixTap: onSuffixTap,
    obscureText: obscureText,
    keyboardType: keyboardType,
    maxLines: maxLines,
    enabled: enabled,
    validator: validator,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
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
      child: EnhancedGlassContainer(
        hasGoldTint: true,
        hasGlow: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
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
      child: EnhancedGlassContainer(
        hasGoldTint: isSelected,
        hasGlow: isSelected,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? Colors.amber : Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
