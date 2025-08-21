import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/asset_model.dart';
import '../../../core/config/environment.dart';
import '../../../core/utils/app_logger.dart';

/// Service for managing assets with both local (Isar) and cloud (Supabase) storage
///
/// This service provides a unified interface for saving, retrieving, and managing
/// AI-generated assets. It handles synchronization between local storage and
/// cloud storage automatically.
class AssetService {
  final Isar _isar;
  final SupabaseClient _supabase;
  static const String _bucketName = 'assets';
  static const _uuid = Uuid();

  AssetService({required Isar isar, required SupabaseClient supabase})
    : _isar = isar,
      _supabase = supabase;

  /// Save an asset with image data to both Supabase Storage and local Isar database
  ///
  /// This method performs the following operations:
  /// 1. Uploads image data to Supabase Storage
  /// 2. Gets the public URL from Supabase
  /// 3. Updates the asset with the image path
  /// 4. Saves the asset to the local Isar database
  ///
  /// Returns the saved AssetModel with updated paths and metadata
  Future<AssetModel> saveAsset(AssetModel asset, Uint8List imageData) async {
    try {
      AppLogger.info('💾 Saving asset: ${asset.prompt}');

      // Generate a unique filename for the image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = _getFileExtension(asset.mimeType ?? 'image/png');
      final fileName =
          '${asset.userId}/${timestamp}_${_uuid.v4()}.$fileExtension';

      AppLogger.debug('📁 Uploading to path: $fileName');

      // Step 1: Upload image to Supabase Storage (with fallback)
      String publicUrl = '';
      try {
        await _supabase.storage
            .from(_bucketName)
            .uploadBinary(
              fileName,
              imageData,
              fileOptions: FileOptions(
                contentType: asset.mimeType ?? 'image/png',
                upsert: false,
              ),
            );

        AppLogger.info('☁️ Image uploaded to Supabase Storage');

        // Step 2: Get the public URL for the uploaded image
        publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);

        AppLogger.debug('🔗 Public URL: $publicUrl');
      } catch (storageError) {
        AppLogger.warning('⚠️ Supabase storage upload failed: $storageError');
        AppLogger.info('📱 Saving asset locally without cloud storage');

        // For development/fallback: create a local path reference
        publicUrl =
            'local://asset_${DateTime.now().millisecondsSinceEpoch}.png';
      }

      // Step 3: Update asset with storage information
      final isCloudStored = !publicUrl.startsWith('local://');
      final updatedAsset = asset.copyWith(
        supabaseId: asset.supabaseId.isEmpty ? _uuid.v4() : asset.supabaseId,
        imagePath: publicUrl,
        fileSizeBytes: imageData.length,
        status: isCloudStored ? AssetStatus.completed : AssetStatus.synced,
        createdAt: asset.createdAt,
      );

      // Step 4: Save to local Isar database
      await _isar.writeTxn(() async {
        await _isar.assetModels.put(updatedAsset);
      });

      AppLogger.info('✅ Asset saved successfully: ${updatedAsset.supabaseId}');
      AppLogger.info('📍 Storage type: ${isCloudStored ? "Cloud" : "Local"}');

      // Step 5: Optionally save metadata to Supabase database for cloud sync
      if (isCloudStored) {
        await _saveAssetToSupabaseDatabase(updatedAsset);
      } else {
        AppLogger.debug(
          '⚠️ Skipping Supabase database sync - using local storage only',
        );
      }

      return updatedAsset;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error saving asset: $e');
      AppLogger.error('Stack trace: $stackTrace');

      // Update asset status to failed and save locally
      final failedAsset = asset.copyWith(
        status: AssetStatus.failed,
        errorMessage: e.toString(),
      );

      try {
        await _isar.writeTxn(() async {
          await _isar.assetModels.put(failedAsset);
        });
      } catch (localSaveError) {
        AppLogger.error(
          '❌ Failed to save error state locally: $localSaveError',
        );
      }

      rethrow;
    }
  }

  /// Get all assets as a reactive stream from the local Isar database
  ///
  /// Returns a Stream that automatically updates when assets are added,
  /// modified, or deleted from the local database.
  Stream<List<AssetModel>> getAssets() {
    try {
      AppLogger.debug('📱 Getting assets stream from local database');

      return _isar.assetModels.where().sortByCreatedAtDesc().watch(
        fireImmediately: true,
      );
    } catch (e) {
      AppLogger.error('❌ Error getting assets stream: $e');
      // Return empty stream in case of error
      return Stream.value([]);
    }
  }

  /// Get assets for a specific user
  ///
  /// Returns a Stream of assets filtered by userId, sorted by creation date (newest first)
  Stream<List<AssetModel>> getAssetsForUser(String userId) {
    try {
      AppLogger.debug('👤 Getting assets for user: $userId');

      return _isar.assetModels
          .filter()
          .userIdEqualTo(userId)
          .sortByCreatedAtDesc()
          .watch(fireImmediately: true);
    } catch (e) {
      AppLogger.error('❌ Error getting user assets: $e');
      return Stream.value([]);
    }
  }

  /// Get favorite assets as a stream
  Stream<List<AssetModel>> getFavoriteAssets() {
    try {
      AppLogger.debug('⭐ Getting favorite assets stream');

      return _isar.assetModels
          .filter()
          .isFavoriteEqualTo(true)
          .sortByCreatedAtDesc()
          .watch(fireImmediately: true);
    } catch (e) {
      AppLogger.error('❌ Error getting favorite assets: $e');
      return Stream.value([]);
    }
  }

  /// Toggle the favorite status of an asset
  ///
  /// Updates both the local database and optionally syncs with cloud storage
  Future<void> toggleFavorite(AssetModel asset) async {
    try {
      AppLogger.info('⭐ Toggling favorite for asset: ${asset.supabaseId}');

      final updatedAsset = asset.copyWith(isFavorite: !asset.isFavorite);

      // Update in local database
      await _isar.writeTxn(() async {
        await _isar.assetModels.put(updatedAsset);
      });

      AppLogger.info('✅ Favorite status updated locally');

      // Optionally sync with Supabase database
      await _updateAssetInSupabaseDatabase(updatedAsset);
    } catch (e) {
      AppLogger.error('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Delete an asset from both local storage and cloud storage
  Future<void> deleteAsset(AssetModel asset) async {
    try {
      AppLogger.info('🗑️ Deleting asset: ${asset.supabaseId}');

      // Delete from Supabase Storage
      if (asset.imagePath.isNotEmpty && asset.imagePath.contains(_bucketName)) {
        try {
          // Extract the file path from the public URL
          final uri = Uri.parse(asset.imagePath);
          final pathSegments = uri.pathSegments;
          final fileName = pathSegments
              .sublist(pathSegments.indexOf(_bucketName) + 1)
              .join('/');

          await _supabase.storage.from(_bucketName).remove([fileName]);

          AppLogger.info('☁️ Image deleted from Supabase Storage');
        } catch (storageError) {
          AppLogger.warning('⚠️ Failed to delete from storage: $storageError');
          // Continue with local deletion even if cloud deletion fails
        }
      }

      // Delete from local database
      await _isar.writeTxn(() async {
        await _isar.assetModels.delete(asset.id);
      });

      // Delete from Supabase database
      await _deleteAssetFromSupabaseDatabase(asset.supabaseId);

      AppLogger.info('✅ Asset deleted successfully');
    } catch (e) {
      AppLogger.error('❌ Error deleting asset: $e');
      rethrow;
    }
  }

  /// Search assets by prompt text
  Stream<List<AssetModel>> searchAssets(String query) {
    try {
      AppLogger.debug('🔍 Searching assets with query: $query');

      if (query.isEmpty) {
        return getAssets();
      }

      return _isar.assetModels
          .filter()
          .promptContains(query, caseSensitive: false)
          .sortByCreatedAtDesc()
          .watch(fireImmediately: true);
    } catch (e) {
      AppLogger.error('❌ Error searching assets: $e');
      return Stream.value([]);
    }
  }

  /// Get assets by tags
  Stream<List<AssetModel>> getAssetsByTags(List<String> tags) {
    try {
      AppLogger.debug('🏷️ Getting assets by tags: $tags');

      return _isar.assetModels
          .filter()
          .anyOf(tags, (q, tag) => q.tagsElementContains(tag))
          .sortByCreatedAtDesc()
          .watch(fireImmediately: true);
    } catch (e) {
      AppLogger.error('❌ Error getting assets by tags: $e');
      return Stream.value([]);
    }
  }

  /// Update asset tags
  Future<void> updateAssetTags(AssetModel asset, List<String> newTags) async {
    try {
      AppLogger.info('🏷️ Updating tags for asset: ${asset.supabaseId}');

      final updatedAsset = asset.copyWith(tags: newTags);

      await _isar.writeTxn(() async {
        await _isar.assetModels.put(updatedAsset);
      });

      await _updateAssetInSupabaseDatabase(updatedAsset);

      AppLogger.info('✅ Asset tags updated successfully');
    } catch (e) {
      AppLogger.error('❌ Error updating asset tags: $e');
      rethrow;
    }
  }

  /// Sync assets from Supabase database to local storage
  Future<void> syncAssetsFromCloud(String userId) async {
    try {
      AppLogger.info('🔄 Syncing assets from cloud for user: $userId');

      final response = await _supabase
          .from('assets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<AssetModel> cloudAssets = (response as List)
          .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (cloudAssets.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.assetModels.putAll(cloudAssets);
        });

        AppLogger.info('✅ Synced ${cloudAssets.length} assets from cloud');
      }
    } catch (e) {
      AppLogger.error('❌ Error syncing from cloud: $e');
      // Don't rethrow - sync errors shouldn't break the app
    }
  }

  /// Save asset metadata to Supabase database for cloud sync
  Future<void> _saveAssetToSupabaseDatabase(AssetModel asset) async {
    try {
      if (!Environment.hasSupabaseConfig) {
        AppLogger.debug(
          '⚠️ Supabase not configured, skipping cloud database save',
        );
        return;
      }

      await _supabase.from('assets').upsert(asset.toJson());

      AppLogger.debug('☁️ Asset metadata saved to Supabase database');
    } catch (e) {
      AppLogger.warning('⚠️ Failed to save to Supabase database: $e');
      // Don't rethrow - local save already succeeded
    }
  }

  /// Update asset metadata in Supabase database
  Future<void> _updateAssetInSupabaseDatabase(AssetModel asset) async {
    try {
      if (!Environment.hasSupabaseConfig) {
        AppLogger.debug(
          '⚠️ Supabase not configured, skipping cloud database update',
        );
        return;
      }

      await _supabase
          .from('assets')
          .update(asset.toJson())
          .eq('supabase_id', asset.supabaseId);

      AppLogger.debug('☁️ Asset metadata updated in Supabase database');
    } catch (e) {
      AppLogger.warning('⚠️ Failed to update Supabase database: $e');
      // Don't rethrow - local update already succeeded
    }
  }

  /// Delete asset metadata from Supabase database
  Future<void> _deleteAssetFromSupabaseDatabase(String supabaseId) async {
    try {
      if (!Environment.hasSupabaseConfig) {
        AppLogger.debug(
          '⚠️ Supabase not configured, skipping cloud database delete',
        );
        return;
      }

      await _supabase.from('assets').delete().eq('supabase_id', supabaseId);

      AppLogger.debug('☁️ Asset metadata deleted from Supabase database');
    } catch (e) {
      AppLogger.warning('⚠️ Failed to delete from Supabase database: $e');
      // Don't rethrow - local delete already succeeded
    }
  }

  /// Get file extension from MIME type
  String _getFileExtension(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'image/png':
        return 'png';
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      default:
        return 'png'; // Default to PNG
    }
  }
}
