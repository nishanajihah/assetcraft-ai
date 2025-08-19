import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/utils/app_logger.dart';

part 'generation_state_providers.g.dart';

/// State provider to track the selected asset category (e.g., "Logo", "Icon")
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String? build() => null;

  void setCategory(String? category) {
    AppLogger.debug('Setting selected category: $category');
    state = category;
  }

  void clearCategory() {
    state = null;
  }
}

/// State provider to track the selected logo type (e.g., "Logo only", "Logo + Name")
@riverpod
class SelectedLogoType extends _$SelectedLogoType {
  @override
  String? build() => null;

  void setLogoType(String? logoType) {
    AppLogger.debug('Setting selected logo type: $logoType');
    state = logoType;
  }

  void clearLogoType() {
    state = null;
  }
}

/// State provider to track the number of colors selected for a logo
@riverpod
class SelectedColorCount extends _$SelectedColorCount {
  @override
  int? build() => null;

  void setColorCount(int? colorCount) {
    AppLogger.debug('Setting selected color count: $colorCount');
    state = colorCount;
  }

  void clearColorCount() {
    state = null;
  }
}

/// Future provider that fetches creative prompt suggestions from the Gemini API
/// This provider depends on the selected category and will reload when it changes
@riverpod
Future<List<String>> suggestions(SuggestionsRef ref) async {
  final selectedCategory = ref.watch(selectedCategoryProvider);

  // If no category is selected, return empty list
  if (selectedCategory == null || selectedCategory.isEmpty) {
    AppLogger.debug('No category selected, returning empty suggestions');
    return [];
  }

  AppLogger.debug('Fetching suggestions for category: $selectedCategory');

  try {
    final aiService = ref.read(aiServiceProvider);
    final suggestions = await aiService.getPromptSuggestions(selectedCategory);

    AppLogger.debug(
      'Received ${suggestions.length} suggestions for $selectedCategory',
    );
    return suggestions;
  } catch (e) {
    AppLogger.error('Failed to fetch suggestions: $e');
    // Return some default suggestions as fallback
    return _getDefaultSuggestions(selectedCategory);
  }
}

/// Future provider that fetches expert-level prompt suggestions from the Gemini API
/// This uses the new getSuggestions method for more concise, professional suggestions
@riverpod
Future<List<String>> expertSuggestions(ExpertSuggestionsRef ref) async {
  final selectedCategory = ref.watch(selectedCategoryProvider);

  // If no category is selected, return empty list
  if (selectedCategory == null || selectedCategory.isEmpty) {
    AppLogger.debug('No category selected, returning empty expert suggestions');
    return [];
  }

  AppLogger.debug(
    'Fetching expert suggestions for category: $selectedCategory',
  );

  try {
    final aiService = ref.read(aiServiceProvider);
    final suggestions = await aiService.getSuggestions(selectedCategory);

    AppLogger.debug(
      'Received ${suggestions.length} expert suggestions for $selectedCategory',
    );
    return suggestions;
  } catch (e) {
    AppLogger.error('Failed to fetch expert suggestions: $e');
    // Return some default suggestions as fallback
    return _getDefaultSuggestions(selectedCategory).take(3).toList();
  }
}

/// Helper function to provide default suggestions when API fails
List<String> _getDefaultSuggestions(String category) {
  switch (category.toLowerCase()) {
    case 'logo':
      return [
        'A modern minimalist logo with clean lines',
        'A vintage-inspired logo with elegant typography',
        'A tech startup logo with geometric shapes',
        'A creative agency logo with artistic elements',
        'A professional corporate logo design',
      ];
    case 'icon':
      return [
        'A simple flat icon with bold colors',
        'A detailed icon with realistic shadows',
        'A minimalist line art icon',
        'A 3D-style icon with depth and lighting',
        'A colorful gradient icon design',
      ];
    case 'character':
      return [
        'A friendly cartoon character with big eyes',
        'A heroic fantasy warrior with armor',
        'A cute animal mascot character',
        'A futuristic robot with glowing details',
        'A magical wizard with flowing robes',
      ];
    case 'environment':
      return [
        'A peaceful forest clearing with sunbeams',
        'A bustling cyberpunk city at night',
        'A magical floating castle in clouds',
        'A serene mountain landscape at sunset',
        'An underwater coral reef scene',
      ];
    case 'ui element':
      return [
        'A sleek modern button with gradient',
        'A glass-morphism card design',
        'A futuristic navigation menu',
        'A clean dashboard widget',
        'An animated loading spinner',
      ];
    case 'texture':
      return [
        'A realistic wood grain texture',
        'A metallic brushed steel surface',
        'A soft fabric weave pattern',
        'A rough stone wall texture',
        'An abstract geometric pattern',
      ];
    case 'background':
      return [
        'A soft gradient background',
        'A starry night sky background',
        'An abstract geometric pattern',
        'A watercolor wash background',
        'A subtle noise texture background',
      ];
    case 'object':
      return [
        'A magical sword with glowing runes',
        'A vintage pocket watch',
        'A futuristic spaceship',
        'A cozy reading chair',
        'A steampunk mechanical device',
      ];
    default:
      return [
        'A creative and unique design',
        'An artistic and beautiful creation',
        'A professional and polished asset',
        'An innovative and modern design',
        'A detailed and high-quality artwork',
      ];
  }
}

/// Convenience provider to get the current generation state summary
@riverpod
Map<String, dynamic> generationStateSummary(GenerationStateSummaryRef ref) {
  final category = ref.watch(selectedCategoryProvider);
  final logoType = ref.watch(selectedLogoTypeProvider);
  final colorCount = ref.watch(selectedColorCountProvider);

  return {
    'category': category,
    'logoType': logoType,
    'colorCount': colorCount,
    'hasCategory': category != null && category.isNotEmpty,
    'hasLogoType': logoType != null && logoType.isNotEmpty,
    'hasColorCount': colorCount != null,
  };
}

/// Helper provider to check if all required selections are made for the current category
@riverpod
bool isGenerationReady(IsGenerationReadyRef ref) {
  final category = ref.watch(selectedCategoryProvider);
  final logoType = ref.watch(selectedLogoTypeProvider);
  final colorCount = ref.watch(selectedColorCountProvider);

  // No category selected
  if (category == null || category.isEmpty) {
    return false;
  }

  // For logo category, we need both logo type and color count
  if (category.toLowerCase() == 'logo') {
    return logoType != null && logoType.isNotEmpty && colorCount != null;
  }

  // For other categories, just having a category is enough
  return true;
}

/// Provider to reset all generation state
@riverpod
class GenerationStateManager extends _$GenerationStateManager {
  @override
  void build() {}

  void resetAllState() {
    AppLogger.debug('Resetting all generation state');
    ref.invalidate(selectedCategoryProvider);
    ref.invalidate(selectedLogoTypeProvider);
    ref.invalidate(selectedColorCountProvider);
  }

  void resetFromCategory() {
    AppLogger.debug('Resetting state from category level');
    ref.read(selectedLogoTypeProvider.notifier).clearLogoType();
    ref.read(selectedColorCountProvider.notifier).clearColorCount();
  }

  void resetFromLogoType() {
    AppLogger.debug('Resetting state from logo type level');
    ref.read(selectedColorCountProvider.notifier).clearColorCount();
  }
}
