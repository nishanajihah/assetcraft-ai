import 'dart:developer' as developer;

/// Enhanced Logger for AssetCraft AI
///
/// Provides structured logging with different levels and easy debugging
class AppLogger {
  static const String _appName = 'AssetCraft AI';

  /// Log info messages
  static void info(String message, {String? tag, Object? data}) {
    final logTag = tag ?? 'INFO';
    developer.log(
      message,
      name: '$_appName - $logTag',
      level: 800,
      error: data,
    );
  }

  /// Log debug messages
  static void debug(String message, {String? tag, Object? data}) {
    final logTag = tag ?? 'DEBUG';
    developer.log(
      message,
      name: '$_appName - $logTag',
      level: 700,
      error: data,
    );
  }

  /// Log warning messages
  static void warning(String message, {String? tag, Object? data}) {
    final logTag = tag ?? 'WARNING';
    developer.log(
      message,
      name: '$_appName - $logTag',
      level: 900,
      error: data,
    );
  }

  /// Log error messages
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logTag = tag ?? 'ERROR';
    developer.log(
      message,
      name: '$_appName - $logTag',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log success messages
  static void success(String message, {String? tag, Object? data}) {
    final logTag = tag ?? 'SUCCESS';
    developer.log(
      message,
      name: '$_appName - $logTag',
      level: 800,
      error: data,
    );
  }

  /// Log API calls
  static void api(String method, String endpoint, {Object? data}) {
    developer.log(
      '$method $endpoint',
      name: '$_appName - API',
      level: 800,
      error: data,
    );
  }
}
