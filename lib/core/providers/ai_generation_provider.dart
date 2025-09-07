import 'package:flutter/foundation.dart';
import '../../services/image_generation_service.dart';
import '../../services/gemini_service.dart';
import '../utils/logger.dart';

/// Provider for handling AI image generation state and logic
class AIGenerationProvider extends ChangeNotifier {
  // Generation state
  bool _isGenerating = false;
  String? _error;
  List<String> _generatedImages = []; // Base64 encoded images
  String _currentPrompt = '';

  // Generation parameters
  String _selectedAssetType = '';
  String _selectedStyle = '';
  String _selectedColor = '';
  String _aspectRatio = '1:1';

  // History
  List<Map<String, dynamic>> _generationHistory = [];
  bool _isLoadingHistory = false;

  // Suggestions
  List<String> _suggestions = [];

  // Additional properties for UI compatibility
  String? get generatedImage =>
      _generatedImages.isNotEmpty ? _generatedImages.first : null;
  String? get errorMessage => _error;
  List<String> get suggestions => _suggestions;

  // Getters
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  List<String> get generatedImages => _generatedImages;
  String get currentPrompt => _currentPrompt;
  String get selectedAssetType => _selectedAssetType;
  String get selectedStyle => _selectedStyle;
  String get selectedColor => _selectedColor;
  String get aspectRatio => _aspectRatio;
  List<Map<String, dynamic>> get generationHistory => _generationHistory;
  bool get isLoadingHistory => _isLoadingHistory;

  /// Set generation parameters
  void setAssetType(String assetType) {
    _selectedAssetType = assetType;
    notifyListeners();
  }

  void setStyle(String style) {
    _selectedStyle = style;
    notifyListeners();
  }

  void setColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setAspectRatio(String aspectRatio) {
    _aspectRatio = aspectRatio;
    notifyListeners();
  }

  void setPrompt(String prompt) {
    _currentPrompt = prompt;
    notifyListeners();
  }

  /// Clear current generation
  void clearGeneration() {
    _generatedImages.clear();
    _error = null;
    _currentPrompt = '';
    notifyListeners();
  }

  /// Generate image with current parameters
  Future<bool> generateImage({String? customPrompt}) async {
    try {
      _isGenerating = true;
      _error = null;
      _generatedImages.clear();
      notifyListeners();

      // Build prompt with current parameters
      String finalPrompt = customPrompt ?? _buildEnhancedPrompt();
      _currentPrompt = finalPrompt;

      // Generate image using Vertex AI through Supabase Edge Function
      final result = await ImageGenerationService.generateImageImagen4(
        prompt: finalPrompt,
        aspectRatio: _aspectRatio,
      );

      if (result != null && result['success'] == true) {
        // Extract image data from Vertex AI response
        final vertexData = result['data'];
        if (vertexData != null && vertexData['predictions'] != null) {
          final predictions = vertexData['predictions'] as List;
          if (predictions.isNotEmpty) {
            final imageData = predictions.first;
            if (imageData['bytesBase64Encoded'] != null) {
              // Convert Vertex AI response to our format
              _generatedImages = [imageData['bytesBase64Encoded']];
              _error = null;

              // Save to generation history
              await _saveToHistory(finalPrompt, _generatedImages.first);
              return true;
            }
          }
        }

        _error = 'Invalid image data received from Vertex AI';
        return false;
      } else {
        _error = result?['error'] ?? 'Generation failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.error(
        'Image generation failed',
        tag: 'AIGenerationProvider',
        error: e,
      );
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Enhance prompt using Gemini AI
  Future<String> enhancePrompt(String basePrompt) async {
    try {
      return await GeminiService.enhancePrompt(basePrompt);
    } catch (e) {
      AppLogger.error(
        'Failed to enhance prompt with Gemini',
        tag: 'AIGenerationProvider',
        error: e,
      );
      // Return original prompt if enhancement fails
      return basePrompt;
    }
  }

  /// Build enhanced prompt from current parameters
  String _buildEnhancedPrompt() {
    List<String> promptParts = [];

    // Add asset type context
    if (_selectedAssetType.isNotEmpty) {
      switch (_selectedAssetType) {
        case 'character':
          promptParts.add('A detailed character design');
          break;
        case 'environment':
          promptParts.add('A beautiful environment scene');
          break;
        case 'object':
          promptParts.add('A well-designed object');
          break;
        case 'texture':
          promptParts.add('A high-quality texture pattern');
          break;
        default:
          promptParts.add('A digital asset');
      }
    }

    // Add style context
    if (_selectedStyle.isNotEmpty) {
      promptParts.add('in $_selectedStyle style');
    }

    // Add color context
    if (_selectedColor.isNotEmpty) {
      promptParts.add('with $_selectedColor color scheme');
    }

    // Add base prompt
    if (_currentPrompt.isNotEmpty) {
      promptParts.add(_currentPrompt);
    }

    // Add quality enhancers
    promptParts.add('high quality, detailed, professional digital art');

    return promptParts.join(', ');
  }

  /// Save image to user library
  Future<bool> saveToLibrary(String imageBase64) async {
    try {
      // For now, just add to generation history
      // You can implement actual library saving later
      AppLogger.info('Saving image to library', tag: 'AIGenerationProvider');
      return true;
    } catch (e) {
      _error = 'Failed to save image: $e';
      notifyListeners();
      return false;
    }
  }

  /// Load generation history
  Future<void> loadGenerationHistory() async {
    try {
      _isLoadingHistory = true;
      notifyListeners();

      // For now, history is kept in memory
      // You can implement persistent storage later
      AppLogger.info('Loading generation history', tag: 'AIGenerationProvider');
    } catch (e) {
      _error = 'Failed to load history: $e';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Save to history (internal)
  Future<void> _saveToHistory(String prompt, String imageBase64) async {
    try {
      // Add to local history for now
      _generationHistory.insert(0, {
        'prompt': prompt,
        'image_base64': imageBase64,
        'aspect_ratio': _aspectRatio,
        'asset_type': _selectedAssetType,
        'style': _selectedStyle,
        'color': _selectedColor,
        'generated_at': DateTime.now().toIso8601String(),
      });

      // Keep only last 50 items
      if (_generationHistory.length > 50) {
        _generationHistory = _generationHistory.take(50).toList();
      }
    } catch (e) {
      // Don't fail generation if history save fails
      AppLogger.warning(
        'Failed to save to history: $e',
        tag: 'AIGenerationProvider',
      );
    }
  }

  /// Reset all generation parameters
  void resetParameters() {
    _selectedAssetType = '';
    _selectedStyle = '';
    _selectedColor = '';
    _aspectRatio = '1:1';
    _currentPrompt = '';
    _generatedImages.clear();
    _error = null;
    notifyListeners();
  }

  /// Regenerate with same parameters
  Future<bool> regenerate() async {
    if (_currentPrompt.isEmpty) {
      _error = 'No prompt to regenerate';
      notifyListeners();
      return false;
    }

    return await generateImage(customPrompt: _currentPrompt);
  }

  /// Get prompt suggestions based on current parameters
  List<String> getPromptSuggestions() {
    List<String> suggestions = [];

    switch (_selectedAssetType) {
      case 'character':
        suggestions.addAll([
          'a brave warrior with ancient armor',
          'a mystical mage casting spells',
          'a cyberpunk ninja in neon city',
          'a friendly village merchant',
          'an alien creature from distant planet',
        ]);
        break;
      case 'environment':
        suggestions.addAll([
          'a serene mountain landscape at sunset',
          'a bustling medieval marketplace',
          'a futuristic cityscape with flying cars',
          'an enchanted forest with glowing mushrooms',
          'an underwater coral reef civilization',
        ]);
        break;
      case 'object':
        suggestions.addAll([
          'an ancient magical sword with runes',
          'a steampunk mechanical clockwork device',
          'a glowing crystal with mystical powers',
          'a futuristic weapon with energy core',
          'an ornate treasure chest filled with gems',
        ]);
        break;
      case 'texture':
        suggestions.addAll([
          'weathered stone wall with moss',
          'polished metal with scratches',
          'fabric with intricate patterns',
          'wood grain with natural imperfections',
          'alien surface with bio-luminescent patterns',
        ]);
        break;
      default:
        suggestions.addAll([
          'a beautiful digital artwork',
          'concept art with professional quality',
          'detailed illustration with vibrant colors',
          'artistic design with modern style',
          'creative visual with unique composition',
        ]);
    }

    return suggestions;
  }

  /// Generate suggestions based on current parameters using Gemini AI
  Future<void> generateSuggestions() async {
    try {
      // Use Gemini service to generate AI-powered suggestions
      _suggestions = await GeminiService.generateSuggestions(
        assetType: _selectedAssetType.isNotEmpty
            ? _selectedAssetType
            : 'general',
        style: _selectedStyle.isNotEmpty ? _selectedStyle : null,
        theme: _selectedColor.isNotEmpty ? _selectedColor : null,
      );
      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'Failed to generate suggestions using Gemini',
        tag: 'AIGenerationProvider',
        error: e,
      );
      // Fallback to manual suggestions
      _suggestions = getPromptSuggestions();
      notifyListeners();
    }
  }

  /// Generate image with enhanced parameters
  Future<bool> generateWithPrompt({
    required String prompt,
    required String assetType,
  }) async {
    setPrompt(prompt);
    setAssetType(assetType);
    return await generateImage();
  }
}
