import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Enhanced Glassmorphism and Neumorphism Container Widgets
///
/// This file contains reusable container widgets with dramatic glassmorphism
/// and neumorphism effects that can be applied across the entire app for
/// consistent premium visual styling.

/// Enhanced Glassmorphism Container with strong visual effects
class EnhancedGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double borderWidth;
  final bool hasGoldTint;
  final bool hasGlow;
  final VoidCallback? onTap;

  const EnhancedGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.borderWidth = 1.5,
    this.hasGoldTint = false,
    this.hasGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          // Enhanced glassmorphism gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasGoldTint
                ? [
                    AppColors.primaryGold.withValues(alpha: 0.2),
                    AppColors.primaryGold.withValues(alpha: 0.05),
                    AppColors.primaryYellow.withValues(alpha: 0.15),
                  ]
                : [
                    AppColors.backgroundSecondary.withValues(alpha: 0.5),
                    AppColors.backgroundSecondary.withValues(alpha: 0.2),
                    AppColors.backgroundSecondary.withValues(alpha: 0.4),
                  ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          // Glassmorphism border
          border: Border.all(
            color: hasGoldTint
                ? AppColors.primaryGold.withValues(alpha: 0.5)
                : AppColors.primaryGold.withValues(alpha: 0.4),
            width: borderWidth,
          ),
          boxShadow: [
            // Strong neumorphic dark shadow
            BoxShadow(
              color: AppColors.neuShadowDark.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(6, 6),
              spreadRadius: 0,
            ),
            // Neumorphic light shadow
            BoxShadow(
              color: AppColors.neuHighlight.withValues(alpha: 0.9),
              blurRadius: 16,
              offset: const Offset(-3, -3),
              spreadRadius: 0,
            ),
            // Enhanced depth
            BoxShadow(
              color: AppColors.neuShadowDark.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            // Inner glow
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.6),
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
            // Optional gold glow effect
            if (hasGlow)
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 0),
                spreadRadius: 1,
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Enhanced Neumorphic Container with dramatic depth effects
class EnhancedNeuContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isPressed;
  final bool hasGoldAccent;
  final VoidCallback? onTap;

  const EnhancedNeuContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.isPressed = false,
    this.hasGoldAccent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          // Enhanced background with optional gold accent
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasGoldAccent
                ? [
                    AppColors.neuBackground,
                    AppColors.primaryGold.withValues(alpha: 0.05),
                    AppColors.neuBackground,
                  ]
                : [
                    AppColors.neuBackground,
                    AppColors.backgroundSecondary.withValues(alpha: 0.3),
                    AppColors.neuBackground,
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isPressed
              ? [
                  // Inset pressed effect
                  BoxShadow(
                    color: AppColors.neuShadowDark.withValues(alpha: 0.3),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: AppColors.neuHighlight.withValues(alpha: 0.8),
                    offset: const Offset(-1, -1),
                    blurRadius: 3,
                    spreadRadius: 0,
                  ),
                ]
              : [
                  // Strong neumorphic raised effect
                  BoxShadow(
                    color: AppColors.neuShadowDark.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(8, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.neuHighlight.withValues(alpha: 1.0),
                    blurRadius: 20,
                    offset: const Offset(-4, -4),
                    spreadRadius: 0,
                  ),
                  // Enhanced depth shadow
                  BoxShadow(
                    color: AppColors.neuShadowDark.withValues(alpha: 0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                    spreadRadius: 4,
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

/// Enhanced Icon Container with glassmorphism and glow effects
class EnhancedIconContainer extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? iconColor;
  final double containerSize;
  final double borderRadius;
  final bool hasStrongGlow;
  final VoidCallback? onTap;

  const EnhancedIconContainer({
    super.key,
    required this.icon,
    this.size = 24,
    this.iconColor,
    this.containerSize = 48,
    this.borderRadius = 12,
    this.hasStrongGlow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          // Multi-layer gradient for depth
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGold.withValues(alpha: 0.4),
              AppColors.primaryGold.withValues(alpha: 0.1),
              AppColors.primaryYellow.withValues(alpha: 0.2),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            // Strong neumorphic shadows
            BoxShadow(
              color: AppColors.neuShadowDark.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(4, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.neuHighlight.withValues(alpha: 0.8),
              blurRadius: 12,
              offset: const Offset(-2, -2),
              spreadRadius: 0,
            ),
            // Enhanced glow effect
            if (hasStrongGlow)
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 0),
                spreadRadius: 1,
              ),
          ],
        ),
        child: Icon(
          icon,
          size: size,
          color: iconColor ?? AppColors.primaryGold,
        ),
      ),
    );
  }
}

/// Enhanced Input Container with glassmorphism for text fields
class EnhancedInputContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double minHeight;
  final double maxHeight;
  final bool hasFocus;

  const EnhancedInputContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.minHeight = 56,
    this.maxHeight = 200,
    this.hasFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Enhanced glassmorphism gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundSecondary.withValues(alpha: 0.6),
            AppColors.backgroundSecondary.withValues(alpha: 0.3),
            AppColors.backgroundSecondary.withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        // Enhanced glassmorphism border
        border: Border.all(
          color: hasFocus
              ? AppColors.primaryGold.withValues(alpha: 0.8)
              : AppColors.primaryGold.withValues(alpha: 0.5),
          width: hasFocus ? 2.0 : 1.5,
        ),
        boxShadow: [
          // Strong neumorphic inset shadows for input field
          BoxShadow(
            color: AppColors.neuShadowDark.withValues(alpha: 0.2),
            offset: const Offset(3, 3),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: AppColors.neuHighlight.withValues(alpha: 0.8),
            offset: const Offset(-1, -1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
          // Enhanced outer depth
          BoxShadow(
            color: AppColors.neuShadowDark.withValues(alpha: 0.15),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          // Subtle glow
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
          // Focus glow effect
          if (hasFocus)
            BoxShadow(
              color: AppColors.primaryGold.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 0),
              spreadRadius: 2,
            ),
        ],
      ),
      child: child,
    );
  }
}

/// Enhanced Cost Display Container with dramatic glassmorphism
class EnhancedCostContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isHighlighted;

  const EnhancedCostContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.isHighlighted = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Multi-layer glassmorphism gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundPrimary.withValues(alpha: 0.9),
            AppColors.backgroundSecondary.withValues(alpha: 0.6),
            AppColors.primaryGold.withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.primaryGold.withValues(
            alpha: isHighlighted ? 0.8 : 0.5,
          ),
          width: isHighlighted ? 2 : 1.5,
        ),
        boxShadow: [
          // Strong neumorphic dark shadow
          BoxShadow(
            color: AppColors.neuShadowDark.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(8, 8),
            spreadRadius: 0,
          ),
          // Neumorphic light shadow
          BoxShadow(
            color: AppColors.neuHighlight.withValues(alpha: 1.0),
            blurRadius: 20,
            offset: const Offset(-4, -4),
            spreadRadius: 0,
          ),
          // Enhanced gold glow
          if (isHighlighted)
            BoxShadow(
              color: AppColors.primaryGold.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 0),
              spreadRadius: 2,
            ),
          // Deep shadow for more depth
          BoxShadow(
            color: AppColors.neuShadowDark.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Enhanced Badge Container for small elements like number badges
class EnhancedBadgeContainer extends StatelessWidget {
  final Widget child;
  final double size;
  final double borderRadius;
  final bool hasGlow;

  const EnhancedBadgeContainer({
    super.key,
    required this.child,
    this.size = 24,
    this.borderRadius = 6,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGold.withValues(alpha: 0.4),
            AppColors.primaryGold.withValues(alpha: 0.2),
            AppColors.primaryYellow.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neuShadowDark.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
          BoxShadow(
            color: AppColors.neuHighlight.withValues(alpha: 0.8),
            blurRadius: 2,
            offset: const Offset(-0.5, -0.5),
          ),
          if (hasGlow)
            BoxShadow(
              color: AppColors.primaryGold.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 0),
              spreadRadius: 0.5,
            ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

/// Enhanced Card Container for larger content areas
class EnhancedCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isSelected;
  final bool hasHover;
  final VoidCallback? onTap;

  const EnhancedCardContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.isSelected = false,
    this.hasHover = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            // Enhanced glassmorphism background
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      AppColors.primaryGold.withValues(alpha: 0.3),
                      AppColors.primaryGold.withValues(alpha: 0.1),
                      AppColors.primaryYellow.withValues(alpha: 0.2),
                    ]
                  : [
                      AppColors.backgroundSecondary.withValues(alpha: 0.6),
                      AppColors.backgroundSecondary.withValues(alpha: 0.3),
                      AppColors.backgroundSecondary.withValues(alpha: 0.5),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            // Enhanced glassmorphism border
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGold.withValues(alpha: 0.8)
                  : AppColors.primaryGold.withValues(alpha: 0.3),
              width: isSelected ? 2.0 : 1.5,
            ),
            boxShadow: [
              // Strong neumorphic dark shadow (bottom-right)
              BoxShadow(
                color: AppColors.neuShadowDark.withValues(
                  alpha: hasHover ? 0.3 : 0.25,
                ),
                blurRadius: hasHover ? 20 : 16,
                offset: Offset(hasHover ? 8 : 6, hasHover ? 8 : 6),
                spreadRadius: 0,
              ),
              // Neumorphic light shadow (top-left)
              BoxShadow(
                color: AppColors.neuHighlight.withValues(alpha: 0.9),
                blurRadius: hasHover ? 20 : 16,
                offset: Offset(hasHover ? -4 : -3, hasHover ? -4 : -3),
                spreadRadius: 0,
              ),
              // Enhanced depth shadow
              BoxShadow(
                color: AppColors.neuShadowDark.withValues(alpha: 0.12),
                blurRadius: hasHover ? 28 : 24,
                offset: Offset(0, hasHover ? 14 : 10),
                spreadRadius: hasHover ? 3 : 2,
              ),
              // Inner glow for glassmorphism
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 2,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
              // Selection glow
              if (isSelected)
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 0),
                  spreadRadius: 2,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Utility class for creating enhanced shadow effects
class EnhancedShadows {
  /// Creates a strong neumorphic shadow set
  static List<BoxShadow> neuShadowStrong({
    double blurRadius = 16,
    double offset = 6,
    double alpha = 0.25,
  }) {
    return [
      BoxShadow(
        color: AppColors.neuShadowDark.withValues(alpha: alpha),
        blurRadius: blurRadius,
        offset: Offset(offset, offset),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: AppColors.neuHighlight.withValues(alpha: 0.9),
        blurRadius: blurRadius,
        offset: Offset(-offset / 2, -offset / 2),
        spreadRadius: 0,
      ),
    ];
  }

  /// Creates a glass-like shadow set
  static List<BoxShadow> glassShadow({
    double blurRadius = 12,
    double depthBlur = 24,
    double alpha = 0.12,
  }) {
    return [
      BoxShadow(
        color: AppColors.neuShadowDark.withValues(alpha: alpha * 1.25),
        blurRadius: blurRadius,
        offset: const Offset(0, 6),
        spreadRadius: 1,
      ),
      BoxShadow(
        color: AppColors.neuShadowDark.withValues(alpha: alpha),
        blurRadius: depthBlur,
        offset: const Offset(0, 10),
        spreadRadius: 2,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.6),
        blurRadius: 2,
        offset: const Offset(0, 1),
        spreadRadius: 0,
      ),
    ];
  }

  /// Creates a gold glow effect
  static BoxShadow goldGlow({
    double blurRadius = 12,
    double alpha = 0.3,
    double spreadRadius = 1,
  }) {
    return BoxShadow(
      color: AppColors.primaryGold.withValues(alpha: alpha),
      blurRadius: blurRadius,
      offset: const Offset(0, 0),
      spreadRadius: spreadRadius,
    );
  }
}
