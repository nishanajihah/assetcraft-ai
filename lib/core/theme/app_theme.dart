import 'package:flutter/material.dart';

/// AssetCraft AI App Theme
///
/// Gold-themed neomorphic design system with premium feel
/// Color scheme: Gold primary, teal accents, warm neutrals
class AppColors {
  // Primary Colors
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color primaryGoldLight = Color(0xFFE8C547);
  static const Color primaryGoldDark = Color(0xFFB8941F);
  static const Color primaryYellow = Color(0xFFFDD835);

  // Accent Colors
  static const Color accentTeal = Color(0xFF26A69A);
  static const Color accentDeepOrange = Color(0xFFFF7043);
  static const Color accentPink = Color(0xFFEC407A);
  static const Color accentIndigo = Color(0xFF5C6BC0);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentBlue = Color(0xFF2196F3);

  // Background Colors (Neomorphic)
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundLight = Color(0xFFF8F8F8);
  static const Color backgroundDark = Color(0xFFE8E8E8);
  static const Color backgroundSecondary = Color(0xFFEFEFEF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF0F0F0);
  static const Color surfaceBright = Color(0xFFFAFAFA);

  // Neomorphic specific colors
  static const Color neuBackground = Color(0xFFF0F0F0);
  static const Color neuShadowDark = Color(0xFFD1D1D1);
  static const Color neuShadowLight = Color(0xFFFFFFFF);
  static const Color neuHighlight = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Shadow Colors (Neomorphic)
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFE0E0E0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGold, primaryGoldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentTeal, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows and Glows
  static const BoxShadow primaryShadow = BoxShadow(
    color: Color(0x40D4AF37),
    blurRadius: 16,
    offset: Offset(0, 8),
    spreadRadius: 0,
  );

  static const BoxShadow primaryGlow = BoxShadow(
    color: Color(0x20D4AF37),
    blurRadius: 32,
    offset: Offset(0, 0),
    spreadRadius: 8,
  );

  static const BoxShadow neomorphicShadowDark = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 10,
    offset: Offset(5, 5),
    spreadRadius: 0,
  );

  static const BoxShadow neomorphicShadowLight = BoxShadow(
    color: Color(0xFFFFFFFF),
    blurRadius: 10,
    offset: Offset(-5, -5),
    spreadRadius: 0,
  );
}

/// Text Styles with golden theme
class AppTextStyles {
  static const String _fontFamily = 'Inter';

  // Heading Styles
  static const TextStyle headingLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Button Styles
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // Caption Style
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.3,
  );
}

/// App Dimensions and Spacing
class AppDimensions {
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Elevation
  static const double cardElevation = 4.0;
  static const double buttonElevation = 2.0;
  static const double appBarElevation = 0.0;

  // Button Heights
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}

/// Enhanced Box Shadows for Neomorphic Design
class AppShadows {
  // Neomorphic outset shadows (raised elements)
  static List<BoxShadow> neuOutset({
    double blurRadius = 10,
    double offset = 5,
    double alpha = 0.3,
  }) => [
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

  // Neomorphic inset shadows (pressed/input elements)
  static List<BoxShadow> neuInset({
    double blurRadius = 6,
    double offset = 3,
    double alpha = 0.25,
  }) => [
    BoxShadow(
      color: AppColors.neuShadowDark.withValues(alpha: alpha),
      blurRadius: blurRadius,
      offset: Offset(offset, offset),
      spreadRadius: -1,
    ),
    BoxShadow(
      color: AppColors.neuHighlight.withValues(alpha: 0.8),
      blurRadius: blurRadius / 2,
      offset: Offset(-offset / 2, -offset / 2),
      spreadRadius: 0,
    ),
  ];

  // Enhanced card shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: AppColors.shadowDark.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
}

/// Main App Theme
class AppTheme {
  static ThemeData get goldTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles._fontFamily,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGold,
        primary: AppColors.primaryGold,
        secondary: AppColors.accentTeal,
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.surfaceDim,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        brightness: Brightness.light,
      ),

      // Background Color
      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles._fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
          elevation: AppDimensions.cardElevation,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGold,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGold,
          textStyle: AppTextStyles.button,
          side: const BorderSide(color: AppColors.primaryGold, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingMedium,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryGold,
      ),
    );
  }
}
