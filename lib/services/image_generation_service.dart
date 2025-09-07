import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';

class ImageGenerationService {
  static const String _logTag = 'ImageGenerationService';

  /// Generate an image using Vertex AI's Imagen models through Supabase Edge Function
  static Future<Map<String, dynamic>?> generateImage({
    required String prompt,
    String? modelVersion,
    String? aspectRatio,
    String? negativePrompt,
    int? sampleCount,
  }) async {
    try {
      AppLogger.info('Generating image with Vertex AI', tag: _logTag);
      AppLogger.debug(
        'Prompt: ${prompt.length > 100 ? prompt.substring(0, 100) + '...' : prompt}',
        tag: _logTag,
      );
      AppLogger.debug(
        'Model: ${modelVersion ?? "imagegeneration@006"}',
        tag: _logTag,
      );
      AppLogger.debug(
        'Aspect Ratio: ${aspectRatio ?? "default"}',
        tag: _logTag,
      );

      // Prepare request body for the Edge Function
      final requestBody = <String, dynamic>{'prompt': prompt};

      // Add optional parameters if provided
      if (modelVersion != null) {
        requestBody['model_version'] = modelVersion;
      }
      if (aspectRatio != null) {
        requestBody['aspectRatio'] = aspectRatio;
      }
      if (negativePrompt != null) {
        requestBody['negativePrompt'] = negativePrompt;
      }
      if (sampleCount != null) {
        requestBody['sampleCount'] = sampleCount;
      }

      AppLogger.debug('Request body: $requestBody', tag: _logTag);

      // Call the Supabase Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'generate-image',
        body: requestBody,
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug('Raw function response: ${response.data}', tag: _logTag);

      // Check if the response indicates success
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          AppLogger.info('Image generation successful', tag: _logTag);
          return responseData;
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
      AppLogger.error(
        'Image generation service error: $e',
        tag: _logTag,
        error: e,
      );
      AppLogger.debug('Stack trace: $stackTrace', tag: _logTag);

      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generate an image with default Imagen 4.0 settings
  static Future<Map<String, dynamic>?> generateImageImagen4({
    required String prompt,
    String aspectRatio = "1:1",
    String? negativePrompt,
  }) async {
    return await generateImage(
      prompt: prompt,
      modelVersion: "imagegeneration@006", // Imagen 4.0
      aspectRatio: aspectRatio,
      negativePrompt: negativePrompt,
      sampleCount: 1,
    );
  }

  /// Generate an image with Imagen 3.0 Fast for quicker generation
  static Future<Map<String, dynamic>?> generateImageImagen3Fast({
    required String prompt,
    String aspectRatio = "1:1",
    String? negativePrompt,
  }) async {
    return await generateImage(
      prompt: prompt,
      modelVersion: "imagen-3.0-fast-generate-001",
      aspectRatio: aspectRatio,
      negativePrompt: negativePrompt,
      sampleCount: 1,
    );
  }
}
