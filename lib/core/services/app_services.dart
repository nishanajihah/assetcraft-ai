import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // Temporarily disabled
import '../config/environment.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';

/// Core services initialization for AssetCraft AI
class AppServices {
  static bool _isInitialized = false;

  /// Initialize all core services
  static Future<void> initialize() async {
    if (_isInitialized) return;

    List<String> successfulServices = [];
    List<String> failedServices = [];

    // Initialize Supabase
    if (await _initializeSupabase()) {
      successfulServices.add('Supabase');
    } else {
      failedServices.add('Supabase');
    }

    // Initialize RevenueCat (only on mobile)
    if (!kIsWeb) {
      if (await _initializeRevenueCat()) {
        successfulServices.add('RevenueCat');
      } else {
        failedServices.add('RevenueCat');
      }
    }

    // Initialize OneSignal (only on mobile)
    if (!kIsWeb) {
      if (await _initializeOneSignal()) {
        successfulServices.add('OneSignal');

        // Initialize notification service after OneSignal
        try {
          await NotificationService.instance.initialize();
          successfulServices.add('NotificationService');
        } catch (e) {
          failedServices.add('NotificationService');
          AppLogger.warning('⚠️ NotificationService initialization failed: $e');
        }
      } else {
        failedServices.add('OneSignal');
      }
    }

    // Initialize Google Mobile Ads (only on mobile) - Temporarily disabled
    // if (!kIsWeb) {
    //   if (await _initializeGoogleAds()) {
    //     successfulServices.add('Google Ads');
    //   } else {
    //     failedServices.add('Google Ads');
    //   }
    // }

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
      if (!Environment.hasSupabaseConfig ||
          Environment.supabaseUrl.contains('placeholder') ||
          Environment.supabaseAnonKey.contains('placeholder')) {
        AppLogger.warning(
          '⚠️ Supabase configuration missing or using placeholders, skipping initialization',
        );
        AppLogger.info('💡 App will run in development mode without Supabase');
        return false;
      }

      AppLogger.info('🗄️ Initializing Supabase...');
      await Supabase.initialize(
        url: Environment.supabaseUrl,
        anonKey: Environment.supabaseAnonKey,
        debug: Environment.isDevelopment,
      );

      AppLogger.info('✅ Supabase initialized successfully');
      return true;
    } catch (e) {
      AppLogger.warning('⚠️ Supabase initialization failed: $e');
      AppLogger.info('💡 Using mock mode for development');
      return false;
    }
  }

  /// Initialize RevenueCat
  static Future<bool> _initializeRevenueCat() async {
    try {
      if (!Environment.hasRevenueCatConfig) {
        AppLogger.warning(
          '⚠️ RevenueCat configuration missing (no REVENUECAT_API_KEY), skipping initialization',
        );
        return false;
      }

      // Skip RevenueCat in development/emulator for cleaner logs
      if (Environment.isDevelopment) {
        AppLogger.info('🧪 Skipping RevenueCat in development/emulator');
        return false;
      }

      late PurchasesConfiguration configuration;

      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(Environment.revenueCatApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(Environment.revenueCatApiKey);
      } else {
        AppLogger.info('⚠️ RevenueCat not supported on this platform');
        return false; // Skip for unsupported platforms
      }

      AppLogger.info('💳 Initializing RevenueCat...');
      await Purchases.configure(configuration);

      AppLogger.info('✅ RevenueCat initialized successfully');
      return true;
    } catch (e) {
      AppLogger.warning('⚠️ RevenueCat initialization failed: $e');
      AppLogger.info('💡 Purchases will be disabled');
      return false;
    }
  }

  /// Initialize OneSignal
  static Future<bool> _initializeOneSignal() async {
    try {
      // Skip OneSignal if not enabled or if running in emulator/debug
      if (!Environment.enablePushNotifications) {
        AppLogger.info('📵 Push notifications disabled in environment');
        return false;
      }

      if (!Environment.hasOneSignalConfig) {
        AppLogger.warning(
          '⚠️ OneSignal configuration missing (no ONESIGNAL_APP_ID), skipping initialization',
        );
        return false;
      }

      // Additional check for development - skip OneSignal in emulator
      if (Environment.isDevelopment && !kIsWeb) {
        AppLogger.info('🧪 Skipping OneSignal in development/emulator');
        return false;
      }

      AppLogger.info('🔔 Initializing OneSignal...');
      OneSignal.initialize(Environment.oneSignalAppId);

      // Add a small delay to allow OneSignal to initialize
      await Future.delayed(const Duration(milliseconds: 500));

      // Request permission for notifications
      await OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers for the app
      NotificationService.instance.setNotificationHandlers();

      AppLogger.info('✅ OneSignal initialized successfully');
      return true;
    } catch (e) {
      AppLogger.warning('⚠️ OneSignal initialization failed: $e');
      AppLogger.info('💡 Push notifications will be disabled');
      return false;
    }
  }

  /// Initialize Google Mobile Ads - Temporarily disabled
  // static Future<bool> _initializeGoogleAds() async {
  //   try {
  //     await MobileAds.instance.initialize();
  //
  //     AppLogger.info('✅ Google Mobile Ads initialized');
  //     return true;
  //   } catch (e) {
  //     AppLogger.warning('⚠️ Google Mobile Ads initialization failed: $e');
  //     AppLogger.info('💡 Ads will be disabled');
  //     return false;
  //   }
  // }

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;

  /// Get Supabase client (safe)
  static SupabaseClient? get supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      AppLogger.warning('⚠️ Supabase not available: $e');
      return null;
    }
  }
}
