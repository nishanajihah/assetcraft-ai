import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../containers/enhanced_containers.dart';

/// Enhanced Text Field with neomorphic styling
class EnhancedTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final String? errorText;

  const EnhancedTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        EnhancedNeuContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            maxLength: maxLength,
            enabled: enabled,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              counterText: '',
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

/// Enhanced Search Bar with neomorphic styling
class EnhancedSearchBar extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;

  const EnhancedSearchBar({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: hintText ?? 'Search...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller?.text.isNotEmpty == true) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Icon(
                Icons.clear,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Enhanced Dropdown with neomorphic styling
class EnhancedDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;
  final String? hintText;
  final String? labelText;

  const EnhancedDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.hintText,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        EnhancedNeuContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              hint: hintText != null
                  ? Text(
                      hintText!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
              style: AppTextStyles.bodyMedium,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
