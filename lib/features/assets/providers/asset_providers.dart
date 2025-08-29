import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../services/asset_service.dart';
import '../../../core/database/storage_service.dart';
import '../../../core/database/web_storage_service.dart';

part 'asset_providers.g.dart';

/// Provider for the correct StorageService implementation based on platform
@riverpod
Future<StorageService> storageService(StorageServiceRef ref) async {
  if (kIsWeb) {
    // Return web implementation for web platform
    return await WebStorageService.create();
  } else {
    // Use the factory function for mobile platforms (handles mock vs real storage)
    return await StorageService.getInstance();
  }
}

/// Provider for the AssetService
@riverpod
Future<AssetService> assetService(AssetServiceRef ref) async {
  final storage = await ref.watch(storageServiceProvider.future);
  final supabase = Supabase.instance.client;

  return AssetService(storage: storage, supabase: supabase);
}

/// Initialize AssetService asynchronously (deprecated - use assetService instead)
@Deprecated('Use assetService provider instead')
@riverpod
Future<AssetService> initAssetService(InitAssetServiceRef ref) async {
  return ref.watch(assetServiceProvider.future);
}

/// Provider for getting all assets as a stream
@riverpod
Stream<List<AssetModel>> allAssets(AllAssetsRef ref) async* {
  final assetService = await ref.watch(assetServiceProvider.future);
  yield* assetService.getAssets();
}

/// Provider for getting favorite assets as a stream
@riverpod
Stream<List<AssetModel>> favoriteAssets(FavoriteAssetsRef ref) async* {
  final assetService = await ref.watch(assetServiceProvider.future);
  yield* assetService.getFavoriteAssets();
}

/// Provider for getting assets for a specific user
@riverpod
Stream<List<AssetModel>> userAssets(UserAssetsRef ref, String userId) async* {
  final assetService = await ref.watch(assetServiceProvider.future);
  yield* assetService.getAssetsForUser(userId);
}

/// Provider for searching assets
@riverpod
Stream<List<AssetModel>> searchAssets(
  SearchAssetsRef ref,
  String query,
) async* {
  final assetService = await ref.watch(assetServiceProvider.future);
  yield* assetService.searchAssets(query);
}

/// Provider for getting assets by tags
@riverpod
Stream<List<AssetModel>> assetsByTags(
  AssetsByTagsRef ref,
  List<String> tags,
) async* {
  final assetService = await ref.watch(assetServiceProvider.future);
  yield* assetService.getAssetsByTags(tags);
}
