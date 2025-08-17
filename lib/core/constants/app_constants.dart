/// App-wide constants for AssetCraft AI
class AppConstants {
  // App Info
  static const String appName = 'AssetCraft AI';
  static const String appTagline = 'Create. Design. Build.';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY'; // To be replaced
  static const String supabaseUrl = 'YOUR_SUPABASE_URL'; // To be replaced
  static const String supabaseAnonKey =
      'YOUR_SUPABASE_ANON_KEY'; // To be replaced

  // RevenueCat Configuration
  static const String revenueCatApiKey =
      'YOUR_REVENUECAT_KEY'; // To be replaced

  // Credit System
  static const int freeDailyCredits = 5;
  static const int starterPackCredits = 25;
  static const int creatorPackCredits = 75;
  static const int proPackCredits = 200;

  // Pricing (in USD cents)
  static const int starterPackPrice = 299; // $2.99
  static const int creatorPackPrice = 799; // $7.99
  static const int proPackPrice = 1999; // $19.99
  static const int premiumMonthlyPrice = 999; // $9.99

  // Product IDs for RevenueCat
  static const String starterPackId = 'starter_pack_25';
  static const String creatorPackId = 'creator_pack_75';
  static const String proPackId = 'pro_pack_200';
  static const String premiumMonthlyId = 'premium_monthly';

  // Asset Generation
  static const int maxPromptLength = 500;
  static const List<String> supportedFormats = ['PNG', 'JPG', 'SVG'];
  static const List<String> assetTypes = [
    'Character',
    'Environment',
    'UI Element',
    'Icon',
    'Texture',
    'Logo',
    'Background',
    'Object',
  ];

  // File Storage
  static const int maxFileSizeMB = 10;
  static const int maxAssetsPerUser = 1000;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Error Messages
  static const String noInternetError = 'No internet connection';
  static const String insufficientCreditsError = 'Insufficient credits';
  static const String generationFailedError = 'Asset generation failed';
  static const String loginRequiredError = 'Please log in to continue';

  // Success Messages
  static const String assetGeneratedSuccess = 'Asset generated successfully!';
  static const String assetSavedSuccess = 'Asset saved to library';
  static const String creditsAddedSuccess = 'Credits added to account';
}

/// Feature flags for development/testing
class FeatureFlags {
  static const bool enableMockAI = true; // Set to false for production
  static const bool enableAnalytics = false; // Enable for production
  static const bool enablePushNotifications = false;
  static const bool enableSocialSharing = true;
  static const bool enableOfflineMode = true;
}

/// Environment configuration
enum Environment { development, staging, production }

class EnvironmentConfig {
  static const Environment current = Environment.development;

  static bool get isDevelopment => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProduction => current == Environment.production;

  static String get baseUrl {
    switch (current) {
      case Environment.development:
        return 'https://dev-api.assetcraft.ai';
      case Environment.staging:
        return 'https://staging-api.assetcraft.ai';
      case Environment.production:
        return 'https://api.assetcraft.ai';
    }
  }
}
