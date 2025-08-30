import '../../../features/assets/models/asset_model.dart';
import '../../../features/assets/services/asset_service.dart';
import '../../../core/utils/app_logger.dart';

/// Service for managing the community gallery functionality
class GalleryService {
  final AssetService _assetService;

  GalleryService(this._assetService);

  /// Fetch all public assets from Supabase
  Future<List<AssetModel>> fetchPublicAssets() async {
    try {
      AppLogger.info('Fetching public assets via AssetService');
      return await _assetService.getPublicAssets();
    } catch (error) {
      AppLogger.error('Error fetching public assets: $error');
      throw Exception('Failed to fetch public assets: $error');
    }
  }

  /// Toggle the public status of an asset
  Future<void> toggleAssetPublicStatus(AssetModel asset) async {
    try {
      AppLogger.info('Toggling public status for asset: ${asset.supabaseId}');
      await _assetService.toggleAssetPublicStatus(asset);
      AppLogger.info('Successfully updated asset public status');
    } catch (error) {
      AppLogger.error('Error toggling asset public status: $error');
      throw Exception('Failed to update asset public status: $error');
    }
  }

  /// Get recent public assets (limited count for featured section)
  Future<List<AssetModel>> getRecentPublicAssets({int limit = 10}) async {
    try {
      AppLogger.info('Fetching recent public assets (limit: $limit)');

      final allPublicAssets = await _assetService.getPublicAssets();

      // Return limited number of assets
      final recentAssets = allPublicAssets.take(limit).toList();

      AppLogger.info(
        'Successfully fetched ${recentAssets.length} recent public assets',
      );
      return recentAssets;
    } catch (error) {
      AppLogger.error('Error fetching recent public assets: $error');
      throw Exception('Failed to fetch recent public assets: $error');
    }
  }

  /// Get public assets count for analytics
  Future<int> getPublicAssetsCount() async {
    try {
      final publicAssets = await _assetService.getPublicAssets();
      return publicAssets.length;
    } catch (error) {
      AppLogger.error('Error getting public assets count: $error');
      return 0;
    }
  }
}
