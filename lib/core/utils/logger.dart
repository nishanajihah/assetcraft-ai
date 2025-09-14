import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Enhanced Logger for AssetCraft AI
///
/// Provides structured logging with different levels, visual icons, and easy debugging
/// Logs are only shown in debug mode (development) and suppressed in release builds
/// Features beautiful console output with emojis and color coding
class AppLogger {
  static const String _appName = 'AssetCraft AI';

  // Color codes for console output
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _bold = '\x1B[1m';
  static const String _dim = '\x1B[2m';

  /// Check if we should log based on build mode
  static bool get _shouldLog => kDebugMode;

  /// Helper method to output logs using developer.log for proper Flutter logging
  static void _logOutput(String message) {
    if (!_shouldLog) return;
    developer.log(message, name: _appName);
  }

  /// Get current timestamp for logs
  static String get _timestamp {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }

  /// Format log message with colors and icons
  static String _formatMessage(
    String level,
    String icon,
    String color,
    String message,
    String tag,
  ) {
    final timestamp = '$_dim$_timestamp$_reset';
    final levelTag = '$color$_bold[$level]$_reset';
    final appTag = '$_cyan$_appName$_reset';
    final serviceTag = '$_magenta$tag$_reset';

    return '$timestamp $icon $levelTag $appTag > $serviceTag: $color$message$_reset';
  }

  /// Log info messages with 📘 icon
  static void info(String message, {String? tag, Object? data}) {
    if (!_shouldLog) return;

    final logTag = tag ?? 'INFO';
    final formattedMessage = _formatMessage(
      'INFO',
      '📘',
      _blue,
      message,
      logTag,
    );

    developer.log(
      formattedMessage,
      name: '$_appName - $logTag',
      level: 800,
      error: data,
    );

    // Also print to console for better visibility
    if (kDebugMode) {
      _logOutput(formattedMessage);
    }
  }

  /// Log debug messages with 🔍 icon (only in development)
  static void debug(String message, {String? tag, Object? data}) {
    if (!_shouldLog) return;

    final logTag = tag ?? 'DEBUG';
    final formattedMessage = _formatMessage(
      'DEBUG',
      '🔍',
      _dim,
      message,
      logTag,
    );

    developer.log(
      formattedMessage,
      name: '$_appName - $logTag',
      level: 700,
      error: data,
    );

    if (kDebugMode) {
      _logOutput(formattedMessage);
    }
  }

  /// Log warning messages with ⚠️ icon
  static void warning(String message, {String? tag, Object? data}) {
    if (!_shouldLog) return;

    final logTag = tag ?? 'WARNING';
    final formattedMessage = _formatMessage(
      'WARN',
      '⚠️',
      _yellow,
      message,
      logTag,
    );

    developer.log(
      formattedMessage,
      name: '$_appName - $logTag',
      level: 900,
      error: data,
    );

    if (kDebugMode) {
      _logOutput(formattedMessage);
    }
  }

  /// Log error messages with ❌ icon (always shown, even in production for crash reports)
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logTag = tag ?? 'ERROR';
    final formattedMessage = _formatMessage(
      'ERROR',
      '❌',
      _red,
      message,
      logTag,
    );

    developer.log(
      formattedMessage,
      name: '$_appName - $logTag',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );

    // Always print errors to console
    _logOutput(formattedMessage);

    // Print error details if available
    if (error != null && kDebugMode) {
      final errorDetails = '$_red$_dim  └─ Error: $error$_reset';
      _logOutput(errorDetails);
    }

    // Print stack trace if available (only in debug)
    if (stackTrace != null && kDebugMode) {
      final stackLines = stackTrace.toString().split('\n');
      for (int i = 0; i < stackLines.length && i < 5; i++) {
        final stackLine = '$_red$_dim  │  ${stackLines[i]}$_reset';
        _logOutput(stackLine);
      }
      if (stackLines.length > 5) {
        _logOutput(
          '$_red$_dim  └─ ... (${stackLines.length - 5} more lines)$_reset',
        );
      }
    }
  }

  /// Log success messages with ✅ icon
  static void success(String message, {String? tag, Object? data}) {
    if (!_shouldLog) return;

    final logTag = tag ?? 'SUCCESS';
    final formattedMessage = _formatMessage(
      'SUCCESS',
      '✅',
      _green,
      message,
      logTag,
    );

    developer.log(
      formattedMessage,
      name: '$_appName - $logTag',
      level: 800,
      error: data,
    );

    if (kDebugMode) {
      _logOutput(formattedMessage);
    }
  }

  /// Log API calls with 🌐 icon (only in development)
  static void api(String method, String endpoint, {Object? data}) {
    if (!_shouldLog) return;

    final message = '$method $endpoint';
    final formattedMessage = _formatMessage('API', '🌐', _cyan, message, 'API');

    developer.log(
      formattedMessage,
      name: '$_appName - API',
      level: 800,
      error: data,
    );

    if (kDebugMode) {
      _logOutput(formattedMessage);

      // Print request data if available
      if (data != null) {
        final dataString = '$_cyan$_dim  └─ Data: $data$_reset';
        _logOutput(dataString);
      }
    }
  }

  /// Log performance metrics with ⚡ icon
  static void performance(String operation, Duration duration, {String? tag}) {
    if (!_shouldLog) return;

    final logTag = tag ?? 'PERFORMANCE';
    final message = '$operation completed in ${duration.inMilliseconds}ms';
    final formattedMessage = _formatMessage(
      'PERF',
      '⚡',
      _magenta,
      message,
      logTag,
    );

    developer.log(formattedMessage, name: '$_appName - $logTag', level: 800);

    if (kDebugMode) {
      _logOutput(formattedMessage);
    }
  }

  /// Log network operations with 📡 icon
  static void network(String operation, {String? tag, Object? data}) {
    if (!_shouldLog) return;

    final logTag = tag ?? 'NETWORK';
    final formattedMessage = _formatMessage(
      'NETWORK',
      '📡',
      _blue,
      operation,
      logTag,
    );

    developer.log(
      formattedMessage,
      name: '$_appName - $logTag',
      level: 800,
      error: data,
    );

    if (kDebugMode) {
      _logOutput(formattedMessage);
    }
  }

  /// Log user actions with 👤 icon
  static void userAction(String action, {String? tag, Object? data}) {
    if (!_shouldLog) return;

    final logTag = tag ?? 'USER';
    final formattedMessage = _formatMessage(
      'USER',
      '👤',
      _green,
      action,
      logTag,
    );

    developer.log(
      formattedMessage,
      name: '$_appName - $logTag',
      level: 800,
      error: data,
    );

    if (kDebugMode) {
      _logOutput(formattedMessage);
    }
  }

  /// Log lifecycle events with 🔄 icon
  static void lifecycle(String event, {String? tag, Object? data}) {
    if (!_shouldLog) return;

    final logTag = tag ?? 'LIFECYCLE';
    final formattedMessage = _formatMessage(
      'LIFECYCLE',
      '🔄',
      _yellow,
      event,
      logTag,
    );

    developer.log(
      formattedMessage,
      name: '$_appName - $logTag',
      level: 800,
      error: data,
    );

    if (kDebugMode) {
      _logOutput(formattedMessage);
    }
  }

  /// Print a beautiful separator line
  static void separator({String title = ''}) {
    if (!_shouldLog) return;

    const line =
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    final timestamp = '$_dim$_timestamp$_reset';

    if (title.isNotEmpty) {
      final titleLine = '$_cyan$_bold $title $_reset';
      final separator = '$timestamp 📋 $_cyan$line$_reset';
      final titleWithPadding = '$timestamp 📋$titleLine';

      _logOutput(separator);
      _logOutput(titleWithPadding);
      _logOutput('$timestamp 📋 $_cyan$line$_reset');
    } else {
      _logOutput('$timestamp 📋 $_cyan$line$_reset');
    }
  }

  /// Print app startup banner
  static void startupBanner() {
    if (!_shouldLog) return;

    const banner = '''
╔══════════════════════════════════════════════════════════════════╗
║                          🎨 AssetCraft AI                        ║
║                     Premium AI Asset Generation                  ║
║                                                                  ║
║  🚀 Starting application...                                      ║
║  📱 Flutter × Supabase × Vertex AI                               ║
║  🔥 Debug Mode: Enabled                                          ║
╚══════════════════════════════════════════════════════════════════╝
''';

    _logOutput('$_green$_bold$banner$_reset');
  }

  /// Print shutdown message
  static void shutdown() {
    if (!_shouldLog) return;

    final timestamp = '$_dim$_timestamp$_reset';
    final message = '$_yellow$_bold👋 AssetCraft AI - Session ended$_reset';

    _logOutput('$timestamp $message');
  }
}
