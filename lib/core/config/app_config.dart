import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AppConfig
///
/// Centralized configuration class for accessing environment variables
/// and app-wide settings loaded from .env file
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://rmtqskaeyetecgpckrsg.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtdHFza2FleWV0ZWNncGNrcnNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0OTE2MjMsImV4cCI6MjA3MTA2NzYyM30.OwhEB_FO-l34M9hpTxhXgrW93RmxKzfiBFekO4EJID8';

  // Vertex AI Configuration
  static String get vertexAiProjectId =>
      dotenv.env['VERTEX_AI_PROJECT_ID'] ?? 'your-project-id';

  static String get vertexAiRegion =>
      dotenv.env['VERTEX_AI_REGION'] ?? 'us-central1';

  static String get imagenModel =>
      dotenv.env['IMAGEN_MODEL'] ?? 'imagen-3.0-generate-001';

  // Google Ads Configuration
  static String get googleAdsAppIdAndroid =>
      dotenv.env['GOOGLE_ADS_APP_ID_ANDROID'] ??
      'ca-app-pub-3940256099942544~3347511713';

  static String get googleAdsAppIdIos =>
      dotenv.env['GOOGLE_ADS_APP_ID_IOS'] ??
      'ca-app-pub-3940256099942544~1458002511';

  static String get googleAdsBannerUnitIdAndroid =>
      dotenv.env['GOOGLE_ADS_BANNER_UNIT_ID_ANDROID'] ??
      'ca-app-pub-3940256099942544/6300978111';

  static String get googleAdsBannerUnitIdIos =>
      dotenv.env['GOOGLE_ADS_BANNER_UNIT_ID_IOS'] ??
      'ca-app-pub-3940256099942544/2934735716';

  static String get googleAdsInterstitialUnitIdAndroid =>
      dotenv.env['GOOGLE_ADS_INTERSTITIAL_UNIT_ID_ANDROID'] ??
      'ca-app-pub-3940256099942544/1033173712';

  static String get googleAdsInterstitialUnitIdIos =>
      dotenv.env['GOOGLE_ADS_INTERSTITIAL_UNIT_ID_IOS'] ??
      'ca-app-pub-3940256099942544/4411468910';

  static String get googleAdsRewardedUnitIdAndroid =>
      dotenv.env['GOOGLE_ADS_REWARDED_UNIT_ID_ANDROID'] ??
      'ca-app-pub-3940256099942544/5224354917';

  static String get googleAdsRewardedUnitIdIos =>
      dotenv.env['GOOGLE_ADS_REWARDED_UNIT_ID_IOS'] ??
      'ca-app-pub-3940256099942544/1712485313';

  // RevenueCat Configuration
  static String get revenueCatApiKeyAndroid =>
      dotenv.env['REVENUECAT_API_KEY_ANDROID'] ?? 'your-android-api-key';

  static String get revenueCatApiKeyIos =>
      dotenv.env['REVENUECAT_API_KEY_IOS'] ?? 'your-ios-api-key';

  // OneSignal Configuration
  static String get oneSignalAppId =>
      dotenv.env['ONESIGNAL_APP_ID'] ?? '06a29e91-92c0-4374-8ff4-de51062ae4f5';

  // Google AI Configuration
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyDauJ27wFYUpR0b7DTV_pnp0bzosGuv0cM';

  static String get geminiTextModel =>
      dotenv.env['GEMINI_TEXT_MODEL'] ?? 'gemini-1.5-flash';

  // App Configuration
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  // Feature Flags
  static bool get enableDebugLogging =>
      dotenv.env['ENABLE_DEBUG_LOGGING']?.toLowerCase() == 'true';

  static bool get enableAnalytics =>
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';

  static bool get enableCrashlytics =>
      dotenv.env['ENABLE_CRASHLYTICS']?.toLowerCase() == 'true';

  static bool get enablePremiumFeatures =>
      dotenv.env['ENABLE_PREMIUM_FEATURES']?.toLowerCase() == 'true';

  static bool get enableCommunityGallery =>
      dotenv.env['ENABLE_COMMUNITY_GALLERY']?.toLowerCase() == 'true';

  static bool get enableSocialSharing =>
      dotenv.env['ENABLE_SOCIAL_SHARING']?.toLowerCase() == 'true';

  static bool get enableOfflineMode =>
      dotenv.env['ENABLE_OFFLINE_MODE']?.toLowerCase() == 'true';

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

  // Helper methods
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  /// Get a custom environment variable
  static String getEnvVar(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }

  /// Check if a feature is enabled
  static bool isFeatureEnabled(String featureName) {
    return dotenv.env[featureName]?.toLowerCase() == 'true';
  }

  /// Get all environment variables (for debugging)
  static Map<String, String> getAllEnvVars() {
    return Map<String, String>.from(dotenv.env);
  }

  /// Print configuration summary (without sensitive data)
  static void printConfigSummary() {
    print('🔧 AppConfig Summary:');
    print('   Environment: $environment');
    print('   App Version: $appVersion');
    print('   Debug Logging: $enableDebugLogging');
    print('   Analytics: $enableAnalytics');
    print('   Premium Features: $enablePremiumFeatures');
    print('   Community Gallery: $enableCommunityGallery');
    print('   API URL: $apiUrl');
  }
}
