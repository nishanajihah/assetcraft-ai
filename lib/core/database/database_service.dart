import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_logger.dart';
import '../constants/app_constants.dart';
import 'models/user_model.dart';
import 'models/asset_model.dart';
import 'models/generation_model.dart';

/// Hive database service for AssetCraft AI
/// Handles all local database operations with Hive
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  static bool _isInitialized = false;

  // Box references
  Box<UserModel>? _userBox;
  Box<AssetModel>? _assetBox;
  Box<GenerationModel>? _generationBox;
  Box? _settingsBox;

  /// Initialize Hive database
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🗄️ Initializing Hive database...');

      // Initialize Hive for Flutter
      await Hive.initFlutter();

      // Note: Type adapters will be registered after code generation
      // _registerAdapters();

      // Open boxes
      await instance._openBoxes();

      _isInitialized = true;
      AppLogger.info('✅ Hive database initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize Hive database', e, stackTrace);
      rethrow;
    }
  }

  /// Open all required Hive boxes
  Future<void> _openBoxes() async {
    try {
      // For now, use basic boxes until adapters are generated
      _userBox = await Hive.openBox<UserModel>(AppConstants.userBoxName);
      _assetBox = await Hive.openBox<AssetModel>(AppConstants.assetsBoxName);
      _generationBox = await Hive.openBox<GenerationModel>('generations_box');
      _settingsBox = await Hive.openBox('settings_box');

      AppLogger.info('📦 All Hive boxes opened successfully');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to open Hive boxes', e, stackTrace);
      rethrow;
    }
  }

  /// Close all Hive boxes
  static Future<void> close() async {
    try {
      await Hive.close();
      _isInitialized = false;
      AppLogger.info('📦 Hive database closed');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to close Hive database', e, stackTrace);
    }
  }

  /// Clear all data (useful for logout or reset)
  Future<void> clearAllData() async {
    try {
      await _userBox?.clear();
      await _assetBox?.clear();
      await _generationBox?.clear();
      await _settingsBox?.clear();
      AppLogger.info('🗑️ All database data cleared');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to clear database data', e, stackTrace);
      rethrow;
    }
  }

  /// Get database size information
  Map<String, int> getDatabaseInfo() {
    return {
      'users': _userBox?.length ?? 0,
      'assets': _assetBox?.length ?? 0,
      'generations': _generationBox?.length ?? 0,
      'settings': _settingsBox?.length ?? 0,
    };
  }

  // ===== User Operations =====

  /// Save user to database
  Future<void> saveUser(UserModel user) async {
    try {
      await _userBox?.put(user.id, user);
      AppLogger.debug('👤 User saved: ${user.id}');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to save user', e, stackTrace);
      rethrow;
    }
  }

  /// Get user by ID
  UserModel? getUser(String userId) {
    try {
      return _userBox?.get(userId);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get user', e, stackTrace);
      return null;
    }
  }

  /// Get current user (first user in box)
  UserModel? getCurrentUser() {
    try {
      final users = _userBox?.values.toList() ?? [];
      return users.isNotEmpty ? users.first : null;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get current user', e, stackTrace);
      return null;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _userBox?.delete(userId);
      AppLogger.debug('🗑️ User deleted: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to delete user', e, stackTrace);
      rethrow;
    }
  }

  // ===== Asset Operations =====

  /// Save asset to database
  Future<void> saveAsset(AssetModel asset) async {
    try {
      await _assetBox?.put(asset.id, asset);
      AppLogger.debug('🎨 Asset saved: ${asset.id}');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to save asset', e, stackTrace);
      rethrow;
    }
  }

  /// Get asset by ID
  AssetModel? getAsset(String assetId) {
    try {
      return _assetBox?.get(assetId);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get asset', e, stackTrace);
      return null;
    }
  }

  /// Get all assets for a user
  List<AssetModel> getUserAssets(String userId) {
    try {
      return _assetBox?.values
              .where((asset) => asset.userId == userId)
              .toList() ??
          [];
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get user assets', e, stackTrace);
      return [];
    }
  }

  /// Get favorite assets for a user
  List<AssetModel> getFavoriteAssets(String userId) {
    try {
      return _assetBox?.values
              .where((asset) => asset.userId == userId && asset.isFavorite)
              .toList() ??
          [];
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get favorite assets', e, stackTrace);
      return [];
    }
  }

  /// Search assets by name or tags
  List<AssetModel> searchAssets(String query, String userId) {
    try {
      final lowerQuery = query.toLowerCase();
      return _assetBox?.values
              .where(
                (asset) =>
                    asset.userId == userId &&
                    (asset.name.toLowerCase().contains(lowerQuery) ||
                        asset.description.toLowerCase().contains(lowerQuery) ||
                        asset.tags.any(
                          (tag) => tag.toLowerCase().contains(lowerQuery),
                        )),
              )
              .toList() ??
          [];
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to search assets', e, stackTrace);
      return [];
    }
  }

  /// Delete asset
  Future<void> deleteAsset(String assetId) async {
    try {
      await _assetBox?.delete(assetId);
      AppLogger.debug('🗑️ Asset deleted: $assetId');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to delete asset', e, stackTrace);
      rethrow;
    }
  }

  // ===== Generation Operations =====

  /// Save generation to database
  Future<void> saveGeneration(GenerationModel generation) async {
    try {
      await _generationBox?.put(generation.id, generation);
      AppLogger.debug('🤖 Generation saved: ${generation.id}');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to save generation', e, stackTrace);
      rethrow;
    }
  }

  /// Get generation by ID
  GenerationModel? getGeneration(String generationId) {
    try {
      return _generationBox?.get(generationId);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get generation', e, stackTrace);
      return null;
    }
  }

  /// Get all generations for a user
  List<GenerationModel> getUserGenerations(String userId) {
    try {
      return _generationBox?.values
              .where((generation) => generation.userId == userId)
              .toList() ??
          [];
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get user generations', e, stackTrace);
      return [];
    }
  }

  /// Get recent generations for a user
  List<GenerationModel> getRecentGenerations(String userId, {int limit = 10}) {
    try {
      final generations = getUserGenerations(userId);
      generations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return generations.take(limit).toList();
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get recent generations', e, stackTrace);
      return [];
    }
  }

  /// Delete generation
  Future<void> deleteGeneration(String generationId) async {
    try {
      await _generationBox?.delete(generationId);
      AppLogger.debug('🗑️ Generation deleted: $generationId');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to delete generation', e, stackTrace);
      rethrow;
    }
  }

  // ===== Settings Operations =====

  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox?.put(key, value);
      AppLogger.debug('⚙️ Setting saved: $key');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to save setting', e, stackTrace);
      rethrow;
    }
  }

  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to get setting', e, stackTrace);
      return defaultValue;
    }
  }

  /// Delete setting
  Future<void> deleteSetting(String key) async {
    try {
      await _settingsBox?.delete(key);
      AppLogger.debug('🗑️ Setting deleted: $key');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to delete setting', e, stackTrace);
      rethrow;
    }
  }
}
