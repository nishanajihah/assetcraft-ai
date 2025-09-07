import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';

class GeminiService {
  static const String _logTag = 'GeminiService';

  /// Enhance a prompt using Gemini AI through Supabase Edge Function
  static Future<String> enhancePrompt(String basePrompt) async {
    try {
      AppLogger.info('Enhancing prompt with Gemini AI', tag: _logTag);
      AppLogger.debug('Base prompt: $basePrompt', tag: _logTag);

      final response = await Supabase.instance.client.functions.invoke(
        'gemini-enhance-prompt',
        body: {'prompt': basePrompt, 'task': 'enhance_for_image_generation'},
      );

      if (response.data != null && response.data['enhanced_prompt'] != null) {
        final enhancedPrompt = response.data['enhanced_prompt'] as String;
        AppLogger.info('Prompt enhanced successfully', tag: _logTag);
        AppLogger.debug('Enhanced prompt: $enhancedPrompt', tag: _logTag);
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
      // Return original prompt if enhancement fails
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

      if (response.data != null && response.data['suggestions'] != null) {
        final suggestions = (response.data['suggestions'] as List)
            .map((suggestion) => suggestion.toString())
            .toList();

        AppLogger.info(
          'Generated ${suggestions.length} suggestions',
          tag: _logTag,
        );
        return suggestions;
      } else {
        AppLogger.warning('No suggestions returned from Gemini', tag: _logTag);
        return _getFallbackSuggestions(assetType);
      }
    } catch (e) {
      AppLogger.error('Failed to generate suggestions', tag: _logTag, error: e);
      // Return fallback suggestions if AI fails
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
      AppLogger.info('Sending chat message to Gemini', tag: _logTag);

      final response = await Supabase.instance.client.functions.invoke(
        'gemini-chat',
        body: {'message': message, 'context': 'assetcraft_ai_assistant'},
      );

      if (response.data != null && response.data['response'] != null) {
        final chatResponse = response.data['response'] as String;
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
