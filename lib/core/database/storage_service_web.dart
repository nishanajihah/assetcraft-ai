import '../utils/app_logger.dart';
import 'storage_service.dart';
import 'web_storage_service.dart';

/// Web storage factory
Future<StorageService> createPlatformStorage() async {
  AppLogger.info('🌐 Initializing web storage service...');
  return await WebStorageService.create();
}
