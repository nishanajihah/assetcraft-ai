import '../utils/app_logger.dart';
import 'storage_service.dart';
import '../../mock/storage/mock_storage_service.dart';
import '../../mock/mock_config.dart';

/// Factory function to create the appropriate storage service
/// Uses mock storage when ENABLE_MOCK_STORAGE is true
Future<StorageService> createPlatformStorage() async {
  try {
    AppLogger.info('🗃️ Initializing storage service...');

    if (MockConfig.isMockStorageEnabled) {
      AppLogger.warning('⚠️ Using mock storage service (no persistence)');
      AppLogger.info('💡 Mock mode enabled via environment configuration');
      final mockStorage = MockStorageService();
      AppLogger.info('✅ Mock storage service initialized successfully');
      return mockStorage;
    }

    // TODO: Re-enable Isar storage once generator issues are resolved
    AppLogger.error('❌ Real storage not available - Isar generator issues');
    AppLogger.info('🔄 Falling back to mock storage service');
    final mockStorage = MockStorageService();
    return mockStorage;

    /* 
    // Original Isar implementation (commented out due to generator issues)
    final isar = await IsarService.getInstance();
    AppLogger.info('✅ Isar storage service initialized successfully');
    return IsarStorageService._(isar);
    */
  } catch (e) {
    AppLogger.error('❌ Failed to initialize storage service: $e');
    AppLogger.info('🔄 Falling back to mock storage service...');
    return MockStorageService();
  }
}
