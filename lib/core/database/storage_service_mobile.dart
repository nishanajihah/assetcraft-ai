import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/assets/models/asset_model.dart';
import '../utils/app_logger.dart';
import 'storage_service.dart';
import '../../mock/storage/mock_storage_service.dart';
import '../../mock/mock_config.dart';

/// Hive-based storage service for mobile/desktop platforms
///
/// This service provides asset storage functionality using Hive database
/// for high performance local storage with reactive updates.
class HiveStorageService extends StorageService {
  late final Box<AssetModel> _assetsBox;
  static const String _boxName = 'assets';

  HiveStorageService._(this._assetsBox);

  static Future<HiveStorageService> create() async {
    AppLogger.info('📱 Initializing Hive storage service...');

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(AssetModelAdapter().typeId)) {
        Hive.registerAdapter(AssetModelAdapter());
      }
      if (!Hive.isAdapterRegistered(AssetStatusAdapter().typeId)) {
        Hive.registerAdapter(AssetStatusAdapter());
      }

      // Open the assets box
      final box = await Hive.openBox<AssetModel>(_boxName);

      AppLogger.info(
        '✅ Hive storage service initialized with ${box.length} assets',
      );
      return HiveStorageService._(box);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize Hive storage: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> saveAsset(AssetModel asset) async {
    try {
      await _assetsBox.put(asset.supabaseId, asset);
      AppLogger.debug('💾 Asset saved: ${asset.supabaseId}');
    } catch (e) {
      AppLogger.error('❌ Failed to save asset: $e');
      rethrow;
    }
  }

  @override
  Future<AssetModel?> getAsset(String id) async {
    try {
      final asset = _assetsBox.get(id);
      AppLogger.debug(
        '🔍 Retrieved asset: $id - ${asset != null ? "found" : "not found"}',
      );
      return asset;
    } catch (e) {
      AppLogger.error('❌ Failed to get asset: $e');
      return null;
    }
  }

  @override
  Future<List<AssetModel>> getAllAssets() async {
    try {
      final assets = _assetsBox.values.toList();
      // Sort by creation date, newest first
      assets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      AppLogger.debug('📋 Retrieved ${assets.length} assets');
      return assets;
    } catch (e) {
      AppLogger.error('❌ Failed to get all assets: $e');
      return [];
    }
  }

  @override
  Future<void> deleteAsset(String id) async {
    try {
      await _assetsBox.delete(id);
      AppLogger.debug('🗑️ Asset deleted: $id');
    } catch (e) {
      AppLogger.error('❌ Failed to delete asset: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateAsset(AssetModel asset) async {
    try {
      await _assetsBox.put(asset.supabaseId, asset);
      AppLogger.debug('🔄 Asset updated: ${asset.supabaseId}');
    } catch (e) {
      AppLogger.error('❌ Failed to update asset: $e');
      rethrow;
    }
  }

  @override
  Stream<List<AssetModel>> watchAssets() {
    return _assetsBox.watch().map((_) {
      final assets = _assetsBox.values.toList();
      // Sort by creation date, newest first
      assets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return assets;
    });
  }

  @override
  Stream<List<AssetModel>> searchAssets(String query) {
    return watchAssets().map((assets) {
      return assets
          .where(
            (asset) =>
                asset.prompt.toLowerCase().contains(query.toLowerCase()) ||
                asset.tags.any(
                  (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();
    });
  }

  @override
  Stream<List<AssetModel>> getAssetsByTags(List<String> tags) {
    return watchAssets().map((assets) {
      return assets
          .where((asset) => tags.any((tag) => asset.tags.contains(tag)))
          .toList();
    });
  }

  @override
  Future<void> saveMultipleAssets(List<AssetModel> assets) async {
    try {
      await _assetsBox.putAll({
        for (final asset in assets) asset.supabaseId: asset,
      });
      AppLogger.debug('💾 ${assets.length} assets saved');
    } catch (e) {
      AppLogger.error('❌ Failed to save multiple assets: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    try {
      await _assetsBox.close();
      AppLogger.info('🔒 Hive storage service closed');
    } catch (e) {
      AppLogger.error('❌ Failed to close Hive storage: $e');
    }
  }
}

/// Factory function to create the appropriate storage service
/// Uses mock storage when ENABLE_MOCK_STORAGE is true, otherwise uses Hive
Future<StorageService> createPlatformStorage() async {
  try {
    AppLogger.info('🗃️ Initializing storage service...');

    if (MockConfig.isMockStorageEnabled) {
      AppLogger.warning('⚠️ Using mock storage service (no persistence)');
      AppLogger.info('💡 Mock mode enabled via environment configuration');
      final mockStorage = MockStorageService();
      AppLogger.info('✅ Mock storage service initialized successfully');
      return mockStorage;
    }

    // Use Hive storage for production
    AppLogger.info('📱 Initializing Hive storage service...');
    final hiveStorage = await HiveStorageService.create();
    AppLogger.info('✅ Hive storage service initialized successfully');
    return hiveStorage;
  } catch (e) {
    AppLogger.error('❌ Failed to initialize storage service: $e');
    AppLogger.info('🔄 Falling back to mock storage service...');
    return MockStorageService();
  }
}
