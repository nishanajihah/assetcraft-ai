import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/neu_container.dart';
import '../../gemstones/gemstone_ui_provider.dart';
import '../services/store_service.dart';
import '../../gemstones/widgets/gemstone_notification_widget.dart';
import '../../../mock/mock_config.dart';
import '../../../mock/store/mock_store_service.dart';
import '../../../core/services/user_service.dart';

/// Enhanced Store Screen using the new StoreService
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
            actions: [
              // Restore purchases button
              IconButton(
                onPressed: _isLoading ? null : _restorePurchases,
                icon: const Icon(Icons.restore),
                tooltip: 'Restore Purchases',
              ),
            ],
          ),

          // Body content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Gemstone Count
                  _buildCurrentGemstonesCard(),

                  const SizedBox(height: 24),

                  // Gemstone Packages
                  _buildGemstonePackagesSection(),

                  const SizedBox(height: 24),

                  // Pro Subscription (if available)
                  _buildProSubscriptionSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentGemstonesCard() {
    final gemstonesAsync = ref.watch(currentUserGemstonesProvider);

    return NeuContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.diamond, color: AppColors.primaryGold, size: 48),
          const SizedBox(height: 12),
          Text(
            'Current Gemstones',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          gemstonesAsync.when(
            data: (gemstones) => Text(
              '$gemstones',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text(
              'Error loading gemstones',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Use Gemstones to generate amazing assets with AI',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGemstonePackagesSection() {
    // Check if mock mode is enabled
    if (MockConfig.isMockStoreEnabled) {
      return _buildMockGemstonePackages();
    }

    final packagesAsync = ref.watch(availablePackagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gemstone Packages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        packagesAsync.when(
          data: (packages) {
            if (packages.isEmpty) {
              return _buildNoPackagesAvailable();
            }

            // Filter consumable packages (gemstones)
            final gemstonePackages = packages.where((package) {
              return package.packageType == PackageType.custom ||
                  package.storeProduct.identifier.toLowerCase().contains('gem');
            }).toList();

            if (gemstonePackages.isEmpty) {
              return _buildNoPackagesAvailable();
            }

            return Column(
              children: gemstonePackages
                  .map((package) => _buildGemstonePackageCard(package))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildPackagesError(error),
        ),
      ],
    );
  }

  Widget _buildGemstonePackageCard(Package package) {
    final storeService = ref.read(storeServiceProvider);
    final gemstonesAmount = storeService.extractGemstonesFromPackage(package);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: NeuContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.diamond, color: AppColors.primaryGold, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$gemstonesAmount Gemstones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        package.storeProduct.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  package.storeProduct.priceString,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _purchasePackage(package),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.textOnGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Purchase',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProSubscriptionSection() {
    final hasSubscriptionAsync = ref.watch(hasActiveSubscriptionProvider);

    return hasSubscriptionAsync.when(
      data: (hasSubscription) {
        if (hasSubscription) {
          return _buildActiveSubscriptionCard();
        } else {
          return _buildSubscriptionOfferCard();
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildActiveSubscriptionCard() {
    return NeuContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 48),
          const SizedBox(height: 12),
          Text(
            'Pro Subscription Active',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have unlimited access to all features',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOfferCard() {
    return NeuContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.star, color: AppColors.primaryGold, size: 48),
          const SizedBox(height: 12),
          Text(
            'Go Pro',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlimited generations, premium templates, and priority support',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _showComingSoon,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.textOnGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPackagesAvailable() {
    return NeuContainer(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No packages available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Packages are currently being set up. Please check back later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesError(Object error) {
    return NeuContainer(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading packages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(availablePackagesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Purchase handling methods
  Future<void> _purchasePackage(Package package) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storeService = ref.read(storeServiceProvider);
      final result = await storeService.purchasePackage(package);

      if (!mounted) return;

      switch (result.result) {
        case PurchaseResult.success:
          _showSuccessMessage(result);
          // Refresh gemstones count
          ref.invalidate(currentUserGemstonesProvider);
          break;

        case PurchaseResult.userCancelled:
          _showMessage('Purchase cancelled', isError: false);
          break;

        case PurchaseResult.error:
          _showMessage(result.errorMessage ?? 'Purchase failed', isError: true);
          break;

        case PurchaseResult.notAllowed:
          _showMessage(
            result.errorMessage ?? 'Purchases not allowed',
            isError: true,
          );
          break;

        case PurchaseResult.alreadyOwned:
          _showMessage('You already own this item', isError: false);
          break;
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unexpected error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storeService = ref.read(storeServiceProvider);
      final result = await storeService.restorePurchases();

      if (!mounted) return;

      if (result.isSuccess) {
        _showMessage('Purchases restored successfully', isError: false);
        // Refresh providers
        ref.invalidate(currentUserGemstonesProvider);
        ref.invalidate(hasActiveSubscriptionProvider);
      } else {
        _showMessage(
          result.errorMessage ?? 'Failed to restore purchases',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error restoring purchases: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage(PurchaseResultData result) {
    if (result.gemstonesReceived != null && result.gemstonesReceived! > 0) {
      // Show in-app notification
      GemstoneNotificationOverlay.showPurchaseSuccess(
        context,
        gemstonesReceived: result.gemstonesReceived!,
        totalGemstones: 0, // Will be updated by the provider
      );
    }

    _showMessage(
      'Purchase successful! Gemstones added to your account.',
      isError: false,
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showComingSoon() {
    _showMessage('Pro subscription coming soon!', isError: false);
  }

  /// Build mock gemstone packages when in mock mode
  Widget _buildMockGemstonePackages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Gemstone Packages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGold, width: 1),
              ),
              child: const Text(
                'MOCK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: MockStoreService.mockPackages
              .where((package) => !package.isSubscription)
              .map(
                (mockPackage) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMockPackageCard(mockPackage),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  /// Build a mock package card
  Widget _buildMockPackageCard(MockPackage mockPackage) {
    return NeuContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Gemstone icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.diamond,
              color: AppColors.primaryGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Package details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mockPackage.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mockPackage.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${mockPackage.gemstones}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'gemstones',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price and purchase button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mockPackage.priceString,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _handleMockPurchase(mockPackage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.textOnGold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnGold,
                        ),
                      )
                    : const Text('Buy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handle mock purchase
  Future<void> _handleMockPurchase(MockPackage mockPackage) async {
    setState(() => _isLoading = true);

    try {
      final result = await MockStoreService.simulatePurchase(mockPackage);

      if (result.isSuccess) {
        // Add gemstones to user account
        if (result.gemstonesReceived != null && result.gemstonesReceived! > 0) {
          final userService = ref.read(userServiceProvider);
          await userService.addGemstones(result.gemstonesReceived!);
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully purchased ${mockPackage.title}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Purchase failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mock purchase error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }
}
