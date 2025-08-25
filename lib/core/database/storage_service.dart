import 'package:flutter/foundation.dart';
import '../../features/assets/models/asset_model.dart';

// Platform-specific imports
import 'storage_service_mobile.dart'
    if (dart.library.html) 'storage_service_web.dart';

/// Abstract storage service that works across all platforms
abstract class StorageService {
  static StorageService? _instance;

  /// Get the appropriate storage service instance based on platform
  static Future<StorageService> getInstance() async {
    if (_instance != null) {
      return _instance!;
    }

    _instance = await createPlatformStorage();
    return _instance!;
  }

  // Abstract methods that must be implemented by platform-specific services
  Future<void> saveAsset(AssetModel asset);
  Future<AssetModel?> getAsset(String id);
  Future<List<AssetModel>> getAllAssets();
  Future<void> deleteAsset(String id);
  Future<void> updateAsset(AssetModel asset);
  Stream<List<AssetModel>> watchAssets();

  // Query methods
  Stream<List<AssetModel>> searchAssets(String query);
  Stream<List<AssetModel>> getAssetsByTags(List<String> tags);
  Future<void> saveMultipleAssets(List<AssetModel> assets);

  Future<void> close();
}
