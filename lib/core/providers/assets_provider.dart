import 'package:flutter/foundation.dart';
import '../database/database_service.dart';
import '../database/models/asset_model.dart';
import '../utils/app_logger.dart';

/// Global assets state provider
class AssetsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<AssetModel> _assets = [];
  List<AssetModel> _favoriteAssets = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  AssetType? _filterType;

  // Getters
  List<AssetModel> get assets => _getFilteredAssets();
  List<AssetModel> get allAssets => _assets;
  List<AssetModel> get favoriteAssets => _favoriteAssets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  AssetType? get filterType => _filterType;
  int get assetsCount => _assets.length;
  int get favoritesCount => _favoriteAssets.length;

  /// Initialize assets provider
  Future<void> initialize(String userId) async {
    _setLoading(true);
    try {
      await _loadUserAssets(userId);
      AppLogger.info(
        '🎨 Assets provider initialized: ${_assets.length} assets',
      );
    } catch (e, stackTrace) {
      _setError('Failed to initialize assets: $e');
      AppLogger.error('❌ Failed to initialize assets provider', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Load user assets from database
  Future<void> _loadUserAssets(String userId) async {
    _assets = _databaseService.getUserAssets(userId);
    _favoriteAssets = _databaseService.getFavoriteAssets(userId);
    _clearError();
    notifyListeners();
  }

  /// Refresh assets
  Future<void> refreshAssets(String userId) async {
    await _loadUserAssets(userId);
    AppLogger.info('🔄 Assets refreshed: ${_assets.length} assets');
  }

  /// Add new asset
  Future<void> addAsset(AssetModel asset) async {
    try {
      await _databaseService.saveAsset(asset);
      _assets.add(asset);
      if (asset.isFavorite) {
        _favoriteAssets.add(asset);
      }
      _clearError();
      notifyListeners();
      AppLogger.info('🎨 Asset added: ${asset.name}');
    } catch (e, stackTrace) {
      _setError('Failed to add asset: $e');
      AppLogger.error('❌ Failed to add asset', e, stackTrace);
    }
  }

  /// Update existing asset
  Future<void> updateAsset(AssetModel updatedAsset) async {
    try {
      await _databaseService.saveAsset(updatedAsset);

      final index = _assets.indexWhere((asset) => asset.id == updatedAsset.id);
      if (index != -1) {
        _assets[index] = updatedAsset;
      }

      // Update favorites list
      _favoriteAssets.removeWhere((asset) => asset.id == updatedAsset.id);
      if (updatedAsset.isFavorite) {
        _favoriteAssets.add(updatedAsset);
      }

      _clearError();
      notifyListeners();
      AppLogger.info('🎨 Asset updated: ${updatedAsset.name}');
    } catch (e, stackTrace) {
      _setError('Failed to update asset: $e');
      AppLogger.error('❌ Failed to update asset', e, stackTrace);
    }
  }

  /// Delete asset
  Future<void> deleteAsset(String assetId) async {
    try {
      await _databaseService.deleteAsset(assetId);
      _assets.removeWhere((asset) => asset.id == assetId);
      _favoriteAssets.removeWhere((asset) => asset.id == assetId);
      _clearError();
      notifyListeners();
      AppLogger.info('🗑️ Asset deleted: $assetId');
    } catch (e, stackTrace) {
      _setError('Failed to delete asset: $e');
      AppLogger.error('❌ Failed to delete asset', e, stackTrace);
    }
  }

  /// Toggle asset favorite status
  Future<void> toggleFavorite(String assetId) async {
    try {
      final asset = _assets.firstWhere((asset) => asset.id == assetId);
      final updatedAsset = asset.copyWith(
        isFavorite: !asset.isFavorite,
        updatedAt: DateTime.now(),
      );
      await updateAsset(updatedAsset);
      AppLogger.info(
        '💖 Asset favorite toggled: ${asset.name} - ${updatedAsset.isFavorite}',
      );
    } catch (e, stackTrace) {
      _setError('Failed to toggle favorite: $e');
      AppLogger.error('❌ Failed to toggle favorite', e, stackTrace);
    }
  }

  /// Search assets
  void searchAssets(String query) {
    _searchQuery = query;
    notifyListeners();
    AppLogger.debug('🔍 Assets search: $query');
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
    AppLogger.debug('🔍 Assets search cleared');
  }

  /// Filter assets by type
  void filterByType(AssetType? type) {
    _filterType = type;
    notifyListeners();
    AppLogger.debug('🔽 Assets filtered by type: ${type?.name ?? 'all'}');
  }

  /// Clear filter
  void clearFilter() {
    _filterType = null;
    notifyListeners();
    AppLogger.debug('🔽 Assets filter cleared');
  }

  /// Get filtered assets based on search and filter
  List<AssetModel> _getFilteredAssets() {
    var filtered = List<AssetModel>.from(_assets);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (asset) =>
                asset.name.toLowerCase().contains(query) ||
                asset.description.toLowerCase().contains(query) ||
                asset.tags.any((tag) => tag.toLowerCase().contains(query)),
          )
          .toList();
    }

    // Apply type filter
    if (_filterType != null) {
      filtered = filtered.where((asset) => asset.type == _filterType).toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  /// Get assets by type
  List<AssetModel> getAssetsByType(AssetType type) {
    return _assets.where((asset) => asset.type == type).toList();
  }

  /// Get recent assets
  List<AssetModel> getRecentAssets({int limit = 10}) {
    final sorted = List<AssetModel>.from(_assets);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  /// Get asset by ID
  AssetModel? getAssetById(String assetId) {
    try {
      return _assets.firstWhere((asset) => asset.id == assetId);
    } catch (e) {
      return null;
    }
  }

  /// Clear all assets
  Future<void> clearAssets() async {
    _assets.clear();
    _favoriteAssets.clear();
    _searchQuery = '';
    _filterType = null;
    _clearError();
    notifyListeners();
    AppLogger.info('🗑️ All assets cleared from provider');
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
