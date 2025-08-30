import 'package:flutter/material.dart';
import '../../features/store/services/store_service.dart';
import '../../core/services/user_service.dart';
import '../../core/utils/app_logger.dart';
import '../../features/gemstones/widgets/gemstone_notification_widget.dart';
import 'mock_store_service.dart';

/// Enhanced mock purchase handler with realistic flow
/// This provides a complete purchase experience for testing
class MockPurchaseHandler {
  final UserService _userService;

  MockPurchaseHandler(this._userService);

  /// Handle mock gemstone purchase with full user experience
  Future<PurchaseResultData> handleMockPurchase(
    BuildContext context,
    MockPackage package,
  ) async {
    AppLogger.info(
      '🎭 [MOCK PURCHASE] Starting mock purchase flow: ${package.title}',
    );

    // Show loading state would be handled by UI
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate purchase processing
    final result = await MockStoreService.simulatePurchase(package);

    if (result.isSuccess && result.gemstonesReceived != null) {
      // Add gemstones to user account
      await _userService.addGemstones(result.gemstonesReceived!);

      // Get updated total
      final totalGemstones = await _userService.getGemstones();

      AppLogger.info(
        '💎 [MOCK PURCHASE] Added ${result.gemstonesReceived} gemstones. Total: $totalGemstones',
      );

      // Show beautiful notification overlay
      if (context.mounted) {
        GemstoneNotificationOverlay.showPurchaseSuccess(
          context,
          gemstonesReceived: result.gemstonesReceived!,
          totalGemstones: totalGemstones,
        );
      }

      return PurchaseResultData(
        result: PurchaseResult.success,
        gemstonesReceived: result.gemstonesReceived,
        customerInfo: null,
      );
    }

    return result;
  }

  /// Handle mock subscription purchase
  Future<PurchaseResultData> handleMockSubscription(
    BuildContext context,
    MockPackage package,
  ) async {
    AppLogger.info(
      '📋 [MOCK PURCHASE] Starting mock subscription: ${package.title}',
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    // Subscriptions are usually successful in testing
    AppLogger.info('✅ [MOCK PURCHASE] Subscription activated');

    return const PurchaseResultData(
      result: PurchaseResult.success,
      gemstonesReceived: 0,
      customerInfo: null,
    );
  }

  /// Handle mock purchase cancellation
  static PurchaseResultData handleMockCancellation() {
    AppLogger.info('❌ [MOCK PURCHASE] User cancelled purchase');
    return const PurchaseResultData(result: PurchaseResult.userCancelled);
  }

  /// Handle mock purchase error
  static PurchaseResultData handleMockError(String errorMessage) {
    AppLogger.error('🚫 [MOCK PURCHASE] Error: $errorMessage');
    return PurchaseResultData(
      result: PurchaseResult.error,
      errorMessage: errorMessage,
    );
  }

  /// Simulate different purchase outcomes for testing
  static Future<PurchaseResultData> simulateRandomOutcome(
    MockPackage package,
  ) async {
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    // 80% success, 15% cancel, 5% error
    if (random < 80) {
      return MockStoreService.simulatePurchase(package);
    } else if (random < 95) {
      await Future.delayed(const Duration(milliseconds: 500));
      return handleMockCancellation();
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      return handleMockError('Network error (simulated)');
    }
  }
}
