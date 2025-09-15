import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';

/// AppInitializationService
///
/// Centralized service for handling all app initialization tasks
/// Includes .env loading, Firebase, Supabase, and Google Ads setup
class AppInitializationService {
  static bool _isInitialized = false;
  static String? _initializationError;

  /// Gets the initialization status
  static bool get isInitialized => _isInitialized;

  /// Gets any initialization error
  static String? get initializationError => _initializationError;

  /// Initialize all app services
  static Future<bool> initialize() async {
    if (_isInitialized) {
      AppLogger.info('🔄 App already initialized, skipping...', tag: 'AppInit');
      return true;
    }

    AppLogger.info('🚀 Starting AssetCraft AI initialization', tag: 'AppInit');

    try {
      // Step 1: Load environment configuration
      await _loadEnvironmentConfig();

      // Step 2: Set system UI preferences
      await _configureSystemUI();

      // Step 3: Initialize Supabase (primary backend)
      await _initializeSupabase();

      // Step 4: Initialize OneSignal (skip Firebase since using OneSignal)
      await _initializeOneSignal();

      // Step 5: Initialize Google Mobile Ads (when ready)
      // await _initializeMobileAds();

      // Step 6: Validate configuration
      await _validateConfiguration();

      _isInitialized = true;
      _initializationError = null;

      AppLogger.success(
        '🎉 All services initialized successfully',
        tag: 'AppInit',
      );
      return true;
    } catch (e, stackTrace) {
      _initializationError = e.toString();
      AppLogger.error(
        '❌ Failed to initialize services: ${e.toString()}',
        tag: 'AppInit',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Load environment configuration from .env file
  static Future<void> _loadEnvironmentConfig() async {
    try {
      AppLogger.info('📄 Loading environment configuration...', tag: 'AppInit');

      // Load the .env file
      await dotenv.load(fileName: ".env");

      AppLogger.success(
        '✅ Environment configuration loaded successfully',
        tag: 'AppInit',
      );

      // Log environment info (without sensitive data)
      AppLogger.info(
        '🌍 Environment: ${AppConfig.environment}',
        tag: 'AppInit',
      );
      AppLogger.info('🌐 API URL: ${AppConfig.apiUrl}', tag: 'AppInit');
      AppLogger.info(
        '🤖 AI Models: Configured in Edge Functions',
        tag: 'AppInit',
      );

      // Print config summary in debug mode
      if (kDebugMode) {
        AppConfig.printConfigSummary();
      }
    } catch (e) {
      AppLogger.warning(
        '⚠️ Could not load .env file, using default configuration',
        tag: 'AppInit',
      );
      // Continue with default configuration if .env is not found
    }
  }

  /// Configure system UI overlay style and orientations
  static Future<void> _configureSystemUI() async {
    AppLogger.info('🎨 Configuring system UI...', tag: 'AppInit');

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    AppLogger.success('✅ System UI configured successfully', tag: 'AppInit');
  }

  /// Initialize OneSignal for push notifications
  static Future<void> _initializeOneSignal() async {
    AppLogger.info('� Initializing OneSignal...', tag: 'AppInit');

    // For now, just log that OneSignal would be initialized
    // When OneSignal package is added, this will be:
    // await OneSignal.shared.setAppId(AppConfig.oneSignalAppId);

    AppLogger.info(
      'OneSignal App ID: ${AppConfig.oneSignalAppId}',
      tag: 'AppInit',
    );
    AppLogger.success('✅ OneSignal configuration ready', tag: 'AppInit');
  }

  /// Initialize Supabase with environment configuration
  static Future<void> _initializeSupabase() async {
    AppLogger.info('🗄️ Initializing Supabase...', tag: 'AppInit');

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    AppLogger.success('✅ Supabase initialized successfully', tag: 'AppInit');
  }

  /// Validate that all required configuration is present
  static Future<void> _validateConfiguration() async {
    AppLogger.info('✅ Validating configuration...', tag: 'AppInit');

    final requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];

    final optionalEnvVars = [
      'VERTEX_AI_CREDENTIALS',
      'IMAGEN_MODEL',
      'GEMINI_API_KEY',
      'REVENUECAT_ANDROID_KEY',
    ];

    final missingVars = <String>[];
    for (final varName in requiredEnvVars) {
      if (AppConfig.getEnvVar(varName).isEmpty) {
        missingVars.add(varName);
      }
    }

    if (missingVars.isNotEmpty) {
      AppLogger.warning(
        '⚠️ Missing required environment variables: ${missingVars.join(', ')}',
        tag: 'AppInit',
      );
      AppLogger.warning(
        '⚠️ App will use default configuration',
        tag: 'AppInit',
      );
    } else {
      AppLogger.success(
        '✅ All required configuration is present',
        tag: 'AppInit',
      );
    }

    // Check optional configurations
    final missingOptional = <String>[];
    for (final varName in optionalEnvVars) {
      if (AppConfig.getEnvVar(varName).isEmpty) {
        missingOptional.add(varName);
      }
    }

    if (missingOptional.isNotEmpty) {
      AppLogger.info(
        '💡 Optional configurations not set: ${missingOptional.join(', ')}',
        tag: 'AppInit',
      );
    }

    // Log specific service availability
    AppLogger.info('🔧 Service Configuration:', tag: 'AppInit');
    AppLogger.info(
      '   Vertex AI: ${AppConfig.hasVertexAiCredentials ? "✅ Configured" : "❌ Not configured"}',
      tag: 'AppInit',
    );
    AppLogger.info(
      '   RevenueCat Android: ${AppConfig.hasRevenueCatAndroid ? "✅ Configured" : "❌ Not configured"}',
      tag: 'AppInit',
    );
    AppLogger.info('   AI Models: Managed in Edge Functions', tag: 'AppInit');
  }

  /// Get environment variable with optional default value
  static String getEnvVar(String key, {String? defaultValue}) {
    return AppConfig.getEnvVar(key, defaultValue: defaultValue ?? '');
  }

  /// Check if a feature flag is enabled
  static bool isFeatureEnabled(String featureName) {
    return AppConfig.isFeatureEnabled(featureName);
  }

  /// Get the current environment (development, staging, production)
  static String get environment => AppConfig.environment;

  /// Check if debug mode is enabled
  static bool get isDebugMode => kDebugMode;

  /// Reset initialization state (for testing purposes)
  static void reset() {
    _isInitialized = false;
    _initializationError = null;
  }
}
