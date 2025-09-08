import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Enhanced Logger for AssetCraft AI
///
/// Provides structured logging with different levels and easy debugging
/// Logs are only shown in debug mode (development) and suppressed in release builds
class AppLogger {
  static const String _appName = 'AssetCraft AI';

  /// Check if we should log based on build mode
  static bool get _shouldLog => kDebugMode;

  /// Log info messages
  static void info(String message, {String? tag, Object? data}) {
    if (!_shouldLog) return;

    final logTag = tag ?? 'INFO';
    developer.log(
      message,
      name: '$_appName - $logTag',
      level: 800,
      error: data,
    );
  }

  /// Log debug messages (only in development)
  static void debug(String message, {String? tag, Object? data}) {
    if (!_shouldLog) return;

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
    if (!_shouldLog) return;

    final logTag = tag ?? 'WARNING';
    developer.log(
      message,
      name: '$_appName - $logTag',
      level: 900,
      error: data,
    );
  }

  /// Log error messages (always shown, even in production for crash reports)
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
    if (!_shouldLog) return;

    final logTag = tag ?? 'SUCCESS';
    developer.log(
      message,
      name: '$_appName - $logTag',
      level: 800,
      error: data,
    );
  }

  /// Log API calls (only in development)
  static void api(String method, String endpoint, {Object? data}) {
    if (!_shouldLog) return;

    developer.log(
      '$method $endpoint',
      name: '$_appName - API',
      level: 800,
      error: data,
    );
  }
}
