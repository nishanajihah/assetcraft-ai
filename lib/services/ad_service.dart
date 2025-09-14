import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/providers/user_provider.dart';
import '../core/utils/logger.dart';

/// AdService for managing Google Mobile Ads (AdMob)
///
/// Handles rewarded ads that allow users to earn gemstones
/// Features:
/// - Load and show rewarded ads
/// - Platform-specific ad unit IDs
/// - Integration with UserProvider for gemstone rewards
/// - Comprehensive error handling and logging
class AdService {
  static const String _logTag = 'AdService';

  // Test Ad Unit IDs (use these for development)
  static const String _androidTestAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  // Production Ad Unit IDs
  static const String _androidProdAdUnitId =
      'ca-app-pub-2164599835834518/6904263507';
  static const String _iosProdAdUnitId =
      'ca-app-pub-2164599835834518/6904263507'; // Update with your iOS ad unit

  // Private variables
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  UserProvider? _userProvider;

  // Reward configuration
  static const int _rewardGemstones = 5;

  // Getters
  bool get isAdLoaded => _isAdLoaded;
  bool get isAdLoading => _isAdLoading;

  /// Initialize the AdService with UserProvider reference
  void initialize(UserProvider userProvider) {
    _userProvider = userProvider;
    AppLogger.info('AdService initialized', tag: _logTag);
  }

  /// Get the appropriate ad unit ID based on platform and build mode
  String get _adUnitId {
    if (kDebugMode) {
      // Use test IDs in debug mode
      return Platform.isAndroid ? _androidTestAdUnitId : _iosTestAdUnitId;
    } else {
      // Use production IDs in release mode
      return Platform.isAndroid ? _androidProdAdUnitId : _iosProdAdUnitId;
    }
  }

  /// Load a rewarded ad
  Future<void> loadAd() async {
    if (_isAdLoading) {
      AppLogger.warning('Ad is already loading', tag: _logTag);
      return;
    }

    if (_isAdLoaded) {
      AppLogger.info('Ad is already loaded', tag: _logTag);
      return;
    }

    _isAdLoading = true;
    AppLogger.info('Loading rewarded ad...', tag: _logTag);

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            AppLogger.success('Rewarded ad loaded successfully', tag: _logTag);
            _rewardedAd = ad;
            _isAdLoaded = true;
            _isAdLoading = false;

            // Set up ad callbacks
            _setupAdCallbacks();
          },
          onAdFailedToLoad: (LoadAdError error) {
            AppLogger.error(
              'Failed to load rewarded ad: ${error.message}',
              tag: _logTag,
              error: error,
            );
            _rewardedAd = null;
            _isAdLoaded = false;
            _isAdLoading = false;
          },
        ),
      );
    } catch (e) {
      AppLogger.error('Exception while loading ad: $e', tag: _logTag, error: e);
      _isAdLoading = false;
    }
  }

  /// Show the loaded rewarded ad
  Future<bool> showAd() async {
    if (_rewardedAd == null || !_isAdLoaded) {
      AppLogger.warning('No ad loaded to show', tag: _logTag);

      // Try to load an ad for next time
      loadAd();
      return false;
    }

    AppLogger.info('Showing rewarded ad', tag: _logTag);

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          AppLogger.success(
            'User earned reward: ${reward.amount} ${reward.type}',
            tag: _logTag,
          );
          _grantReward();
        },
      );

      return true;
    } catch (e) {
      AppLogger.error('Exception while showing ad: $e', tag: _logTag, error: e);
      return false;
    }
  }

  /// Set up ad lifecycle callbacks
  void _setupAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        AppLogger.info('Ad showed full screen content', tag: _logTag);
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        AppLogger.info('Ad dismissed full screen content', tag: _logTag);
        _cleanupAd();

        // Pre-load next ad
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        AppLogger.error(
          'Ad failed to show full screen content: ${error.message}',
          tag: _logTag,
          error: error,
        );
        _cleanupAd();
      },
    );
  }

  /// Grant reward to the user
  void _grantReward() {
    if (_userProvider != null) {
      _userProvider!.addGemstones(_rewardGemstones);
      AppLogger.success(
        'Granted $_rewardGemstones gemstones to user',
        tag: _logTag,
      );
    } else {
      AppLogger.error(
        'UserProvider not available, cannot grant reward',
        tag: _logTag,
      );
    }
  }

  /// Clean up ad resources
  void _cleanupAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
    AppLogger.info('Ad resources cleaned up', tag: _logTag);
  }

  /// Check if ads are available (for UI state)
  bool canShowAd() {
    return _isAdLoaded && _rewardedAd != null;
  }

  /// Get reward amount for UI display
  static int get rewardAmount => _rewardGemstones;

  /// Dispose of the service
  void dispose() {
    AppLogger.info('Disposing AdService', tag: _logTag);
    _cleanupAd();
    _userProvider = null;
  }
}
