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

  // ===== USER MANAGEMENT METHODS (Two-Table Architecture) =====

  /// Get user record from users table by auth_user_id
  static Future<Map<String, dynamic>?> getUserRecord(String authUserId) async {
    try {
      AppLogger.info(
        'Getting user record for auth user: $authUserId',
        tag: _logTag,
      );

      final response = await _supabase
          .from('users')
          .select('*')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (response != null) {
        AppLogger.success('User record found', tag: _logTag);
      } else {
        AppLogger.warning('User record not found', tag: _logTag);
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get user record: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get complete user data (joins users and user_profiles tables)
  static Future<Map<String, dynamic>?> getCompleteUserData(
    String authUserId,
  ) async {
    try {
      AppLogger.info(
        'Getting complete user data for auth user: $authUserId',
        tag: _logTag,
      );

      final response = await _supabase
          .from('users')
          .select('''
            *,
            user_profiles!inner(*)
          ''')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (response != null) {
        AppLogger.success('Complete user data loaded', tag: _logTag);

        // Flatten the structure for easier access
        final userData = Map<String, dynamic>.from(response);
        final profileData = userData['user_profiles'] as Map<String, dynamic>;
        userData.remove('user_profiles');
        userData.addAll(profileData);

        return userData;
      } else {
        AppLogger.warning('Complete user data not found', tag: _logTag);
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get complete user data: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Update last login timestamp for user
  static Future<bool> updateLastLogin(String authUserId) async {
    try {
      AppLogger.info('Updating last login for user: $authUserId', tag: _logTag);

      await _supabase
          .from('users')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('auth_user_id', authUserId);

      AppLogger.success('Last login updated successfully', tag: _logTag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update last login: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get user's gemstones balance from user_profiles table
  static Future<int?> getUserGemstones(String userId) async {
    try {
      AppLogger.info('Getting user gemstones balance', tag: _logTag);

      final response = await _supabase
          .from('user_profiles') // Using unified user_profiles table
          .select('gemstones')
          .eq('user_id', userId)
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
          .from('user_profiles') // Using unified user_profiles table
          .update({'gemstones': newBalance})
          .eq('user_id', userId);

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
          .from('user_profiles') // Using unified user_profiles table
          .select('is_pro')
          .eq('user_id', userId)
          .single();

      final proStatus = response['is_pro'] as bool;

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
          .from('user_profiles') // Using unified user_profiles table
          .update({'is_pro': proStatus})
          .eq('user_id', userId);

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
          .from('user_profiles') // Using unified user_profiles table
          .select('last_free_gemstones_grant, gemstones')
          .eq('user_id', userId)
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
            .from('user_profiles') // Using unified user_profiles table
            .update({
              'gemstones': newBalance,
              'last_free_gemstones_grant': now.toIso8601String(),
            })
            .eq('user_id', userId);

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
          .from('user_profiles') // Using unified user_profiles table
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingUser == null) {
        // Create new user profile
        await _supabase
            .from('user_profiles') // Using unified user_profiles table
            .insert({
              'user_id': userId,
              'gemstones': 10, // Starting gemstones
              'is_pro': false,
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

  // ===== USER PROFILE MANAGEMENT =====

  /// Get user profile from database
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      AppLogger.info('Fetching user profile for user: $userId', tag: _logTag);

      final response = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        AppLogger.debug('User profile loaded successfully', tag: _logTag);
        return response;
      } else {
        AppLogger.warning(
          'User profile not found for user: $userId',
          tag: _logTag,
        );
        return null;
      }
    } catch (e) {
      AppLogger.error('Failed to fetch user profile', error: e, tag: _logTag);
      return null;
    }
  }

  /// Update user profile in database
  static Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.info('Updating user profile for user: $userId', tag: _logTag);
      AppLogger.debug(
        'Profile updates: ${updates.keys.join(', ')}',
        tag: _logTag,
      );

      await _supabase
          .from('user_profiles')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId);

      AppLogger.info('User profile updated successfully', tag: _logTag);
      return true;
    } catch (e) {
      AppLogger.error('Failed to update user profile', error: e, tag: _logTag);
      return false;
    }
  }

  /// Delete all user data (for account deletion)
  static Future<bool> deleteUserData(String userId) async {
    try {
      AppLogger.info('Deleting all data for user: $userId', tag: _logTag);

      // Delete user's assets first (due to foreign key constraints)
      await _supabase.from('assets').delete().eq('user_id', userId);
      AppLogger.debug('User assets deleted', tag: _logTag);

      // Delete generation history if exists
      await _supabase.from('generation_history').delete().eq('user_id', userId);
      AppLogger.debug('User generation history deleted', tag: _logTag);

      // Delete user profile last
      await _supabase.from('user_profiles').delete().eq('user_id', userId);
      AppLogger.debug('User profile deleted', tag: _logTag);

      AppLogger.info('All user data deleted successfully', tag: _logTag);
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete user data', error: e, tag: _logTag);
      return false;
    }
  }

  /// Get all user assets for data export
  static Future<List<Map<String, dynamic>>> getUserAssets(String userId) async {
    try {
      AppLogger.info('Fetching all assets for user data export', tag: _logTag);

      final response = await _supabase
          .from('assets')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      AppLogger.info(
        'Fetched ${response.length} assets for export',
        tag: _logTag,
      );
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch user assets for export',
        error: e,
        tag: _logTag,
      );
      return [];
    }
  }
}
