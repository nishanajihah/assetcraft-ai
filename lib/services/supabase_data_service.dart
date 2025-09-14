import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import '../core/models/asset_model.dart';

/// Supabase Data Service
///
/// Handles database operations for user assets and generation history
/// Features:
/// - Save generated assets to database
/// - Load user's asset library
/// - Track generation history
/// - Handle user profile updates
/// - Enforce Row Level Security (RLS)
class SupabaseDataService {
  static const String _logTag = 'SupabaseDataService';

  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Save a generated asset to the database
  static Future<String?> saveAsset({
    required String userId,
    required String prompt,
    required String imagePath, // Using actual column name from schema
    String? assetType, // Optional - not in schema but useful for filtering
    String? style, // Optional - can be stored in prompt or metadata
  }) async {
    try {
      AppLogger.info('Saving asset to database', tag: _logTag);
      AppLogger.debug(
        'Asset details: prompt=${prompt.length > 50 ? '${prompt.substring(0, 50)}...' : prompt}',
        tag: _logTag,
      );

      final assetData = {
        'user_id': userId,
        'prompt': prompt,
        'image_path': imagePath, // Using your actual column name
        'is_public': false, // Private by default
        'is_favorite': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('assets') // Using your actual table name
          .insert(assetData)
          .select('id')
          .single();

      final assetId = response['id'] as String;

      AppLogger.success('Asset saved successfully: $assetId', tag: _logTag);
      return assetId;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to save asset: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Load user's assets from database
  static Future<List<AssetModel>> loadUserAssets(String userId) async {
    try {
      AppLogger.info('Loading user assets from database', tag: _logTag);

      final response = await _supabase
          .from('assets') // Using your actual table name
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final assets = (response as List)
          .map((asset) => AssetModel.fromJson(asset))
          .toList();

      AppLogger.success(
        'Loaded ${assets.length} assets for user',
        tag: _logTag,
      );

      return assets;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load user assets: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Load community assets (public assets from all users)
  static Future<List<AssetModel>> loadCommunityAssets({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      AppLogger.info('Loading community assets from database', tag: _logTag);

      final response = await _supabase
          .from('assets') // Using your actual table name
          .select('*')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final assets = (response as List)
          .map((asset) => AssetModel.fromJson(asset))
          .toList();

      AppLogger.success(
        'Loaded ${assets.length} community assets',
        tag: _logTag,
      );

      return assets;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load community assets: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Toggle asset favorite status
  static Future<bool> toggleAssetFavorite(
    String assetId,
    bool isFavorite,
  ) async {
    try {
      AppLogger.info(
        'Toggling asset favorite status: $assetId -> $isFavorite',
        tag: _logTag,
      );

      await _supabase
          .from('assets') // Using your actual table name
          .update({'is_favorite': isFavorite})
          .eq('id', assetId);

      AppLogger.success('Asset favorite status updated', tag: _logTag);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to toggle asset favorite: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Toggle asset public status
  static Future<bool> toggleAssetPublic(String assetId, bool isPublic) async {
    try {
      AppLogger.info(
        'Toggling asset public status: $assetId -> $isPublic',
        tag: _logTag,
      );

      await _supabase
          .from('assets') // Using your actual table name
          .update({'is_public': isPublic})
          .eq('id', assetId);

      AppLogger.success('Asset public status updated', tag: _logTag);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to toggle asset public status: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Delete an asset
  static Future<bool> deleteAsset(String assetId) async {
    try {
      AppLogger.info('Deleting asset: $assetId', tag: _logTag);

      await _supabase
          .from('assets') // Using your actual table name
          .delete()
          .eq('id', assetId);

      AppLogger.success('Asset deleted successfully', tag: _logTag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to delete asset: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get user's gemstones balance from users table
  static Future<int?> getUserGemstones(String userId) async {
    try {
      AppLogger.info('Getting user gemstones balance', tag: _logTag);

      final response = await _supabase
          .from('users') // Using your actual table name
          .select('gemstones')
          .eq('id', userId)
          .single();

      final gemstones = response['gemstones'] as int;

      AppLogger.success('User has $gemstones gemstones', tag: _logTag);
      return gemstones;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get user gemstones: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Update user's gemstones balance
  static Future<bool> updateUserGemstones(String userId, int newBalance) async {
    try {
      AppLogger.info(
        'Updating user gemstones balance to $newBalance',
        tag: _logTag,
      );

      await _supabase
          .from('users') // Using your actual table name
          .update({'gemstones': newBalance})
          .eq('id', userId);

      AppLogger.success('User gemstones updated successfully', tag: _logTag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update user gemstones: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get user's pro status
  static Future<bool?> getUserProStatus(String userId) async {
    try {
      AppLogger.info('Getting user pro status', tag: _logTag);

      final response = await _supabase
          .from('users') // Using your actual table name
          .select('pro_status')
          .eq('id', userId)
          .single();

      final proStatus = response['pro_status'] as bool;

      AppLogger.success('User pro status: $proStatus', tag: _logTag);
      return proStatus;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get user pro status: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Update user's pro status
  static Future<bool> updateUserProStatus(String userId, bool proStatus) async {
    try {
      AppLogger.info('Updating user pro status to $proStatus', tag: _logTag);

      await _supabase
          .from('users') // Using your actual table name
          .update({'pro_status': proStatus})
          .eq('id', userId);

      AppLogger.success('User pro status updated successfully', tag: _logTag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update user pro status: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Grant daily free gemstones if eligible
  static Future<bool> grantDailyFreeGemstones(String userId) async {
    try {
      AppLogger.info('Checking daily free gemstones eligibility', tag: _logTag);

      // Check when user last received free gemstones
      final response = await _supabase
          .from('users') // Using your actual table name
          .select('last_free_gemstones_grant, gemstones')
          .eq('id', userId)
          .single();

      final lastGrant = response['last_free_gemstones_grant'];
      final currentGemstones = response['gemstones'] as int;

      // Check if 24 hours have passed since last grant
      final now = DateTime.now();
      DateTime? lastGrantDate;

      if (lastGrant != null) {
        lastGrantDate = DateTime.parse(lastGrant);
      }

      if (lastGrantDate == null ||
          now.difference(lastGrantDate).inHours >= 24) {
        const freeGemstonesAmount = 5; // Daily free gemstones
        final newBalance = currentGemstones + freeGemstonesAmount;

        // Update gemstones and last grant timestamp
        await _supabase
            .from('users') // Using your actual table name
            .update({
              'gemstones': newBalance,
              'last_free_gemstones_grant': now.toIso8601String(),
            })
            .eq('id', userId);

        AppLogger.success(
          'Granted $freeGemstonesAmount free gemstones. New balance: $newBalance',
          tag: _logTag,
        );
        return true;
      } else {
        AppLogger.info(
          'User not eligible for free gemstones yet',
          tag: _logTag,
        );
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to grant daily free gemstones: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Create or update user profile
  static Future<bool> ensureUserProfile(String userId) async {
    try {
      AppLogger.info('Ensuring user profile exists', tag: _logTag);

      // Check if user exists
      final existingUser = await _supabase
          .from('users') // Using your actual table name
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingUser == null) {
        // Create new user profile
        await _supabase
            .from('users') // Using your actual table name
            .insert({
              'id': userId,
              'gemstones': 10, // Starting gemstones
              'pro_status': false,
              'created_at': DateTime.now().toIso8601String(),
            });

        AppLogger.success('Created new user profile', tag: _logTag);
      } else {
        AppLogger.info('User profile already exists', tag: _logTag);
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to ensure user profile: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get asset statistics for user
  static Future<Map<String, int>?> getUserAssetStats(String userId) async {
    try {
      AppLogger.info('Getting user asset statistics', tag: _logTag);

      final response = await _supabase
          .from('assets') // Using your actual table name
          .select('is_favorite, is_public')
          .eq('user_id', userId);

      final assets = response as List;

      final stats = {
        'total': assets.length,
        'favorites': assets.where((a) => a['is_favorite'] == true).length,
        'public': assets.where((a) => a['is_public'] == true).length,
        'private': assets.where((a) => a['is_public'] == false).length,
      };

      AppLogger.success('Retrieved user asset statistics', tag: _logTag);
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get user asset statistics: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
