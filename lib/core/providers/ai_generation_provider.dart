import 'package:flutter/foundation.dart';
import '../../services/image_generation_service.dart';
import '../../services/gemini_service.dart';
import '../../services/supabase_storage_service.dart';
import '../../services/supabase_data_service.dart';
import '../../services/cost_monitoring_service.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';

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

  // SAFETY: Prevent retry loops and excessive costs
  int _consecutiveFailures = 0;
  DateTime? _lastFailureTime;
  static const int _maxConsecutiveFailures = 3;
  static const int _failureCooldownMinutes = 5;

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

  // Configuration getters
  String get currentImagenModel => AppConfig.imagenModel;
  bool get hasVertexAiCredentials => AppConfig.hasVertexAiCredentials;

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
      // SAFETY CHECK 1: Check for consecutive failures and cooldown
      if (_consecutiveFailures >= _maxConsecutiveFailures &&
          _lastFailureTime != null) {
        final timeSinceLastFailure = DateTime.now().difference(
          _lastFailureTime!,
        );
        if (timeSinceLastFailure.inMinutes < _failureCooldownMinutes) {
          _error =
              'Too many consecutive failures. Please wait ${_failureCooldownMinutes - timeSinceLastFailure.inMinutes} more minutes before trying again.';
          AppLogger.warning(
            'Generation blocked due to consecutive failures',
            tag: 'AIGenerationProvider',
          );
          notifyListeners();
          return false;
        } else {
          // Reset after cooldown
          _consecutiveFailures = 0;
          _lastFailureTime = null;
        }
      }

      _isGenerating = true;
      _error = null;
      _generatedImages.clear();
      notifyListeners();

      // Build prompt with current parameters
      String finalPrompt = customPrompt ?? _buildEnhancedPrompt();
      _currentPrompt = finalPrompt;

      // SAFETY CHECK 2: Validate prompt
      if (finalPrompt.trim().isEmpty) {
        _error = 'Please provide a valid prompt for image generation';
        _isGenerating = false;
        notifyListeners();
        return false;
      }

      // SAFETY CHECK 3: Check cost limits
      const estimatedCost = 0.10; // Estimate RM0.10 per image generation
      if (!await CostMonitoringService.canMakeRequest(
        'vertex_ai_generation',
        estimatedCostRM: estimatedCost,
      )) {
        _error =
            'Daily cost limit reached. Image generation is temporarily disabled to prevent excessive charges.';
        _isGenerating = false;
        notifyListeners();
        return false;
      }

      // Generate image using Vertex AI through Supabase Edge Function
      final result = await ImageGenerationService.generateImageWithVertexAI(
        prompt: finalPrompt,
      );

      // Track the cost
      await CostMonitoringService.trackCost(
        'vertex_ai_generation',
        estimatedCost,
      );

      if (result != null && result['success'] == true) {
        // Image data is already extracted and formatted by the service
        if (result['imageBase64'] != null) {
          _generatedImages = [result['imageBase64']];
          _error = null;

          // SAFETY: Reset failure count on success
          _consecutiveFailures = 0;
          _lastFailureTime = null;

          // Save to generation history
          await _saveToHistory(finalPrompt, _generatedImages.first);
          return true;
        }

        _error = 'Invalid image data received from service';
        _recordFailure();
        return false;
      } else {
        _error = result?['error'] ?? 'Generation failed';
        _recordFailure();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _recordFailure();
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

  /// Record a failure to prevent retry loops
  void _recordFailure() {
    _consecutiveFailures++;
    _lastFailureTime = DateTime.now();

    AppLogger.warning(
      'Generation failure recorded. Count: $_consecutiveFailures',
      tag: 'AIGenerationProvider',
    );

    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      AppLogger.error(
        'Maximum consecutive failures reached. Entering cooldown period.',
        tag: 'AIGenerationProvider',
      );
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

  /// Save image to user library with proper Supabase integration
  Future<bool> saveToLibrary(String imageBase64, {String? userId}) async {
    try {
      if (userId == null) {
        AppLogger.error(
          'User ID required to save to library',
          tag: 'AIGenerationProvider',
        );
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }

      AppLogger.info(
        'Saving generated image to user library',
        tag: 'AIGenerationProvider',
      );

      // 1. Upload image to Supabase Storage
      final imageUrl = await SupabaseStorageService.uploadImage(
        imageBase64: imageBase64,
        userId: userId,
        assetType: _selectedAssetType,
      );

      if (imageUrl == null) {
        _error = 'Failed to upload image to storage';
        notifyListeners();
        return false;
      }

      // 2. Save asset metadata to database
      final assetId = await SupabaseDataService.saveAsset(
        userId: userId,
        prompt: _currentPrompt,
        imagePath: imageUrl, // Using imagePath parameter name from new schema
        assetType: _selectedAssetType, // Optional parameter
        style: _selectedStyle, // Optional parameter
      );

      if (assetId == null) {
        _error = 'Failed to save asset to database';
        notifyListeners();
        return false;
      }

      AppLogger.success(
        'Image saved to library successfully: $assetId',
        tag: 'AIGenerationProvider',
      );
      return true;
    } catch (e, stackTrace) {
      _error = 'Failed to save image: $e';
      AppLogger.error(
        'Failed to save image to library: $e',
        tag: 'AIGenerationProvider',
        error: e,
        stackTrace: stackTrace,
      );
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
      // SAFETY CHECK: Validate inputs before making API call
      if (_selectedAssetType.trim().isEmpty) {
        AppLogger.warning(
          'No asset type selected, using fallback suggestions',
          tag: 'AIGenerationProvider',
        );
        _suggestions = getPromptSuggestions();
        notifyListeners();
        return;
      }

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
      // SAFETY: Always fallback to manual suggestions on error
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

  /// Get current AI configuration for debugging
  Map<String, dynamic> getConfigInfo() {
    return {
      'imagenModel': currentImagenModel,
      'hasVertexAiCredentials': hasVertexAiCredentials,
      'environment': AppConfig.environment,
      'isProduction': AppConfig.isProduction,
    };
  }

  /// Print configuration summary
  void printConfigInfo() {
    final config = getConfigInfo();
    AppLogger.info('🤖 AI Configuration:', tag: 'AIGenerationProvider');
    AppLogger.info(
      '   Imagen Model: ${config['imagenModel']}',
      tag: 'AIGenerationProvider',
    );
    AppLogger.info(
      '   Has Credentials: ${config['hasVertexAiCredentials']}',
      tag: 'AIGenerationProvider',
    );
    AppLogger.info(
      '   Environment: ${config['environment']}',
      tag: 'AIGenerationProvider',
    );
  }
}
