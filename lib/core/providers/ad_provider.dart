import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';
import '../utils/logger.dart';
import 'user_provider.dart';

/// AdProvider for managing ad state and integration with UI
///
/// Provides reactive state management for ad loading and showing
/// Integrates AdService with the Provider pattern used throughout the app
class AdProvider extends ChangeNotifier {
  static const String _logTag = 'AdProvider';

  final AdService _adService = AdService();

  // State variables
  bool _isInitialized = false;
  bool _isLoadingAd = false;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoadingAd => _isLoadingAd;
  bool get canShowAd => _adService.canShowAd();
  bool get isAdLoaded => _adService.isAdLoaded;
  String? get error => _error;
  int get rewardAmount => AdService.rewardAmount;

  /// Initialize the ad provider with UserProvider
  Future<void> initialize(UserProvider userProvider) async {
    try {
      AppLogger.info('Initializing AdProvider', tag: _logTag);

      _adService.initialize(userProvider);

      // Initialize Google Mobile Ads
      await MobileAds.instance.initialize();

      _isInitialized = true;
      _error = null;

      // Pre-load the first ad
      await loadAd();

      AppLogger.success('AdProvider initialized successfully', tag: _logTag);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      AppLogger.error(
        'Failed to initialize AdProvider: $e',
        tag: _logTag,
        error: e,
      );
      notifyListeners();
    }
  }

  /// Load a rewarded ad
  Future<void> loadAd() async {
    if (!_isInitialized) {
      AppLogger.warning('AdProvider not initialized', tag: _logTag);
      return;
    }

    if (_isLoadingAd) {
      AppLogger.warning('Already loading an ad', tag: _logTag);
      return;
    }

    try {
      _isLoadingAd = true;
      _error = null;
      notifyListeners();

      await _adService.loadAd();

      AppLogger.success('Ad loaded successfully', tag: _logTag);
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to load ad: $e', tag: _logTag, error: e);
    } finally {
      _isLoadingAd = false;
      notifyListeners();
    }
  }

  /// Show the loaded rewarded ad
  Future<bool> showAd() async {
    if (!_isInitialized) {
      _error = 'Ads not initialized';
      notifyListeners();
      return false;
    }

    if (!canShowAd) {
      _error = 'No ad available to show';
      notifyListeners();
      return false;
    }

    try {
      AppLogger.info('Showing rewarded ad', tag: _logTag);

      final success = await _adService.showAd();

      if (success) {
        AppLogger.success('Ad shown successfully', tag: _logTag);
        _error = null;
      } else {
        _error = 'Failed to show ad';
        AppLogger.warning('Failed to show ad', tag: _logTag);
      }

      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Exception while showing ad: $e', tag: _logTag, error: e);
      notifyListeners();
      return false;
    }
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if the user can earn rewards (for UI display)
  bool canEarnReward() {
    return _isInitialized && canShowAd;
  }

  /// Get status message for UI
  String getStatusMessage() {
    if (!_isInitialized) {
      return 'Initializing ads...';
    } else if (_isLoadingAd) {
      return 'Loading ad...';
    } else if (canShowAd) {
      return 'Watch ad to earn $rewardAmount gemstones!';
    } else {
      return 'No ads available right now';
    }
  }

  @override
  void dispose() {
    AppLogger.info('Disposing AdProvider', tag: _logTag);
    _adService.dispose();
    super.dispose();
  }
}
