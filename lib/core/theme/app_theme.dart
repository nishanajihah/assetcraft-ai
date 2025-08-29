import 'package:flutter/material.dart';

/// AssetCraft AI Color Scheme
/// Custom colors for Neumorphism + Glassmorphism design
class AppColors {
  // Primary Colors (from your specification)
  static const Color primaryDark = Color(0xFF282F44); // #282F44
  static const Color primaryGold = Color(0xFFE6AF2E); // #E6AF2E
  static const Color primaryYellow = Color(0xFFF5D061); // #F5D061
  static const Color primaryLight = Color(0xFFECECEC); // #ECECEC

  // Gradient variations for depth
  static const Color primaryDarkVariant = Color(0xFF1A1F30);
  static const Color primaryGoldVariant = Color(0xFFD49A1A);

  // Neumorphism specific colors (enhanced for light mode)
  static const Color neuShadowDark = Color(
    0xFFC8C8C8,
  ); // Better shadow for light mode
  static const Color neuHighlight = Color(0xFFFFFFFF); // Pure white highlight
  static const Color neuBackground = Color(0xFFECECEC); // Main background

  // Glassmorphism specific colors
  static Color glassBackground = primaryLight.withValues(alpha: 0.3);
  static Color glassBorder = primaryGold.withValues(alpha: 0.3);

  // Semantic colors (enhanced for better visibility)
  static const Color success = Color(
    0xFF2E7D32,
  ); // Darker green for better contrast
  static const Color error = Color(0xFFD32F2F); // Better red contrast
  static const Color warning = Color(0xFFF57C00); // Enhanced orange
  static const Color info = Color(
    0xFF1976D2,
  ); // Darker blue for better readability

  // Text colors (enhanced for light mode readability)
  static const Color textPrimary = Color(
    0xFF1A1F2E,
  ); // Darker for better contrast
  static const Color textSecondary = Color(0xFF3D3D3D); // Darker secondary text
  static const Color textHint = Color(0xFF666666); // Better contrast for hints
  static const Color textOnGold = Color(
    0xFF1A1F2E,
  ); // Dark text on gold background

  // Background variations (light mode)
  static const Color backgroundPrimary = primaryLight;
  static const Color backgroundSecondary = Color(0xFFF8F8F8);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // Gemstone system colors (light mode)
  static const Color gemstoneGold = primaryGold;
  static const Color gemstoneBackground = Color(0xFFF5F5F5);
  static const Color gemstoneBorder = Color(0xFFE0E0E0);
}

/// Material Theme Configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryGold,
        primaryContainer: AppColors.primaryYellow,
        secondary: AppColors.primaryYellow,
        secondaryContainer: AppColors.primaryYellow.withValues(alpha: 0.3),
        surface: AppColors.backgroundCard,
        error: AppColors.error,
        onPrimary: AppColors.textOnGold,
        onSecondary: AppColors.primaryDark,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
        outline: AppColors.glassBorder,
        shadow: AppColors.neuShadowDark,
      ),

      // App Bar (enhanced for better readability)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          inherit: true,
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Elevated Button (enhanced for better readability)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.textOnGold,
          elevation: 2,
          shadowColor: AppColors.primaryGold.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            inherit: true,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGold,
          textStyle: const TextStyle(
            inherit: true,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.primaryGold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            inherit: true,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Text Theme (enhanced for better readability with consistent inheritance)
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          inherit: true,
          color: AppColors.textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          inherit: true,
          color: AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          inherit: true,
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          inherit: true,
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        titleSmall: TextStyle(
          inherit: true,
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          inherit: true,
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        bodyMedium: TextStyle(
          inherit: true,
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        bodySmall: TextStyle(
          inherit: true,
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
        labelLarge: TextStyle(
          inherit: true,
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelMedium: TextStyle(
          inherit: true,
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
        labelSmall: TextStyle(
          inherit: true,
          color: AppColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),

      // Input Decoration (enhanced for better readability)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: const TextStyle(
          inherit: true,
          color: AppColors.textHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          inherit: true,
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          inherit: true,
          color: AppColors.primaryGold,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Navigation Bar (enhanced for better readability)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundPrimary,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(
          inherit: true,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          inherit: true,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}

/// Neumorphism styling utilities
class NeuStyles {
  static BoxDecoration neuContainer({
    Color? color,
    double borderRadius = 16,
    double depth = 4,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.neuBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        // Dark shadow (bottom-right)
        BoxShadow(
          color: AppColors.neuShadowDark,
          offset: Offset(depth, depth),
          blurRadius: depth * 2,
          spreadRadius: 0,
        ),
        // Light shadow (top-left)
        BoxShadow(
          color: AppColors.neuHighlight,
          offset: Offset(-depth / 2, -depth / 2),
          blurRadius: depth,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration neuPressed({
    Color? color,
    double borderRadius = 16,
    double depth = 2,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.neuBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        // Inset shadow effect for light mode
        BoxShadow(
          color: AppColors.neuShadowDark,
          offset: Offset(depth, depth),
          blurRadius: depth * 2,
          spreadRadius: 0,
        ),
      ],
    );
  }
}

/// Glassmorphism styling utilities
class GlassStyles {
  static BoxDecoration glassContainer({
    double borderRadius = 16,
    double opacity = 0.1,
    double blurRadius = 10,
  }) {
    return BoxDecoration(
      color: AppColors.glassBackground.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorder, width: 1),
    );
  }
}
