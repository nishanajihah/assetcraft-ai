import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Logs an info message
  static void log(String message) {
    _logger.i(message);
  }

  /// Logs a debug message
  static void debug(String message) {
    _logger.d(message);
  }

  /// Logs a warning message
  static void warning(String message) {
    _logger.w(message);
  }

  /// Logs an error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a verbose message
  static void verbose(String message) {
    _logger.t(message);
  }
}
