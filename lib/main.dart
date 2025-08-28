import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// Environment configuration
import 'core/config/environment.dart';
import 'mock/mock_config.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

// Widget imports
import 'shared/widgets/app_initializer.dart';
import 'mock/widgets/mock_indicator.dart';

/// Main entry point for AssetCraft AI
///
/// This file initializes:
/// 1. Flutter framework essentials
/// 2. Riverpod state management
/// 3. App theme with custom color palette
/// 4. Third-party services (RevenueCat, OneSignal)
/// 5. Defers environment and service initialization to AppInitializer
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize mock configuration first
  await MockConfig.initialize();

  // Print mock configuration for debugging
  if (MockConfig.isDebugLoggingEnabled) {
    MockConfig.printConfiguration();
  }

  // Set preferred orientations (mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize third-party services
  await initializeServices();

  // Run the app with Riverpod
  runApp(const ProviderScope(child: AssetCraftApp()));
}

/// Initialize third-party services for monetization and engagement
///
/// This method sets up:
/// 1. OneSignal for push notifications
/// 2. RevenueCat for in-app purchases and subscriptions
Future<void> initializeServices() async {
  try {
    // Initialize environment first to access configuration values
    await Environment.initialize();

    // Initialize OneSignal if configuration is available
    if (Environment.hasOneSignalConfig) {
      debugPrint('🔔 Initializing OneSignal...');
      OneSignal.initialize(Environment.oneSignalAppId);

      // Request push notification permissions
      await OneSignal.Notifications.requestPermission(true);
      debugPrint('✅ OneSignal initialized successfully');
    } else {
      debugPrint('⚠️ OneSignal configuration missing, skipping initialization');
    }

    // Initialize RevenueCat if configuration is available
    if (Environment.hasRevenueCatConfig) {
      debugPrint('💳 Initializing RevenueCat...');
      // Set debug log level for development
      await Purchases.setLogLevel(LogLevel.debug);

      // Get platform-specific API keys
      final String rcAndroidKey = const String.fromEnvironment(
        'REVENUECAT_ANDROID_KEY',
        defaultValue: '',
      );
      // The iOS key is optional for now
      final String rcIosKey = const String.fromEnvironment(
        'REVENUECAT_IOS_KEY',
        defaultValue: '',
      );

      // Determine which API key to use based on platform
      String rcApiKey = '';
      if (Platform.isAndroid) {
        rcApiKey = rcAndroidKey.isNotEmpty
            ? rcAndroidKey
            : Environment.revenueCatApiKey;
      } else if (Platform.isIOS) {
        rcApiKey = rcIosKey;
        // TODO(developer): Add your iOS RevenueCat key here once available.
        // A valid key is required for in-app purchases on iOS.
        if (rcApiKey.isEmpty) {
          debugPrint('⚠️ iOS RevenueCat key not available yet');
        }
      }

      // Configure RevenueCat if we have a valid API key
      if (rcApiKey.isNotEmpty) {
        await Purchases.configure(PurchasesConfiguration(rcApiKey));
        debugPrint(
          '✅ RevenueCat initialized successfully for ${Platform.isAndroid ? "Android" : "iOS"}',
        );
      } else {
        debugPrint(
          '⚠️ RevenueCat not configured - missing API key for current platform',
        );
      }
    } else {
      debugPrint(
        '⚠️ RevenueCat configuration missing, skipping initialization',
      );
    }

    debugPrint('✅ Third-party services initialization complete');
  } catch (e) {
    debugPrint('❌ Error initializing services: $e');
  }
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
      home: const MockIndicator(child: AppInitializer()),

      // Global error handling
      builder: (context, widget) {
        // Handle text scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: widget ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
