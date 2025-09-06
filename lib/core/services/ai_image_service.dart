import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Service for handling AI image generation through Supabase Edge Functions
class AIImageService {
  static final _supabase = Supabase.instance.client;
  static const String _logTag = 'AIImageService';

  /// Generate image using Vertex AI Imagen through Supabase Edge Function
  static Future<AIImageResult> generateImage({
    required String prompt,
    String aspectRatio = '1:1',
    String model = 'imagen-3.0-fast-generate-001',
  }) async {
    try {
      AppLogger.info(
        'Starting image generation with prompt: $prompt',
        tag: _logTag,
      );

      // Call the Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'generate-image',
        body: {'prompt': prompt, 'aspectRatio': aspectRatio, 'model': model},
      );

      AppLogger.debug(
        'Edge function response status: ${response.status}',
        tag: _logTag,
      );

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error occurred';
        throw AIImageException('Image generation failed: $error');
      }

      final data = response.data;

      if (data['success'] != true) {
        throw AIImageException(data['error'] ?? 'Image generation failed');
      }

      // Parse the response
      final images = data['images'] as List<dynamic>;
      final generatedImages = <AIGeneratedImage>[];

      for (final imageData in images) {
        final base64String = imageData['bytesBase64Encoded'] as String;
        final mimeType = imageData['mimeType'] as String? ?? 'image/png';

        // Decode base64 to bytes
        final imageBytes = base64Decode(base64String);

        generatedImages.add(
          AIGeneratedImage(
            imageBytes: imageBytes,
            mimeType: mimeType,
            prompt: prompt,
            aspectRatio: aspectRatio,
          ),
        );
      }

      AppLogger.success(
        'Successfully generated ${generatedImages.length} images',
        tag: _logTag,
      );

      return AIImageResult(
        success: true,
        images: generatedImages,
        prompt: prompt,
        aspectRatio: aspectRatio,
      );
    } catch (e) {
      AppLogger.error('Error generating image: $e', tag: _logTag, error: e);

      if (e is AIImageException) {
        rethrow;
      }

      throw AIImageException('Failed to generate image: ${e.toString()}');
    }
  }

  /// Enhance prompt using Gemini (for better image generation)
  static Future<String> enhancePrompt(String originalPrompt) async {
    try {
      // Call another Edge Function for prompt enhancement
      final response = await _supabase.functions.invoke(
        'enhance-prompt',
        body: {'prompt': originalPrompt},
      );

      if (response.status == 200 && response.data['success'] == true) {
        return response.data['enhancedPrompt'] as String;
      }

      // Fallback to original prompt if enhancement fails
      return originalPrompt;
    } catch (e) {
      AppLogger.warning(
        'Prompt enhancement failed, using original: $e',
        tag: _logTag,
        data: e,
      );
      return originalPrompt;
    }
  }

  /// Get generation history for the current user
  static Future<List<AIGenerationHistory>> getGenerationHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('generation_history')
          .select('*')
          .eq('user_id', _supabase.auth.currentUser?.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map((item) => AIGenerationHistory.fromJson(item))
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching generation history: $e',
        tag: _logTag,
        error: e,
      );
      return [];
    }
  }

  /// Save generated image to user's library
  static Future<bool> saveToLibrary({
    required Uint8List imageBytes,
    required String prompt,
    required String aspectRatio,
    String? assetType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload image to Supabase Storage
      final fileName = 'generated_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = '$userId/$fileName';

      await _supabase.storage
          .from('generated-images')
          .uploadBinary(path, imageBytes);

      // Get public URL
      final imageUrl = _supabase.storage
          .from('generated-images')
          .getPublicUrl(path);

      // Save metadata to database
      await _supabase.from('user_assets').insert({
        'user_id': userId,
        'image_url': imageUrl,
        'prompt': prompt,
        'aspect_ratio': aspectRatio,
        'asset_type': assetType,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.success('Image saved to library successfully', tag: _logTag);
      return true;
    } catch (e) {
      AppLogger.error(
        'Error saving image to library: $e',
        tag: _logTag,
        error: e,
      );
      return false;
    }
  }
}

/// Result class for AI image generation
class AIImageResult {
  final bool success;
  final List<AIGeneratedImage> images;
  final String prompt;
  final String aspectRatio;
  final String? error;

  AIImageResult({
    required this.success,
    required this.images,
    required this.prompt,
    required this.aspectRatio,
    this.error,
  });
}

/// Individual generated image
class AIGeneratedImage {
  final Uint8List imageBytes;
  final String mimeType;
  final String prompt;
  final String aspectRatio;

  AIGeneratedImage({
    required this.imageBytes,
    required this.mimeType,
    required this.prompt,
    required this.aspectRatio,
  });
}

/// Generation history item
class AIGenerationHistory {
  final String id;
  final String userId;
  final String prompt;
  final String imageUrl;
  final String aspectRatio;
  final String? assetType;
  final DateTime createdAt;

  AIGenerationHistory({
    required this.id,
    required this.userId,
    required this.prompt,
    required this.imageUrl,
    required this.aspectRatio,
    this.assetType,
    required this.createdAt,
  });

  factory AIGenerationHistory.fromJson(Map<String, dynamic> json) {
    return AIGenerationHistory(
      id: json['id'],
      userId: json['user_id'],
      prompt: json['prompt'],
      imageUrl: json['image_url'],
      aspectRatio: json['aspect_ratio'],
      assetType: json['asset_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Custom exception for AI image generation
class AIImageException implements Exception {
  final String message;

  AIImageException(this.message);

  @override
  String toString() => 'AIImageException: $message';
}
