import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';

class ImageGenerationService {
  static const String _logTag = 'ImageGenerationService';

  /// Generate an image using Vertex AI through Supabase Edge Function
  /// This function uses the IMAGEN_MODEL and VERTEX_AI_CREDENTIALS secrets
  /// configured in your Supabase project environment
  static Future<Map<String, dynamic>?> generateImageWithVertexAI({
    required String prompt,
  }) async {
    try {
      AppLogger.info('Generating image with Vertex AI', tag: _logTag);
      AppLogger.debug(
        'Prompt: ${prompt.length > 100 ? prompt.substring(0, 100) + '...' : prompt}',
        tag: _logTag,
      );

      // Call the Supabase Edge Function with just the prompt
      // Model version and credentials are managed on the backend
      final response = await Supabase.instance.client.functions.invoke(
        'generate-image',
        body: {'prompt': prompt},
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug('Raw function response: ${response.data}', tag: _logTag);

      // Check if the response indicates success
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          AppLogger.info('Image generation successful', tag: _logTag);

          // Extract image data from Vertex AI response
          final vertexData = responseData['data'];
          if (vertexData != null && vertexData['predictions'] != null) {
            final predictions = vertexData['predictions'] as List;
            if (predictions.isNotEmpty) {
              final imageData = predictions.first;

              // Vertex AI returns base64 encoded image in bytesBase64Encoded field
              if (imageData['bytesBase64Encoded'] != null) {
                return {
                  'success': true,
                  'imageBase64': imageData['bytesBase64Encoded'],
                  'metadata': responseData['metadata'],
                };
              }
            }
          }

          AppLogger.error(
            'Invalid image data received from Vertex AI',
            tag: _logTag,
          );
          return {
            'success': false,
            'error': 'Invalid image data received from Vertex AI',
          };
        } else {
          final error = responseData['error'] ?? 'Unknown error occurred';
          AppLogger.error('Image generation failed: $error', tag: _logTag);
          return {'success': false, 'error': error};
        }
      }

      AppLogger.error(
        'Invalid response format from Edge Function',
        tag: _logTag,
      );
      return {'success': false, 'error': 'Invalid response format'};
    } catch (e, stackTrace) {
      AppLogger.error('Image generation service error: $e', tag: _logTag);
      AppLogger.debug('Stack trace: $stackTrace', tag: _logTag);

      return {'success': false, 'error': e.toString()};
    }
  }

  /// Legacy method for backward compatibility - now uses Vertex AI
  @Deprecated('Use generateImageWithVertexAI instead')
  static Future<Map<String, dynamic>?> generateImage({
    required String prompt,
    String? modelVersion,
    String? aspectRatio,
    String? negativePrompt,
    int? sampleCount,
  }) async {
    AppLogger.warning(
      'Using deprecated generateImage method, switching to Vertex AI',
      tag: _logTag,
    );
    return await generateImageWithVertexAI(prompt: prompt);
  }

  /// Generate image with Imagen 4.0 - uses backend model configuration
  static Future<Map<String, dynamic>?> generateImageImagen4({
    required String prompt,
    String? aspectRatio,
    String? negativePrompt,
  }) async {
    return await generateImageWithVertexAI(prompt: prompt);
  }

  /// Generate image with fast generation - uses backend model configuration
  static Future<Map<String, dynamic>?> generateImageFast({
    required String prompt,
    String? aspectRatio,
    String? negativePrompt,
  }) async {
    return await generateImageWithVertexAI(prompt: prompt);
  }
}
