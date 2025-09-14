import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import 'cost_monitoring_service.dart';
import 'cache_service.dart';

class GeminiService {
  static const String _logTag = 'GeminiService';

  /// Enhance a prompt using Gemini AI through Supabase Edge Function
  static Future<String> enhancePrompt(String basePrompt) async {
    try {
      // SAFETY CHECK 1: Validate input
      if (basePrompt.trim().isEmpty) {
        AppLogger.warning(
          'Empty prompt provided, skipping Gemini enhancement',
          tag: _logTag,
        );
        return basePrompt;
      }

      if (basePrompt.trim().length < 3) {
        AppLogger.warning(
          'Prompt too short for enhancement, using original',
          tag: _logTag,
        );
        return basePrompt;
      }

      // CACHE CHECK: Look for cached enhanced prompt first
      final cachedPrompt = await CacheService.getCachedEnhancedPrompt(
        basePrompt,
      );
      if (cachedPrompt != null) {
        AppLogger.info(
          'Using cached enhanced prompt - saved API cost!',
          tag: _logTag,
        );
        return cachedPrompt;
      }

      // SAFETY CHECK 2: Cost and rate limiting
      const estimatedCost = 0.02; // Estimate RM0.02 per enhancement
      if (!await CostMonitoringService.canMakeRequest(
        'gemini_enhance',
        estimatedCostRM: estimatedCost,
      )) {
        AppLogger.error(
          'Request blocked by cost/rate limiting - using original prompt',
          tag: _logTag,
        );
        return basePrompt;
      }

      AppLogger.info('Enhancing prompt with Gemini AI', tag: _logTag);
      AppLogger.debug(
        'Base prompt: ${basePrompt.substring(0, basePrompt.length > 100 ? 100 : basePrompt.length)}...',
        tag: _logTag,
      );

      final response = await Supabase.instance.client.functions.invoke(
        'gemini-enhance-prompt',
        body: {'prompt': basePrompt, 'task': 'enhance_for_image_generation'},
      );

      // Track the cost
      await CostMonitoringService.trackCost('gemini_enhance', estimatedCost);

      if (response.data != null && response.data['enhanced_prompt'] != null) {
        final enhancedPrompt = response.data['enhanced_prompt'] as String;

        // SAFETY CHECK 3: Validate response
        if (enhancedPrompt.trim().isEmpty) {
          AppLogger.warning(
            'Empty enhanced prompt received, using original',
            tag: _logTag,
          );
          return basePrompt;
        }

        AppLogger.info('Prompt enhanced successfully', tag: _logTag);
        AppLogger.debug(
          'Enhanced prompt: ${enhancedPrompt.substring(0, enhancedPrompt.length > 100 ? 100 : enhancedPrompt.length)}...',
          tag: _logTag,
        );

        // CACHE: Store the enhanced prompt for future use
        await CacheService.cacheEnhancedPrompt(basePrompt, enhancedPrompt);

        return enhancedPrompt;
      } else {
        AppLogger.warning(
          'No enhanced prompt returned, using original',
          tag: _logTag,
        );
        return basePrompt;
      }
    } catch (e) {
      AppLogger.error('Failed to enhance prompt', tag: _logTag, error: e);
      // SAFETY: Always return original prompt if enhancement fails
      return basePrompt;
    }
  }

  /// Generate prompt suggestions using Gemini AI
  static Future<List<String>> generateSuggestions({
    required String assetType,
    String? style,
    String? theme,
  }) async {
    try {
      // SAFETY CHECK 1: Validate inputs
      if (assetType.trim().isEmpty) {
        AppLogger.warning(
          'Empty asset type provided, using fallback suggestions',
          tag: _logTag,
        );
        return _getFallbackSuggestions(assetType);
      }

      // CACHE CHECK: Look for cached suggestions first
      final cachedSuggestions = await CacheService.getCachedSuggestions(
        assetType,
        style,
        theme,
      );
      if (cachedSuggestions != null) {
        AppLogger.info(
          'Using cached suggestions - saved API cost!',
          tag: _logTag,
        );
        return cachedSuggestions;
      }

      // SAFETY CHECK 2: Cost and rate limiting
      const estimatedCost = 0.015; // Estimate RM0.015 per suggestion generation
      if (!await CostMonitoringService.canMakeRequest(
        'gemini_suggestions',
        estimatedCostRM: estimatedCost,
      )) {
        AppLogger.error(
          'Request blocked by cost/rate limiting - using fallback suggestions',
          tag: _logTag,
        );
        return _getFallbackSuggestions(assetType);
      }

      AppLogger.info('Generating suggestions with Gemini AI', tag: _logTag);
      AppLogger.debug(
        'Asset type: $assetType, Style: $style, Theme: $theme',
        tag: _logTag,
      );

      final response = await Supabase.instance.client.functions.invoke(
        'gemini-generate-suggestions',
        body: {
          'asset_type': assetType,
          'style': style,
          'theme': theme,
          'count': 5, // Request 5 suggestions
        },
      );

      // Track the cost
      await CostMonitoringService.trackCost(
        'gemini_suggestions',
        estimatedCost,
      );

      if (response.data != null && response.data['suggestions'] != null) {
        final suggestions = (response.data['suggestions'] as List)
            .map((suggestion) => suggestion.toString())
            .where(
              (suggestion) => suggestion.trim().isNotEmpty,
            ) // Filter empty suggestions
            .toList();

        // SAFETY CHECK 3: Validate response
        if (suggestions.isEmpty) {
          AppLogger.warning(
            'No valid suggestions returned from Gemini, using fallback',
            tag: _logTag,
          );
          return _getFallbackSuggestions(assetType);
        }

        AppLogger.info(
          'Generated ${suggestions.length} suggestions',
          tag: _logTag,
        );

        // CACHE: Store the suggestions for future use
        await CacheService.cacheSuggestions(
          assetType,
          style,
          theme,
          suggestions,
        );

        return suggestions;
      } else {
        AppLogger.warning('No suggestions returned from Gemini', tag: _logTag);
        return _getFallbackSuggestions(assetType);
      }
    } catch (e) {
      AppLogger.error('Failed to generate suggestions', tag: _logTag, error: e);
      // SAFETY: Always return fallback suggestions if AI fails
      return _getFallbackSuggestions(assetType);
    }
  }

  /// Get fallback suggestions when AI is unavailable
  static List<String> _getFallbackSuggestions(String assetType) {
    switch (assetType.toLowerCase()) {
      case 'character':
        return [
          'Fantasy warrior with magical armor',
          'Cyberpunk hacker with neon implants',
          'Medieval knight with ornate sword',
          'Space explorer in futuristic suit',
          'Mystical mage casting spells',
        ];
      case 'environment':
        return [
          'Enchanted forest with glowing mushrooms',
          'Futuristic cityscape at sunset',
          'Ancient temple ruins overgrown with vines',
          'Alien planet with floating rocks',
          'Underwater coral reef city',
        ];
      case 'object':
        return [
          'Ornate magical staff with crystals',
          'High-tech weapon with energy core',
          'Ancient artifact with mysterious runes',
          'Futuristic vehicle design',
          'Mystical potion bottle glowing',
        ];
      case 'texture':
        return [
          'Weathered stone wall texture',
          'Metallic surface with scratches',
          'Organic bark pattern',
          'Fabric weave with intricate patterns',
          'Crystal formation surface',
        ];
      default:
        return [
          'Beautiful digital artwork',
          'Highly detailed illustration',
          'Concept art masterpiece',
          'Professional game asset',
          'High-quality render',
        ];
    }
  }

  /// Chat with Gemini AI for general assistance
  static Future<String> chat(String message) async {
    try {
      // SAFETY CHECK 1: Validate input
      if (message.trim().isEmpty) {
        AppLogger.warning(
          'Empty message provided to Gemini chat',
          tag: _logTag,
        );
        return 'Please provide a message for me to respond to.';
      }

      if (message.trim().length > 1000) {
        AppLogger.warning(
          'Message too long for Gemini chat, truncating',
          tag: _logTag,
        );
        message = message.substring(0, 1000);
      }

      // SAFETY CHECK 2: Cost and rate limiting
      const estimatedCost = 0.01; // Estimate RM0.01 per chat message
      if (!await CostMonitoringService.canMakeRequest(
        'gemini_chat',
        estimatedCostRM: estimatedCost,
      )) {
        AppLogger.error(
          'Chat request blocked by cost/rate limiting',
          tag: _logTag,
        );
        return 'I apologize, but I have reached my usage limit for today. Please try again later or contact support.';
      }

      AppLogger.info('Sending chat message to Gemini', tag: _logTag);

      final response = await Supabase.instance.client.functions.invoke(
        'gemini-chat',
        body: {'message': message, 'context': 'assetcraft_ai_assistant'},
      );

      // Track the cost
      await CostMonitoringService.trackCost('gemini_chat', estimatedCost);

      if (response.data != null && response.data['response'] != null) {
        final chatResponse = response.data['response'] as String;

        // SAFETY CHECK 3: Validate response
        if (chatResponse.trim().isEmpty) {
          AppLogger.warning('Empty response from Gemini chat', tag: _logTag);
          return 'I apologize, but I am unable to provide a response at the moment. Please try again later.';
        }

        AppLogger.info('Received chat response from Gemini', tag: _logTag);
        return chatResponse;
      } else {
        return 'I apologize, but I am unable to respond at the moment. Please try again later.';
      }
    } catch (e) {
      AppLogger.error('Failed to get chat response', tag: _logTag, error: e);
      return 'I encountered an error while processing your request. Please try again.';
    }
  }
}
