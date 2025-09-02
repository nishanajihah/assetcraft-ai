import '../../core/utils/app_logger.dart';
import '../../core/database/storage_service.dart';
import '../../features/assets/models/asset_model.dart';

/// Mock storage service for development and testing
///
/// This service provides in-memory storage without persistence.
/// Used when Hive is not available or for testing purposes.
/// All data is lost when the app restarts.
class MockStorageService extends StorageService {
  final List<AssetModel> _assets = [];
  static int _idCounter = 1;

  /// Create some sample data for development
  MockStorageService() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    final sampleAssets = [
      AssetModel(
        supabaseId: 'sample_1',
        userId: 'user_123',
        prompt: 'A beautiful sunset over mountains',
        imagePath: 'https://picsum.photos/512/512?random=1',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isFavorite: false,
        tags: ['sunset', 'mountains', 'nature'],
        imageWidth: 512,
        imageHeight: 512,
        fileSizeBytes: 1000000,
        mimeType: 'image/jpeg',
        status: AssetStatus.completed,
      ),
      AssetModel(
        supabaseId: 'sample_2',
        userId: 'user_123',
        prompt: 'Cyberpunk city at night with neon lights',
        imagePath: 'https://picsum.photos/512/512?random=2',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        isFavorite: true,
        tags: ['cyberpunk', 'city', 'neon', 'night'],
        imageWidth: 512,
        imageHeight: 512,
        fileSizeBytes: 980000,
        mimeType: 'image/png',
        status: AssetStatus.completed,
      ),
      AssetModel(
        supabaseId: 'sample_3',
        userId: 'user_123',
        prompt: 'Cute cartoon cat wearing a wizard hat',
        imagePath: 'https://picsum.photos/512/512?random=3',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isFavorite: false,
        tags: ['cat', 'wizard', 'cute', 'cartoon'],
        imageWidth: 512,
        imageHeight: 512,
        fileSizeBytes: 750000,
        mimeType: 'image/jpeg',
        status: AssetStatus.completed,
      ),
    ];

    _assets.addAll(sampleAssets);
    AppLogger.info(
      '🎭 Mock storage initialized with ${sampleAssets.length} sample assets',
    );
  }

  @override
  Future<void> saveAsset(AssetModel asset) async {
    AppLogger.info('💾 [MOCK] Saving asset: ${asset.supabaseId}');

    // Simulate some delay like a real database
    await Future.delayed(const Duration(milliseconds: 100));

    // Remove existing asset with same supabaseId if it exists
    _assets.removeWhere((a) => a.supabaseId == asset.supabaseId);

    // Add the new asset
    _assets.add(asset);

    AppLogger.info('✅ [MOCK] Asset saved successfully');
  }

  @override
  Future<AssetModel?> getAsset(String id) async {
    AppLogger.debug('🔍 [MOCK] Getting asset: $id');

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      return _assets.firstWhere((asset) => asset.supabaseId == id);
    } catch (e) {
      AppLogger.debug('❌ [MOCK] Asset not found: $id');
      return null;
    }
  }

  @override
  Future<List<AssetModel>> getAllAssets() async {
    AppLogger.debug('📋 [MOCK] Getting all assets (${_assets.length} total)');

    await Future.delayed(const Duration(milliseconds: 100));

    // Sort by creation date (newest first)
    final sortedAssets = List<AssetModel>.from(_assets);
    sortedAssets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedAssets;
  }

  @override
  Future<void> deleteAsset(String id) async {
    AppLogger.info('🗑️ [MOCK] Deleting asset: $id');

    await Future.delayed(const Duration(milliseconds: 50));

    _assets.removeWhere((asset) => asset.supabaseId == id);
    AppLogger.info('✅ [MOCK] Asset deleted successfully');
  }

  @override
  Future<void> updateAsset(AssetModel asset) async {
    AppLogger.info('📝 [MOCK] Updating asset: ${asset.supabaseId}');

    await Future.delayed(const Duration(milliseconds: 100));

    final index = _assets.indexWhere((a) => a.supabaseId == asset.supabaseId);
    if (index != -1) {
      _assets[index] = asset;
      AppLogger.info('✅ [MOCK] Asset updated successfully');
    } else {
      AppLogger.warning(
        '⚠️ [MOCK] Asset not found for update: ${asset.supabaseId}',
      );
    }
  }

  @override
  Stream<List<AssetModel>> watchAssets() async* {
    AppLogger.debug('👁️ [MOCK] Watching assets');

    // For mock storage, just yield current assets periodically
    while (true) {
      yield await getAllAssets();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Stream<List<AssetModel>> searchAssets(String query) async* {
    AppLogger.debug('🔍 [MOCK] Searching assets for: "$query"');

    final allAssets = await getAllAssets();
    final queryLower = query.toLowerCase();

    final filtered = allAssets
        .where(
          (asset) =>
              asset.prompt.toLowerCase().contains(queryLower) ||
              asset.tags.any((tag) => tag.toLowerCase().contains(queryLower)),
        )
        .toList();

    AppLogger.debug('✅ [MOCK] Found ${filtered.length} matching assets');
    yield filtered;
  }

  @override
  Stream<List<AssetModel>> getAssetsByTags(List<String> tags) async* {
    AppLogger.debug('🏷️ [MOCK] Getting assets by tags: $tags');

    await Future.delayed(const Duration(milliseconds: 100));

    final allAssets = await getAllAssets();
    final filtered = allAssets
        .where((asset) => tags.any((tag) => asset.tags.contains(tag)))
        .toList();

    AppLogger.debug('✅ [MOCK] Found ${filtered.length} assets with tags');
    yield filtered;
  }

  /// Mock-specific method to add more sample data
  void addSampleAsset(String prompt, List<String> tags) {
    final asset = AssetModel(
      supabaseId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_123',
      prompt: prompt,
      imagePath: 'https://picsum.photos/512/512?random=$_idCounter',
      createdAt: DateTime.now(),
      isFavorite: false,
      tags: tags,
      imageWidth: 512,
      imageHeight: 512,
      fileSizeBytes: 1000000,
      mimeType: 'image/jpeg',
      status: AssetStatus.completed,
    );

    _assets.add(asset);
    AppLogger.info('🎭 [MOCK] Added sample asset: $prompt');
  }

  @override
  Future<void> saveMultipleAssets(List<AssetModel> assets) async {
    AppLogger.debug('💾 [MOCK] Saving ${assets.length} assets');

    await Future.delayed(const Duration(milliseconds: 200));

    for (final asset in assets) {
      await saveAsset(asset);
    }

    AppLogger.info('✅ [MOCK] Saved ${assets.length} assets');
  }

  @override
  Future<void> close() async {
    AppLogger.info('🔒 [MOCK] Closing mock storage service');
    // Mock storage doesn't need cleanup
    AppLogger.info('✅ [MOCK] Mock storage service closed');
  }

  /// Get mock statistics for development
  Map<String, dynamic> getMockStats() {
    final tagCounts = <String, int>{};

    for (final asset in _assets) {
      for (final tag in asset.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    return {
      'totalAssets': _assets.length,
      'tagCounts': tagCounts,
      'favoriteCount': _assets.where((a) => a.isFavorite).length,
      'oldestAsset': _assets.isNotEmpty
          ? _assets
                .map((a) => a.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newestAsset': _assets.isNotEmpty
          ? _assets
                .map((a) => a.createdAt)
                .reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
}
