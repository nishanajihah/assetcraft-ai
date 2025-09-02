import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../store/presentation/store_screen.dart';
import '../widgets/gemstone_notification_widget.dart';
import '../gemstone_ui_provider.dart';

/// Gemstone Screen - Displayed when users are out of gemstones
///
/// This screen provides options for users to earn more gemstones:
/// - Watch rewarded ads
/// - Purchase gemstone packages
/// - Information about daily gemstones
class GemstoneScreen extends ConsumerStatefulWidget {
  const GemstoneScreen({super.key});

  @override
  ConsumerState<GemstoneScreen> createState() => _GemstoneScreenState();
}

class _GemstoneScreenState extends ConsumerState<GemstoneScreen>
    with TickerProviderStateMixin {
  bool _isLoadingAd = false;
  bool _isWatchingAd = false;
  late AnimationController _sparkleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGemstones = ref.watch(currentUserGemstonesProvider);
    final isAdReady = ref.watch(isAdReadyProvider);
    final isAdLoading = ref.watch(isAdLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Get More Gemstones',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              AppColors.backgroundPrimary.withValues(alpha: 0.95),
              AppColors.backgroundPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Gemstones Status
                _buildCurrentGemstonesCard(currentGemstones),

                const SizedBox(height: 24),

                // Watch Ad Section
                _buildWatchAdSection(isAdReady, isAdLoading),

                const SizedBox(height: 24),

                // Purchase Gemstones Section
                _buildPurchaseSection(),

                const SizedBox(height: 24),

                // Daily Gemstones Info
                _buildDailyGemstonesInfo(),

                const SizedBox(height: 24),

                // Tips Section
                _buildTipsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentGemstonesCard(AsyncValue<int> currentGemstones) {
    return AppCardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryGold.withValues(alpha: 0.3),
                        AppColors.primaryGold.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.diamond,
                    color: AppColors.primaryGold,
                    size: 48,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Current Gemstones',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          currentGemstones.when(
            data: (gemstones) => Text(
              '$gemstones',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: gemstones <= 0 ? AppColors.error : AppColors.primaryGold,
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) =>
                Text('Error', style: TextStyle(color: AppColors.error)),
          ),
          if (currentGemstones.value != null &&
              currentGemstones.value! <= 0) ...[
            const SizedBox(height: 12),
            Text(
              "You're out of Gemstones!",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Watch ads or purchase more to continue creating amazing assets',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWatchAdSection(bool isAdReady, bool isAdLoading) {
    return AppCardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watch Ad to Earn Gemstones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Earn 3 free gemstones by watching a short ad',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canWatchAd(isAdReady, isAdLoading)
                  ? _watchRewardedAd
                  : null,
              icon: _isWatchingAd
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow, size: 24),
              label: Text(_getWatchAdButtonText(isAdReady, isAdLoading)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          if (!isAdReady && !isAdLoading) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ad is not ready yet. Please try again in a moment.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseSection() {
    return AppCardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGold.withValues(alpha: 0.3),
                      AppColors.primaryGold.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_bag,
                  color: AppColors.primaryGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Gemstones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Support the app and get instant gemstones',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToStore,
              icon: const Icon(Icons.store, size: 24),
              label: const Text('Visit Store'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGemstonesInfo() {
    return AppCardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.3),
                      Colors.blue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Free Gemstones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Come back tomorrow for 5 free gemstones!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return AppCardContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips to Earn More Gemstones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            '🎯',
            'Watch ads regularly',
            'Each ad gives you 3 gemstones instantly',
          ),
          const SizedBox(height: 12),
          _buildTipItem('📅', 'Log in daily', 'Get 5 free gemstones every day'),
          const SizedBox(height: 12),
          _buildTipItem(
            '💎',
            'Purchase gemstone packages',
            'Support the app and get more value',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canWatchAd(bool isAdReady, bool isAdLoading) {
    return !_isLoadingAd && !_isWatchingAd && isAdReady && !isAdLoading;
  }

  String _getWatchAdButtonText(bool isAdReady, bool isAdLoading) {
    if (_isWatchingAd) return 'Watching Ad...';
    if (_isLoadingAd || isAdLoading) return 'Loading Ad...';
    if (!isAdReady) return 'Ad Not Ready';
    return 'Watch Ad (+3 Gemstones)';
  }

  Future<void> _watchRewardedAd() async {
    setState(() {
      _isLoadingAd = true;
    });

    try {
      final adService = ref.read(adServiceProvider);

      // Try to load ad if not ready
      if (!adService.isAdReady) {
        final loaded = await adService.loadRewardedAd();
        if (!loaded) {
          _showError('Failed to load ad. Please try again later.');
          return;
        }
      }

      setState(() {
        _isLoadingAd = false;
        _isWatchingAd = true;
      });

      // Show the ad
      final rewardEarned = await adService.showRewardedAd();

      if (rewardEarned) {
        _showSuccess('Great! You earned 3 gemstones!');

        // Show success notification
        if (mounted) {
          final userService = ref.read(userServiceProvider);
          final currentGemstones = await userService.getGemstones();

          GemstoneNotificationOverlay.showAdReward(
            context,
            gemstonesReceived: 3,
            totalGemstones: currentGemstones,
          );
        }

        // Refresh gemstones count
        ref.invalidate(currentUserGemstonesProvider);
      } else {
        _showError('Ad was not completed. No reward earned.');
      }
    } catch (e) {
      AppLogger.error('Error watching rewarded ad: $e');
      _showError('Failed to show ad. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAd = false;
          _isWatchingAd = false;
        });
      }
    }
  }

  void _navigateToStore() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const StoreScreen()));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
