import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

class CostMonitoringService {
  static const String _logTag = 'CostMonitoringService';
  static const String _costKeyPrefix = 'api_cost_';
  static const String _requestCountPrefix = 'api_request_count_';
  static const String _lastResetKey = 'last_cost_reset';
  static const double _maxCostRM = 100.0; // RM100 limit
  static const int _maxRequestsPerHour = 50; // Rate limit
  static const String _notificationEmail = 'nishanajihah88@gmail.com';

  /// Track API cost for a specific service
  static Future<void> trackCost(String service, double costRM) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final costKey = '$_costKeyPrefix${service}_$today';

      final currentCost = prefs.getDouble(costKey) ?? 0.0;
      final newCost = currentCost + costRM;

      await prefs.setDouble(costKey, newCost);

      AppLogger.warning(
        'API cost tracked: $service = RM$costRM (Total today: RM$newCost)',
        tag: _logTag,
      );

      // Check if we're approaching the limit
      final totalDailyCost = await getTotalDailyCost();

      if (totalDailyCost >= _maxCostRM) {
        AppLogger.error(
          'COST ALERT: Daily cost exceeded RM$_maxCostRM! Current: RM$totalDailyCost',
          tag: _logTag,
        );
        await _sendCostAlert(totalDailyCost, 'EXCEEDED');
      } else if (totalDailyCost >= _maxCostRM * 0.8) {
        AppLogger.warning(
          'COST WARNING: Daily cost approaching limit. Current: RM$totalDailyCost',
          tag: _logTag,
        );
        await _sendCostAlert(totalDailyCost, 'WARNING');
      }
    } catch (e) {
      AppLogger.error('Failed to track cost: $e', tag: _logTag, error: e);
    }
  }

  /// Get total daily cost across all services
  static Future<double> getTotalDailyCost() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final keys = prefs.getKeys();

      double totalCost = 0.0;

      for (final key in keys) {
        if (key.startsWith(_costKeyPrefix) && key.endsWith(today)) {
          totalCost += prefs.getDouble(key) ?? 0.0;
        }
      }

      return totalCost;
    } catch (e) {
      AppLogger.error(
        'Failed to get total daily cost: $e',
        tag: _logTag,
        error: e,
      );
      return 0.0;
    }
  }

  /// Check if we can make an API request (rate limiting + cost limiting)
  static Future<bool> canMakeRequest(
    String service, {
    double estimatedCostRM = 0.01,
  }) async {
    try {
      // Check cost limit
      final currentCost = await getTotalDailyCost();
      if (currentCost + estimatedCostRM > _maxCostRM) {
        AppLogger.error(
          'Request blocked: Would exceed daily cost limit (Current: RM$currentCost, Estimated: RM$estimatedCostRM)',
          tag: _logTag,
        );
        return false;
      }

      // Check rate limit
      final canMakeRateLimitedRequest = await _checkRateLimit(service);
      if (!canMakeRateLimitedRequest) {
        AppLogger.warning(
          'Request blocked: Rate limit exceeded for $service',
          tag: _logTag,
        );
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.error(
        'Error checking request permission: $e',
        tag: _logTag,
        error: e,
      );
      return false; // Fail safe - don't allow request if we can't check
    }
  }

  /// Check rate limiting for a service
  static Future<bool> _checkRateLimit(String service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final hourKey =
          '$_requestCountPrefix${service}_${now.hour}_${now.day}_${now.month}';

      final currentCount = prefs.getInt(hourKey) ?? 0;

      if (currentCount >= _maxRequestsPerHour) {
        return false;
      }

      // Increment counter
      await prefs.setInt(hourKey, currentCount + 1);
      return true;
    } catch (e) {
      AppLogger.error('Rate limit check failed: $e', tag: _logTag, error: e);
      return false;
    }
  }

  /// Send cost alert email (simplified - you can integrate with your email service)
  static Future<void> _sendCostAlert(
    double currentCost,
    String alertType,
  ) async {
    try {
      AppLogger.error(
        '🚨 COST ALERT [$alertType]: RM$currentCost spent today! Email would be sent to $_notificationEmail',
        tag: _logTag,
      );

      // Here you would integrate with an email service like:
      // - Supabase Edge Function for email
      // - Firebase Functions
      // - Third-party service like SendGrid, etc.

      // For now, we'll just log the alert
      // TODO: Implement actual email sending
    } catch (e) {
      AppLogger.error('Failed to send cost alert: $e', tag: _logTag, error: e);
    }
  }

  /// Reset daily costs (call this daily or when needed)
  static Future<void> resetDailyCosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Remove old cost entries
      for (final key in keys) {
        if (key.startsWith(_costKeyPrefix) && !key.endsWith(today)) {
          await prefs.remove(key);
        }
      }

      await prefs.setString(_lastResetKey, today);
      AppLogger.info('Daily costs reset completed', tag: _logTag);
    } catch (e) {
      AppLogger.error(
        'Failed to reset daily costs: $e',
        tag: _logTag,
        error: e,
      );
    }
  }

  /// Get cost breakdown by service
  static Future<Map<String, double>> getCostBreakdown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final keys = prefs.getKeys();
      final Map<String, double> breakdown = {};

      for (final key in keys) {
        if (key.startsWith(_costKeyPrefix) && key.endsWith(today)) {
          final service = key
              .replaceAll(_costKeyPrefix, '')
              .replaceAll('_$today', '');
          breakdown[service] = prefs.getDouble(key) ?? 0.0;
        }
      }

      return breakdown;
    } catch (e) {
      AppLogger.error(
        'Failed to get cost breakdown: $e',
        tag: _logTag,
        error: e,
      );
      return {};
    }
  }

  /// Check if user should be warned about costs
  static Future<bool> shouldWarnUser() async {
    final currentCost = await getTotalDailyCost();
    return currentCost >= _maxCostRM * 0.5; // Warn at 50% of limit
  }
}
