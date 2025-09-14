import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

class CacheService {
  static const String _logTag = 'CacheService';
  static const String _promptCachePrefix = 'prompt_cache_';
  static const String _suggestionsCachePrefix = 'suggestions_cache_';
  static const int _cacheDurationHours = 24; // Cache for 24 hours

  /// Cache an enhanced prompt to avoid re-processing
  static Future<void> cacheEnhancedPrompt(
    String originalPrompt,
    String enhancedPrompt,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _promptCachePrefix + _generateCacheKey(originalPrompt);

      final cacheData = {
        'enhanced_prompt': enhancedPrompt,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));

      AppLogger.debug('Cached enhanced prompt', tag: _logTag);
    } catch (e) {
      AppLogger.error(
        'Failed to cache enhanced prompt: $e',
        tag: _logTag,
        error: e,
      );
    }
  }

  /// Get cached enhanced prompt if available and not expired
  static Future<String?> getCachedEnhancedPrompt(String originalPrompt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _promptCachePrefix + _generateCacheKey(originalPrompt);

      final cachedDataString = prefs.getString(cacheKey);
      if (cachedDataString == null) return null;

      final cacheData = jsonDecode(cachedDataString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      // Check if cache is still valid (within 24 hours)
      if (cacheAge < _cacheDurationHours * 60 * 60 * 1000) {
        AppLogger.debug('Using cached enhanced prompt', tag: _logTag);
        return cacheData['enhanced_prompt'] as String;
      } else {
        // Remove expired cache
        await prefs.remove(cacheKey);
        AppLogger.debug('Removed expired prompt cache', tag: _logTag);
        return null;
      }
    } catch (e) {
      AppLogger.error(
        'Failed to get cached prompt: $e',
        tag: _logTag,
        error: e,
      );
      return null;
    }
  }

  /// Cache suggestions to avoid re-generating
  static Future<void> cacheSuggestions(
    String assetType,
    String? style,
    String? theme,
    List<String> suggestions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          _suggestionsCachePrefix +
          _generateSuggestionsKey(assetType, style, theme);

      final cacheData = {
        'suggestions': suggestions,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));

      AppLogger.debug('Cached suggestions for $assetType', tag: _logTag);
    } catch (e) {
      AppLogger.error(
        'Failed to cache suggestions: $e',
        tag: _logTag,
        error: e,
      );
    }
  }

  /// Get cached suggestions if available and not expired
  static Future<List<String>?> getCachedSuggestions(
    String assetType,
    String? style,
    String? theme,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          _suggestionsCachePrefix +
          _generateSuggestionsKey(assetType, style, theme);

      final cachedDataString = prefs.getString(cacheKey);
      if (cachedDataString == null) return null;

      final cacheData = jsonDecode(cachedDataString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      // Check if cache is still valid (within 24 hours)
      if (cacheAge < _cacheDurationHours * 60 * 60 * 1000) {
        final suggestions = (cacheData['suggestions'] as List)
            .map((item) => item.toString())
            .toList();

        AppLogger.debug(
          'Using cached suggestions for $assetType',
          tag: _logTag,
        );
        return suggestions;
      } else {
        // Remove expired cache
        await prefs.remove(cacheKey);
        AppLogger.debug('Removed expired suggestions cache', tag: _logTag);
        return null;
      }
    } catch (e) {
      AppLogger.error(
        'Failed to get cached suggestions: $e',
        tag: _logTag,
        error: e,
      );
      return null;
    }
  }

  /// Generate a cache key from prompt (using hash for consistency)
  static String _generateCacheKey(String prompt) {
    // Simple hash function for cache key
    return prompt.toLowerCase().trim().hashCode.abs().toString();
  }

  /// Generate cache key for suggestions based on parameters
  static String _generateSuggestionsKey(
    String assetType,
    String? style,
    String? theme,
  ) {
    final keyComponents = [
      assetType.toLowerCase().trim(),
      style?.toLowerCase().trim() ?? '',
      theme?.toLowerCase().trim() ?? '',
    ];
    return keyComponents.join('_').hashCode.abs().toString();
  }

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_promptCachePrefix) ||
            key.startsWith(_suggestionsCachePrefix)) {
          await prefs.remove(key);
        }
      }

      AppLogger.info('Cleared all cache data', tag: _logTag);
    } catch (e) {
      AppLogger.error('Failed to clear cache: $e', tag: _logTag, error: e);
    }
  }

  /// Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int removedCount = 0;

      for (final key in keys) {
        if (key.startsWith(_promptCachePrefix) ||
            key.startsWith(_suggestionsCachePrefix)) {
          final cachedDataString = prefs.getString(key);
          if (cachedDataString != null) {
            try {
              final cacheData =
                  jsonDecode(cachedDataString) as Map<String, dynamic>;
              final timestamp = cacheData['timestamp'] as int;
              final cacheAge =
                  DateTime.now().millisecondsSinceEpoch - timestamp;

              if (cacheAge >= _cacheDurationHours * 60 * 60 * 1000) {
                await prefs.remove(key);
                removedCount++;
              }
            } catch (e) {
              // Remove invalid cache entries
              await prefs.remove(key);
              removedCount++;
            }
          }
        }
      }

      if (removedCount > 0) {
        AppLogger.info(
          'Cleared $removedCount expired cache entries',
          tag: _logTag,
        );
      }
    } catch (e) {
      AppLogger.error(
        'Failed to clear expired cache: $e',
        tag: _logTag,
        error: e,
      );
    }
  }

  /// Get cache statistics
  static Future<Map<String, int>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int promptCacheCount = 0;
      int suggestionsCacheCount = 0;

      for (final key in keys) {
        if (key.startsWith(_promptCachePrefix)) {
          promptCacheCount++;
        } else if (key.startsWith(_suggestionsCachePrefix)) {
          suggestionsCacheCount++;
        }
      }

      return {
        'prompt_cache_count': promptCacheCount,
        'suggestions_cache_count': suggestionsCacheCount,
        'total_cache_count': promptCacheCount + suggestionsCacheCount,
      };
    } catch (e) {
      AppLogger.error('Failed to get cache stats: $e', tag: _logTag, error: e);
      return {};
    }
  }
}
