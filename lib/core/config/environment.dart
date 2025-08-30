import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_logger.dart';

/// Environment configuration for AssetCraft AI
/// This handles all environment variables and API keys from .env files
class Environment {
  /// Initialize environment from .env files
  static Future<void> initialize() async {
    try {
      // Always load the main .env file (this is what you modify)
      await dotenv.load(fileName: '.env');
      AppLogger.safePrint('✅ Loaded environment from .env');
    } catch (e) {
      AppLogger.safePrint('❌ Could not load .env file: $e');
    }
  }

  /// Environment stages
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  /// Current environment stage
  static String get currentStage =>
      dotenv.get('ENVIRONMENT', fallback: 'production');

  /// Environment checks
  static bool get isDevelopment => currentStage == development;
  static bool get isStaging => currentStage == staging;
  static bool get isProduction => currentStage == production;

  /// Base API URLs per environment
  static String get baseApiUrl {
    switch (currentStage) {
      case development:
        return dotenv.get(
          'DEV_API_URL',
          fallback: 'https://dev-api.assetcraft.ai',
        );
      case staging:
        return dotenv.get(
          'STAGING_API_URL',
          fallback: 'https://staging-api.assetcraft.ai',
        );
      case production:
      default:
        return dotenv.get(
          'PROD_API_URL',
          fallback: 'https://api.assetcraft.ai',
        );
    }
  }

  // API Keys from .env files
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  static String get revenueCatApiKey =>
      dotenv.get('REVENUECAT_API_KEY', fallback: '');
  static String get oneSignalAppId =>
      dotenv.get('ONESIGNAL_APP_ID', fallback: '');
  static String get geminiApiKey => dotenv.get('GEMINI_API_KEY', fallback: '');
  static String get paddleVendorId =>
      dotenv.get('PADDLE_VENDOR_ID', fallback: '');
  static String get paddleApiKey => dotenv.get('PADDLE_API_KEY', fallback: '');

  // Gemini AI Model Configuration
  static String get geminiTextModel =>
      dotenv.get('GEMINI_TEXT_MODEL', fallback: 'gemini-1.5-flash');
  static String get geminiSuggestionsModel =>
      dotenv.get('GEMINI_SUGGESTIONS_MODEL', fallback: 'gemini-1.5-flash');

  // Google Cloud Imagen Configuration
  static String get googleCloudProjectId =>
      dotenv.get('GOOGLE_CLOUD_PROJECT_ID', fallback: '');
  static String get googleCloudApiKey =>
      dotenv.get('GOOGLE_CLOUD_API_KEY', fallback: '');
  static String get imagenModel =>
      dotenv.get('IMAGEN_MODEL', fallback: 'imagen-3.0-generate-001');

  // Validation methods
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static bool get hasRevenueCatConfig => revenueCatApiKey.isNotEmpty;
  static bool get hasOneSignalConfig => oneSignalAppId.isNotEmpty;
  static bool get hasGeminiConfig => geminiApiKey.isNotEmpty;
  static bool get hasGoogleCloudConfig =>
      googleCloudProjectId.isNotEmpty && googleCloudApiKey.isNotEmpty;
  static bool get hasPaddleConfig =>
      paddleVendorId.isNotEmpty && paddleApiKey.isNotEmpty;

  /// Feature flags from .env files

  // 🧪 SMART MOCK SYSTEM
  // Development = Mock by default, Production = Real by default
  // But you can override with FORCE_MOCK_* variables

  static bool get enableMockAI {
    final forceOverride = dotenv.get('FORCE_MOCK_AI', fallback: '');
    if (forceOverride.isNotEmpty) {
      return forceOverride.toLowerCase() == 'true';
    }
    // Default: Development = true, Production = false
    return isDevelopment;
  }

  static bool get enableMockStore {
    final forceOverride = dotenv.get('FORCE_MOCK_STORE', fallback: '');
    if (forceOverride.isNotEmpty) {
      return forceOverride.toLowerCase() == 'true';
    }
    // Default: Development = true, Production = false
    return isDevelopment;
  }

  static bool get enableMockAuth {
    final forceOverride = dotenv.get('FORCE_MOCK_AUTH', fallback: '');
    if (forceOverride.isNotEmpty) {
      return forceOverride.toLowerCase() == 'true';
    }
    // Default: Development = true, Production = false
    return isDevelopment;
  }

  static bool get enableMockNotifications {
    final forceOverride = dotenv.get('FORCE_MOCK_NOTIFICATIONS', fallback: '');
    if (forceOverride.isNotEmpty) {
      return forceOverride.toLowerCase() == 'true';
    }
    // Default: Development = true, Production = false
    return isDevelopment;
  }

  static bool get enableMockStorage {
    final forceOverride = dotenv.get('FORCE_MOCK_STORAGE', fallback: '');
    if (forceOverride.isNotEmpty) {
      return forceOverride.toLowerCase() == 'true';
    }
    // Default: Development = true, Production = false
    return isDevelopment;
  }

  // Other feature flags
  static bool get enablePushNotifications =>
      dotenv.get('ENABLE_PUSH_NOTIFICATIONS', fallback: 'true').toLowerCase() ==
      'true';
  static bool get enableSocialSharing =>
      dotenv.get('ENABLE_SOCIAL_SHARING', fallback: 'true').toLowerCase() ==
      'true';
  static bool get enableOfflineMode =>
      dotenv.get('ENABLE_OFFLINE_MODE', fallback: 'true').toLowerCase() ==
      'true';
  static bool get enablePremiumFeatures =>
      dotenv.get('ENABLE_PREMIUM_FEATURES', fallback: 'true').toLowerCase() ==
      'true';
  static bool get enableAds =>
      dotenv.get('ENABLE_ADS', fallback: 'false').toLowerCase() == 'true';
  static bool get enableAnalytics =>
      dotenv.get('ENABLE_ANALYTICS', fallback: 'true').toLowerCase() == 'true';
  static bool get enableSplashScreen =>
      dotenv.get('ENABLE_SPLASH_SCREEN', fallback: 'true').toLowerCase() ==
      'true';
  static bool get skipAuthentication =>
      dotenv.get('SKIP_AUTHENTICATION', fallback: 'false').toLowerCase() ==
      'true';

  /// Debug helper
  static void printConfig() {
    // Only print config in development to reduce startup overhead
    if (!isDevelopment) return;

    AppLogger.debug('🔧 Environment Configuration:');
    AppLogger.debug('  🎯 Stage: $currentStage');
    AppLogger.debug('  🌐 API URL: $baseApiUrl');
    AppLogger.debug('  🔑 Supabase: ${hasSupabaseConfig ? "✅" : "❌"}');
    AppLogger.debug('  💰 RevenueCat: ${hasRevenueCatConfig ? "✅" : "❌"}');
    AppLogger.debug('  🔔 OneSignal: ${hasOneSignalConfig ? "✅" : "❌"}');
    AppLogger.debug('  🤖 Gemini: ${hasGeminiConfig ? "✅" : "❌"}');
    AppLogger.debug('  ☁️ Google Cloud: ${hasGoogleCloudConfig ? "✅" : "❌"}');
    AppLogger.debug('  🏪 Paddle: ${hasPaddleConfig ? "✅" : "❌"}');
    AppLogger.debug('  🧪 Mock AI: ${enableMockAI ? "✅" : "❌"}');
    AppLogger.debug('  🧪 Mock Store: ${enableMockStore ? "✅" : "❌"}');
    AppLogger.debug('  🧪 Mock Auth: ${enableMockAuth ? "✅" : "❌"}');
    AppLogger.debug(
      '  🧪 Mock Notifications: ${enableMockNotifications ? "✅" : "❌"}',
    );
    AppLogger.debug('  🧪 Mock Storage: ${enableMockStorage ? "✅" : "❌"}');
    AppLogger.debug('  📊 Analytics: ${enableAnalytics ? "✅" : "❌"}');
  }

  /// Get status for UI display
  static String get environmentStatus {
    return isDevelopment ? '🔧 DEV' : '🚀 PROD';
  }

  static String get mockStatus {
    List<String> mocks = [];
    if (enableMockAI) mocks.add('AI');
    if (enableMockStore) mocks.add('Store');
    if (enableMockAuth) mocks.add('Auth');
    if (enableMockNotifications) mocks.add('Notif');
    if (enableMockStorage) mocks.add('Storage');

    if (mocks.isEmpty) return '🔴 Real Data';
    return '🧪 Mock: ${mocks.join(', ')}';
  }
}
