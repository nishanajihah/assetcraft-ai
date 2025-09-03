import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging utility for AssetCraft AI
class AppLogger {
  static late Logger _logger;
  static bool _isInitialized = false;

  /// Initialize the logger
  static void initialize() {
    if (_isInitialized) return;

    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
      ),
      output: ConsoleOutput(),
    );

    _isInitialized = true;
    info('🚀 AppLogger initialized');
  }

  /// Log debug messages (only in debug mode)
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info messages
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void warning(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (!_isInitialized) initialize();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal messages
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Safe print that works even if logger is not initialized
  static void safePrint(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}

/// Production filter to control log levels in release mode
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      // In release mode, only log warnings and errors
      return event.level.index >= Level.warning.index;
    }
    // In debug/profile mode, log everything
    return true;
  }
}
