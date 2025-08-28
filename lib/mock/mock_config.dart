import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';

/// Centralized mock configuration service
/// Manages all mock/testing flags from environment variables
class MockConfig {
  static const String _envFile = '.env';

  // Cache the values for performance
  static bool? _mockModeEnabled;
  static bool? _mockAiEnabled;
  static bool? _mockStorageEnabled;
  static bool? _mockStoreEnabled;
  static bool? _mockNotificationsEnabled;
  static bool? _mockAuthEnabled;
  static bool? _mockGemstonesEnabled;
  static bool? _showMockIndicator;
  static bool? _debugLogging;

  /// Initialize mock configuration (should be called at app startup)
  static Future<void> initialize() async {
    await dotenv.load(fileName: _envFile);

    // Clear cache to reload values
    _clearCache();
  }

  /// Clear cached values (useful for hot reload during development)
  static void _clearCache() {
    _mockModeEnabled = null;
    _mockAiEnabled = null;
    _mockStorageEnabled = null;
    _mockStoreEnabled = null;
    _mockNotificationsEnabled = null;
    _mockAuthEnabled = null;
    _mockGemstonesEnabled = null;
    _showMockIndicator = null;
    _debugLogging = null;
  }

  /// Get environment string value
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  /// Check if we're in production environment
  static bool get isProduction => environment == 'production';

  /// Check if we're in development environment
  static bool get isDevelopment => environment == 'development';

  /// Check if we're in testing mode
  static bool get isTesting => environment == 'testing';

  /// Master mock mode toggle - when true, all individual mocks are enabled
  static bool get isMockModeEnabled {
    _mockModeEnabled ??= _getBoolValue('ENABLE_MOCK_MODE', defaultValue: false);
    return _mockModeEnabled!;
  }

  /// AI Generation Mock
  static bool get isMockAiEnabled {
    _mockAiEnabled ??= _getBoolValue(
      'ENABLE_MOCK_AI',
      defaultValue: isMockModeEnabled,
    );
    return _mockAiEnabled!;
  }

  /// Storage Mock (in-memory instead of Isar)
  static bool get isMockStorageEnabled {
    _mockStorageEnabled ??= _getBoolValue(
      'ENABLE_MOCK_STORAGE',
      defaultValue: isMockModeEnabled,
    );
    return _mockStorageEnabled!;
  }

  /// Store/Purchases Mock
  static bool get isMockStoreEnabled {
    _mockStoreEnabled ??= _getBoolValue(
      'ENABLE_MOCK_STORE',
      defaultValue: isMockModeEnabled,
    );
    return _mockStoreEnabled!;
  }

  /// Notifications Mock
  static bool get isMockNotificationsEnabled {
    _mockNotificationsEnabled ??= _getBoolValue(
      'ENABLE_MOCK_NOTIFICATIONS',
      defaultValue: isMockModeEnabled,
    );
    return _mockNotificationsEnabled!;
  }

  /// Authentication Mock
  static bool get isMockAuthEnabled {
    _mockAuthEnabled ??= _getBoolValue(
      'ENABLE_MOCK_AUTH',
      defaultValue: isMockModeEnabled,
    );
    return _mockAuthEnabled!;
  }

  /// Gemstones Mock
  static bool get isMockGemstonesEnabled {
    _mockGemstonesEnabled ??= _getBoolValue(
      'ENABLE_MOCK_GEMSTONES',
      defaultValue: isMockModeEnabled,
    );
    return _mockGemstonesEnabled!;
  }

  /// Show mock indicator in UI
  static bool get showMockIndicator {
    _showMockIndicator ??= _getBoolValue(
      'SHOW_MOCK_INDICATOR',
      defaultValue: isMockModeEnabled,
    );
    return _showMockIndicator!;
  }

  /// Enable debug logging
  static bool get isDebugLoggingEnabled {
    _debugLogging ??= _getBoolValue(
      'ENABLE_DEBUG_LOGGING',
      defaultValue: isDevelopment,
    );
    return _debugLogging!;
  }

  /// Skip authentication during development
  static bool get skipAuthentication {
    return _getBoolValue('SKIP_AUTHENTICATION', defaultValue: isDevelopment);
  }

  /// Get a summary of current mock configuration
  static Map<String, dynamic> getMockStatus() {
    return {
      'environment': environment,
      'isMockModeEnabled': isMockModeEnabled,
      'mockServices': {
        'ai': isMockAiEnabled,
        'storage': isMockStorageEnabled,
        'store': isMockStoreEnabled,
        'notifications': isMockNotificationsEnabled,
        'auth': isMockAuthEnabled,
        'gemstones': isMockGemstonesEnabled,
      },
      'debugSettings': {
        'showMockIndicator': showMockIndicator,
        'debugLogging': isDebugLoggingEnabled,
        'skipAuth': skipAuthentication,
      },
    };
  }

  /// Helper to get boolean value from environment
  static bool _getBoolValue(String key, {bool defaultValue = false}) {
    final value = dotenv.env[key]?.toLowerCase();
    if (value == null) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes';
  }

  /// Helper to log current configuration (useful for debugging)
  static void printConfiguration() {
    if (kDebugMode) {
      AppLogger.debug('🔧 MockConfig Status:');
      AppLogger.debug('  Environment: $environment');
      AppLogger.debug(
        '  Mock Mode: ${isMockModeEnabled ? "ENABLED" : "DISABLED"}',
      );

      if (isMockModeEnabled ||
          isMockAiEnabled ||
          isMockStorageEnabled ||
          isMockStoreEnabled) {
        AppLogger.debug('  🧪 Active Mocks:');
        if (isMockAiEnabled) AppLogger.debug('    - AI Generation');
        if (isMockStorageEnabled) AppLogger.debug('    - Storage Service');
        if (isMockStoreEnabled) AppLogger.debug('    - Store/Purchases');
        if (isMockNotificationsEnabled) AppLogger.debug('    - Notifications');
        if (isMockAuthEnabled) AppLogger.debug('    - Authentication');
        if (isMockGemstonesEnabled) AppLogger.debug('    - Gemstones');
      }

      if (showMockIndicator) {
        AppLogger.debug('  📱 Mock indicator will be shown in UI');
      }
    }
  }
}
