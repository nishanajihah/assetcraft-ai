import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';
import '../utils/app_logger.dart';
import 'user_service.dart';

part 'notification_service.g.dart';

/// Service for managing push notifications using OneSignal
///
/// This service handles OneSignal integration, notification event handling,
/// and provides a clean interface for sending different types of notifications.
/// It integrates with Supabase for user data and UserService for business logic.
class NotificationService {
  final SupabaseClient _supabase;
  final UserService? _userService;
  bool _isInitialized = false;

  NotificationService({
    required SupabaseClient supabase,
    UserService? userService,
  }) : _supabase = supabase,
       _userService = userService;

  /// Initialize OneSignal and set up event handlers
  Future<void> initNotifications() async {
    if (_isInitialized || kIsWeb) {
      AppLogger.info('📵 Notifications already initialized or running on web');
      return;
    }

    try {
      // Check if OneSignal is configured and enabled
      if (!Environment.enablePushNotifications ||
          !Environment.hasOneSignalConfig) {
        AppLogger.info('📵 Push notifications disabled or not configured');
        return;
      }

      AppLogger.info('🔔 Initializing OneSignal notifications...');

      // Initialize OneSignal with app ID
      OneSignal.initialize(Environment.oneSignalAppId);

      // Set up notification event listeners
      _setupNotificationEventListeners();

      // Set external user ID for targeted notifications
      await _setExternalUserId();

      _isInitialized = true;
      AppLogger.info('✅ NotificationService initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize NotificationService: $e');
      rethrow;
    }
  }

  /// Set up OneSignal event listeners for handling notifications
  void _setupNotificationEventListeners() {
    try {
      // Handle notification received while app is in foreground
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        AppLogger.info(
          '🔔 Notification received in foreground: ${event.notification.title}',
        );

        // Parse notification payload
        final notification = event.notification;
        final additionalData = notification.additionalData;

        // Handle daily gemstone notifications with custom in-app overlay
        if (additionalData != null &&
            additionalData['type'] == 'daily_gemstones') {
          _handleDailyGemstoneNotification(additionalData);
          event.preventDefault(); // Prevent default system notification
          return;
        }

        // Show other notifications normally
        event.notification.display();
      });

      // Handle notification clicks when app is opened from notification
      OneSignal.Notifications.addClickListener((event) {
        AppLogger.info('🔔 Notification clicked: ${event.notification.title}');
        _handleNotificationClick(event.notification);
      });

      // Handle permission changes
      OneSignal.Notifications.addPermissionObserver((state) {
        AppLogger.info('🔔 Notification permission changed: $state');
      });

      AppLogger.debug('✅ Notification event listeners set up');
    } catch (e) {
      AppLogger.error('❌ Failed to set up notification event listeners: $e');
    }
  }

  /// Handle daily gemstone notifications with custom in-app display
  void _handleDailyGemstoneNotification(Map<String, dynamic> data) {
    try {
      final gemstonesReceived = data['gemstones_received'] as int? ?? 0;
      final totalGemstones = data['total_gemstones'] as int? ?? 0;

      AppLogger.info(
        '💎 Daily gemstones notification: +$gemstonesReceived (Total: $totalGemstones)',
      );

      // Show custom in-app notification overlay
      // This would typically trigger a UI component to show the notification
      _showInAppGemstoneNotification(
        gemstonesReceived: gemstonesReceived,
        totalGemstones: totalGemstones,
      );
    } catch (e) {
      AppLogger.error('❌ Error handling daily gemstone notification: $e');
    }
  }

  /// Show custom in-app notification overlay for daily gemstones
  void _showInAppGemstoneNotification({
    required int gemstonesReceived,
    required int totalGemstones,
  }) {
    // This method would typically emit an event or call a callback
    // to show a custom UI overlay. For now, we'll log it.
    AppLogger.info(
      '🎉 Showing in-app gemstone notification: +$gemstonesReceived Gemstones! Total: $totalGemstones',
    );

    // In a real implementation, you might:
    // 1. Use a stream controller to emit the notification data
    // 2. Call a callback function passed during initialization
    // 3. Use a state management solution to trigger UI updates
    // 4. Show a custom dialog or overlay widget
  }

  /// Set external user ID in OneSignal for targeted notifications
  Future<void> _setExternalUserId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        OneSignal.login(user.id);
        AppLogger.info('👤 OneSignal external user ID set: ${user.id}');
      } else {
        AppLogger.warning('⚠️ No authenticated user found for OneSignal setup');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to set OneSignal external user ID: $e');
    }
  }

  /// Handle notification click actions
  void _handleNotificationClick(OSNotification notification) {
    try {
      final additionalData = notification.additionalData;

      if (additionalData != null) {
        final action = additionalData['action'];
        final type = additionalData['type'];

        switch (type ?? action) {
          case 'daily_gemstones':
            // Navigate to gemstones/generation screen
            AppLogger.info(
              '📱 Navigating to generation screen from notification',
            );
            // UserService integration could be added here for data refresh
            break;
          case 'low_gemstones':
            // Navigate to purchase screen
            AppLogger.info(
              '📱 Navigating to purchase screen from notification',
            );
            break;
          case 'welcome':
            // Navigate to onboarding or main screen
            AppLogger.info('📱 Handling welcome notification');
            break;
          default:
            AppLogger.info('📱 Default notification action');
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error handling notification click: $e');
    }
  }

  /// Send a local notification for daily gemstones received
  Future<void> sendDailyGemstoneNotification({
    required int gemstonesReceived,
    required int totalGemstones,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      // Check if user has granted permission for notifications
      final hasPermission = OneSignal.Notifications.permission;
      if (!hasPermission) {
        AppLogger.info('📵 Notification permission not granted');
        return;
      }

      AppLogger.info(
        '🔔 Daily gemstone notification triggered: +$gemstonesReceived (Total: $totalGemstones)',
      );

      // For daily gemstone notifications, we prefer showing the in-app overlay
      // instead of a system notification
      _showInAppGemstoneNotification(
        gemstonesReceived: gemstonesReceived,
        totalGemstones: totalGemstones,
      );
    } catch (e) {
      AppLogger.error('❌ Failed to send daily gemstone notification: $e');
    }
  }

  /// Send a welcome notification for new users
  Future<void> sendWelcomeNotification() async {
    if (!_isInitialized || kIsWeb) return;

    try {
      final hasPermission = OneSignal.Notifications.permission;
      if (!hasPermission) return;

      AppLogger.info('🔔 Welcome notification triggered');
      // This would typically be sent from your backend server
      // For now, we just log the intent
    } catch (e) {
      AppLogger.error('❌ Failed to send welcome notification: $e');
    }
  }

  /// Send notification when user is running low on gemstones
  Future<void> sendLowGemstonesNotification({
    required int remainingGemstones,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      final hasPermission = OneSignal.Notifications.permission;
      if (!hasPermission) return;

      if (remainingGemstones <= 3) {
        AppLogger.info(
          '🔔 Low gemstones notification triggered: $remainingGemstones remaining',
        );
        // This would typically be sent from your backend server
        // You could trigger a server-side notification here via API call
      }
    } catch (e) {
      AppLogger.error('❌ Failed to send low gemstones notification: $e');
    }
  }

  /// Send notification for successful purchase
  Future<void> sendPurchaseSuccessNotification({
    required int gemstonesReceived,
    required int totalGemstones,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      final hasPermission = OneSignal.Notifications.permission;
      if (!hasPermission) return;

      AppLogger.info(
        '🔔 Purchase success notification: +$gemstonesReceived (Total: $totalGemstones)',
      );
      // This would typically be sent from your backend server
    } catch (e) {
      AppLogger.error('❌ Failed to send purchase success notification: $e');
    }
  }

  /// Get the OneSignal player ID for server-side notifications
  Future<String?> getPlayerId() async {
    if (!_isInitialized || kIsWeb) return null;

    try {
      final deviceState = OneSignal.User.pushSubscription;
      return deviceState.id;
    } catch (e) {
      AppLogger.error('❌ Failed to get OneSignal player ID: $e');
      return null;
    }
  }

  /// Set user tags for targeted notifications
  Future<void> setUserTags(Map<String, String> tags) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      OneSignal.User.addTags(tags);
      AppLogger.debug('🏷️ User tags set: $tags');
    } catch (e) {
      AppLogger.error('❌ Failed to set user tags: $e');
    }
  }

  /// Request notification permission if not already granted
  Future<bool> requestPermission() async {
    if (!_isInitialized || kIsWeb) return false;

    try {
      final permission = await OneSignal.Notifications.requestPermission(true);
      AppLogger.info('🔔 Notification permission: $permission');
      return permission;
    } catch (e) {
      AppLogger.error('❌ Failed to request notification permission: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> get hasPermission async {
    if (!_isInitialized || kIsWeb) return false;

    try {
      return OneSignal.Notifications.permission;
    } catch (e) {
      AppLogger.error('❌ Failed to check notification permission: $e');
      return false;
    }
  }

  /// Update external user ID when user authentication changes
  Future<void> updateExternalUserId(String? userId) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      if (userId != null) {
        OneSignal.login(userId);
        AppLogger.info('👤 OneSignal external user ID updated: $userId');
      } else {
        OneSignal.logout();
        AppLogger.info('👤 OneSignal user logged out');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to update OneSignal external user ID: $e');
    }
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;
}

/// Riverpod provider for the notification service
@riverpod
NotificationService notificationService(NotificationServiceRef ref) {
  final supabase = Supabase.instance.client;
  // Remove circular dependency for now - we'll handle this later
  return NotificationService(supabase: supabase);
}

/// Provider to check if notifications are available and enabled
@riverpod
Future<bool> notificationsEnabled(NotificationsEnabledRef ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.hasPermission;
}
