import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/ad_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../components/app_components.dart';

/// Rewarded Ad Button Widget
///
/// A reusable button component that allows users to watch ads and earn gemstones
/// Can be placed anywhere in the app where you want to offer ad rewards
class RewardedAdButton extends StatefulWidget {
  final String? customText;
  final VoidCallback? onRewardEarned;

  const RewardedAdButton({super.key, this.customText, this.onRewardEarned});

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAds();
    });
  }

  Future<void> _initializeAds() async {
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (!adProvider.isInitialized) {
      await adProvider.initialize(userProvider);
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AdProvider, UserProvider>(
      builder: (context, adProvider, userProvider, child) {
        if (!_isInitialized) {
          return const SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGold.withValues(alpha: 0.1),
                  AppColors.primaryGoldLight.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: AppColors.primaryGold,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watch Ad for Rewards',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: AppColors.primaryGold,
                            ),
                          ),
                          Text(
                            'Earn ${adProvider.rewardAmount} gemstones',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Gemstone count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.diamond,
                            size: 16,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${userProvider.gemstoneCount}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status message
                Text(
                  adProvider.getStatusMessage(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Error message
                if (adProvider.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentDeepOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.accentDeepOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            adProvider.error!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accentDeepOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action buttons
                Row(
                  children: [
                    // Load ad button (if needed)
                    if (!adProvider.canShowAd && !adProvider.isLoadingAd) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => adProvider.loadAd(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Load Ad'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGold,
                            side: BorderSide(color: AppColors.primaryGold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Watch ad button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: adProvider.canShowAd
                            ? () => _watchAd(adProvider)
                            : null,
                        icon: adProvider.isLoadingAd
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(widget.customText ?? 'Watch Ad'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.backgroundDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _watchAd(AdProvider adProvider) async {
    final success = await adProvider.showAd();

    if (success && mounted) {
      // Clear any errors
      adProvider.clearError();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You earned ${adProvider.rewardAmount} gemstones!'),
          backgroundColor: AppColors.accentTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Call optional callback
      widget.onRewardEarned?.call();
    }
  }
}
