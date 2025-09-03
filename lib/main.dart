import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Core imports
import 'core/config/environment.dart';
import 'core/services/app_services.dart';
import 'core/database/database_service.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/assets_provider.dart';
import 'core/providers/generation_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/helpers.dart';

// Shared widgets
import 'shared/widgets/app_initializer.dart';

/// Main entry point for AssetCraft AI
///
/// This new clean architecture features:
/// 1. Proper Hive database integration
/// 2. Clean Provider state management
/// 3. Environment-based configuration
/// 4. Platform-specific service initialization
/// 5. Modular feature structure
void main() async {
  // Ensure Flutter framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first
  AppLogger.initialize();
  AppLogger.info('🚀 Starting AssetCraft AI...');

  // Log platform information
  _logPlatformInfo();

  // Configure platform-specific settings
  await _configurePlatform();

  // Initialize core services
  await _initializeCoreServices();

  // Run the app
  runApp(const AssetCraftApp());
}

/// Configure platform-specific settings
Future<void> _configurePlatform() async {
  try {
    AppLogger.info('🔧 Configuring platform: ${PlatformUtils.platformName}');

    // Set portrait orientation for mobile platforms
    if (PlatformUtils.isMobile) {
      await PlatformUtils.setPortraitOrientation();
      AppLogger.info('📱 Portrait orientation set for mobile');
    }

    // Web-specific configurations
    if (PlatformUtils.isWeb) {
      AppLogger.info('🌐 Web platform detected');
    }

    // Desktop-specific configurations
    if (PlatformUtils.isDesktop) {
      AppLogger.info('🖥️ Desktop platform detected');
    }
  } catch (e, stackTrace) {
    AppLogger.error('❌ Platform configuration failed', e, stackTrace);
  }
}

/// Initialize core services in the correct order
Future<void> _initializeCoreServices() async {
  try {
    AppLogger.info('🔧 Initializing core services...');

    // 1. Initialize environment configuration
    await Environment.initialize();
    AppLogger.info('✅ Environment initialized');

    // Print environment configuration in debug mode
    if (kDebugMode) {
      Environment.printConfiguration();
    }

    // 2. Initialize Hive database
    await DatabaseService.initialize();
    AppLogger.info('✅ Database initialized');

    // 3. Initialize external services (async to avoid blocking UI)
    if (!PlatformUtils.isWeb) {
      unawaited(_initializeExternalServices());
    }

    AppLogger.info('✅ Core services initialization complete');
  } catch (e, stackTrace) {
    AppLogger.error('❌ Core services initialization failed', e, stackTrace);
    // Continue anyway - app should still work with limited functionality
  }
}

/// Initialize external services asynchronously
Future<void> _initializeExternalServices() async {
  try {
    AppLogger.info('🌐 Initializing external services...');

    await AppServices.initialize().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        AppLogger.warning('⏰ External services initialization timed out');
      },
    );

    AppLogger.info('✅ External services initialized');
  } catch (e, stackTrace) {
    AppLogger.warning(
      '⚠️ External services initialization failed (app will continue)',
      e,
      stackTrace,
    );
  }
}

/// Log platform information for debugging
void _logPlatformInfo() {
  if (kDebugMode) {
    AppLogger.debug('🔧 ========== PLATFORM INFO ==========');
    AppLogger.debug('📱 Platform: ${PlatformUtils.platformName}');
    AppLogger.debug('🌐 Is Web: ${PlatformUtils.isWeb}');
    AppLogger.debug('📱 Is Mobile: ${PlatformUtils.isMobile}');
    AppLogger.debug('🖥️ Is Desktop: ${PlatformUtils.isDesktop}');
    AppLogger.debug('🛠️ Is Debug: $kDebugMode');
    AppLogger.debug('🏗️ Is Profile: $kProfileMode');
    AppLogger.debug('🚀 Is Release: $kReleaseMode');
    AppLogger.debug('🔧 ===================================');
  }
}

/// Main application widget with Provider state management
class AssetCraftApp extends StatelessWidget {
  const AssetCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AssetsProvider()),
        ChangeNotifierProvider(create: (_) => GenerationProvider()),

        // Add more providers as features are implemented
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: AppTheme.lightTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
        ),
        darkTheme: AppTheme.darkTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(AppTheme.darkTheme.textTheme),
        ),
        themeMode: ThemeMode.system,

        // Use AppInitializer to handle startup flow
        home: const AppInitializer(),

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
      ),
    );
  }
}
