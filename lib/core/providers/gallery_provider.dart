import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../models/asset_model.dart';
import '../../services/supabase_data_service.dart';

/// Gallery Provider
///
/// Manages user's asset library and community gallery
class GalleryProvider extends ChangeNotifier {
  static const String _logTag = 'GalleryProvider';

  List<AssetModel> _userAssets = [];
  List<AssetModel> _communityAssets = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Recent';

  // Getters
  List<AssetModel> get userAssets => _filteredAssets(_userAssets);
  List<AssetModel> get communityAssets => _filteredAssets(_communityAssets);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  String get selectedSort => _selectedSort;

  // Available filters and sorts
  List<String> get availableFilters => [
    'All',
    'Favorites',
    'Public',
    'Private',
  ];
  List<String> get availableSorts => ['Recent', 'Oldest', 'Favorites'];

  /// Load user assets from database
  Future<void> loadUserAssets(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.info('Loading user assets', tag: _logTag);

      final assets = await SupabaseDataService.loadUserAssets(userId);
      _userAssets = assets;

      AppLogger.success('Loaded ${assets.length} user assets', tag: _logTag);
    } catch (e, stackTrace) {
      _error = 'Failed to load user assets: $e';
      AppLogger.error('Failed to load user assets: $e', tag: _logTag);
      AppLogger.debug('Stack trace: $stackTrace', tag: _logTag);

      // Fallback to mock data in debug mode
      if (kDebugMode) {
        _userAssets = _generateMockAssets(isUserAsset: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load community assets from database
  Future<void> loadCommunityAssets() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.info('Loading community assets', tag: _logTag);

      final assets = await SupabaseDataService.loadCommunityAssets();
      _communityAssets = assets;

      AppLogger.success(
        'Loaded ${assets.length} community assets',
        tag: _logTag,
      );
    } catch (e, stackTrace) {
      _error = 'Failed to load community assets: $e';
      AppLogger.error('Failed to load community assets: $e', tag: _logTag);
      AppLogger.debug('Stack trace: $stackTrace', tag: _logTag);

      // Fallback to mock data in debug mode
      if (kDebugMode) {
        _communityAssets = _generateMockAssets(isUserAsset: false);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle asset favorite status
  Future<void> toggleFavorite(AssetModel asset) async {
    try {
      AppLogger.info('Toggling favorite for asset: ${asset.id}', tag: _logTag);

      final success = await SupabaseDataService.toggleAssetFavorite(
        asset.id,
        !asset.isFavorite,
      );

      if (success) {
        // Update local state
        _updateAssetInList(
          _userAssets,
          asset.copyWith(isFavorite: !asset.isFavorite),
        );
        _updateAssetInList(
          _communityAssets,
          asset.copyWith(isFavorite: !asset.isFavorite),
        );
        notifyListeners();

        AppLogger.success('Asset favorite status updated', tag: _logTag);
      } else {
        _error = 'Failed to update favorite status';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      AppLogger.error('Failed to toggle favorite: $e', tag: _logTag);
      notifyListeners();
    }
  }

  /// Toggle asset public status
  Future<void> togglePublic(AssetModel asset) async {
    try {
      AppLogger.info(
        'Toggling public status for asset: ${asset.id}',
        tag: _logTag,
      );

      final success = await SupabaseDataService.toggleAssetPublic(
        asset.id,
        !asset.isPublic,
      );

      if (success) {
        // Update local state
        _updateAssetInList(
          _userAssets,
          asset.copyWith(isPublic: !asset.isPublic),
        );
        _updateAssetInList(
          _communityAssets,
          asset.copyWith(isPublic: !asset.isPublic),
        );
        notifyListeners();

        AppLogger.success('Asset public status updated', tag: _logTag);
      } else {
        _error = 'Failed to update public status';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle public status: $e';
      AppLogger.error('Failed to toggle public status: $e', tag: _logTag);
      notifyListeners();
    }
  }

  /// Delete asset
  Future<void> deleteAsset(AssetModel asset) async {
    try {
      AppLogger.info('Deleting asset: ${asset.id}', tag: _logTag);

      final success = await SupabaseDataService.deleteAsset(asset.id);

      if (success) {
        // Remove from local state
        _userAssets.removeWhere((a) => a.id == asset.id);
        _communityAssets.removeWhere((a) => a.id == asset.id);
        notifyListeners();

        AppLogger.success('Asset deleted successfully', tag: _logTag);
      } else {
        _error = 'Failed to delete asset';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to delete asset: $e';
      AppLogger.error('Failed to delete asset: $e', tag: _logTag);
      notifyListeners();
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Update filter
  void updateFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Update sort
  void updateSort(String sort) {
    _selectedSort = sort;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Filter assets based on search and filter criteria
  List<AssetModel> _filteredAssets(List<AssetModel> assets) {
    var filtered = assets.where((asset) {
      // Search filter - search in prompt since that's what we have
      if (_searchQuery.isNotEmpty &&
          !asset.prompt.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Filter by type
      switch (_selectedFilter) {
        case 'Favorites':
          return asset.isFavorite;
        case 'Public':
          return asset.isPublic;
        case 'Private':
          return !asset.isPublic;
        case 'All':
        default:
          return true;
      }
    }).toList();

    // Sort assets
    switch (_selectedSort) {
      case 'Recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Favorites':
        // Sort favorites first, then by creation date
        filtered.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    return filtered;
  }

  /// Update asset in list helper
  void _updateAssetInList(List<AssetModel> list, AssetModel updatedAsset) {
    final index = list.indexWhere((asset) => asset.id == updatedAsset.id);
    if (index != -1) {
      list[index] = updatedAsset;
    }
  }

  /// Generate mock assets for testing
  List<AssetModel> _generateMockAssets({required bool isUserAsset}) {
    return List.generate(
      20,
      (index) => AssetModel(
        id: '${isUserAsset ? 'user' : 'community'}_asset_$index',
        userId: isUserAsset ? 'current_user' : 'user_$index',
        prompt:
            'A beautiful ${['fantasy', 'futuristic', 'magical', 'mystical'][index % 4]} scene with detailed AI-generated artwork',
        imagePath: 'https://picsum.photos/300/300?random=$index',
        isPublic: !isUserAsset ? true : (index % 3 == 0),
        isFavorite: index % 4 == 0,
        createdAt: DateTime.now().subtract(Duration(days: index)),
      ),
    );
  }
}
