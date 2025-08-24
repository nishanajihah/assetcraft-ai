import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/neu_container.dart';
import '../../../core/services/user_service.dart';
import '../providers/store_providers.dart';

/// Store Screen for purchasing Gemstones and Pro subscription
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App Bar
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Get Gemstones',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),

        // Body content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Gemstone Count
                NeuContainer(
                  padding: const EdgeInsets.all(24),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final creditsAsync = ref.watch(userCreditsProvider);

                      return Column(
                        children: [
                          Icon(
                            Icons.diamond,
                            size: 48,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your Gemstones',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          creditsAsync.when(
                            data: (credits) => Text(
                              '$credits Gemstones',
                              style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text(
                              '0 Gemstones',
                              style: TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Each gemstone generates one high-quality asset',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Gemstone Packs Section
                const Text(
                  'Gemstone Packs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Gemstone Packs Grid
                Consumer(
                  builder: (context, ref, child) {
                    final offeringsAsync = ref.watch(offeringsProvider);

                    return offeringsAsync.when(
                      data: (offerings) {
                        // Check if offerings and current package are available
                        if (offerings.current == null ||
                            offerings.current!.availablePackages.isEmpty) {
                          return _buildPlaceholderGemstonesGrid();
                        }

                        // Get consumable packages (one-time purchases)
                        final consumablePackages = offerings
                            .current!
                            .availablePackages
                            .where(
                              (package) =>
                                  package.packageType == PackageType.lifetime ||
                                  package.packageType == PackageType.custom,
                            )
                            .toList();

                        if (consumablePackages.isEmpty) {
                          return _buildPlaceholderGemstonesGrid();
                        }

                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.8,
                              ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: consumablePackages.length,
                          itemBuilder: (context, index) {
                            final package = consumablePackages[index];
                            final product = package.storeProduct;

                            // Extract gemstone amount from product identifier
                            // Assuming product identifiers follow pattern like "gems_10", "gems_25", etc.
                            final String productId = product.identifier;
                            int gemAmount = 0;

                            if (productId.contains('_')) {
                              final parts = productId.split('_');
                              if (parts.length > 1) {
                                gemAmount = int.tryParse(parts.last) ?? 0;
                              }
                            }

                            return _buildGemstonePackCard(
                              '${gemAmount > 0 ? gemAmount : ''} Gemstones',
                              product.priceString,
                              gemAmount,
                              package,
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildPlaceholderGemstonesGrid(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Pro Subscription Section
                const Text(
                  'Pro Subscription',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Pro Subscription Card
                _buildProSubscriptionCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build gemstone pack cards
  Widget _buildGemstonePackCard(
    String title,
    String price,
    int amount, [
    Package? package,
  ]) {
    return NeuContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.diamond, size: 32, color: AppColors.primaryGold),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              if (package != null) {
                try {
                  debugPrint('🛒 Purchasing ${package.identifier}...');
                  final purchaseResult = await Purchases.purchasePackage(
                    package,
                  );
                  debugPrint(
                    '✅ Purchase completed: ${purchaseResult.entitlements.all}',
                  );

                  // TODO: Update user's gemstone count based on purchase
                  // This would typically involve calling a backend API

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Purchase successful! Gemstones added to your account.',
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint('❌ Purchase failed: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Purchase failed: ${e.toString()}')),
                  );
                }
              } else {
                debugPrint('⚠️ Cannot purchase: Package is null');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.textOnGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  // Helper method to build pro subscription card
  Widget _buildProSubscriptionCard() {
    return Consumer(
      builder: (context, ref, child) {
        final offeringsAsync = ref.watch(offeringsProvider);

        return offeringsAsync.when(
          data: (offerings) {
            // Check if offerings and current package are available
            if (offerings.current == null) {
              return _buildPlaceholderProCard();
            }

            // Get subscription packages
            final subscriptionPackages = offerings.current!.availablePackages
                .where(
                  (package) =>
                      package.packageType == PackageType.monthly ||
                      package.packageType == PackageType.annual,
                )
                .toList();

            if (subscriptionPackages.isEmpty) {
              return _buildPlaceholderProCard();
            }

            // Find monthly and annual packages
            Package? monthlyPackage = subscriptionPackages.firstWhere(
              (package) => package.packageType == PackageType.monthly,
              orElse: () => subscriptionPackages.first,
            );

            Package? annualPackage;
            try {
              annualPackage = subscriptionPackages.firstWhere(
                (package) => package.packageType == PackageType.annual,
              );
            } catch (e) {
              annualPackage = null;
            }

            return NeuContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 32, color: AppColors.primaryGold),
                      const SizedBox(width: 8),
                      const Text(
                        'AssetCraft Pro',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unlimited access to all features',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Feature list
                  ..._buildFeatureList([
                    'Unlimited asset generation',
                    'Priority processing',
                    'Advanced customization options',
                    'Commercial usage rights',
                    'Early access to new features',
                  ]),
                  const SizedBox(height: 16),
                  // Price
                  Text(
                    '${monthlyPackage.storeProduct.priceString}/month',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (annualPackage != null)
                    Text(
                      'or ${annualPackage.storeProduct.priceString}/year (save 17%)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Subscribe button
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        debugPrint(
                          '🛒 Purchasing subscription ${monthlyPackage.identifier}...',
                        );
                        final purchaseResult = await Purchases.purchasePackage(
                          monthlyPackage,
                        );
                        debugPrint(
                          '✅ Subscription purchase completed: ${purchaseResult.entitlements.all}',
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Subscription successful! You now have AssetCraft Pro.',
                            ),
                          ),
                        );
                      } catch (e) {
                        debugPrint('❌ Subscription purchase failed: $e');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Subscription failed: ${e.toString()}',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.textOnGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Subscribe Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildPlaceholderProCard(),
        );
      },
    );
  }

  // Helper method to build feature list items
  List<Widget> _buildFeatureList(List<String> features) {
    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primaryGold, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                feature,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Helper method to build placeholder gemstones grid when RevenueCat data is not available
  Widget _buildPlaceholderGemstonesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.8,
      children: [
        _buildGemstonePackCard('10 Gemstones', '\$4.99', 10),
        _buildGemstonePackCard('25 Gemstones', '\$9.99', 25),
        _buildGemstonePackCard('50 Gemstones', '\$14.99', 50),
        _buildGemstonePackCard('100 Gemstones', '\$24.99', 100),
      ],
    );
  }

  // Helper method to build placeholder pro card when RevenueCat data is not available
  Widget _buildPlaceholderProCard() {
    return NeuContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 32, color: AppColors.primaryGold),
              const SizedBox(width: 8),
              const Text(
                'AssetCraft Pro',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlimited access to all features',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Feature list
          ..._buildFeatureList([
            'Unlimited asset generation',
            'Priority processing',
            'Advanced customization options',
            'Commercial usage rights',
            'Early access to new features',
          ]),
          const SizedBox(height: 16),
          // Price
          const Text(
            '\$19.99/month',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'or \$199.99/year (save 17%)',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // Subscribe button
          ElevatedButton(
            onPressed: () {
              // TODO: Implement subscription logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.textOnGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Subscribe Now',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
