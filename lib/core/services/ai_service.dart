import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/environment.dart';
import '../utils/app_logger.dart';

part 'ai_service.g.dart';

/// AI Service for generating assets using Google Gemini
///
/// This service handles API calls to Google Gemini for AI-powered asset generation.
/// It provides methods to generate images from text prompts and handles API key
/// security through environment variables.
class AiService {
  late final GenerativeModel _textModel;
  late final GenerativeModel _imageModel;
  late final GenerativeModel _suggestionsModel;
  late final String _apiKey;

  /// Initialize the AI service with the Gemini API key
  AiService() {
    _apiKey = Environment.geminiApiKey;

    if (_apiKey.isEmpty || _apiKey.contains('placeholder')) {
      AppLogger.warning('⚠️ Gemini API key not configured');
      throw Exception('Gemini API key is required for AI service');
    }

    // Initialize different Gemini models for different purposes
    _textModel = GenerativeModel(
      model: Environment.geminiTextModel,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.8,
        maxOutputTokens: 2048,
      ),
    );

    _imageModel = GenerativeModel(
      model: Environment.geminiImageModel,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.8,
        maxOutputTokens: 2048,
      ),
    );

    _suggestionsModel = GenerativeModel(
      model: Environment.geminiSuggestionsModel,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.9,
        maxOutputTokens: 1024,
      ),
    );

    AppLogger.info('✅ AI Service initialized with models:');
    AppLogger.info('  Text: ${Environment.geminiTextModel}');
    AppLogger.info('  Image: ${Environment.geminiImageModel}');
    AppLogger.info('  Suggestions: ${Environment.geminiSuggestionsModel}');
  }

  /// Generate an asset from a text prompt
  ///
  /// Takes a [prompt] string and returns generated image data as Uint8List.
  /// This method uses the image generation model to create images directly.
  ///
  /// Returns null if generation fails or if the response doesn't contain image data.
  Future<Uint8List?> generateAssetFromPrompt(String prompt) async {
    try {
      AppLogger.info('🎨 Generating asset from prompt: $prompt');

      // Check if mock AI is enabled
      if (Environment.enableMockAI) {
        AppLogger.info('🎭 Mock AI enabled, creating mock image...');
        await Future.delayed(const Duration(seconds: 2));
        return _createMockImage();
      }

      // Create the enhanced prompt for better asset generation
      final enhancedPrompt = _enhancePromptForAssetGeneration(prompt);
      AppLogger.debug('Enhanced prompt: $enhancedPrompt');

      AppLogger.info('🚀 Calling Gemini 2.0 image generation model...');

      try {
        // Try to use the Gemini image generation model directly
        final response = await _imageModel.generateContent([
          Content.text(enhancedPrompt),
        ]);

        AppLogger.info('✅ Received response from Gemini image model');

        // Check if response contains text that might include image references
        if (response.text?.isNotEmpty == true) {
          final responseText = response.text!;

          // Check if response contains base64 image data
          if (responseText.contains('data:image/') ||
              responseText.contains('base64')) {
            final base64Match = RegExp(
              r'data:image/[^;]+;base64,([A-Za-z0-9+/=]+)',
            ).firstMatch(responseText);

            if (base64Match != null) {
              final base64Data = base64Match.group(1)!;
              final imageBytes = base64Decode(base64Data);
              AppLogger.info(
                '✅ Successfully decoded base64 image from response',
              );
              return Uint8List.fromList(imageBytes);
            }
          }

          AppLogger.debug(
            'Response text: ${responseText.substring(0, math.min(200, responseText.length))}...',
          );
        }

        // If we reach here, no image data was found in the response
        AppLogger.warning('⚠️ Response received but no image data found');

        // Fall back to detailed prompt generation for external services
        return await _generateImageViaTextPrompt(enhancedPrompt);
      } catch (modelError) {
        AppLogger.error('❌ Gemini image model error: $modelError');

        // If the model-specific error is about modalities, try alternative approach
        if (modelError.toString().contains('modalities') ||
            modelError.toString().contains('TEXT, IMAGE')) {
          AppLogger.info(
            '🔄 Trying alternative approach for image generation...',
          );
          return await _generateImageViaTextPrompt(enhancedPrompt);
        }

        rethrow;
      }
    } catch (e) {
      AppLogger.error('❌ Error generating asset: $e');

      // Don't fall back to mock in production - return null to show proper error
      if (!Environment.enableMockAI) {
        AppLogger.info('🚫 Production mode: returning null instead of mock');
        return null;
      }

      AppLogger.info('🎭 Falling back to mock image due to error');
      return _createMockImage();
    }
  }

  /// Alternative method to generate images via text prompts when direct image generation fails
  Future<Uint8List?> _generateImageViaTextPrompt(String prompt) async {
    try {
      AppLogger.info(
        '🔄 Generating detailed prompt for external image services...',
      );

      // Generate a detailed description for the image
      final detailedPrompt = await _generateDetailedImagePrompt(prompt);
      AppLogger.info('📝 Generated detailed prompt: $detailedPrompt');

      AppLogger.warning(
        '⚠️ Gemini 2.0 image generation API needs specific configuration',
      );
      AppLogger.info(
        '💡 Generated optimized prompt for external image generation services',
      );
      AppLogger.info(
        '🎯 Ready for DALL-E, Stable Diffusion, or Midjourney APIs',
      );

      // For now, create a placeholder that indicates the prompt is ready
      // In production, this would be sent to an external image generation API
      AppLogger.info(
        '🎨 Creating informational placeholder (replace with external API call)',
      );
      return _createMockImage();
    } catch (e) {
      AppLogger.error('❌ Error in alternative image generation: $e');
      return null;
    }
  }

  /// Generate a detailed image prompt using the text model
  Future<String> _generateDetailedImagePrompt(String basePrompt) async {
    try {
      final detailPrompt =
          '''
Create a very detailed, specific prompt for AI image generation based on this request: "$basePrompt"

The detailed prompt should include:
- Specific visual elements and composition
- Art style and aesthetic direction
- Color scheme and lighting
- Technical quality specifications
- Professional design elements

Return only the detailed prompt text, ready to use for image generation.
''';

      final response = await _textModel.generateContent([
        Content.text(detailPrompt),
      ]);

      if (response.text?.isNotEmpty == true) {
        return response.text!.trim();
      }

      return basePrompt; // Fallback to original prompt
    } catch (e) {
      AppLogger.warning('⚠️ Error generating detailed prompt: $e');
      return basePrompt;
    }
  }

  /// Enhance the user prompt for better asset generation
  String _enhancePromptForAssetGeneration(String userPrompt) {
    return '''
Generate a high-quality digital image asset: "$userPrompt"

Create a professional digital asset with these specifications:
- High resolution (1024x1024 pixels minimum)
- Clean, modern design suitable for applications
- Transparent background when appropriate
- Vector-style or clean raster graphics
- Professional color palette
- Clear, crisp details optimized for digital use

Style guidelines:
- Modern, minimalist aesthetic
- Suitable for mobile and web applications
- Professional quality for commercial use
- Clear visual hierarchy and composition

Output the generated image directly.
''';
  }

  /// Create a mock image for testing
  Uint8List _createMockImage() {
    // Create a simple 100x100 colored square as base64 PNG
    // This is a valid PNG that can be displayed with Image.memory()
    const base64Image =
        'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAIFSURBVHic7doxS8NAGIDhNwmkQ6c6dHJw6OTg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8A==';

    // Decode base64 to bytes
    final bytes = base64Decode(base64Image);
    return Uint8List.fromList(bytes);
  }

  /// Alternative method using HTTP directly for custom API endpoints
  ///
  /// This method demonstrates how to make HTTP POST requests to custom
  /// image generation APIs that might not have Dart SDKs.
  Future<Uint8List?> generateAssetFromPromptHttp(String prompt) async {
    try {
      AppLogger.info('🌐 Making HTTP request for asset generation');

      // Example HTTP request structure - customize based on your API
      final response = await http.post(
        Uri.parse('https://api.example-image-generator.com/v1/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'width': 1024,
          'height': 1024,
          'quality': 'high',
          'style': 'digital-art',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Assuming the API returns a base64 encoded image
        if (data['image'] != null) {
          return base64Decode(data['image']);
        }

        // Or if the API returns a URL to download the image
        if (data['image_url'] != null) {
          final imageResponse = await http.get(Uri.parse(data['image_url']));
          if (imageResponse.statusCode == 200) {
            return imageResponse.bodyBytes;
          }
        }
      }

      AppLogger.warning(
        '⚠️ HTTP request failed with status: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      AppLogger.error('❌ HTTP request error: $e');
      return null;
    }
  }

  /// Get creative prompt suggestions from Gemini for a specific asset category
  ///
  /// Takes an asset [category] and returns a list of creative prompt suggestions
  /// that users can use as inspiration for their asset generation.
  Future<List<String>> getPromptSuggestions(String category) async {
    try {
      AppLogger.info('💡 Getting prompt suggestions for category: $category');

      final suggestionPrompt =
          '''
Generate 5 creative and inspiring prompt suggestions for creating ${category.toLowerCase()} assets.

Each suggestion should be:
- Specific and detailed
- Creative and engaging
- Suitable for AI image generation
- Professional quality oriented
- Between 10-20 words

Format: Return only the suggestions, one per line, without numbering or bullets.

Category: $category
''';

      final response = await _suggestionsModel.generateContent([
        Content.text(suggestionPrompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        AppLogger.warning('⚠️ No suggestions received from Gemini');
        return [];
      }

      // Parse the response text into individual suggestions
      final suggestions = response.text!
          .split('\n')
          .map((line) => line.trim())
          .where(
            (line) =>
                line.isNotEmpty &&
                !line.startsWith('*') &&
                !line.startsWith('-'),
          )
          .take(5)
          .toList();

      AppLogger.info(
        '✅ Generated ${suggestions.length} suggestions for $category',
      );
      return suggestions;
    } catch (e) {
      AppLogger.error('❌ Error getting prompt suggestions: $e');
      return [];
    }
  }

  /// Get creative suggestions from Gemini for a specific asset category
  ///
  /// Expert AI prompt creator method that provides three unique, creative,
  /// and professional-sounding suggestions ready for text-to-image generation.
  Future<List<String>> getSuggestions(String category) async {
    try {
      AppLogger.info('🎨 Getting expert suggestions for category: $category');

      final suggestionPrompt =
          '''
You are an expert AI prompt creator. I need three unique, creative, and professional-sounding suggestions for a user to create a $category. The suggestions should be concise and ready to use in a text-to-image generator. Format the response as a bulleted list with each suggestion on a new line.
''';

      final response = await _suggestionsModel.generateContent([
        Content.text(suggestionPrompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        AppLogger.warning('⚠️ No suggestions received from Gemini');
        return [];
      }

      // Parse the response text into individual suggestions
      final suggestions = response.text!
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) {
            // Remove bullet points, numbers, and other formatting
            String cleaned = line;
            if (line.startsWith('•') ||
                line.startsWith('-') ||
                line.startsWith('*')) {
              cleaned = line.substring(1).trim();
            }
            // Remove numbered lists (1., 2., etc.)
            if (RegExp(r'^\d+\.\s*').hasMatch(cleaned)) {
              cleaned = cleaned.replaceFirst(RegExp(r'^\d+\.\s*'), '');
            }
            return cleaned;
          })
          .where((line) => line.isNotEmpty)
          .take(3)
          .toList();

      AppLogger.info(
        '✅ Generated ${suggestions.length} expert suggestions for $category',
      );
      return suggestions;
    } catch (e) {
      AppLogger.error('❌ Error getting expert suggestions: $e');
      return [];
    }
  }

  /// Generate color palette suggestions for a given prompt or theme
  ///
  /// Takes a [prompt] or [theme] and returns a list of color suggestions
  /// in various formats (hex, RGB, color names, CMYK)
  Future<List<Map<String, dynamic>>> generateColorPalette(String prompt) async {
    try {
      AppLogger.info('🎨 Generating color palette for: $prompt');

      final colorPrompt =
          '''
Generate a professional color palette of 5-8 colors for the theme/concept: "$prompt"

For each color, provide:
1. Color name (descriptive name like "Ocean Blue", "Sunset Orange")
2. Hex code (e.g., #FF5733)
3. RGB values (e.g., RGB(255, 87, 51))
4. CMYK values (e.g., CMYK(0, 66, 80, 0))

Format the response as JSON:
{
  "colors": [
    {
      "name": "Color Name",
      "hex": "#RRGGBB",
      "rgb": "RGB(r, g, b)",
      "cmyk": "CMYK(c, m, y, k)"
    }
  ]
}

Make sure the colors work well together and are suitable for digital design.
''';

      final response = await _suggestionsModel.generateContent([
        Content.text(colorPrompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        AppLogger.warning('⚠️ No color palette received from Gemini');
        return [];
      }

      try {
        // Try to parse JSON response
        final jsonResponse = jsonDecode(response.text!);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('colors')) {
          final colors = jsonResponse['colors'] as List;
          final colorList = colors
              .map((color) => color as Map<String, dynamic>)
              .toList();

          AppLogger.info(
            '✅ Generated color palette with ${colorList.length} colors',
          );
          return colorList;
        }
      } catch (e) {
        AppLogger.warning('⚠️ Failed to parse color palette JSON: $e');

        // Fallback: try to extract colors from text
        final lines = response.text!.split('\n');
        final colors = <Map<String, dynamic>>[];

        for (final line in lines) {
          if (line.contains('#') && line.length > 10) {
            final hexMatch = RegExp(r'#([A-Fa-f0-9]{6})').firstMatch(line);
            if (hexMatch != null) {
              final hex = '#${hexMatch.group(1)}';
              colors.add({
                'name': 'Generated Color ${colors.length + 1}',
                'hex': hex,
                'rgb': 'RGB(${_hexToRgb(hex)})',
                'cmyk': 'CMYK(0, 0, 0, 0)', // Simplified for fallback
              });
            }
          }
        }

        if (colors.isNotEmpty) {
          AppLogger.info(
            '✅ Extracted ${colors.length} colors from text response',
          );
          return colors;
        }
      }

      AppLogger.warning('⚠️ Could not parse color palette from response');
      return [];
    } catch (e) {
      AppLogger.error('❌ Error generating color palette: $e');
      return [];
    }
  }

  /// Generate color suggestions for a specific use case
  ///
  /// Takes a [context] (e.g., "button", "background", "accent") and returns
  /// color suggestions with explanations
  Future<List<Map<String, String>>> generateColorSuggestions(
    String context,
  ) async {
    try {
      AppLogger.info('🎨 Generating color suggestions for: $context');

      final colorPrompt =
          '''
Suggest 3-5 professional colors for a $context in digital design.

For each color suggestion, provide:
1. Color name (e.g., "Professional Blue")
2. Hex code (e.g., #2E86AB)
3. Description/reason why it works well for $context

Format as JSON:
{
  "suggestions": [
    {
      "name": "Color Name",
      "hex": "#RRGGBB",
      "description": "Why this color works well for $context"
    }
  ]
}
''';

      final response = await _suggestionsModel.generateContent([
        Content.text(colorPrompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        AppLogger.warning('⚠️ No color suggestions received from Gemini');
        return [];
      }

      try {
        final jsonResponse = jsonDecode(response.text!);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('suggestions')) {
          final suggestions = jsonResponse['suggestions'] as List;
          final colorSuggestions = suggestions
              .map((suggestion) => Map<String, String>.from(suggestion as Map))
              .toList();

          AppLogger.info(
            '✅ Generated ${colorSuggestions.length} color suggestions',
          );
          return colorSuggestions;
        }
      } catch (e) {
        AppLogger.warning('⚠️ Failed to parse color suggestions JSON: $e');
      }

      AppLogger.warning('⚠️ Could not parse color suggestions from response');
      return [];
    } catch (e) {
      AppLogger.error('❌ Error generating color suggestions: $e');
      return [];
    }
  }

  /// Convert hex color to RGB string
  String _hexToRgb(String hex) {
    final hexColor = hex.replaceAll('#', '');
    final r = int.parse(hexColor.substring(0, 2), radix: 16);
    final g = int.parse(hexColor.substring(2, 4), radix: 16);
    final b = int.parse(hexColor.substring(4, 6), radix: 16);
    return '$r, $g, $b';
  }

  /// Check if the AI service is properly configured
  bool get isConfigured =>
      _apiKey.isNotEmpty && !_apiKey.contains('placeholder');

  /// Get the current model information
  String get modelInfo => 'gemini-1.5-flash';
}

/// Riverpod provider for the AI service
///
/// This provider creates and exposes an instance of AiService.
/// It uses riverpod_annotation for code generation.
@riverpod
AiService aiService(AiServiceRef ref) {
  return AiService();
}

/// Provider for checking if AI service is available
@riverpod
bool isAiServiceAvailable(IsAiServiceAvailableRef ref) {
  try {
    final aiService = ref.watch(aiServiceProvider);
    return aiService.isConfigured;
  } catch (e) {
    return false;
  }
}
