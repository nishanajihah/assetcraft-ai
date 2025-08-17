import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

// Widget imports
import 'shared/widgets/app_initializer.dart';

/// Main entry point for AssetCraft AI
///
/// This file initializes:
/// 1. Flutter framework essentials
/// 2. Riverpod state management
/// 3. App theme with custom color palette
/// 4. Defers environment and service initialization to AppInitializer
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run the app with Riverpod
  runApp(const ProviderScope(child: AssetCraftApp()));
}

/// Main application widget
/// Uses ConsumerWidget to access Riverpod providers
class AssetCraftApp extends ConsumerWidget {
  const AssetCraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration with custom colors
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
        colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
          primary: AppColors.primaryDark, // #282F44
          secondary: AppColors.primaryGold, // #E6AF2E
          tertiary: AppColors.primaryYellow, // #F5D061
          surface: AppColors.primaryLight, // #ECECEC
        ),
      ),

      // Use AppInitializer to handle async initialization
      home: const AppInitializer(),

      // Global error handling
      builder: (context, widget) {
        // Handle text scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
          ),
          child: widget ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
