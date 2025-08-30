import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
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
/// 2. Platform-specific configurations
/// 3. Riverpod state management
/// 4. App theme with custom color palette
/// 5. Third-party services (RevenueCat, OneSignal)
/// 6. Defers environment and service initialization to AppInitializer
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Print platform information for debugging
  _logPlatformInfo();

  // Initialize mock configuration first
  await MockConfig.initialize();

  // Print mock configuration only in debug mode
  if (kDebugMode && MockConfig.isDebugLoggingEnabled) {
    MockConfig.printConfiguration();
  }

  // Platform-specific configurations
  await _configurePlatform();

  // Initialize third-party services asynchronously to not block UI
  initializeServices();

  // Run the app with Riverpod immediately
  runApp(const ProviderScope(child: AssetCraftApp()));
}

/// Configure platform-specific settings
Future<void> _configurePlatform() async {
  try {
    if (kIsWeb) {
      debugPrint('🌐 Running on Web platform');
      // Web-specific configurations
      // No orientation lock needed for web
    } else {
      // Mobile platform configurations
      if (Platform.isAndroid) {
        debugPrint('🤖 Running on Android platform');
      } else if (Platform.isIOS) {
        debugPrint('🍎 Running on iOS platform');
      } else if (Platform.isWindows) {
        debugPrint('🪟 Running on Windows platform');
      } else if (Platform.isMacOS) {
        debugPrint('🖥️ Running on macOS platform');
      } else if (Platform.isLinux) {
        debugPrint('🐧 Running on Linux platform');
      }

      // Set preferred orientations for mobile platforms only
      if (Platform.isAndroid || Platform.isIOS) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        debugPrint('📱 Portrait orientation locked for mobile');
      }
    }
  } catch (e) {
    debugPrint('⚠️ Platform configuration error: $e');
  }
}

/// Log platform information for debugging
void _logPlatformInfo() {
  if (kDebugMode) {
    debugPrint('🔧 ========== PLATFORM INFO ==========');
    debugPrint('📱 Is Web: $kIsWeb');
    debugPrint('🛠️ Is Debug: $kDebugMode');
    debugPrint('🏗️ Is Profile: $kProfileMode');
    debugPrint('🚀 Is Release: $kReleaseMode');

    if (!kIsWeb) {
      debugPrint('🤖 Is Android: ${Platform.isAndroid}');
      debugPrint('🍎 Is iOS: ${Platform.isIOS}');
      debugPrint('🪟 Is Windows: ${Platform.isWindows}');
      debugPrint('🖥️ Is macOS: ${Platform.isMacOS}');
      debugPrint('🐧 Is Linux: ${Platform.isLinux}');
      debugPrint('💻 Operating System: ${Platform.operatingSystem}');
      debugPrint(
        '📋 Operating System Version: ${Platform.operatingSystemVersion}',
      );
    }
    debugPrint('🔧 ===================================');
  }
}

/// Initialize third-party services for monetization and engagement
///
/// This method sets up:
/// 1. OneSignal for push notifications
/// 2. RevenueCat for in-app purchases and subscriptions
///
/// Uses timeout to prevent hanging during initialization
Future<void> initializeServices() async {
  try {
    // Add timeout to prevent hanging
    await _initializeServicesInternal().timeout(const Duration(seconds: 30));
  } on TimeoutException {
    debugPrint('⏰ Service initialization timed out after 30 seconds');
  } catch (e) {
    debugPrint('❌ Error initializing services: $e');
  }
}

/// Internal service initialization logic
Future<void> _initializeServicesInternal() async {
  // Initialize environment first to access configuration values
  await Environment.initialize();

  // Initialize OneSignal if configuration is available
  if (Environment.hasOneSignalConfig) {
    debugPrint('🔔 Initializing OneSignal...');

    if (kIsWeb) {
      debugPrint(
        '🌐 OneSignal on Web has limited support, proceeding with caution',
      );
    }

    try {
      OneSignal.initialize(Environment.oneSignalAppId);

      // Request push notification permissions (mobile only)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await OneSignal.Notifications.requestPermission(true);
      }

      debugPrint('✅ OneSignal initialized successfully');
    } catch (e) {
      debugPrint('⚠️ OneSignal initialization failed: $e');
    }
  } else {
    debugPrint('⚠️ OneSignal configuration missing, skipping initialization');
  }

  // Initialize RevenueCat if configuration is available
  if (Environment.hasRevenueCatConfig) {
    debugPrint('💳 Initializing RevenueCat...');

    if (kIsWeb) {
      debugPrint('🌐 RevenueCat not supported on Web, using mock mode');
      return;
    }

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
    } else {
      debugPrint('⚠️ RevenueCat not supported on ${Platform.operatingSystem}');
      return;
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
    debugPrint('⚠️ RevenueCat configuration missing, skipping initialization');
  }

  debugPrint('✅ Third-party services initialization complete');
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
