import '../utils/app_logger.dart';
import 'storage_service.dart';
import 'isar_service.dart';
import '../../features/assets/models/asset_model.dart';

/// Isar-based storage service for mobile/desktop
class IsarStorageService extends StorageService {
  late final dynamic _isar; // Using dynamic to avoid import issues on web

  IsarStorageService._(this._isar);

  @override
  Future<void> saveAsset(AssetModel asset) async {
    await _isar.writeTxn(() async {
      await _isar.assetModels.put(asset);
    });
  }

  @override
  Future<AssetModel?> getAsset(String id) async {
    return await _isar.assetModels.filter().supabaseIdEqualTo(id).findFirst();
  }

  @override
  Future<List<AssetModel>> getAllAssets() async {
    return await _isar.assetModels.where().sortByCreatedAtDesc().findAll();
  }

  @override
  Future<void> deleteAsset(String id) async {
    await _isar.writeTxn(() async {
      final asset = await _isar.assetModels
          .filter()
          .supabaseIdEqualTo(id)
          .findFirst();
      if (asset != null) {
        await _isar.assetModels.delete(asset.id);
      }
    });
  }

  @override
  Future<void> updateAsset(AssetModel asset) async {
    await _isar.writeTxn(() async {
      await _isar.assetModels.put(asset);
    });
  }

  @override
  Stream<List<AssetModel>> watchAssets() {
    return _isar.assetModels.where().sortByCreatedAtDesc().watch(
      fireImmediately: true,
    );
  }

  @override
  Stream<List<AssetModel>> searchAssets(String query) {
    return _isar.assetModels
        .filter()
        .promptContains(query, caseSensitive: false)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Stream<List<AssetModel>> getAssetsByTags(List<String> tags) {
    return _isar.assetModels
        .filter()
        .anyOf(tags, (q, tag) => q.tagsElementContains(tag))
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<void> saveMultipleAssets(List<AssetModel> assets) async {
    await _isar.writeTxn(() async {
      await _isar.assetModels.putAll(assets);
    });
  }

  @override
  Future<void> close() async {
    await IsarService.close();
  }
}

/// Mobile/Desktop storage factory
Future<StorageService> createPlatformStorage() async {
  AppLogger.info('📱 Initializing Isar storage service...');
  final isar = await IsarService.getInstance();
  return IsarStorageService._(isar);
}
