import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_logger.dart';

/// Environment configuration for AssetCraft AI
/// Handles all environment variables and configuration settings
class Environment {
  static bool _isInitialized = false;

  /// Initialize environment configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load(fileName: '.env');
      AppLogger.info('✅ Environment configuration loaded');
    } catch (e) {
      AppLogger.warning('⚠️ Could not load .env file: $e');
      AppLogger.info('📝 Using default configuration values');
    }

    _isInitialized = true;
  }

  /// Environment stages
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  /// Current environment stage
  static String get currentStage => _getString('ENVIRONMENT', 'development');

  /// Environment checks
  static bool get isDevelopment => currentStage == development;
  static bool get isStaging => currentStage == staging;
  static bool get isProduction => currentStage == production;

  // ===== API Configuration =====

  /// Gemini AI API Key
  static String get geminiApiKey => _getString('GEMINI_API_KEY', '');

  /// Supabase URL
  static String get supabaseUrl => _getString('SUPABASE_URL', '');

  /// Supabase Anonymous Key
  static String get supabaseAnonKey => _getString('SUPABASE_ANON_KEY', '');

  /// OneSignal App ID
  static String get oneSignalAppId => _getString('ONESIGNAL_APP_ID', '');

  /// RevenueCat API Key (Android)
  static String get revenueCatAndroidKey =>
      _getString('REVENUECAT_ANDROID_KEY', '');

  /// RevenueCat API Key (iOS)
  static String get revenueCatIosKey => _getString('REVENUECAT_IOS_KEY', '');

  /// Google Mobile Ads App ID (Android)
  static String get admobAndroidAppId => _getString('ADMOB_ANDROID_APP_ID', '');

  /// Google Mobile Ads App ID (iOS)
  static String get admobIosAppId => _getString('ADMOB_IOS_APP_ID', '');

  // ===== Feature Flags =====

  /// Enable mock mode (for development/testing)
  static bool get enableMockMode => _getBool('ENABLE_MOCK_MODE', false);

  /// Enable mock AI generation
  static bool get enableMockAI => _getBool('ENABLE_MOCK_AI', false);

  /// Enable mock storage
  static bool get enableMockStorage => _getBool('ENABLE_MOCK_STORAGE', false);

  /// Enable mock store/purchases
  static bool get enableMockStore => _getBool('ENABLE_MOCK_STORE', false);

  /// Enable mock notifications
  static bool get enableMockNotifications =>
      _getBool('ENABLE_MOCK_NOTIFICATIONS', false);

  /// Enable mock authentication
  static bool get enableMockAuth => _getBool('ENABLE_MOCK_AUTH', false);

  /// Show mock indicator in UI
  static bool get showMockIndicator => _getBool('SHOW_MOCK_INDICATOR', false);

  /// Enable debug logging
  static bool get enableDebugLogging =>
      _getBool('ENABLE_DEBUG_LOGGING', kDebugMode);

  // ===== App Configuration =====

  /// Maximum generation attempts
  static int get maxGenerationAttempts => _getInt('MAX_GENERATION_ATTEMPTS', 3);

  /// Maximum assets per generation
  static int get maxAssetsPerGeneration =>
      _getInt('MAX_ASSETS_PER_GENERATION', 10);

  /// API timeout in seconds
  static int get apiTimeoutSeconds => _getInt('API_TIMEOUT_SECONDS', 30);

  /// Enable analytics
  static bool get enableAnalytics => _getBool('ENABLE_ANALYTICS', isProduction);

  /// Enable crash reporting
  static bool get enableCrashReporting =>
      _getBool('ENABLE_CRASH_REPORTING', isProduction);

  // ===== Validation Methods =====

  /// Check if Gemini AI is properly configured
  static bool get hasGeminiConfig => geminiApiKey.isNotEmpty;

  /// Check if Supabase is properly configured
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Check if OneSignal is properly configured
  static bool get hasOneSignalConfig => oneSignalAppId.isNotEmpty;

  /// Check if RevenueCat is properly configured
  static bool get hasRevenueCatConfig =>
      revenueCatAndroidKey.isNotEmpty || revenueCatIosKey.isNotEmpty;

  /// Check if AdMob is properly configured
  static bool get hasAdMobConfig =>
      admobAndroidAppId.isNotEmpty || admobIosAppId.isNotEmpty;

  // ===== Private Helper Methods =====

  /// Get string value from environment
  static String _getString(String key, String defaultValue) {
    if (!_isInitialized) {
      AppLogger.warning('Environment not initialized, using default for $key');
      return defaultValue;
    }
    return dotenv.get(key, fallback: defaultValue);
  }

  /// Get boolean value from environment
  static bool _getBool(String key, bool defaultValue) {
    if (!_isInitialized) {
      AppLogger.warning('Environment not initialized, using default for $key');
      return defaultValue;
    }
    final value = dotenv
        .get(key, fallback: defaultValue.toString())
        .toLowerCase();
    return value == 'true' || value == '1';
  }

  /// Get integer value from environment
  static int _getInt(String key, int defaultValue) {
    if (!_isInitialized) {
      AppLogger.warning('Environment not initialized, using default for $key');
      return defaultValue;
    }
    final value = dotenv.get(key, fallback: defaultValue.toString());
    return int.tryParse(value) ?? defaultValue;
  }

  // ===== Debug Methods =====

  /// Print environment configuration (debug mode only)
  static void printConfiguration() {
    if (!kDebugMode) return;

    AppLogger.debug('🔧 ========== ENVIRONMENT CONFIGURATION ==========');
    AppLogger.debug('📱 Environment: $currentStage');
    AppLogger.debug(
      '🤖 Gemini AI: ${hasGeminiConfig ? 'Configured' : 'Not configured'}',
    );
    AppLogger.debug(
      '🗄️ Supabase: ${hasSupabaseConfig ? 'Configured' : 'Not configured'}',
    );
    AppLogger.debug(
      '🔔 OneSignal: ${hasOneSignalConfig ? 'Configured' : 'Not configured'}',
    );
    AppLogger.debug(
      '💰 RevenueCat: ${hasRevenueCatConfig ? 'Configured' : 'Not configured'}',
    );
    AppLogger.debug(
      '📺 AdMob: ${hasAdMobConfig ? 'Configured' : 'Not configured'}',
    );
    AppLogger.debug('🧪 Mock Mode: $enableMockMode');
    AppLogger.debug('🧪 Mock AI: $enableMockAI');
    AppLogger.debug('🧪 Mock Storage: $enableMockStorage');
    AppLogger.debug('🧪 Mock Store: $enableMockStore');
    AppLogger.debug('🧪 Mock Notifications: $enableMockNotifications');
    AppLogger.debug('🧪 Mock Auth: $enableMockAuth');
    AppLogger.debug('👁️ Show Mock Indicator: $showMockIndicator');
    AppLogger.debug('🐛 Debug Logging: $enableDebugLogging');
    AppLogger.debug('🔧 =============================================');
  }
}

/// App configuration that combines environment and runtime settings
class AppConfig {
  /// Get the appropriate API base URL based on environment
  static String get apiBaseUrl {
    switch (Environment.currentStage) {
      case Environment.development:
        return 'https://dev-api.assetcraft.ai';
      case Environment.staging:
        return 'https://staging-api.assetcraft.ai';
      case Environment.production:
      default:
        return 'https://api.assetcraft.ai';
    }
  }

  /// Get API timeout duration
  static Duration get apiTimeout =>
      Duration(seconds: Environment.apiTimeoutSeconds);

  /// Check if app is in mock mode
  static bool get isMockMode => Environment.enableMockMode || kDebugMode;

  /// Check if features should use mock implementations
  static bool get shouldUseMockAI =>
      Environment.enableMockAI || !Environment.hasGeminiConfig;
  static bool get shouldUseMockStorage => Environment.enableMockStorage;
  static bool get shouldUseMockStore =>
      Environment.enableMockStore || !Environment.hasRevenueCatConfig;
  static bool get shouldUseMockNotifications =>
      Environment.enableMockNotifications || !Environment.hasOneSignalConfig;
  static bool get shouldUseMockAuth =>
      Environment.enableMockAuth || !Environment.hasSupabaseConfig;

  /// Check if services are available
  static bool get isGeminiAvailable =>
      Environment.hasGeminiConfig && !shouldUseMockAI;
  static bool get isSupabaseAvailable =>
      Environment.hasSupabaseConfig && !shouldUseMockAuth;
  static bool get isOneSignalAvailable =>
      Environment.hasOneSignalConfig && !shouldUseMockNotifications;
  static bool get isRevenueCatAvailable =>
      Environment.hasRevenueCatConfig && !shouldUseMockStore;
  static bool get isAdMobAvailable => Environment.hasAdMobConfig;
}
