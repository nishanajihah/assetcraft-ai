import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/user_service.dart';
import '../../core/utils/app_logger.dart';
import 'widgets/gemstone_notification_widget.dart';

part 'gemstone_ui_provider.g.dart';

/// Enhanced provider that combines gemstone streaming with UI notifications
@riverpod
class GemstoneStreamNotifier extends _$GemstoneStreamNotifier {
  @override
  Stream<int> build() async* {
    final userService = ref.watch(userServiceProvider);

    yield* userService.gemstonesStream.asyncMap((gemstones) async {
      // Check if daily gemstones were awarded and show notification
      await _checkAndShowDailyGemstonesNotification(userService);
      return gemstones;
    });
  }

  /// Check if daily gemstones were awarded and show in-app notification
  Future<void> _checkAndShowDailyGemstonesNotification(
    UserService userService,
  ) async {
    try {
      final gemstonesAwarded = userService.lastDailyGemstonesAwarded;
      final totalGemstones = userService.lastDailyGemstonesTotal;

      if (gemstonesAwarded != null && totalGemstones != null) {
        // Log that gemstones were awarded, but don't show notification here
        // The UI will handle showing notifications when it detects changes
        AppLogger.info(
          'Daily gemstones awarded: +$gemstonesAwarded, Total: $totalGemstones',
        );

        // Clear the notification data so it doesn't show again
        userService.clearDailyGemstonesNotification();
      }
    } catch (e) {
      AppLogger.error('Error processing daily gemstones notification: $e');
    }
  }

  /// Show a manual notification for daily gemstones (for testing or manual triggers)
  void showDailyGemstonesNotification(
    BuildContext context,
    int gemstonesReceived,
    int totalGemstones,
  ) {
    try {
      GemstoneNotificationOverlay.showDailyGemstones(
        context,
        gemstonesReceived: gemstonesReceived,
        totalGemstones: totalGemstones,
      );
    } catch (e) {
      AppLogger.error('Error showing manual daily gemstones notification: $e');
    }
  }

  /// Show low gemstones warning
  void showLowGemstonesWarning(BuildContext context, int remainingGemstones) {
    try {
      GemstoneNotificationOverlay.showLowGemstones(
        context,
        remainingGemstones: remainingGemstones,
      );
    } catch (e) {
      AppLogger.error('Error showing low gemstones warning: $e');
    }
  }

  /// Show purchase success notification
  void showPurchaseSuccessNotification(
    BuildContext context,
    int gemstonesReceived,
    int totalGemstones,
  ) {
    try {
      GemstoneNotificationOverlay.showPurchaseSuccess(
        context,
        gemstonesReceived: gemstonesReceived,
        totalGemstones: totalGemstones,
      );
    } catch (e) {
      AppLogger.error('Error showing purchase success notification: $e');
    }
  }
}

/// Simple provider for current gemstones (Future-based)
@riverpod
Future<int> currentUserGemstones(CurrentUserGemstonesRef ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getGemstones();
}

/// Provider to check for pending daily gemstone notifications
@riverpod
Future<({int gemstones, int total})?> pendingDailyGemstoneNotification(
  PendingDailyGemstoneNotificationRef ref,
) async {
  final userService = ref.watch(userServiceProvider);

  final gemstonesAwarded = userService.lastDailyGemstonesAwarded;
  final totalGemstones = userService.lastDailyGemstonesTotal;

  if (gemstonesAwarded != null && totalGemstones != null) {
    return (gemstones: gemstonesAwarded, total: totalGemstones);
  }

  return null;
}

/// Helper function to check and show daily gemstone notifications in UI
void checkAndShowDailyGemstoneNotification(
  BuildContext context,
  WidgetRef ref,
) {
  ref.listen(pendingDailyGemstoneNotificationProvider, (previous, next) {
    next.whenData((notification) {
      if (notification != null && context.mounted) {
        GemstoneNotificationOverlay.showDailyGemstones(
          context,
          gemstonesReceived: notification.gemstones,
          totalGemstones: notification.total,
        );

        // Clear the notification after showing it
        final userService = ref.read(userServiceProvider);
        userService.clearDailyGemstonesNotification();

        AppLogger.info(
          'Showed daily gemstone notification: +${notification.gemstones}',
        );
      }
    });
  });
}
