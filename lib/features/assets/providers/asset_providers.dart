import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asset_model.dart';
import '../services/asset_service.dart';
import '../../../core/database/storage_service.dart';

part 'asset_providers.g.dart';

/// Provider for the AssetService
@Riverpod(keepAlive: true)
AssetService assetService(Ref ref) {
  throw UnimplementedError(
    'AssetService needs to be initialized asynchronously',
  );
}

/// Initialize AssetService asynchronously
@riverpod
Future<AssetService> initAssetService(Ref ref) async {
  final storage = await StorageService.getInstance();
  final supabase = Supabase.instance.client;

  return AssetService(storage: storage, supabase: supabase);
}

/// Provider for getting all assets as a stream
@riverpod
Stream<List<AssetModel>> allAssets(Ref ref) async* {
  final assetService = await ref.watch(initAssetServiceProvider.future);
  yield* assetService.getAssets();
}

/// Provider for getting favorite assets as a stream
@riverpod
Stream<List<AssetModel>> favoriteAssets(Ref ref) async* {
  final assetService = await ref.watch(initAssetServiceProvider.future);
  yield* assetService.getFavoriteAssets();
}

/// Provider for getting assets for a specific user
@riverpod
Stream<List<AssetModel>> userAssets(Ref ref, String userId) async* {
  final assetService = await ref.watch(initAssetServiceProvider.future);
  yield* assetService.getAssetsForUser(userId);
}

/// Provider for searching assets
@riverpod
Stream<List<AssetModel>> searchAssets(Ref ref, String query) async* {
  final assetService = await ref.watch(initAssetServiceProvider.future);
  yield* assetService.searchAssets(query);
}

/// Provider for getting assets by tags
@riverpod
Stream<List<AssetModel>> assetsByTags(Ref ref, List<String> tags) async* {
  final assetService = await ref.watch(initAssetServiceProvider.future);
  yield* assetService.getAssetsByTags(tags);
}
