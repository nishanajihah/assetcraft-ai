import 'package:flutter/foundation.dart';
import '../database/database_service.dart';
import '../database/models/generation_model.dart';
import '../utils/app_logger.dart';

/// Global AI generation state provider
class GenerationProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<GenerationModel> _generations = [];
  GenerationModel? _currentGeneration;
  bool _isGenerating = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GenerationModel> get generations => _generations;
  List<GenerationModel> get recentGenerations => _getRecentGenerations();
  GenerationModel? get currentGeneration => _currentGeneration;
  bool get isGenerating => _isGenerating;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get generationsCount => _generations.length;
  int get completedGenerationsCount =>
      _generations.where((g) => g.isCompleted).length;
  int get failedGenerationsCount =>
      _generations.where((g) => g.isFailed).length;

  /// Initialize generation provider
  Future<void> initialize(String userId) async {
    _setLoading(true);
    try {
      await _loadUserGenerations(userId);
      AppLogger.info(
        '🤖 Generation provider initialized: ${_generations.length} generations',
      );
    } catch (e, stackTrace) {
      _setError('Failed to initialize generations: $e');
      AppLogger.error(
        '❌ Failed to initialize generation provider',
        e,
        stackTrace,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Load user generations from database
  Future<void> _loadUserGenerations(String userId) async {
    _generations = _databaseService.getUserGenerations(userId);
    // Sort by creation date (newest first)
    _generations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _clearError();
    notifyListeners();
  }

  /// Refresh generations
  Future<void> refreshGenerations(String userId) async {
    await _loadUserGenerations(userId);
    AppLogger.info(
      '🔄 Generations refreshed: ${_generations.length} generations',
    );
  }

  /// Start new generation
  Future<void> startGeneration(GenerationModel generation) async {
    try {
      _currentGeneration = generation;
      _isGenerating = true;
      await _databaseService.saveGeneration(generation);
      _generations.insert(0, generation); // Add to beginning
      _clearError();
      notifyListeners();
      AppLogger.info('🤖 Generation started: ${generation.prompt}');
    } catch (e, stackTrace) {
      _setError('Failed to start generation: $e');
      AppLogger.error('❌ Failed to start generation', e, stackTrace);
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Update generation status
  Future<void> updateGeneration(GenerationModel updatedGeneration) async {
    try {
      await _databaseService.saveGeneration(updatedGeneration);

      final index = _generations.indexWhere(
        (g) => g.id == updatedGeneration.id,
      );
      if (index != -1) {
        _generations[index] = updatedGeneration;
      }

      if (_currentGeneration?.id == updatedGeneration.id) {
        _currentGeneration = updatedGeneration;

        // Stop generating flag if generation is complete/failed/cancelled
        if (!updatedGeneration.isInProgress) {
          _isGenerating = false;
        }
      }

      _clearError();
      notifyListeners();
      AppLogger.info(
        '🤖 Generation updated: ${updatedGeneration.id} - ${updatedGeneration.status.name}',
      );
    } catch (e, stackTrace) {
      _setError('Failed to update generation: $e');
      AppLogger.error('❌ Failed to update generation', e, stackTrace);
    }
  }

  /// Complete generation with results
  Future<void> completeGeneration(
    String generationId,
    List<String> assetIds, {
    Duration? processingTime,
  }) async {
    try {
      final generation = _generations.firstWhere((g) => g.id == generationId);
      final updatedGeneration = generation.copyWith(
        status: GenerationStatus.completed,
        generatedAssetIds: assetIds,
        updatedAt: DateTime.now(),
        processingTime: processingTime,
      );

      await updateGeneration(updatedGeneration);
      AppLogger.info(
        '✅ Generation completed: $generationId with ${assetIds.length} assets',
      );
    } catch (e, stackTrace) {
      _setError('Failed to complete generation: $e');
      AppLogger.error('❌ Failed to complete generation', e, stackTrace);
    }
  }

  /// Fail generation with error
  Future<void> failGeneration(String generationId, String errorMessage) async {
    try {
      final generation = _generations.firstWhere((g) => g.id == generationId);
      final updatedGeneration = generation.copyWith(
        status: GenerationStatus.failed,
        errorMessage: errorMessage,
        updatedAt: DateTime.now(),
      );

      await updateGeneration(updatedGeneration);
      AppLogger.warning('❌ Generation failed: $generationId - $errorMessage');
    } catch (e, stackTrace) {
      _setError('Failed to fail generation: $e');
      AppLogger.error('❌ Failed to fail generation', e, stackTrace);
    }
  }

  /// Cancel generation
  Future<void> cancelGeneration(String generationId) async {
    try {
      final generation = _generations.firstWhere((g) => g.id == generationId);
      final updatedGeneration = generation.copyWith(
        status: GenerationStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      await updateGeneration(updatedGeneration);
      AppLogger.info('🛑 Generation cancelled: $generationId');
    } catch (e, stackTrace) {
      _setError('Failed to cancel generation: $e');
      AppLogger.error('❌ Failed to cancel generation', e, stackTrace);
    }
  }

  /// Retry failed generation
  Future<void> retryGeneration(String generationId) async {
    try {
      final generation = _generations.firstWhere((g) => g.id == generationId);
      final updatedGeneration = generation.copyWith(
        status: GenerationStatus.pending,
        attempts: generation.attempts + 1,
        errorMessage: null,
        updatedAt: DateTime.now(),
      );

      await updateGeneration(updatedGeneration);
      AppLogger.info(
        '🔄 Generation retry: $generationId (attempt ${updatedGeneration.attempts})',
      );
    } catch (e, stackTrace) {
      _setError('Failed to retry generation: $e');
      AppLogger.error('❌ Failed to retry generation', e, stackTrace);
    }
  }

  /// Delete generation
  Future<void> deleteGeneration(String generationId) async {
    try {
      await _databaseService.deleteGeneration(generationId);
      _generations.removeWhere((g) => g.id == generationId);

      if (_currentGeneration?.id == generationId) {
        _currentGeneration = null;
        _isGenerating = false;
      }

      _clearError();
      notifyListeners();
      AppLogger.info('🗑️ Generation deleted: $generationId');
    } catch (e, stackTrace) {
      _setError('Failed to delete generation: $e');
      AppLogger.error('❌ Failed to delete generation', e, stackTrace);
    }
  }

  /// Get generation by ID
  GenerationModel? getGenerationById(String generationId) {
    try {
      return _generations.firstWhere((g) => g.id == generationId);
    } catch (e) {
      return null;
    }
  }

  /// Get generations by status
  List<GenerationModel> getGenerationsByStatus(GenerationStatus status) {
    return _generations.where((g) => g.status == status).toList();
  }

  /// Get recent generations
  List<GenerationModel> _getRecentGenerations({int limit = 10}) {
    return _generations.take(limit).toList();
  }

  /// Get generation statistics
  Map<String, int> getGenerationStats() {
    return {
      'total': _generations.length,
      'completed': _generations.where((g) => g.isCompleted).length,
      'failed': _generations.where((g) => g.isFailed).length,
      'pending': _generations
          .where((g) => g.status == GenerationStatus.pending)
          .length,
      'generating': _generations
          .where((g) => g.status == GenerationStatus.generating)
          .length,
      'cancelled': _generations.where((g) => g.isCancelled).length,
    };
  }

  /// Clear current generation
  void clearCurrentGeneration() {
    _currentGeneration = null;
    _isGenerating = false;
    notifyListeners();
    AppLogger.info('🤖 Current generation cleared');
  }

  /// Clear all generations
  Future<void> clearGenerations() async {
    _generations.clear();
    _currentGeneration = null;
    _isGenerating = false;
    _clearError();
    notifyListeners();
    AppLogger.info('🗑️ All generations cleared from provider');
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
