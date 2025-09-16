import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class AppConfig {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  // Initialize the configuration
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      _logger.i('🔧 Environment configuration loaded successfully');
    } catch (e) {
      _logger.e('❌ Failed to load environment configuration: $e');
      throw Exception('Failed to load environment configuration');
    }
  }

  // Supabase Configuration
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      _logger.e('❌ SUPABASE_URL not found in environment');
      throw Exception('SUPABASE_URL not configured');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      _logger.e('❌ SUPABASE_ANON_KEY not found in environment');
      throw Exception('SUPABASE_ANON_KEY not configured');
    }
    return key;
  }

  // Environment Configuration
  static String get environment {
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }

  static bool get isProduction {
    return environment.toLowerCase() == 'production';
  }

  static bool get isDevelopment {
    return environment.toLowerCase() == 'development';
  }

  static bool get isStaging {
    return environment.toLowerCase() == 'staging';
  }

  // API Configuration
  static String get apiUrl {
    switch (environment.toLowerCase()) {
      case 'production':
        return dotenv.env['PROD_API_URL'] ?? 'https://api.assetcraft.ai';
      case 'staging':
        return dotenv.env['STAGING_API_URL'] ??
            'https://staging-api.assetcraft.ai';
      default:
        return dotenv.env['DEV_API_URL'] ?? 'http://localhost:3000';
    }
  }

  // AI Configuration
  static String get geminiApiKey {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  static String get geminiTextModel {
    return dotenv.env['GEMINI_TEXT_MODEL'] ?? 'gemini-1.5-flash';
  }

  static String get geminiSuggestionsModel {
    return dotenv.env['GEMINI_SUGGESTIONS_MODEL'] ?? 'gemini-1.5-flash';
  }

  static String get imagenModel {
    return dotenv.env['IMAGEN_MODEL'] ?? 'imagen-4.0-generate-001';
  }

  // OneSignal Configuration
  static String get oneSignalAppId {
    return dotenv.env['ONESIGNAL_APP_ID'] ?? '';
  }

  // Revenue Configuration
  static String get revenueCatIosKey {
    return dotenv.env['REVENUECAT_IOS_KEY'] ?? '';
  }

  static String get revenueCatAndroidKey {
    return dotenv.env['REVENUECAT_ANDROID_KEY'] ?? '';
  }

  static String get paddleVendorId {
    return dotenv.env['PADDLE_VENDOR_ID'] ?? '';
  }

  static String get paddleApiKey {
    return dotenv.env['PADDLE_API_KEY'] ?? '';
  }

  // Debug helper
  static void logConfiguration() {
    if (isDevelopment) {
      _logger.d('🔧 App Configuration:');
      _logger.d('   Environment: $environment');
      _logger.d('   API URL: $apiUrl');
      _logger.d('   Supabase URL: ${supabaseUrl.substring(0, 20)}...');
      _logger.d('   Is Production: $isProduction');
    }
  }
}
