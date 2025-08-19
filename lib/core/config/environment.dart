import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_logger.dart';

/// Environment configuration for AssetCraft AI
/// This handles all environment variables and API keys from .env files
class Environment {
  /// Initialize environment from .env files
  static Future<void> initialize() async {
    // Determine which .env file to load based on environment
    String envFile = '.env'; // default

    // Check if specific environment is set
    const String envStage = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'production',
    );

    switch (envStage) {
      case 'development':
        envFile = '.env.development';
        break;
      case 'staging':
        envFile = '.env.staging';
        break;
      case 'production':
      default:
        envFile = '.env.production';
        break;
    }

    try {
      await dotenv.load(fileName: envFile);
      // Use safePrint during initialization since AppLogger might not be ready
      AppLogger.safePrint('✅ Loaded environment from $envFile');
    } catch (e) {
      AppLogger.safePrint('⚠️ Could not load $envFile, falling back to .env');
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        AppLogger.safePrint('❌ Could not load .env file: $e');
      }
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
  static String get geminiImageModel => dotenv.get(
    'GEMINI_IMAGE_MODEL',
    fallback: 'gemini-2.0-flash-preview-image-generation',
  );
  static String get geminiSuggestionsModel =>
      dotenv.get('GEMINI_SUGGESTIONS_MODEL', fallback: 'gemini-1.5-flash');

  // Validation methods
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static bool get hasRevenueCatConfig => revenueCatApiKey.isNotEmpty;
  static bool get hasOneSignalConfig => oneSignalAppId.isNotEmpty;
  static bool get hasGeminiConfig => geminiApiKey.isNotEmpty;
  static bool get hasPaddleConfig =>
      paddleVendorId.isNotEmpty && paddleApiKey.isNotEmpty;

  /// Feature flags from .env files
  static bool get enableMockAI =>
      dotenv.get('ENABLE_MOCK_AI', fallback: 'false').toLowerCase() == 'true';
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
      dotenv.get('ENABLE_ADS', fallback: 'true').toLowerCase() == 'true';
  static bool get enableAnalytics =>
      dotenv.get('ENABLE_ANALYTICS', fallback: 'false').toLowerCase() == 'true';
  static bool get enableSplashScreen =>
      dotenv.get('ENABLE_SPLASH_SCREEN', fallback: 'true').toLowerCase() ==
      'true';
  static bool get skipAuthentication =>
      dotenv.get('SKIP_AUTHENTICATION', fallback: 'false').toLowerCase() ==
      'true';

  /// Debug helper
  static void printConfig() {
    if (isDevelopment) {
      AppLogger.debug('🔧 Environment Configuration:');
      AppLogger.debug('  Stage: $currentStage');
      AppLogger.debug('  API URL: $baseApiUrl');
      AppLogger.debug('  Supabase: ${hasSupabaseConfig ? "✅" : "❌"}');
      AppLogger.debug('  RevenueCat: ${hasRevenueCatConfig ? "✅" : "❌"}');
      AppLogger.debug('  OneSignal: ${hasOneSignalConfig ? "✅" : "❌"}');
      AppLogger.debug('  Gemini: ${hasGeminiConfig ? "✅" : "❌"}');
      AppLogger.debug('  Paddle: ${hasPaddleConfig ? "✅" : "❌"}');
      AppLogger.debug('  Mock AI: $enableMockAI');
      AppLogger.debug('  Push Notifications: $enablePushNotifications');
      AppLogger.debug('  Analytics: $enableAnalytics');
    }
  }
}
