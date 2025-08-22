import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../features/assets/providers/asset_providers.dart';
import '../../../features/assets/models/asset_model.dart';
import '../../../shared/widgets/neu_container.dart';
import '../../../shared/widgets/app_shell.dart';

/// Asset Library Screen - Browse and manage generated assets
class AssetLibraryScreen extends ConsumerStatefulWidget {
  const AssetLibraryScreen({super.key});

  @override
  ConsumerState<AssetLibraryScreen> createState() => _AssetLibraryScreenState();
}

class _AssetLibraryScreenState extends ConsumerState<AssetLibraryScreen> {
  String? _userId;
  
  @override
  void initState() {
    super.initState();
    _getUserId();
  }
  
  /// Build the empty state widget when no assets are available
  Widget _buildEmptyState() {
    return Center(
      child: NeuContainer(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Assets Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start creating amazing assets with AI',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Get the parent widget that contains the bottom navigation
                final ScaffoldMessengerState? scaffold = ScaffoldMessenger.of(context);
                if (scaffold != null) {
                  // Show a snackbar to inform the user to tap on the Generate tab
                  scaffold.showSnackBar(
                    const SnackBar(
                      content: Text('Tap on the Generate tab to create your first asset'),
                      duration: Duration(seconds: 3),
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
              ),
              child: const Text('Create First Asset'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the asset grid to display all assets
  Widget _buildAssetGrid(List<AssetModel> assets) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return _buildAssetCard(asset);
      },
    );
  }
  
  /// Build a card for a single asset
  Widget _buildAssetCard(AssetModel asset) {
    return NeuContainer(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: asset.imagePath.startsWith('local://')
                ? const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  )
                : Image.network(
                    asset.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      AppLogger.warning('Error loading image: $error');
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
            ),
          ),
          
          // Asset info
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tags
                if (asset.tags.isNotEmpty)
                  Expanded(
                    child: Text(
                      asset.tags.first,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                // Favorite icon
                if (asset.isFavorite)
                  const Icon(
                    Icons.favorite,
                    size: 16,
                    color: AppColors.primaryGold,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  
  void _getUserId() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _userId = user.id;
        });
      } else {
        // Fallback to anonymous user
        setState(() {
          _userId = 'anonymous_user';
        });
      }
    } catch (e) {
      AppLogger.warning('Could not get authenticated user: $e');
      setState(() {
        _userId = 'anonymous_user';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom App Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Asset Library',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Implement search
                },
                icon: const Icon(Icons.search),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Implement filter
                },
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
        ),
        // Body content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats Card
                NeuContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Assets',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _userId == null
                              ? const Text(
                                  '0',
                                  style: TextStyle(
                                    color: AppColors.primaryGold,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Consumer(
                                  builder: (context, ref, child) {
                                    final assetsStream = ref.watch(userAssetsProvider(_userId!));
                                    
                                    return assetsStream.when(
                                      data: (assets) => Text(
                                        '${assets.length}',
                                        style: const TextStyle(
                                          color: AppColors.primaryGold,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      loading: () => const Text(
                                        '...',
                                        style: TextStyle(
                                          color: AppColors.primaryGold,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      error: (_, __) => const Text(
                                        '0',
                                        style: TextStyle(
                                          color: AppColors.primaryGold,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.glassBorder,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Storage Used',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _userId == null
                              ? const Text(
                                  '0 MB',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : Consumer(
                                  builder: (context, ref, child) {
                                    final assetsStream = ref.watch(userAssetsProvider(_userId!));
                                    
                                    return assetsStream.when(
                                      data: (assets) {
                                        // Calculate total storage in MB
                                        final totalBytes = assets.fold<int>(
                                          0,
                                          (sum, asset) => sum + (asset.fileSizeBytes ?? 0),
                                        );
                                        final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
                                        
                                        return Text(
                                          '$totalMB MB',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        );
                                      },
                                      loading: () => const Text(
                                        '...',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      error: (_, __) => const Text(
                                        '0 MB',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Asset Grid or Empty State
                Expanded(
                  child: _userId == null
                    ? _buildEmptyState()
                    : Consumer(
                        builder: (context, ref, child) {
                          final assetsStream = ref.watch(userAssetsProvider(_userId!));
                          
                          return assetsStream.when(
                            data: (assets) {
                              if (assets.isEmpty) {
                                return _buildEmptyState();
                              }
                              
                              return _buildAssetGrid(assets);
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stackTrace) {
                              AppLogger.error('Error loading assets: $error');
                              return Center(
                                child: Text('Error loading assets: $error'),
                              );
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
