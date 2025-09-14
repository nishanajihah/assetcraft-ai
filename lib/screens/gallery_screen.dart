import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/gallery_provider.dart';
import '../core/providers/user_provider.dart';
import '../core/theme/app_theme.dart';
import '../ui/components/app_components.dart';
import '../core/models/asset_model.dart';

/// Gallery Screen
///
/// Displays user's personal library and community gallery
/// Features: Search, Filter, Sort, Grid/List view toggle
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _selectedSort = 'Recent';
  bool _isGridView = true;

  final List<String> _filterOptions = [
    'All',
    'Character',
    'Environment',
    'UI Element',
    'Icon',
    'Texture',
    'Logo',
  ];

  final List<String> _sortOptions = [
    'Recent',
    'Oldest',
    'Popular',
    'Name A-Z',
    'Name Z-A',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GalleryProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Get current user ID from auth
      if (userProvider.userId != null) {
        provider.loadUserAssets(userProvider.userId!);
        provider.loadCommunityAssets();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
            _buildSearchAndFilter(),
            _buildTabBar(),
            Expanded(
              child: Consumer<GalleryProvider>(
                builder: (context, provider, child) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyLibrary(provider),
                      _buildCommunityGallery(provider),
                    ],
                  );
                },
              ),
            ),
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
          Icon(Icons.photo_library, color: AppColors.primaryGold, size: 32),
          SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: Text(
              'Gallery',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return GoldButton(
                text: '${userProvider.gemstoneCount}',
                icon: Icons.diamond,
                onPressed: () {
                  // Navigate to store
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Column(
        children: [
          // Search bar
          NeomorphicTextField(
            controller: _searchController,
            hintText: 'Search assets...',
            prefixIcon: Icons.search,
            onChanged: _onSearchChanged,
          ),

          SizedBox(height: AppDimensions.spacingMedium),

          // Filter and sort options
          Row(
            children: [
              // Filter dropdown
              Expanded(
                child: _buildDropdown(
                  'Filter: $_selectedFilter',
                  _filterOptions,
                  _selectedFilter,
                  (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),

              SizedBox(width: AppDimensions.spacingMedium),

              // Sort dropdown
              Expanded(
                child: _buildDropdown(
                  'Sort: $_selectedSort',
                  _sortOptions,
                  _selectedSort,
                  (value) {
                    setState(() {
                      _selectedSort = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),

              SizedBox(width: AppDimensions.spacingMedium),

              // View toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                child: NeomorphicContainer(
                  padding: EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> options,
    String selectedValue,
    void Function(String?) onChanged,
  ) {
    return NeomorphicContainer(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: Text(hint),
          isExpanded: true,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: AppTextStyles.bodyMedium),
            );
          }).toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.surface,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.all(AppDimensions.paddingLarge),
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
            Tab(text: 'My Library'),
            Tab(text: 'Community'),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLibrary(GalleryProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.userId != null) {
          await provider.loadUserAssets(userProvider.userId!);
        }
      },
      color: AppColors.primaryGold,
      child: _buildAssetGrid(
        provider.userAssets,
        provider.isLoading,
        'Your library is empty',
        'Create your first AI asset!',
      ),
    );
  }

  Widget _buildCommunityGallery(GalleryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadCommunityAssets(),
      color: AppColors.primaryGold,
      child: _buildAssetGrid(
        provider.communityAssets,
        provider.isLoading,
        'No community assets found',
        'Be the first to share your creation!',
      ),
    );
  }

  Widget _buildAssetGrid(
    List<AssetModel> assets,
    bool isLoading,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
        ),
      );
    }

    if (assets.isEmpty) {
      return _buildEmptyState(emptyTitle, emptySubtitle);
    }

    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: _isGridView ? _buildGridView(assets) : _buildListView(assets),
    );
  }

  Widget _buildGridView(List<AssetModel> assets) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(),
        crossAxisSpacing: AppDimensions.spacingMedium,
        mainAxisSpacing: AppDimensions.spacingMedium,
        childAspectRatio: 1.0,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        return _buildAssetCard(assets[index]);
      },
    );
  }

  Widget _buildListView(List<AssetModel> assets) {
    return ListView.builder(
      itemCount: assets.length,
      itemBuilder: (context, index) {
        return _buildAssetListTile(assets[index]);
      },
    );
  }

  Widget _buildAssetCard(AssetModel asset) {
    return Hero(
      tag: 'asset_${asset.id}',
      child: GestureDetector(
        onTap: () => _openAssetDetail(asset),
        child: NeomorphicContainer(
          padding: EdgeInsets.all(AppDimensions.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Asset image
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.surfaceDim,
                    child: asset.imagePath.isNotEmpty
                        ? (asset.imagePath.startsWith('http')
                              ? Image.network(
                                  asset.imagePath,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(AppColors.primaryGold),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildImagePlaceholder();
                                  },
                                )
                              : Image.asset(
                                  asset.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildImagePlaceholder();
                                  },
                                ))
                        : _buildImagePlaceholder(),
                  ),
                ),
              ),

              SizedBox(height: AppDimensions.spacingSmall),

              // Asset info
              Text(
                asset.prompt.isNotEmpty ? asset.prompt : 'AI Generated Asset',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 4),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AI ASSET',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (asset.isFavorite)
                    Icon(Icons.favorite, size: 16, color: AppColors.accentPink),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetListTile(AssetModel asset) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingMedium),
      child: NeomorphicContainer(
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.surfaceDim,
                child: asset.imagePath.isNotEmpty
                    ? (asset.imagePath.startsWith('http')
                          ? Image.network(asset.imagePath, fit: BoxFit.cover)
                          : Image.asset(asset.imagePath, fit: BoxFit.cover))
                    : _buildImagePlaceholder(),
              ),
            ),

            SizedBox(width: AppDimensions.spacingMedium),

            // Asset info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.prompt.isNotEmpty
                        ? asset.prompt
                        : 'AI Generated Asset',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'AI ASSET',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      SizedBox(width: AppDimensions.spacingSmall),

                      Text(
                        _formatDate(asset.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (asset.isFavorite)
                  Icon(Icons.favorite, color: AppColors.accentPink, size: 20),

                SizedBox(width: AppDimensions.spacingSmall),

                GestureDetector(
                  onTap: () => _showAssetOptions(asset),
                  child: Icon(Icons.more_vert, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surfaceDim,
      child: Center(
        child: Icon(Icons.image, color: AppColors.textSecondary, size: 32),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),

          SizedBox(height: AppDimensions.spacingLarge),

          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: AppDimensions.spacingSmall),

          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppDimensions.spacingLarge),

          GoldButton(
            text: '🎨 Create Asset',
            onPressed: () {
              // Navigate to AI generation screen
              // Navigator.pushNamed(context, '/generate');
            },
            variant: ButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 4;
    } else if (screenWidth > 400) {
      return 3;
    } else {
      return 2;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _onSearchChanged(String query) {
    final provider = Provider.of<GalleryProvider>(context, listen: false);
    provider.updateSearchQuery(query);
  }

  void _applyFilters() {
    final provider = Provider.of<GalleryProvider>(context, listen: false);
    provider.updateFilter(_selectedFilter);
    provider.updateSort(_selectedSort);
  }

  void _openAssetDetail(AssetModel asset) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AssetDetailScreen(asset: asset)),
    );
  }

  void _showAssetOptions(AssetModel asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  asset.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.accentPink,
                ),
                title: Text(
                  asset.isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                ),
                onTap: () {
                  _toggleFavorite(asset);
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.share, color: AppColors.primaryGold),
                title: const Text('Share'),
                onTap: () {
                  _shareAsset(asset);
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.download, color: AppColors.accentTeal),
                title: const Text('Download'),
                onTap: () {
                  _downloadAsset(asset);
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.delete, color: AppColors.accentDeepOrange),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(asset);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleFavorite(AssetModel asset) {
    final provider = Provider.of<GalleryProvider>(context, listen: false);
    provider.toggleFavorite(asset);
  }

  void _shareAsset(AssetModel asset) {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality coming soon!')),
    );
  }

  void _downloadAsset(AssetModel asset) {
    // Implement download functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Download started!')));
  }

  void _confirmDelete(AssetModel asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: const Text(
          'Are you sure you want to delete this asset? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteAsset(asset);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDeepOrange,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAsset(AssetModel asset) {
    final provider = Provider.of<GalleryProvider>(context, listen: false);
    provider.deleteAsset(asset);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Asset deleted successfully'),
        backgroundColor: AppColors.accentDeepOrange,
      ),
    );
  }
}

/// Asset Detail Screen
///
/// Full-screen view of individual assets
class AssetDetailScreen extends StatelessWidget {
  final AssetModel asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppDimensions.paddingLarge),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: NeomorphicContainer(
                      padding: EdgeInsets.all(AppDimensions.paddingMedium),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Text(
                        'Asset Detail',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () => _shareAsset(context),
                    child: NeomorphicContainer(
                      padding: EdgeInsets.all(AppDimensions.paddingMedium),
                      child: Icon(Icons.share, color: AppColors.primaryGold),
                    ),
                  ),
                ],
              ),
            ),

            // Image
            Expanded(
              child: Hero(
                tag: 'asset_${asset.id}',
                child: Container(
                  margin: EdgeInsets.all(AppDimensions.paddingLarge),
                  child: NeomorphicContainer(
                    padding: EdgeInsets.all(AppDimensions.paddingSmall),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      child: Container(
                        width: double.infinity,
                        color: AppColors.surfaceDim,
                        child: asset.imagePath.isNotEmpty
                            ? (asset.imagePath.startsWith('http')
                                  ? Image.network(
                                      asset.imagePath,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.asset(
                                      asset.imagePath,
                                      fit: BoxFit.contain,
                                    ))
                            : Center(
                                child: Icon(
                                  Icons.image,
                                  size: 100,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Asset info
            Container(
              padding: EdgeInsets.all(AppDimensions.paddingLarge),
              child: NeomorphicContainer(
                padding: EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prompt',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGold,
                      ),
                    ),

                    SizedBox(height: AppDimensions.spacingSmall),

                    Text(
                      asset.prompt.isNotEmpty
                          ? asset.prompt
                          : 'AI Generated Asset',
                      style: AppTextStyles.bodyMedium,
                    ),

                    SizedBox(height: AppDimensions.spacingMedium),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AI ASSET',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const Spacer(),

                        Text(
                          'Created ${_formatDate(asset.createdAt)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _shareAsset(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality coming soon!')),
    );
  }
}
