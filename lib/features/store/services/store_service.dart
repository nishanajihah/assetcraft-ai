import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../mock/mock_config.dart';
import '../../../mock/store/mock_store_service.dart';

part 'store_service.g.dart';

/// Purchase result enumeration
enum PurchaseResult { success, userCancelled, error, alreadyOwned, notAllowed }

/// Purchase result data class
class PurchaseResultData {
  final PurchaseResult result;
  final String? errorMessage;
  final int? gemstonesReceived;
  final CustomerInfo? customerInfo;

  const PurchaseResultData({
    required this.result,
    this.errorMessage,
    this.gemstonesReceived,
    this.customerInfo,
  });

  bool get isSuccess => result == PurchaseResult.success;
  bool get isUserCancelled => result == PurchaseResult.userCancelled;
  bool get isError => result == PurchaseResult.error;
}

/// Service for handling in-app purchases through RevenueCat
class StoreService {
  final UserService _userService;
  final NotificationService _notificationService;

  StoreService(this._userService, this._notificationService);

  /// Purchase a package and handle all the logic
  Future<PurchaseResultData> purchasePackage(Package package) async {
    // Check if mock mode is enabled
    if (MockConfig.isMockStoreEnabled) {
      return await _handleMockPurchase(package);
    }

    try {
      AppLogger.info('🛒 Starting purchase for package: ${package.identifier}');

      // Attempt the purchase
      final customerInfo = await Purchases.purchasePackage(package);

      // Check if the purchase was successful
      if (customerInfo.entitlements.all.isNotEmpty) {
        AppLogger.info('✅ Purchase successful: ${package.identifier}');

        // Extract gemstones amount from package metadata or identifier
        final gemstonesReceived = extractGemstonesFromPackage(package);

        // Update user's gemstones in the database
        if (gemstonesReceived > 0) {
          await _userService.addGemstones(gemstonesReceived);

          // Send success notification
          await _notificationService.sendPurchaseSuccessNotification(
            gemstonesReceived: gemstonesReceived,
            totalGemstones: await _userService.getGemstones(),
          );

          AppLogger.info(
            '💎 Added $gemstonesReceived gemstones to user account',
          );
        }

        return PurchaseResultData(
          result: PurchaseResult.success,
          gemstonesReceived: gemstonesReceived,
          customerInfo: customerInfo,
        );
      } else {
        AppLogger.warning('⚠️ Purchase completed but no entitlements found');
        return const PurchaseResultData(
          result: PurchaseResult.error,
          errorMessage: 'Purchase completed but no entitlements found',
        );
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          AppLogger.info('❌ Purchase cancelled by user');
          return const PurchaseResultData(result: PurchaseResult.userCancelled);

        case PurchasesErrorCode.storeProblemError:
          AppLogger.error('🏪 Store problem: ${e.message}');
          return PurchaseResultData(
            result: PurchaseResult.error,
            errorMessage:
                'Store is currently unavailable. Please try again later.',
          );

        case PurchasesErrorCode.purchaseNotAllowedError:
          AppLogger.error('🚫 Purchase not allowed: ${e.message}');
          return PurchaseResultData(
            result: PurchaseResult.notAllowed,
            errorMessage: 'Purchases are not allowed on this device.',
          );

        case PurchasesErrorCode.purchaseInvalidError:
          AppLogger.error('❌ Invalid purchase: ${e.message}');
          return PurchaseResultData(
            result: PurchaseResult.error,
            errorMessage: 'Invalid purchase. Please try again.',
          );

        default:
          AppLogger.error('❌ Purchase error: ${e.message}');
          return PurchaseResultData(
            result: PurchaseResult.error,
            errorMessage: e.message ?? 'An unknown error occurred',
          );
      }
    } catch (e) {
      AppLogger.error('❌ Unexpected purchase error: $e');
      return PurchaseResultData(
        result: PurchaseResult.error,
        errorMessage: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Handle mock purchase flow
  Future<PurchaseResultData> _handleMockPurchase(Package package) async {
    AppLogger.info('🎭 [MOCK] Starting mock purchase: ${package.identifier}');

    // Find corresponding mock package
    final mockPackage = MockStoreService.mockPackages.firstWhere(
      (p) => p.identifier == package.identifier,
      orElse: () => MockPackage(
        identifier: package.identifier,
        title: package.storeProduct.title,
        description: package.storeProduct.description,
        price: package.storeProduct.price,
        priceString: package.storeProduct.priceString,
        gemstones: extractGemstonesFromPackage(package),
      ),
    );

    // Simulate the purchase
    final result = await MockStoreService.simulatePurchase(mockPackage);

    // If successful, add gemstones to user account
    if (result.isSuccess &&
        result.gemstonesReceived != null &&
        result.gemstonesReceived! > 0) {
      await _userService.addGemstones(result.gemstonesReceived!);

      // Send mock notification
      await _notificationService.sendPurchaseSuccessNotification(
        gemstonesReceived: result.gemstonesReceived!,
        totalGemstones: await _userService.getGemstones(),
      );

      AppLogger.info(
        '💎 [MOCK] Added ${result.gemstonesReceived} gemstones to user account',
      );
    }

    return result;
  }

  /// Restore previous purchases
  Future<PurchaseResultData> restorePurchases() async {
    // Check if mock mode is enabled
    if (MockConfig.isMockStoreEnabled) {
      return await MockStoreService.simulateRestorePurchases();
    }

    try {
      AppLogger.info('🔄 Restoring purchases...');

      final customerInfo = await Purchases.restorePurchases();

      // Process any active entitlements
      int totalGemstonesRestored = 0;

      for (final entitlement in customerInfo.entitlements.active.values) {
        // You can implement logic here to restore consumable purchases
        // For now, we'll just log the active entitlements
        AppLogger.info('✅ Active entitlement: ${entitlement.identifier}');
      }

      AppLogger.info('✅ Purchases restored successfully');

      return PurchaseResultData(
        result: PurchaseResult.success,
        gemstonesReceived: totalGemstonesRestored,
        customerInfo: customerInfo,
      );
    } catch (e) {
      AppLogger.error('❌ Error restoring purchases: $e');
      return PurchaseResultData(
        result: PurchaseResult.error,
        errorMessage: 'Failed to restore purchases: $e',
      );
    }
  }

  /// Extract gemstones amount from package identifier or metadata
  int extractGemstonesFromPackage(Package package) {
    // Parse gemstones from package identifier
    // Expected format: "gems_10", "gems_50", "gems_100", etc.
    final identifier = package.storeProduct.identifier.toLowerCase();

    // Try to extract number from identifier
    final gemsRegex = RegExp(r'gems?_?(\d+)');
    final match = gemsRegex.firstMatch(identifier);

    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }

    // Fallback: try to extract from title or description
    final title = package.storeProduct.title.toLowerCase();
    final gemsFromTitle = RegExp(r'(\d+)\s*gems?').firstMatch(title);

    if (gemsFromTitle != null) {
      return int.tryParse(gemsFromTitle.group(1) ?? '0') ?? 0;
    }

    // Default fallback based on price tiers (you can customize this)
    final price = package.storeProduct.price;
    if (price <= 0.99) return 10;
    if (price <= 4.99) return 50;
    if (price <= 9.99) return 100;
    if (price <= 19.99) return 250;
    if (price <= 49.99) return 500;

    return 0;
  }

  /// Get available packages for purchase
  Future<List<Package>> getAvailablePackages() async {
    try {
      AppLogger.info('📦 Fetching available packages...');

      final offerings = await Purchases.getOfferings();

      if (offerings.current != null) {
        final packages = offerings.current!.availablePackages;
        AppLogger.info('✅ Found ${packages.length} available packages');
        return packages;
      } else {
        AppLogger.warning('⚠️ No current offering found');
        return [];
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching packages: $e');
      return [];
    }
  }

  /// Check if user has any active subscriptions
  Future<bool> hasActiveSubscription() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      AppLogger.error('❌ Error checking subscriptions: $e');
      return false;
    }
  }
}

/// Riverpod provider for StoreService
@riverpod
StoreService storeService(Ref ref) {
  final userService = ref.watch(userServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return StoreService(userService, notificationService);
}

/// Provider for available packages
@riverpod
Future<List<Package>> availablePackages(Ref ref) async {
  // Check if mock mode is enabled
  if (MockConfig.isMockStoreEnabled) {
    AppLogger.info('🎭 [MOCK] Using mock store packages');
    // Return empty list for now since we can't easily create Package objects
    // The UI will handle this gracefully
    return [];
  }

  final storeService = ref.watch(storeServiceProvider);
  return await storeService.getAvailablePackages();
}

/// Provider for subscription status
@riverpod
Future<bool> hasActiveSubscription(Ref ref) async {
  // Check if mock mode is enabled
  if (MockConfig.isMockStoreEnabled) {
    AppLogger.info('🎭 [MOCK] Using mock subscription status');
    // Return false for mock mode (can be made configurable later)
    return false;
  }

  final storeService = ref.watch(storeServiceProvider);
  return await storeService.hasActiveSubscription();
}
