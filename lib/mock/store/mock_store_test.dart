import '../../core/utils/app_logger.dart';
import 'mock_store_service.dart';

/// Test script for mock store functionality
/// Run this to validate the complete purchase flow
class MockStoreTestSuite {
  static Future<void> runAllTests() async {
    AppLogger.info('🧪 Starting Mock Store Test Suite...');

    await testMockPackages();
    await testPurchaseFlow();
    await testRestoreFlow();

    AppLogger.info('✅ Mock Store Test Suite completed!');
  }

  /// Test mock package creation
  static Future<void> testMockPackages() async {
    AppLogger.info('📦 Testing mock packages...');

    final packages = MockStoreService.mockPackages;
    assert(packages.isNotEmpty, 'Mock packages should not be empty');

    for (final package in packages) {
      AppLogger.debug('Package: ${package.title} - ${package.priceString}');
      assert(package.identifier.isNotEmpty, 'Package ID should not be empty');
      assert(package.price >= 0, 'Package price should be non-negative');
    }

    AppLogger.info('✅ Mock packages test passed');
  }

  /// Test purchase flow
  static Future<void> testPurchaseFlow() async {
    AppLogger.info('🛒 Testing purchase flow...');

    final testPackage = MockStoreService.mockPackages.first;
    final result = await MockStoreService.simulatePurchase(testPackage);

    AppLogger.info('Purchase result: ${result.result}');

    if (result.isSuccess) {
      AppLogger.info('✅ Mock purchase successful!');
      AppLogger.info('💎 Gemstones received: ${result.gemstonesReceived}');
    } else {
      AppLogger.info('📝 Mock purchase result: ${result.result}');
    }
  }

  /// Test restore flow
  static Future<void> testRestoreFlow() async {
    AppLogger.info('🔄 Testing restore flow...');

    final result = await MockStoreService.simulateRestorePurchases();
    AppLogger.info('Restore result: ${result.result}');

    if (result.isSuccess) {
      AppLogger.info('✅ Mock restore successful!');
    }
  }

  /// Test subscription
  static Future<void> testSubscription() async {
    AppLogger.info('📋 Testing subscription...');

    final hasSubscription = await MockStoreService.hasActiveSubscription();
    AppLogger.info('Has active subscription: $hasSubscription');
  }
}
