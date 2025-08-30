import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/assets/models/asset_model.dart';
import '../../../features/assets/providers/asset_providers.dart';
import '../services/gallery_service.dart';

/// Provider for the gallery service
final galleryServiceProvider = FutureProvider<GalleryService>((ref) async {
  final assetService = await ref.watch(assetServiceProvider.future);
  return GalleryService(assetService);
});

/// Provider for the gallery state
final galleryProvider =
    StateNotifierProvider<GalleryNotifier, AsyncValue<List<AssetModel>>>((ref) {
      return GalleryNotifier(ref);
    });

/// Notifier for managing gallery state
class GalleryNotifier extends StateNotifier<AsyncValue<List<AssetModel>>> {
  final Ref _ref;

  GalleryNotifier(this._ref) : super(const AsyncValue.loading());

  /// Fetch public assets from Supabase
  Future<void> fetchPublicAssets() async {
    state = const AsyncValue.loading();

    try {
      final galleryService = await _ref.read(galleryServiceProvider.future);
      final assets = await galleryService.fetchPublicAssets();
      state = AsyncValue.data(assets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh the gallery
  Future<void> refresh() async {
    await fetchPublicAssets();
  }

  /// Toggle the public status of an asset
  Future<void> toggleAssetPublicStatus(AssetModel asset) async {
    try {
      final galleryService = await _ref.read(galleryServiceProvider.future);
      await galleryService.toggleAssetPublicStatus(asset);
      // Refresh the gallery after updating
      await fetchPublicAssets();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
