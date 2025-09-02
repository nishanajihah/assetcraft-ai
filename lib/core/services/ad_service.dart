import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/app_logger.dart';
import 'user_service.dart';

part 'ad_service.g.dart';

/// Service for handling AdMob rewarded ads
///
/// This service manages loading and showing rewarded ads, and handles
/// the reward logic to grant gemstones to users.
class AdService {
  final UserService _userService;
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;

  // Test Ad Unit IDs (use these during development)
  static const String _androidTestAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  // Replace these with your actual ad unit IDs in production
  static const String _androidAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  AdService(this._userService);

  /// Get the appropriate ad unit ID for the current platform
  String get _adUnitId {
    if (Platform.isAndroid) {
      return _androidTestAdUnitId; // Use test ID during development
    } else if (Platform.isIOS) {
      return _iosTestAdUnitId; // Use test ID during development
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Initialize AdMob SDK
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      AppLogger.info('📱 AdMob SDK initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize AdMob SDK: $e');
    }
  }

  /// Load a rewarded ad
  Future<bool> loadRewardedAd() async {
    if (_isLoading) {
      AppLogger.warning('⏳ Ad is already loading');
      return false;
    }

    if (_isAdLoaded) {
      AppLogger.info('✅ Ad already loaded');
      return true;
    }

    _isLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            AppLogger.info('🎯 Rewarded ad loaded successfully');
            _rewardedAd = ad;
            _isAdLoaded = true;
            _isLoading = false;

            // Set the full screen content callback
            _setFullScreenContentCallback();
          },
          onAdFailedToLoad: (LoadAdError error) {
            AppLogger.error('❌ Failed to load rewarded ad: $error');
            _rewardedAd = null;
            _isAdLoaded = false;
            _isLoading = false;
          },
        ),
      );
      return _isAdLoaded;
    } catch (e) {
      AppLogger.error('❌ Exception while loading rewarded ad: $e');
      _isLoading = false;
      return false;
    }
  }

  /// Set full screen content callback for the loaded ad
  void _setFullScreenContentCallback() {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        AppLogger.info('📺 Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        AppLogger.info('❌ Rewarded ad dismissed');
        _disposeCurrentAd();
        // Preload the next ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        AppLogger.error('❌ Rewarded ad failed to show: $error');
        _disposeCurrentAd();
      },
    );
  }

  /// Show the loaded rewarded ad
  Future<bool> showRewardedAd() async {
    if (!_isAdLoaded || _rewardedAd == null) {
      AppLogger.warning('⚠️ No ad loaded to show');
      return false;
    }

    bool rewardEarned = false;

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          AppLogger.info(
            '🎁 User earned reward: ${reward.amount} ${reward.type}',
          );

          // Award gemstones to the user
          await _awardGemstones(reward.amount.toInt());
          rewardEarned = true;
        },
      );

      return rewardEarned;
    } catch (e) {
      AppLogger.error('❌ Exception while showing rewarded ad: $e');
      return false;
    }
  }

  /// Award gemstones to the user after watching an ad
  Future<void> _awardGemstones(int baseAmount) async {
    try {
      // Award 3 gemstones for watching an ad (you can adjust this value)
      const int gemstonesAwarded = 3;

      await _userService.addGemstones(gemstonesAwarded);

      AppLogger.info('💎 Awarded $gemstonesAwarded gemstones for watching ad');
    } catch (e) {
      AppLogger.error('❌ Failed to award gemstones: $e');
      throw Exception('Failed to award gemstones after watching ad');
    }
  }

  /// Check if an ad is ready to be shown
  bool get isAdReady => _isAdLoaded && _rewardedAd != null;

  /// Check if an ad is currently loading
  bool get isLoading => _isLoading;

  /// Dispose the current ad
  void _disposeCurrentAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
  }

  /// Dispose the service and clean up resources
  void dispose() {
    _disposeCurrentAd();
  }
}

/// Provider for AdService using Riverpod
@riverpod
AdService adService(AdServiceRef ref) {
  final userService = ref.watch(userServiceProvider);
  final adService = AdService(userService);

  // Initialize AdMob when the service is created
  adService.initialize();

  // Preload the first ad
  adService.loadRewardedAd();

  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    adService.dispose();
  });

  return adService;
}

/// Provider to check if an ad is ready
@riverpod
bool isAdReady(IsAdReadyRef ref) {
  final adService = ref.watch(adServiceProvider);
  return adService.isAdReady;
}

/// Provider to check if an ad is loading
@riverpod
bool isAdLoading(IsAdLoadingRef ref) {
  final adService = ref.watch(adServiceProvider);
  return adService.isLoading;
}
