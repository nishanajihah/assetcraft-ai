import 'dart:convert';
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
  late final GenerativeModel _model;
  late final String _apiKey;

  /// Initialize the AI service with the Gemini API key
  AiService() {
    _apiKey = Environment.geminiApiKey;

    if (_apiKey.isEmpty || _apiKey.contains('placeholder')) {
      AppLogger.warning('⚠️ Gemini API key not configured');
      throw Exception('Gemini API key is required for AI service');
    }

    // Initialize the Gemini model for image generation
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.8,
        maxOutputTokens: 2048,
      ),
    );

    AppLogger.info('✅ AI Service initialized with Gemini model');
  }

  /// Generate an asset from a text prompt
  ///
  /// Takes a [prompt] string and returns generated image data as Uint8List.
  /// This method handles the API call to Google Gemini and processes the response.
  ///
  /// Returns null if generation fails or if the response doesn't contain image data.
  Future<Uint8List?> generateAssetFromPrompt(String prompt) async {
    try {
      AppLogger.info('🎨 Generating asset from prompt: $prompt');

      // Create the enhanced prompt for better asset generation
      final enhancedPrompt = _enhancePromptForAssetGeneration(prompt);

      // Generate content using Gemini
      final response = await _model.generateContent([
        Content.text(enhancedPrompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        AppLogger.warning('⚠️ Gemini response is empty');
        return null;
      }

      // For now, we'll use the text response to make an image generation request
      // Since Gemini doesn't directly generate images, we'll use it to enhance
      // the prompt and then call an image generation API
      return await _generateImageFromEnhancedPrompt(response.text!);
    } catch (e) {
      AppLogger.error('❌ Error generating asset: $e');
      return null;
    }
  }

  /// Enhance the user prompt for better asset generation
  String _enhancePromptForAssetGeneration(String userPrompt) {
    return '''
Create a detailed description for generating a high-quality digital asset based on this request: "$userPrompt"

The description should include:
- Visual style and aesthetic
- Color palette suggestions
- Composition and layout details
- Technical specifications (resolution, format)
- Art style (realistic, cartoon, minimalist, etc.)

Focus on creating assets suitable for:
- Mobile applications
- Web interfaces
- Game development
- Marketing materials

Make the description clear, specific, and optimized for AI image generation.
''';
  }

  /// Generate image from enhanced prompt using an image generation API
  ///
  /// Since Gemini doesn't directly generate images, this method would typically
  /// call an image generation service like DALL-E, Midjourney API, or Stable Diffusion.
  /// For now, this is a placeholder that would need to be implemented based on
  /// the chosen image generation service.
  Future<Uint8List?> _generateImageFromEnhancedPrompt(
    String enhancedPrompt,
  ) async {
    try {
      // TODO: Implement actual image generation API call
      // This could be DALL-E, Stable Diffusion, or another image generation service

      AppLogger.info(
        '🖼️ Enhanced prompt for image generation: $enhancedPrompt',
      );

      // For now, return null as a placeholder
      // In a real implementation, you would:
      // 1. Call your chosen image generation API
      // 2. Process the response
      // 3. Return the image data as Uint8List

      AppLogger.warning(
        '⚠️ Image generation not implemented yet - placeholder method',
      );
      return null;
    } catch (e) {
      AppLogger.error('❌ Error in image generation: $e');
      return null;
    }
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
