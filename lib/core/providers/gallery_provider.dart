import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../models/asset_model.dart';

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

  /// Load user's personal assets
  Future<void> loadUserAssets() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.info('Loading user assets', tag: _logTag);

      // Simulate loading user assets
      await Future.delayed(const Duration(seconds: 1));

      // Mock data for now - replace with actual data loading
      _userAssets = _generateMockAssets(isUserAsset: true);

      AppLogger.success('User assets loaded successfully', tag: _logTag);
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to load user assets: $e', tag: _logTag);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load community gallery assets
  Future<void> loadCommunityAssets() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.info('Loading community assets', tag: _logTag);

      // Simulate loading community assets
      await Future.delayed(const Duration(seconds: 1));

      // Mock data for now - replace with actual data loading
      _communityAssets = _generateMockAssets(isUserAsset: false);

      AppLogger.success('Community assets loaded successfully', tag: _logTag);
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to load community assets: $e', tag: _logTag);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Update filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Update sort
  void setSort(String sort) {
    _selectedSort = sort;
    notifyListeners();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(AssetModel asset) async {
    try {
      AppLogger.info('Toggling favorite for asset: ${asset.id}', tag: _logTag);

      // Update local state
      asset.isFavorite = !asset.isFavorite;
      notifyListeners();

      // Here you would sync with backend
    } catch (e) {
      AppLogger.error('Failed to toggle favorite: $e', tag: _logTag);
    }
  }

  /// Delete asset
  Future<void> deleteAsset(AssetModel asset) async {
    try {
      AppLogger.info('Deleting asset: ${asset.id}', tag: _logTag);

      // Remove from local list
      _userAssets.removeWhere((a) => a.id == asset.id);
      notifyListeners();

      // Here you would delete from backend
    } catch (e) {
      AppLogger.error('Failed to delete asset: $e', tag: _logTag);
    }
  }

  /// Filter assets based on search and filter criteria
  List<AssetModel> _filteredAssets(List<AssetModel> assets) {
    var filtered = assets.where((asset) {
      // Search filter
      if (_searchQuery.isNotEmpty &&
          !asset.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !asset.tags.any(
            (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
          )) {
        return false;
      }

      // Category filter
      if (_selectedFilter != 'All' && asset.category != _selectedFilter) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    switch (_selectedSort) {
      case 'Recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Popular':
        filtered.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case 'Name A-Z':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Name Z-A':
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    return filtered;
  }

  /// Generate mock assets for testing
  List<AssetModel> _generateMockAssets({required bool isUserAsset}) {
    return List.generate(
      20,
      (index) => AssetModel(
        id: '${isUserAsset ? 'user' : 'community'}_asset_$index',
        title: '${isUserAsset ? 'My' : 'Community'} Asset ${index + 1}',
        description: 'A beautiful AI-generated asset',
        imageUrl: 'https://picsum.photos/300/300?random=$index',
        category: [
          'Character',
          'Environment',
          'UI Element',
          'Icon',
          'Texture',
        ][index % 5],
        tags: ['ai-generated', 'fantasy', 'digital-art'],
        createdAt: DateTime.now().subtract(Duration(days: index)),
        likes: (index * 5) + 10,
        isPublic: !isUserAsset ? true : (index % 3 == 0),
        isFavorite: index % 4 == 0,
        authorId: isUserAsset ? 'current_user' : 'user_$index',
        authorName: isUserAsset ? 'You' : 'Artist ${index + 1}',
        cloudUrl: 'https://picsum.photos/300/300?random=$index',
        prompt:
            'A beautiful ${['fantasy', 'futuristic', 'magical', 'mystical'][index % 4]} scene',
        assetType: [
          'Character',
          'Environment',
          'UI Element',
          'Icon',
          'Texture',
        ][index % 5],
      ),
    );
  }

  /// Clear all data
  void clearData() {
    _userAssets.clear();
    _communityAssets.clear();
    _searchQuery = '';
    _selectedFilter = 'All';
    _selectedSort = 'Recent';
    _error = null;
    notifyListeners();
  }
}
