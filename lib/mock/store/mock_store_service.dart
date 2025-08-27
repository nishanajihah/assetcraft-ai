import '../../features/store/services/store_service.dart';
import '../../core/utils/app_logger.dart';

/// Mock store service for testing purchase flows
///
/// This service simulates RevenueCat purchase behavior without
/// requiring actual payment processing. Useful for testing
/// the purchase UI and flow logic.
class MockStoreService {
  static const bool isEnabled = true;

  /// Mock package data
  static final List<MockPackage> mockPackages = [
    MockPackage(
      identifier: 'gems_10',
      title: '10 Gemstones',
      description: 'Small gemstone pack for quick generations',
      price: 0.99,
      priceString: '\$0.99',
      gemstones: 10,
    ),
    MockPackage(
      identifier: 'gems_50',
      title: '50 Gemstones',
      description: 'Popular gemstone pack - great value!',
      price: 3.99,
      priceString: '\$3.99',
      gemstones: 50,
    ),
    MockPackage(
      identifier: 'gems_100',
      title: '100 Gemstones',
      description: 'Large gemstone pack for power users',
      price: 6.99,
      priceString: '\$6.99',
      gemstones: 100,
    ),
    MockPackage(
      identifier: 'gems_250',
      title: '250 Gemstones',
      description: 'Mega gemstone pack - best value!',
      price: 14.99,
      priceString: '\$14.99',
      gemstones: 250,
    ),
    MockPackage(
      identifier: 'premium_subscription',
      title: 'Premium Subscription',
      description: 'Unlimited generations + priority processing',
      price: 9.99,
      priceString: '\$9.99/month',
      gemstones: 0,
      isSubscription: true,
    ),
  ];

  /// Simulate purchase flow
  static Future<PurchaseResultData> simulatePurchase(
    MockPackage package,
  ) async {
    AppLogger.info(
      '🛒 [MOCK STORE] Starting purchase simulation: ${package.identifier}',
    );

    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    // Simulate different outcomes based on package
    if (package.identifier.contains('subscription')) {
      return _simulateSubscriptionPurchase(package);
    } else {
      return _simulateGemstonesPurchase(package);
    }
  }

  /// Simulate gemstones purchase
  static Future<PurchaseResultData> _simulateGemstonesPurchase(
    MockPackage package,
  ) async {
    // 90% success rate for testing
    final random = DateTime.now().millisecondsSinceEpoch % 10;

    if (random < 9) {
      AppLogger.info(
        '✅ [MOCK STORE] Purchase successful: ${package.gemstones} gemstones',
      );
      return PurchaseResultData(
        result: PurchaseResult.success,
        gemstonesReceived: package.gemstones,
        customerInfo: null, // Mock would need CustomerInfo simulation
      );
    } else {
      AppLogger.info('❌ [MOCK STORE] Purchase failed (simulated error)');
      return const PurchaseResultData(
        result: PurchaseResult.error,
        errorMessage: 'Mock purchase error for testing',
      );
    }
  }

  /// Simulate subscription purchase
  static Future<PurchaseResultData> _simulateSubscriptionPurchase(
    MockPackage package,
  ) async {
    AppLogger.info('📋 [MOCK STORE] Subscription purchase: ${package.title}');

    // Subscriptions have higher success rate
    return PurchaseResultData(
      result: PurchaseResult.success,
      gemstonesReceived: 0, // Subscriptions don't give immediate gemstones
      customerInfo: null,
    );
  }

  /// Simulate restore purchases
  static Future<PurchaseResultData> simulateRestorePurchases() async {
    AppLogger.info('🔄 [MOCK STORE] Simulating restore purchases...');

    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

    // Simulate finding some previous purchases
    AppLogger.info('✅ [MOCK STORE] Restored 2 previous purchases');
    return const PurchaseResultData(
      result: PurchaseResult.success,
      gemstonesReceived: 0, // No new gemstones from restore
    );
  }

  /// Check if user has active subscription (mock)
  static Future<bool> hasActiveSubscription() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate 30% of users have subscription for testing
    final hasSubscription = DateTime.now().millisecondsSinceEpoch % 10 < 3;
    AppLogger.debug(
      '📋 [MOCK STORE] Has active subscription: $hasSubscription',
    );
    return hasSubscription;
  }

  /// Get mock customer info
  static Map<String, dynamic> getMockCustomerInfo() {
    return {
      'originalAppUserId': 'mock_user_123',
      'allPurchasedProductIdentifiers': ['gems_50', 'gems_100'],
      'latestExpirationDate': null,
      'firstSeen': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'originalPurchaseDate': DateTime.now()
          .subtract(const Duration(days: 15))
          .toIso8601String(),
      'requestDate': DateTime.now().toIso8601String(),
    };
  }

  /// Simulate different error scenarios for testing
  static Future<PurchaseResultData> simulateError(String errorType) async {
    AppLogger.info('⚠️ [MOCK STORE] Simulating error: $errorType');

    await Future.delayed(const Duration(seconds: 1));

    switch (errorType) {
      case 'user_cancelled':
        return const PurchaseResultData(result: PurchaseResult.userCancelled);

      case 'store_problem':
        return const PurchaseResultData(
          result: PurchaseResult.error,
          errorMessage: 'Store is currently unavailable (mock error)',
        );

      case 'not_allowed':
        return const PurchaseResultData(
          result: PurchaseResult.notAllowed,
          errorMessage: 'Purchases not allowed (mock restriction)',
        );

      case 'already_owned':
        return const PurchaseResultData(result: PurchaseResult.alreadyOwned);

      default:
        return const PurchaseResultData(
          result: PurchaseResult.error,
          errorMessage: 'Unknown mock error',
        );
    }
  }

  /// Get purchase statistics for testing
  static Map<String, dynamic> getMockPurchaseStats() {
    return {
      'totalPurchases': 5,
      'totalSpent': 29.95,
      'favoritePackage': 'gems_50',
      'lastPurchaseDate': DateTime.now()
          .subtract(const Duration(days: 3))
          .toIso8601String(),
      'gemstonesPurchased': 350,
      'averagePurchaseValue': 5.99,
    };
  }
}

/// Mock package class to simulate RevenueCat Package
class MockPackage {
  final String identifier;
  final String title;
  final String description;
  final double price;
  final String priceString;
  final int gemstones;
  final bool isSubscription;

  const MockPackage({
    required this.identifier,
    required this.title,
    required this.description,
    required this.price,
    required this.priceString,
    required this.gemstones,
    this.isSubscription = false,
  });

  /// Convert to a map for easier testing
  Map<String, dynamic> toMap() {
    return {
      'identifier': identifier,
      'title': title,
      'description': description,
      'price': price,
      'priceString': priceString,
      'gemstones': gemstones,
      'isSubscription': isSubscription,
    };
  }

  @override
  String toString() {
    return 'MockPackage(${toMap()})';
  }
}
