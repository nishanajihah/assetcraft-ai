import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/assets/models/asset_model.dart';
import '../utils/app_logger.dart';

/// Service for managing the Isar database
///
/// This service initializes and provides access to the Isar database instance.
/// It handles database setup, schema management, and provides a singleton
/// instance for the entire application.
class IsarService {
  static Isar? _instance;

  /// Get the singleton Isar instance
  static Future<Isar> getInstance() async {
    if (_instance != null) {
      return _instance!;
    }

    try {
      AppLogger.info('🗃️ Initializing Isar database...');

      // Get the application documents directory
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/assetcraft_ai';

      // Ensure the directory exists
      await Directory(dbPath).create(recursive: true);

      AppLogger.debug('📂 Database path: $dbPath');

      // Initialize Isar with all schemas
      _instance = await Isar.open(
        [AssetModelSchema],
        directory: dbPath,
        name: 'assetcraft_ai',
        relaxedDurability: true,
      );

      AppLogger.info('✅ Isar database initialized successfully');
      return _instance!;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize Isar database: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Close the database connection
  static Future<void> close() async {
    if (_instance != null) {
      AppLogger.info('🔒 Closing Isar database...');
      await _instance!.close();
      _instance = null;
      AppLogger.info('✅ Isar database closed');
    }
  }

  /// Reset the database (delete all data)
  static Future<void> reset() async {
    try {
      AppLogger.warning('⚠️ Resetting Isar database...');

      if (_instance != null) {
        await _instance!.close();
        _instance = null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/assetcraft_ai';
      final dbDir = Directory(dbPath);

      if (await dbDir.exists()) {
        await dbDir.delete(recursive: true);
        AppLogger.info('🗑️ Database directory deleted');
      }

      // Reinitialize the database
      await getInstance();
      AppLogger.info('✅ Database reset completed');
    } catch (e) {
      AppLogger.error('❌ Failed to reset database: $e');
      rethrow;
    }
  }

  /// Get database size in bytes
  static Future<int> getDatabaseSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/assetcraft_ai';
      final dbDir = Directory(dbPath);

      if (!await dbDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in dbDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      AppLogger.error('❌ Failed to get database size: $e');
      return 0;
    }
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final isar = await getInstance();
      final assetCount = await isar.assetModels.count();
      final dbSize = await getDatabaseSize();

      return {
        'assetCount': assetCount,
        'databaseSizeBytes': dbSize,
        'databaseSizeMB': (dbSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      AppLogger.error('❌ Failed to get database stats: $e');
      return {
        'assetCount': 0,
        'databaseSizeBytes': 0,
        'databaseSizeMB': '0.00',
      };
    }
  }
}
