import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/environment.dart';
import '../utils/app_logger.dart';

part 'ai_service.g.dart';

/// AI Service for generating assets using Google Gemini and Google Cloud Imagen
///
/// This service handles API calls to Google Gemini for text generation and suggestions,
/// and Google Cloud Imagen for image generation. It provides methods to generate images
/// from text prompts and handles API key security through environment variables.
class AiService {
  late final GenerativeModel _suggestionsModel;
  late final String _geminiApiKey;
  late final String _googleCloudApiKey;
  late final String _projectId;

  /// Initialize the AI service with the API keys
  AiService() {
    _geminiApiKey = Environment.geminiApiKey;
    _googleCloudApiKey = Environment.googleCloudApiKey;
    _projectId = Environment.googleCloudProjectId;

    if (_geminiApiKey.isEmpty || _geminiApiKey.contains('placeholder')) {
      AppLogger.warning('⚠️ Gemini API key not configured');
      throw Exception('Gemini API key is required for AI service');
    }

    _suggestionsModel = GenerativeModel(
      model: Environment.geminiSuggestionsModel,
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.9,
        maxOutputTokens: 1024,
      ),
    );

    AppLogger.info('✅ AI Service initialized with models:');
    AppLogger.info('  Suggestions: ${Environment.geminiSuggestionsModel}');
    AppLogger.info(
      '  Image Generation: Google Cloud Imagen ${Environment.imagenModel}',
    );
    AppLogger.info(
      '  Google Cloud configured: ${Environment.hasGoogleCloudConfig}',
    );
  }

  /// Generate an asset from a text prompt using Google Cloud Imagen
  ///
  /// Takes a [prompt] string and returns generated image data as Uint8List.
  /// This method uses Google Cloud Imagen API to create images directly.
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

      // Check if Google Cloud is configured
      if (!Environment.hasGoogleCloudConfig) {
        AppLogger.warning(
          '⚠️ Google Cloud Imagen not configured, using mock image',
        );
        AppLogger.info(
          '💡 Please configure GOOGLE_CLOUD_PROJECT_ID and GOOGLE_CLOUD_API_KEY in .env file',
        );
        return _createMockImage();
      }

      // Generate image using Google Cloud Imagen API
      return await _generateImageWithImagen(prompt);
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

  /// Generate image using Google Cloud Imagen API
  Future<Uint8List?> _generateImageWithImagen(String prompt) async {
    try {
      AppLogger.info('🚀 Calling Google Cloud Imagen API...');

      // Create the enhanced prompt for better asset generation
      final enhancedPrompt = _enhancePromptForAssetGeneration(prompt);
      AppLogger.debug('Enhanced prompt: $enhancedPrompt');

      // Prepare the Imagen API request
      final requestBody = {
        'instances': [
          {'prompt': enhancedPrompt},
        ],
        'parameters': {
          'guidance_scale': 15.0, // Higher values follow prompt more closely
          'number_of_images_in_batch': 1,
          'add_watermark': false,
          'safety_filter_level': 'block_few',
          'person_generation': 'allow_adult',
        },
      };

      // Make the API call to Google Cloud Imagen
      final response = await http.post(
        Uri.parse(
          'https://us-central1-aiplatform.googleapis.com/v1/projects/$_projectId/locations/us-central1/publishers/google/models/${Environment.imagenModel}:predict',
        ),
        headers: {
          'Authorization': 'Bearer $_googleCloudApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      AppLogger.debug('Imagen API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        AppLogger.info('✅ Received response from Imagen API');

        // Extract image data from response
        if (responseData['predictions'] != null &&
            responseData['predictions'].isNotEmpty) {
          final prediction = responseData['predictions'][0];

          if (prediction['bytesBase64Encoded'] != null) {
            final base64Data = prediction['bytesBase64Encoded'];
            final imageBytes = base64Decode(base64Data);
            AppLogger.info('✅ Successfully decoded image from Imagen API');
            return Uint8List.fromList(imageBytes);
          }
        }

        AppLogger.warning('⚠️ No image data found in Imagen response');
        return null;
      } else {
        AppLogger.error('❌ Imagen API error: ${response.statusCode}');
        AppLogger.error('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      AppLogger.error('❌ Error calling Imagen API: $e');
      return null;
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
    try {
      // Use a known working PNG base64 string (1x1 pixel black PNG)
      const validPngBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAGA+p6k3wAAAABJRU5ErkJggg==';

      final bytes = base64Decode(validPngBase64);
      final imageData = Uint8List.fromList(bytes);

      // Validate the created image
      if (_isValidImageData(imageData)) {
        AppLogger.info('✅ Created valid mock image (${bytes.length} bytes)');
        AppLogger.debug(
          'First 16 bytes: ${imageData.take(16).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}',
        );
        return imageData;
      } else {
        AppLogger.warning(
          '⚠️ Mock image validation failed, using manual fallback',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error creating mock image: $e');
    }

    // Create minimal PNG manually as fallback
    final List<int> minimalPng = [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, // IHDR length
      0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x00, 0x01, // width = 1
      0x00, 0x00, 0x00, 0x01, // height = 1
      0x08,
      0x00,
      0x00,
      0x00,
      0x00, // bit depth, color type, compression, filter, interlace
      0x37, 0x6E, 0xF9, 0x24, // IHDR CRC
      0x00, 0x00, 0x00, 0x0A, // IDAT length
      0x49, 0x44, 0x41, 0x54, // IDAT
      0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, // compressed data
      0xE2, 0x21, 0xBC, 0x33, // IDAT CRC
      0x00, 0x00, 0x00, 0x00, // IEND length
      0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82, // IEND CRC
    ];

    AppLogger.info(
      '✅ Created fallback PNG manually (${minimalPng.length} bytes)',
    );
    return Uint8List.fromList(minimalPng);
  }

  /// Validate image data to prevent decompression errors
  bool _isValidImageData(Uint8List imageData) {
    try {
      // Check minimum size (PNG header is at least 8 bytes)
      if (imageData.length < 8) {
        AppLogger.warning('⚠️ Image data too small: ${imageData.length} bytes');
        return false;
      }

      // Check PNG signature (first 8 bytes should be PNG signature)
      final pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      for (int i = 0; i < 8; i++) {
        if (imageData[i] != pngSignature[i]) {
          AppLogger.warning('⚠️ Invalid PNG signature');
          return false;
        }
      }

      AppLogger.info('✅ Image data validation passed');
      return true;
    } catch (e) {
      AppLogger.error('❌ Error validating image data: $e');
      return false;
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
          'Authorization': 'Bearer $_geminiApiKey',
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

  /// Generate AI-powered prompt suggestions based on asset type and user input
  ///
  /// This method creates personalized prompt suggestions that take into account
  /// the selected asset type, subtype, and any existing user input to generate
  /// creative and relevant suggestions for image generation.
  Future<List<String>> generatePromptSuggestions({
    required String assetType,
    String? assetSubtype,
    String? userInput,
  }) async {
    try {
      AppLogger.info('🎨 Generating AI prompt suggestions for $assetType');

      String suggestionPrompt;
      if (userInput != null && userInput.isNotEmpty) {
        suggestionPrompt =
            '''
You are an expert AI prompt creator. The user wants to create a $assetType and has started with this idea: "$userInput"

Please enhance and expand this into 3 different creative, professional prompts that would work well for AI image generation. Each prompt should:
- Build upon the user's existing idea
- Be specific and detailed for better AI image generation
- Include relevant style, mood, and technical details
- Be optimized for 2D digital art creation
- Be professional and suitable for commercial use

Format as a simple list with each suggestion on a new line.
''';
      } else {
        suggestionPrompt =
            '''
You are an expert AI prompt creator. The user wants to create a $assetType. Please provide 3 unique, creative, and professional prompt suggestions that would work well for AI image generation.

Each prompt should:
- Be specific and detailed for better AI image generation
- Include relevant style, mood, and technical details
- Be optimized for 2D digital art creation
- Be professional and suitable for commercial use
- Be creative and inspiring

Format as a simple list with each suggestion on a new line.
''';
      }

      final response = await _suggestionsModel.generateContent([
        Content.text(suggestionPrompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        AppLogger.warning('⚠️ No prompt suggestions received from AI');
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

      AppLogger.info('✅ Generated ${suggestions.length} AI prompt suggestions');
      return suggestions;
    } catch (e) {
      AppLogger.error('❌ Error generating prompt suggestions: $e');
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
      _geminiApiKey.isNotEmpty && !_geminiApiKey.contains('placeholder');

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
