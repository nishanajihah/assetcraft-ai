import 'package:logger/logger.dart';

/// Centralized logger for AssetCraft AI
/// Provides different log levels based on environment
class AppLogger {
  static Logger? _logger;

  /// Initialize logger (call this after environment is set up)
  static void initialize({bool isDevelopment = false, bool isStaging = false}) {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: _getLogLevel(isDevelopment, isStaging),
    );
  }

  static Level _getLogLevel(bool isDevelopment, bool isStaging) {
    if (isDevelopment) {
      return Level.debug; // Log everything in development
    } else if (isStaging) {
      return Level.warning; // Log warnings and errors in staging
    } else {
      return Level.error; // Only log errors in production
    }
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger?.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger?.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger?.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger?.e(message, error: error, stackTrace: stackTrace);
  }

  static void wtf(String message, [Object? error, StackTrace? stackTrace]) {
    _logger?.f(message, error: error, stackTrace: stackTrace);
  }

  /// Fallback to print if logger is not initialized
  static void safePrint(String message) {
    if (_logger != null) {
      info(message);
    } else {
      print(message);
    }
  }
}
