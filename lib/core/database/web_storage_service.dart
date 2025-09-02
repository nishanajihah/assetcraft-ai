import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/assets/models/asset_model.dart';
import '../utils/app_logger.dart';
import 'storage_service.dart';

/// Web-compatible storage service using SharedPreferences/localStorage
///
/// This service provides asset storage functionality for web platforms
/// using browser localStorage through SharedPreferences.
class WebStorageService extends StorageService {
  late final SharedPreferences _prefs;
  static const String _assetsKey = 'assetcraft_assets';

  // Stream controller for reactive updates
  final StreamController<List<AssetModel>> _assetsController =
      StreamController<List<AssetModel>>.broadcast();

  WebStorageService._(this._prefs);

  static Future<WebStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = WebStorageService._(prefs);
    AppLogger.info('✅ Web storage service initialized');
    return service;
  }

  @override
  Future<void> saveAsset(AssetModel asset) async {
    try {
      final assets = await getAllAssets();

      // Remove existing asset with same ID if it exists
      assets.removeWhere((a) => a.supabaseId == asset.supabaseId);

      // Add the new/updated asset
      assets.add(asset);

      // Save to localStorage
      await _saveAssetsList(assets);

      // Notify listeners
      _assetsController.add(assets);

      AppLogger.debug('💾 Asset saved to web storage: ${asset.supabaseId}');
    } catch (e) {
      AppLogger.error('❌ Failed to save asset to web storage: $e');
      rethrow;
    }
  }

  @override
  Future<AssetModel?> getAsset(String id) async {
    try {
      final assets = await getAllAssets();
      return assets.cast<AssetModel?>().firstWhere(
        (asset) => asset?.supabaseId == id,
        orElse: () => null,
      );
    } catch (e) {
      AppLogger.error('❌ Failed to get asset from web storage: $e');
      return null;
    }
  }

  @override
  Future<List<AssetModel>> getAllAssets() async {
    try {
      final assetsJson = _prefs.getString(_assetsKey);
      if (assetsJson == null || assetsJson.isEmpty) {
        return [];
      }

      final List<dynamic> assetsList = jsonDecode(assetsJson);
      return assetsList
          .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        ); // Sort by created date desc
    } catch (e) {
      AppLogger.error('❌ Failed to load assets from web storage: $e');
      return [];
    }
  }

  @override
  Future<void> deleteAsset(String id) async {
    try {
      final assets = await getAllAssets();
      assets.removeWhere((asset) => asset.supabaseId == id);

      await _saveAssetsList(assets);
      _assetsController.add(assets);

      AppLogger.debug('🗑️ Asset deleted from web storage: $id');
    } catch (e) {
      AppLogger.error('❌ Failed to delete asset from web storage: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateAsset(AssetModel asset) async {
    // Same as save for web storage
    await saveAsset(asset);
  }

  @override
  Stream<List<AssetModel>> watchAssets() {
    // Emit current assets immediately
    getAllAssets()
        .then((assets) {
          if (assets.isNotEmpty || _assetsController.hasListener) {
            _assetsController.add(assets);
          }
        })
        .catchError((error) {
          AppLogger.error('❌ Error in watchAssets: $error');
          _assetsController.add([]); // Add empty list instead of null
        });

    return _assetsController.stream;
  }

  @override
  Stream<List<AssetModel>> searchAssets(String query) {
    // For web, we'll filter in memory
    return watchAssets().map((assets) {
      return assets
          .where(
            (asset) => asset.prompt.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Stream<List<AssetModel>> getAssetsByTags(List<String> tags) {
    // For web, filter by tags in memory
    return watchAssets().map((assets) {
      return assets
          .where((asset) => tags.any((tag) => asset.tags.contains(tag)))
          .toList();
    });
  }

  @override
  Future<void> saveMultipleAssets(List<AssetModel> assets) async {
    try {
      final existingAssets = await getAllAssets();

      // Remove existing assets with same IDs and add new ones
      for (final newAsset in assets) {
        existingAssets.removeWhere((a) => a.supabaseId == newAsset.supabaseId);
        existingAssets.add(newAsset);
      }

      await _saveAssetsList(existingAssets);
      _assetsController.add(existingAssets);

      AppLogger.debug('💾 ${assets.length} assets saved to web storage');
    } catch (e) {
      AppLogger.error('❌ Failed to save multiple assets to web storage: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await _assetsController.close();
  }

  /// Helper method to save the assets list to localStorage
  Future<void> _saveAssetsList(List<AssetModel> assets) async {
    try {
      final assetsJson = jsonEncode(
        assets.map((asset) => asset.toJson()).toList(),
      );
      await _prefs.setString(_assetsKey, assetsJson);
    } catch (e) {
      AppLogger.error('❌ Failed to save assets list: $e');
      rethrow;
    }
  }
}
