import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// AppConfig
///
/// Centralized configuration class for accessing environment variables
/// and app-wide settings loaded from .env file
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // Environment Configuration
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  // API URLs
  static String get devApiUrl =>
      dotenv.env['DEV_API_URL'] ?? 'http://localhost:3000';

  static String get stagingApiUrl =>
      dotenv.env['STAGING_API_URL'] ?? 'https://staging-api.assetcraft.ai';

  static String get prodApiUrl =>
      dotenv.env['PROD_API_URL'] ?? 'https://api.assetcraft.ai';

  // Get the appropriate API URL based on environment
  static String get apiUrl {
    switch (environment) {
      case 'development':
        return devApiUrl;
      case 'staging':
        return stagingApiUrl;
      case 'production':
        return prodApiUrl;
      default:
        return devApiUrl;
    }
  }

  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://rmtqskaeyetecgpckrsg.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtdHFza2FleWV0ZWNncGNrcnNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0OTE2MjMsImV4cCI6MjA3MTA2NzYyM30.OwhEB_FO-l34M9hpTxhXgrW93RmxKzfiBFekO4EJID8';

  // OneSignal Configuration
  static String get oneSignalAppId =>
      dotenv.env['ONESIGNAL_APP_ID'] ?? '06a29e91-92c0-4374-8ff4-de51062ae4f5';

  // Google AI Configuration (Gemini)
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyDauJ27wFYUpR0b7DTV_pnp0bzosGuv0cM';

  static String get geminiTextModel =>
      dotenv.env['GEMINI_TEXT_MODEL'] ?? 'gemini-1.5-flash';

  static String get geminiSuggestionsModel =>
      dotenv.env['GEMINI_SUGGESTIONS_MODEL'] ?? 'gemini-1.5-flash';

  // Vertex AI Configuration (for image generation)
  static String get vertexAiCredentials =>
      dotenv.env['VERTEX_AI_CREDENTIALS'] ?? '';

  static String get imagenModel =>
      dotenv.env['IMAGEN_MODEL'] ?? 'imagen-4.0-generate-001';

  // RevenueCat Configuration
  static String get revenueCatIosKey => dotenv.env['REVENUECAT_IOS_KEY'] ?? '';

  static String get revenueCatAndroidKey =>
      dotenv.env['REVENUECAT_ANDROID_KEY'] ?? '';

  // Paddle Configuration
  static String get paddleVendorId => dotenv.env['PADDLE_VENDOR_ID'] ?? '';

  static String get paddleApiKey => dotenv.env['PADDLE_API_KEY'] ?? '';

  // Helper methods
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';
  static bool get isDebugMode => isDevelopment;

  // Feature flags and debug settings
  static bool get enableDebugLogging =>
      isFeatureEnabled('ENABLE_DEBUG_LOGGING') || isDevelopment;

  static bool get enableAnalytics =>
      isFeatureEnabled('ENABLE_ANALYTICS') && isProduction;

  // Check if services are configured
  static bool get hasVertexAiCredentials => vertexAiCredentials.isNotEmpty;
  static bool get hasRevenueCatIos => revenueCatIosKey.isNotEmpty;
  static bool get hasRevenueCatAndroid => revenueCatAndroidKey.isNotEmpty;
  static bool get hasPaddleConfig =>
      paddleVendorId.isNotEmpty && paddleApiKey.isNotEmpty;

  /// Get a custom environment variable
  static String getEnvVar(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }

  /// Check if a feature is enabled (looks for 'true' value)
  static bool isFeatureEnabled(String featureName) {
    return dotenv.env[featureName]?.toLowerCase() == 'true';
  }

  /// Get all environment variables (for debugging - be careful with sensitive data)
  static Map<String, String> getAllEnvVars() {
    return Map<String, String>.from(dotenv.env);
  }

  /// Print configuration summary (without sensitive data)
  static void printConfigSummary() {
    AppLogger.info('🔧 AppConfig Summary:', tag: 'AppConfig');
    AppLogger.info('   Environment: $environment', tag: 'AppConfig');
    AppLogger.info('   API URL: $apiUrl', tag: 'AppConfig');
    AppLogger.info('   Imagen Model: $imagenModel', tag: 'AppConfig');
    AppLogger.info('   Gemini Model: $geminiTextModel', tag: 'AppConfig');
    AppLogger.info(
      '   Has Vertex AI Credentials: $hasVertexAiCredentials',
      tag: 'AppConfig',
    );
    AppLogger.info(
      '   Has RevenueCat iOS: $hasRevenueCatIos',
      tag: 'AppConfig',
    );
    AppLogger.info(
      '   Has RevenueCat Android: $hasRevenueCatAndroid',
      tag: 'AppConfig',
    );
    AppLogger.info('   Has Paddle Config: $hasPaddleConfig', tag: 'AppConfig');
  }
}
