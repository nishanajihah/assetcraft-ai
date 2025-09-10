import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Store Provider
///
/// Manages in-app purchases, gemstone packs, and subscriptions
class StoreProvider extends ChangeNotifier {
  static const String _logTag = 'StoreProvider';

  List<GemstonePackModel> _gemstonePacks = [];
  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = false;
  String? _error;
  bool _canClaimDailyBonus = true;
  DateTime? _lastDailyBonusClaim;
  bool _canWatchAd = true;
  bool _isWatchingAd = false;
  bool _isClaimingDaily = false;
  DateTime? _lastAdWatch;

  // Getters
  List<GemstonePackModel> get gemstonePacks => _gemstonePacks;
  List<SubscriptionModel> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canClaimDailyBonus => _canClaimDailyBonus;
  DateTime? get lastDailyBonusClaim => _lastDailyBonusClaim;
  bool get canWatchAd => _canWatchAd;
  bool get isWatchingAd => _isWatchingAd;
  bool get isClaimingDaily => _isClaimingDaily;
  bool get hasDailyBonus => _canClaimDailyBonus;

  String get nextAdCountdown {
    if (_lastAdWatch == null) return '0s';
    final diff = DateTime.now().difference(_lastAdWatch!);
    const cooldown = Duration(minutes: 5); // 5 minute cooldown
    final remaining = cooldown - diff;
    if (remaining.isNegative) return '0s';
    if (remaining.inHours > 0)
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
  }

  /// Load store products
  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.info('Loading store products', tag: _logTag);

      // Simulate loading products
      await Future.delayed(const Duration(seconds: 1));

      // Mock data for now - replace with actual RevenueCat/store integration
      _gemstonePacks = _generateMockGemstoneePacks();
      _subscriptions = _generateMockSubscriptions();

      AppLogger.success('Store products loaded successfully', tag: _logTag);
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to load store products: $e', tag: _logTag);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Purchase gemstone pack
  Future<bool> purchaseGemstonesPack(GemstonePackModel pack) async {
    try {
      AppLogger.info('Purchasing gemstones pack: ${pack.id}', tag: _logTag);

      // Simulate purchase process
      await Future.delayed(const Duration(seconds: 2));

      // Here you would integrate with RevenueCat or Google Play Billing
      // For now, simulate success

      AppLogger.success('Gemstones pack purchased successfully', tag: _logTag);
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to purchase gemstones pack: $e', tag: _logTag);
      return false;
    }
  }

  /// Purchase subscription
  Future<bool> purchaseSubscription(SubscriptionModel subscription) async {
    try {
      AppLogger.info(
        'Purchasing subscription: ${subscription.id}',
        tag: _logTag,
      );

      // Simulate purchase process
      await Future.delayed(const Duration(seconds: 2));

      // Here you would integrate with RevenueCat
      // For now, simulate success

      AppLogger.success('Subscription purchased successfully', tag: _logTag);
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to purchase subscription: $e', tag: _logTag);
      return false;
    }
  }

  /// Watch rewarded ad
  Future<bool> watchRewardedAd() async {
    try {
      AppLogger.info('Watching rewarded ad', tag: _logTag);

      // Simulate ad watching
      await Future.delayed(const Duration(seconds: 3));

      // Here you would integrate with Google Mobile Ads
      // For now, simulate success and reward

      AppLogger.success('Rewarded ad watched successfully', tag: _logTag);
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to watch rewarded ad: $e', tag: _logTag);
      return false;
    }
  }

  /// Claim daily bonus
  Future<bool> claimDailyBonus() async {
    try {
      if (!_canClaimDailyBonus) {
        AppLogger.warning('Daily bonus already claimed today', tag: _logTag);
        return false;
      }

      AppLogger.info('Claiming daily bonus', tag: _logTag);

      // Simulate claiming bonus
      await Future.delayed(const Duration(seconds: 1));

      _lastDailyBonusClaim = DateTime.now();
      _canClaimDailyBonus = false;
      notifyListeners();

      AppLogger.success('Daily bonus claimed successfully', tag: _logTag);
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to claim daily bonus: $e', tag: _logTag);
      return false;
    }
  }

  /// Check if daily bonus can be claimed
  void checkDailyBonusAvailability() {
    if (_lastDailyBonusClaim == null) {
      _canClaimDailyBonus = true;
      return;
    }

    final now = DateTime.now();
    final lastClaim = _lastDailyBonusClaim!;

    // Check if 24 hours have passed
    if (now.difference(lastClaim).inHours >= 24) {
      _canClaimDailyBonus = true;
      notifyListeners();
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      AppLogger.info('Restoring purchases', tag: _logTag);

      // Simulate restore process
      await Future.delayed(const Duration(seconds: 2));

      // Here you would restore purchases through RevenueCat

      AppLogger.success('Purchases restored successfully', tag: _logTag);
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to restore purchases: $e', tag: _logTag);
      return false;
    }
  }

  /// Generate mock gemstone packs
  List<GemstonePackModel> _generateMockGemstoneePacks() {
    return [
      GemstonePackModel(
        id: 'starter_pack',
        name: 'Starter Pack',
        description: 'Perfect for getting started',
        gemstoneCount: 50,
        price: 2.99,
        originalPrice: 4.99,
        isPopular: false,
        discount: 40,
      ),
      GemstonePackModel(
        id: 'value_pack',
        name: 'Value Pack',
        description: 'Best value for your money',
        gemstoneCount: 150,
        price: 7.99,
        originalPrice: 12.99,
        isPopular: true,
        discount: 38,
      ),
      GemstonePackModel(
        id: 'premium_pack',
        name: 'Premium Pack',
        description: 'For serious creators',
        gemstoneCount: 350,
        price: 15.99,
        originalPrice: 24.99,
        isPopular: false,
        discount: 36,
      ),
      GemstonePackModel(
        id: 'mega_pack',
        name: 'Mega Pack',
        description: 'Ultimate creation power',
        gemstoneCount: 1000,
        price: 39.99,
        originalPrice: 59.99,
        isPopular: false,
        discount: 33,
      ),
    ];
  }

  /// Generate mock subscriptions
  List<SubscriptionModel> _generateMockSubscriptions() {
    return [
      SubscriptionModel(
        id: 'pro_monthly',
        name: 'AssetCraft Pro',
        description: 'Monthly subscription',
        price: 9.99,
        period: SubscriptionPeriod.monthly,
        features: [
          'Unlimited generations',
          'Priority processing',
          'Advanced styles',
          'Commercial license',
          '4K resolution exports',
        ],
        isPopular: false,
      ),
      SubscriptionModel(
        id: 'pro_yearly',
        name: 'AssetCraft Pro',
        description: 'Yearly subscription (2 months free!)',
        price: 99.99,
        originalPrice: 119.88,
        period: SubscriptionPeriod.yearly,
        features: [
          'Unlimited generations',
          'Priority processing',
          'Advanced styles',
          'Commercial license',
          '4K resolution exports',
          'Exclusive beta features',
          'Priority support',
        ],
        isPopular: true,
        discount: 17,
      ),
    ];
  }

  /// Clear all data
  void clearData() {
    _gemstonePacks.clear();
    _subscriptions.clear();
    _error = null;
    notifyListeners();
  }
}

/// Gemstone Pack Model
class GemstonePackModel {
  final String id;
  final String name;
  final String description;
  final int gemstoneCount;
  final double price;
  final double? originalPrice;
  final bool isPopular;
  final int? discount;

  GemstonePackModel({
    required this.id,
    required this.name,
    required this.description,
    required this.gemstoneCount,
    required this.price,
    this.originalPrice,
    required this.isPopular,
    this.discount,
  });
}

/// Subscription Model
class SubscriptionModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final SubscriptionPeriod period;
  final List<String> features;
  final bool isPopular;
  final int? discount;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.period,
    required this.features,
    required this.isPopular,
    this.discount,
  });
}

/// Subscription Period
enum SubscriptionPeriod { monthly, yearly }

extension SubscriptionPeriodExtension on SubscriptionPeriod {
  String get displayName {
    switch (this) {
      case SubscriptionPeriod.monthly:
        return 'Monthly';
      case SubscriptionPeriod.yearly:
        return 'Yearly';
    }
  }
}
