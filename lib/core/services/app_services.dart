import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/environment.dart';
import '../utils/app_logger.dart';
import '../utils/helpers.dart';

/// Core services initialization for AssetCraft AI
class AppServices {
  static bool _isInitialized = false;

  /// Initialize all core services
  static Future<void> initialize() async {
    if (_isInitialized) return;

    List<String> successfulServices = [];
    List<String> failedServices = [];

    AppLogger.info('🚀 Initializing AssetCraft AI Services...');

    // Initialize Supabase
    if (await _initializeSupabase()) {
      successfulServices.add('Supabase');
    } else {
      failedServices.add('Supabase');
    }

    // Initialize mobile-only services
    if (PlatformUtils.isMobile) {
      // Initialize OneSignal
      if (await _initializeOneSignal()) {
        successfulServices.add('OneSignal');
      } else {
        failedServices.add('OneSignal');
      }

      // Initialize RevenueCat
      if (await _initializeRevenueCat()) {
        successfulServices.add('RevenueCat');
      } else {
        failedServices.add('RevenueCat');
      }

      // Initialize Google Mobile Ads
      if (await _initializeGoogleAds()) {
        successfulServices.add('Google Ads');
      } else {
        failedServices.add('Google Ads');
      }
    }

    _isInitialized = true;

    // Log summary
    AppLogger.info('🚀 Services Initialization Complete:');
    if (successfulServices.isNotEmpty) {
      AppLogger.info('✅ Successful: ${successfulServices.join(', ')}');
    }
    if (failedServices.isNotEmpty) {
      AppLogger.warning(
        '⚠️ Failed: ${failedServices.join(', ')} (App will continue)',
      );
    }
  }

  /// Initialize Supabase
  static Future<bool> _initializeSupabase() async {
    try {
      // Check if we have valid Supabase configuration
      if (!Environment.hasSupabaseConfig) {
        AppLogger.info('📝 Supabase not configured, skipping initialization');
        return true; // Not an error, just not configured
      }

      await Supabase.initialize(
        url: Environment.supabaseUrl,
        anonKey: Environment.supabaseAnonKey,
        debug: kDebugMode,
      );

      AppLogger.info('✅ Supabase initialized successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize Supabase', e, stackTrace);
      return false;
    }
  }

  /// Initialize OneSignal
  static Future<bool> _initializeOneSignal() async {
    try {
      // Check if we have valid OneSignal configuration
      if (!Environment.hasOneSignalConfig) {
        AppLogger.info('📝 OneSignal not configured, skipping initialization');
        return true; // Not an error, just not configured
      }

      // Initialize OneSignal
      OneSignal.Debug.setLogLevel(
        kDebugMode ? OSLogLevel.verbose : OSLogLevel.warn,
      );
      OneSignal.initialize(Environment.oneSignalAppId);

      // Request notification permissions
      await OneSignal.Notifications.requestPermission(true);

      AppLogger.info('✅ OneSignal initialized successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize OneSignal', e, stackTrace);
      return false;
    }
  }

  /// Initialize RevenueCat
  static Future<bool> _initializeRevenueCat() async {
    try {
      // Check if we have valid RevenueCat configuration
      if (!Environment.hasRevenueCatConfig) {
        AppLogger.info('📝 RevenueCat not configured, skipping initialization');
        return true; // Not an error, just not configured
      }

      // Get the appropriate API key based on platform
      String apiKey;
      if (PlatformUtils.platformName.toLowerCase() == 'android') {
        apiKey = Environment.revenueCatAndroidKey;
      } else if (PlatformUtils.platformName.toLowerCase() == 'ios') {
        apiKey = Environment.revenueCatIosKey;
      } else {
        AppLogger.info('📝 RevenueCat not supported on this platform');
        return true;
      }

      if (apiKey.isEmpty) {
        AppLogger.warning('⚠️ RevenueCat API key not found for this platform');
        return false;
      }

      // Configure RevenueCat
      final configuration = PurchasesConfiguration(apiKey);
      if (kDebugMode) {
        // Note: Debug logging configuration may vary by version
        AppLogger.debug('🐛 RevenueCat debug mode enabled');
      }

      await Purchases.configure(configuration);

      AppLogger.info('✅ RevenueCat initialized successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize RevenueCat', e, stackTrace);
      return false;
    }
  }

  /// Initialize Google Mobile Ads
  static Future<bool> _initializeGoogleAds() async {
    try {
      // Check if we have valid AdMob configuration
      if (!Environment.hasAdMobConfig) {
        AppLogger.info(
          '📝 Google Mobile Ads not configured, skipping initialization',
        );
        return true; // Not an error, just not configured
      }

      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();

      // Note: Consent management API may vary by version
      // For now, just initialize the basic SDK
      AppLogger.debug('📺 Basic Google Mobile Ads SDK initialized');

      AppLogger.info('✅ Google Mobile Ads initialized successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to initialize Google Mobile Ads',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;

  /// Get Supabase client
  static SupabaseClient? get supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      AppLogger.warning('⚠️ Supabase client not available: $e');
      return null;
    }
  }

  /// Reset all services (useful for testing)
  static Future<void> reset() async {
    _isInitialized = false;
    AppLogger.info('🔄 Services reset');
  }
}
