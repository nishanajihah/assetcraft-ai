/// Environment configuration for AssetCraft AI
/// This handles all environment variables and API keys
class Environment {
  // Environment stage configuration
  static const String _environmentStage = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production', // Since we're on main branch for production
  );

  /// Environment stages
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  /// Current environment stage
  static String get currentStage => _environmentStage;

  /// Environment checks
  static bool get isDevelopment => _environmentStage == development;
  static bool get isStaging => _environmentStage == staging;
  static bool get isProduction => _environmentStage == production;

  /// Base API URLs per environment
  static String get baseApiUrl {
    switch (_environmentStage) {
      case development:
        return 'https://dev-api.assetcraft.ai';
      case staging:
        return 'https://staging-api.assetcraft.ai';
      case production:
      default:
        return 'https://api.assetcraft.ai';
    }
  }

  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'your_supabase_url_here',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your_supabase_anon_key_here',
  );

  static const String _revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'your_revenuecat_key_here',
  );

  static const String _oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'your_onesignal_app_id_here',
  );

  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'your_gemini_api_key_here',
  );

  static const String _paddleVendorId = String.fromEnvironment(
    'PADDLE_VENDOR_ID',
    defaultValue: 'your_paddle_vendor_id_here',
  );

  static const String _paddleApiKey = String.fromEnvironment(
    'PADDLE_API_KEY',
    defaultValue: 'your_paddle_api_key_here',
  );

  // Getters with validation
  static String get supabaseUrl {
    if (_supabaseUrl == 'your_supabase_url_here') {
      throw Exception('SUPABASE_URL not configured');
    }
    return _supabaseUrl;
  }

  static String get supabaseAnonKey {
    if (_supabaseAnonKey == 'your_supabase_anon_key_here') {
      throw Exception('SUPABASE_ANON_KEY not configured');
    }
    return _supabaseAnonKey;
  }

  static String get revenueCatApiKey {
    if (_revenueCatApiKey == 'your_revenuecat_key_here') {
      throw Exception('REVENUECAT_API_KEY not configured');
    }
    return _revenueCatApiKey;
  }

  static String get oneSignalAppId {
    if (_oneSignalAppId == 'your_onesignal_app_id_here') {
      throw Exception('ONESIGNAL_APP_ID not configured');
    }
    return _oneSignalAppId;
  }

  static String get geminiApiKey {
    if (_geminiApiKey == 'your_gemini_api_key_here') {
      throw Exception('GEMINI_API_KEY not configured');
    }
    return _geminiApiKey;
  }

  static String get paddleVendorId {
    if (_paddleVendorId == 'your_paddle_vendor_id_here') {
      throw Exception('PADDLE_VENDOR_ID not configured');
    }
    return _paddleVendorId;
  }

  static String get paddleApiKey {
    if (_paddleApiKey == 'your_paddle_api_key_here') {
      throw Exception('PADDLE_API_KEY not configured');
    }
    return _paddleApiKey;
  }

  // Safe getters for development (won't throw)
  static String get supabaseUrlSafe => _supabaseUrl;
  static String get supabaseAnonKeySafe => _supabaseAnonKey;
  static String get revenueCatApiKeySafe => _revenueCatApiKey;
  static String get oneSignalAppIdSafe => _oneSignalAppId;
  static String get geminiApiKeySafe => _geminiApiKey;
  static String get paddleVendorIdSafe => _paddleVendorId;
  static String get paddleApiKeySafe => _paddleApiKey;

  // Development flags
  static const bool enableSplashScreen = bool.fromEnvironment(
    'ENABLE_SPLASH',
    defaultValue: true,
  );
  static const bool skipAuthentication = bool.fromEnvironment(
    'SKIP_AUTH',
    defaultValue: false,
  );

  // Debug and logging flags
  static const bool enableDebugLogging = bool.fromEnvironment(
    'DEBUG_LOGGING',
    defaultValue: true,
  );
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false, // Disabled in development
  );

  /// Feature flags for development/testing and production
  static const bool enableMockAI = bool.fromEnvironment(
    'ENABLE_MOCK_AI',
    defaultValue: false, // Set to true for development/testing
  );

  static const bool enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: true, // Enable for production
  );

  static const bool enableSocialSharing = bool.fromEnvironment(
    'ENABLE_SOCIAL_SHARING',
    defaultValue: true,
  );

  static const bool enableOfflineMode = bool.fromEnvironment(
    'ENABLE_OFFLINE_MODE',
    defaultValue: true,
  );

  static const bool enablePremiumFeatures = bool.fromEnvironment(
    'ENABLE_PREMIUM_FEATURES',
    defaultValue: true,
  );

  static const bool enableAds = bool.fromEnvironment(
    'ENABLE_ADS',
    defaultValue: true,
  );
}
