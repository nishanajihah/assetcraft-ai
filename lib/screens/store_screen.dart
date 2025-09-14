import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/store_provider.dart';
import '../core/providers/user_provider.dart';
import '../core/theme/app_theme.dart';
import '../ui/components/app_components.dart';
import '../ui/widgets/buttons/rewarded_ad_button.dart';

/// Store Screen
///
/// Handles in-app purchases for gemstone packs and subscriptions
/// Features: RevenueCat integration, rewarded ads, restore purchases
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Load store data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StoreProvider>(context, listen: false);
      provider.loadProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: Consumer<StoreProvider>(
                builder: (context, provider, child) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGemstonePacksTab(provider),
                      _buildSubscriptionsTab(provider),
                      _buildRewardsTab(provider),
                    ],
                  );
                },
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        children: [
          Icon(Icons.store, color: AppColors.primaryGold, size: 32),
          SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: Text(
              'Gemstone Store',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return GemstoneCounter(count: userProvider.gemstoneCount);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: NeomorphicContainer(
        padding: EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primaryGold,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Packs'),
            Tab(text: 'Premium'),
            Tab(text: 'Rewards'),
          ],
        ),
      ),
    );
  }

  Widget _buildGemstonePacksTab(StoreProvider provider) {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💎 Gemstone Packs',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryGold,
            ),
          ),
          SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'Purchase gemstones to create unlimited AI assets',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppDimensions.spacingLarge),

          if (provider.isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGold,
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: provider.gemstonePacks.length,
                itemBuilder: (context, index) {
                  final package = provider.gemstonePacks[index];
                  return _buildGemstonePackCard(package, provider);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGemstonePackCard(
    GemstonePackModel package,
    StoreProvider provider,
  ) {
    final isPopular = package.isPopular;
    final isBestValue = package.discount != null && package.discount! > 20;

    return Stack(
      children: [
        NeomorphicContainer(
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gemstone icon with animation for popular packs
              if (isPopular)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryGold,
                              AppColors.accentDeepOrange,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.diamond,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

              SizedBox(height: AppDimensions.spacingMedium),

              Text(
                '${package.gemstoneCount} Gems',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: AppDimensions.spacingSmall),

              if (package.discount != null && package.discount! > 0)
                Text(
                  '+${package.discount}% Bonus!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              SizedBox(height: AppDimensions.spacingMedium),

              GoldButton(
                text: '\$${package.price.toStringAsFixed(2)}',
                onPressed: provider.isLoading
                    ? null
                    : () => _purchasePackage(package, provider),
                variant: isPopular
                    ? ButtonVariant.primary
                    : ButtonVariant.secondary,
                isLoading: provider.isLoading,
              ),
            ],
          ),
        ),

        // Popular badge
        if (isPopular)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentDeepOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'POPULAR',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Best value badge
        if (isBestValue)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'BEST VALUE',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubscriptionsTab(StoreProvider provider) {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👑 Premium Subscriptions',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryGold,
            ),
          ),
          SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'Unlock unlimited creativity with premium features',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppDimensions.spacingLarge),

          if (provider.isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGold,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: provider.subscriptions.length,
                itemBuilder: (context, index) {
                  final plan = provider.subscriptions[index];
                  return _buildSubscriptionCard(plan, provider);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(
    SubscriptionModel plan,
    StoreProvider provider,
  ) {
    final features = plan.features;
    final isRecommended = plan.isPopular;

    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingMedium),
      child: Stack(
        children: [
          NeomorphicContainer(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRecommended
                              ? [
                                  AppColors.primaryGold,
                                  AppColors.accentDeepOrange,
                                ]
                              : [AppColors.accentTeal, AppColors.accentBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isRecommended ? Icons.star : Icons.workspace_premium,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    SizedBox(width: AppDimensions.spacingMedium),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: AppTextStyles.headingSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            plan.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${plan.price.toStringAsFixed(2)}',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          plan.period.displayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: AppDimensions.spacingMedium),

                // Features list
                Column(
                  children: features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.accentTeal,
                            size: 16,
                          ),
                          SizedBox(width: AppDimensions.spacingSmall),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: AppDimensions.spacingMedium),

                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    text: 'Subscribe',
                    onPressed: provider.isLoading
                        ? null
                        : () => _subscribeToPlan(plan, provider),
                    variant: isRecommended
                        ? ButtonVariant.primary
                        : ButtonVariant.secondary,
                    isLoading: provider.isLoading,
                  ),
                ),
              ],
            ),
          ),

          // Recommended badge
          if (isRecommended)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGold, AppColors.accentDeepOrange],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'RECOMMENDED',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(StoreProvider provider) {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎁 Free Rewards',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryGold,
            ),
          ),
          SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'Earn free gemstones by watching ads and completing tasks',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppDimensions.spacingLarge),

          // Watch ad for gems - New AdMob Integration
          const RewardedAdButton(customText: 'Watch Ad (+5 Gems)'),

          SizedBox(height: AppDimensions.spacingLarge),

          // Daily bonus
          NeomorphicContainer(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                SizedBox(width: AppDimensions.spacingMedium),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Bonus',
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.hasDailyBonus
                            ? 'Claim your daily 1 gemstone!'
                            : 'Come back tomorrow for your bonus',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                GoldButton(
                  text: provider.hasDailyBonus ? 'Claim' : 'Claimed',
                  onPressed: provider.hasDailyBonus && !provider.isClaimingDaily
                      ? () => _claimDailyBonus(provider)
                      : null,
                  variant: ButtonVariant.secondary,
                  isLoading: provider.isClaimingDaily,
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingLarge),

          // Special offers
          NeomorphicContainer(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      color: AppColors.accentPink,
                      size: 24,
                    ),
                    SizedBox(width: AppDimensions.spacingSmall),
                    Text(
                      'Special Offers',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppDimensions.spacingSmall),

                Text(
                  '🎉 Welcome bonus: Get 10 free gems on your first purchase!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: AppDimensions.spacingSmall),

                Text(
                  '⭐ Rate us 5 stars to get 5 bonus gems!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusLarge),
          topRight: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GoldButton(
              text: '↻ Restore Purchases',
              onPressed: () => _restorePurchases(),
              variant: ButtonVariant.outline,
            ),
          ),
          SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: GoldButton(
              text: 'Terms & Privacy',
              onPressed: () => _showTermsAndPrivacy(),
              variant: ButtonVariant.outline,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchasePackage(
    GemstonePackModel package,
    StoreProvider provider,
  ) async {
    try {
      final success = await provider.purchaseGemstonesPack(package);
      if (success) {
        _showPurchaseSuccessDialog(package.gemstoneCount);
      } else {
        _showPurchaseErrorDialog();
      }
    } catch (e) {
      _showPurchaseErrorDialog(e.toString());
    }
  }

  Future<void> _subscribeToPlan(
    SubscriptionModel plan,
    StoreProvider provider,
  ) async {
    try {
      final success = await provider.purchaseSubscription(plan);
      if (success) {
        _showSubscriptionSuccessDialog(plan.name);
      } else {
        _showPurchaseErrorDialog();
      }
    } catch (e) {
      _showPurchaseErrorDialog(e.toString());
    }
  }

  Future<void> _claimDailyBonus(StoreProvider provider) async {
    try {
      final success = await provider.claimDailyBonus();
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎁 Daily bonus claimed! +1 gemstone'),
            backgroundColor: AppColors.primaryGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim bonus: $e'),
            backgroundColor: AppColors.accentDeepOrange,
          ),
        );
      }
    }
  }

  void _restorePurchases() async {
    final provider = Provider.of<StoreProvider>(context, listen: false);
    try {
      await provider.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: AppColors.accentTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: $e'),
            backgroundColor: AppColors.accentDeepOrange,
          ),
        );
      }
    }
  }

  void _showTermsAndPrivacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legal Information'),
        content: const Text(
          'Terms of Service and Privacy Policy will be displayed here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseSuccessDialog(int gems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Purchase Successful!'),
        content: Text('You received $gems gemstones!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionSuccessDialog(String planName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👑 Welcome to Premium!'),
        content: Text(
          'You\'re now subscribed to $planName. Enjoy unlimited creativity!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Start Creating!'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseErrorDialog([String? error]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Failed'),
        content: Text(error ?? 'Something went wrong. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
