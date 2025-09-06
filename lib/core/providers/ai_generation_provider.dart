import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/ai_image_service.dart';

/// Provider for handling AI image generation state and logic
class AIGenerationProvider extends ChangeNotifier {
  // Generation state
  bool _isGenerating = false;
  String? _error;
  List<AIGeneratedImage> _generatedImages = [];
  String _currentPrompt = '';

  // Generation parameters
  String _selectedAssetType = '';
  String _selectedStyle = '';
  String _selectedColor = '';
  String _aspectRatio = '1:1';

  // History
  List<AIGenerationHistory> _generationHistory = [];
  bool _isLoadingHistory = false;

  // Getters
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  List<AIGeneratedImage> get generatedImages => _generatedImages;
  String get currentPrompt => _currentPrompt;
  String get selectedAssetType => _selectedAssetType;
  String get selectedStyle => _selectedStyle;
  String get selectedColor => _selectedColor;
  String get aspectRatio => _aspectRatio;
  List<AIGenerationHistory> get generationHistory => _generationHistory;
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

      // Generate image using AI service
      final result = await AIImageService.generateImage(
        prompt: finalPrompt,
        aspectRatio: _aspectRatio,
      );

      if (result.success) {
        _generatedImages = result.images;
        _error = null;

        // Save to generation history
        await _saveToHistory(finalPrompt, result.images.first);

        return true;
      } else {
        _error = result.error ?? 'Generation failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Enhance prompt using AI
  Future<String> enhancePrompt(String basePrompt) async {
    try {
      return await AIImageService.enhancePrompt(basePrompt);
    } catch (e) {
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
  Future<bool> saveToLibrary(AIGeneratedImage image) async {
    try {
      return await AIImageService.saveToLibrary(
        imageBytes: image.imageBytes,
        prompt: image.prompt,
        aspectRatio: image.aspectRatio,
        assetType: _selectedAssetType,
        metadata: {'style': _selectedStyle, 'color': _selectedColor},
      );
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

      _generationHistory = await AIImageService.getGenerationHistory();
    } catch (e) {
      _error = 'Failed to load history: $e';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Save to history (internal)
  Future<void> _saveToHistory(String prompt, AIGeneratedImage image) async {
    try {
      await AIImageService.saveToLibrary(
        imageBytes: image.imageBytes,
        prompt: prompt,
        aspectRatio: image.aspectRatio,
        assetType: _selectedAssetType,
        metadata: {
          'style': _selectedStyle,
          'color': _selectedColor,
          'generated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Don't fail generation if history save fails
      debugPrint('Failed to save to history: $e');
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
}
