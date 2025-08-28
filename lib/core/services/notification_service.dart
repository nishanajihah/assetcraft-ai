import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';
import '../utils/app_logger.dart';

part 'notification_service.g.dart';

/// Service for managing push notifications using OneSignal
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    try {
      // Check if OneSignal is configured and enabled
      if (!Environment.enablePushNotifications ||
          !Environment.hasOneSignalConfig) {
        AppLogger.info('📵 Push notifications disabled or not configured');
        return;
      }

      // OneSignal should already be initialized by AppServices
      // Just mark as initialized
      _isInitialized = true;
      AppLogger.info('✅ NotificationService initialized');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize NotificationService: $e');
    }
  }

  /// Send a local notification for daily credits received
  Future<void> sendDailyCreditNotification({
    required int creditsReceived,
    required int totalCredits,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      // Check if user has granted permission for notifications
      final hasPermission = OneSignal.Notifications.permission;
      if (!hasPermission) {
        AppLogger.info('📵 Notification permission not granted');
        return;
      }

      // Create notification content
      final message =
          'You\'ve received $creditsReceived Gemstones! Total: $totalCredits';

      // For local development/testing, we can use OneSignal's test notification
      // In production, this would typically be sent from your backend
      AppLogger.info('🔔 Sending daily credit notification: $message');

      // Note: OneSignal primarily sends notifications from server-side
      // For immediate feedback, we could show an in-app notification instead
      // or trigger a server-side notification through an API call
    } catch (e) {
      AppLogger.error('❌ Failed to send daily credit notification: $e');
    }
  }

  /// Send a welcome notification for new users
  Future<void> sendWelcomeNotification() async {
    if (!_isInitialized || kIsWeb) return;

    try {
      final hasPermission = OneSignal.Notifications.permission;
      if (!hasPermission) return;

      AppLogger.info('🔔 Welcome notification triggered');
      // Implementation would depend on your backend setup
    } catch (e) {
      AppLogger.error('❌ Failed to send welcome notification: $e');
    }
  }

  /// Send notification when user is running low on credits
  Future<void> sendLowCreditsNotification({
    required int remainingCredits,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    try {
      final hasPermission = OneSignal.Notifications.permission;
      if (!hasPermission) return;

      if (remainingCredits <= 3) {
        AppLogger.info(
          '🔔 Low credits notification triggered: $remainingCredits remaining',
        );
        // Implementation would depend on your backend setup
      }
    } catch (e) {
      AppLogger.error('❌ Failed to send low credits notification: $e');
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

      final message =
          'Purchase successful! You received $gemstonesReceived Gemstones! Total: $totalGemstones';
      AppLogger.info('🔔 Sending purchase success notification: $message');

      // In production, this would typically be sent from your backend
      // For now, we just log it
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

  /// Set notification handlers
  void setNotificationHandlers() {
    if (!_isInitialized || kIsWeb) return;

    try {
      // Handle notification received while app is in foreground
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        AppLogger.info(
          '🔔 Notification received in foreground: ${event.notification.title}',
        );
        // You can customize the notification display here
        event.preventDefault(); // Prevent default display
        event.notification.display(); // Show the notification
      });

      // Handle notification clicks
      OneSignal.Notifications.addClickListener((event) {
        AppLogger.info('🔔 Notification clicked: ${event.notification.title}');
        // Handle navigation or actions based on notification data
        _handleNotificationClick(event.notification);
      });
    } catch (e) {
      AppLogger.error('❌ Failed to set notification handlers: $e');
    }
  }

  /// Handle notification click actions
  void _handleNotificationClick(OSNotification notification) {
    try {
      final additionalData = notification.additionalData;

      if (additionalData != null) {
        final action = additionalData['action'];

        switch (action) {
          case 'daily_credits':
            // Navigate to credits/generation screen
            AppLogger.info(
              '📱 Navigating to generation screen from notification',
            );
            break;
          case 'low_credits':
            // Navigate to purchase screen
            AppLogger.info(
              '📱 Navigating to purchase screen from notification',
            );
            break;
          default:
            AppLogger.info('📱 Default notification action');
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error handling notification click: $e');
    }
  }
}

/// Riverpod provider for the notification service
@riverpod
NotificationService notificationService(Ref ref) {
  return NotificationService.instance;
}

/// Provider to check if notifications are available and enabled
@riverpod
Future<bool> notificationsEnabled(Ref ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.hasPermission;
}
