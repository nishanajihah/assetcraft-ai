import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/utils/app_logger.dart';

/// Provider to fetch product offerings from RevenueCat
final offeringsProvider = FutureProvider<Offerings>((ref) async {
  try {
    AppLogger.info('🛒 Fetching RevenueCat offerings...');

    // Check if Purchases is configured
    final isConfigured = await Purchases.isConfigured;
    if (!isConfigured) {
      AppLogger.error('❌ RevenueCat is not configured');
      throw Exception(
        'RevenueCat is not configured. Please initialize Purchases first.',
      );
    }

    // Fetch offerings from RevenueCat
    final offerings = await Purchases.getOfferings();

    if (offerings.current == null) {
      AppLogger.warning('⚠️ No current offering found in RevenueCat');
    } else {
      AppLogger.info(
        '✅ Successfully fetched ${offerings.current!.availablePackages.length} packages',
      );

      // Log available packages for debugging
      for (final package in offerings.current!.availablePackages) {
        AppLogger.debug(
          '📦 Package: ${package.identifier} - ${package.storeProduct.title} (${package.storeProduct.priceString})',
        );
      }
    }

    return offerings;
  } catch (e, stack) {
    AppLogger.error('❌ Error fetching offerings: $e');
    AppLogger.error('Stack trace: $stack');
    rethrow; // Re-throw to let the UI handle the error state
  }
});
