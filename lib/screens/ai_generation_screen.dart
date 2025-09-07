import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/ai_generation_provider.dart';
import '../core/providers/user_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/widget_wrappers.dart';

/// AI Generation Screen
///
/// Multi-step image generation process:
/// 1. Asset Type Selection
/// 2. Style & Color Selection
/// 3. Prompt Input & Enhancement
/// 4. Image Generation & Display
class AIGenerationScreen extends StatefulWidget {
  const AIGenerationScreen({super.key});

  @override
  State<AIGenerationScreen> createState() => _AIGenerationScreenState();
}

class _AIGenerationScreenState extends State<AIGenerationScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _promptController = TextEditingController();

  // Generation steps
  int _currentStep = 0;
  String? _selectedAssetType;
  String? _selectedStyle;
  Color? _selectedColor;

  // Asset type options matching your screenshot
  final List<Map<String, dynamic>> _assetTypes = [
    {
      'id': 'character',
      'title': 'Character',
      'description': 'Create NPCs, heroes, and creatures',
      'icon': Icons.person,
    },
    {
      'id': 'environment',
      'title': 'Environment',
      'description': 'Build worlds and landscapes',
      'icon': Icons.landscape,
    },
    {
      'id': 'ui_element',
      'title': 'UI Element',
      'description': 'Design interface components',
      'icon': Icons.widgets,
    },
    {
      'id': 'icon',
      'title': 'Icon',
      'description': 'Craft symbols and indicators',
      'icon': Icons.category,
    },
    {
      'id': 'texture',
      'title': 'Texture',
      'description': 'Generate materials and patterns',
      'icon': Icons.texture,
    },
    {
      'id': 'logo',
      'title': 'Logo',
      'description': 'Design brand identities',
      'icon': Icons.star,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer2<AIGenerationProvider, UserProvider>(
          builder: (context, aiProvider, userProvider, child) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildAssetTypeSelection(),
                      _buildStyleSelection(),
                      _buildPromptInput(),
                      _buildGenerationResult(aiProvider),
                    ],
                  ),
                ),
                _buildBottomNavigation(aiProvider, userProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _goToPreviousStep,
              child: NeomorphicContainer(
                padding: EdgeInsets.all(AppDimensions.paddingMedium),
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryGold,
                  size: 24,
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    '⚡ Asset Studio',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return GemstoneCounter(count: userProvider.gemstoneCount);
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: _currentStep > 0 ? 48 : 0),
        ],
      ),
    );
  }

  Widget _buildAssetTypeSelection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(1, 'Choose Asset Type'),
            SizedBox(height: AppDimensions.spacingLarge),
            Text(
              'What type of asset would you like to create?',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppDimensions.spacingLarge),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: _assetTypes.length,
                itemBuilder: (context, index) {
                  final assetType = _assetTypes[index];
                  final isSelected = _selectedAssetType == assetType['id'];

                  return AssetTypeCard(
                    title: assetType['title'],
                    subtitle: assetType['description'],
                    icon: assetType['icon'],
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedAssetType = assetType['id'];
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleSelection() {
    final styles = ['Photographic', 'Artistic', 'Cartoon', 'Minimalist'];
    final colors = [
      AppColors.primaryGold,
      AppColors.accentDeepOrange,
      AppColors.accentTeal,
      AppColors.accentPurple,
      AppColors.accentPink,
      AppColors.accentBlue,
    ];

    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(2, 'Choose Style & Color'),
          SizedBox(height: AppDimensions.spacingLarge),

          // Style Selection
          Text(
            'Select a style:',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMedium),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: styles.map((style) {
              final isSelected = _selectedStyle == style;
              return GoldButton(
                text: style,
                onPressed: () {
                  setState(() {
                    _selectedStyle = style;
                  });
                },
                variant: isSelected
                    ? ButtonVariant.primary
                    : ButtonVariant.secondary,
              );
            }).toList(),
          ),

          SizedBox(height: AppDimensions.spacingLarge),

          // Color Selection
          Text(
            'Choose a dominant color:',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMedium),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: colors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(30),
                    border: isSelected
                        ? Border.all(color: AppColors.primaryGold, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 30)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptInput() {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(3, 'Describe Your Vision'),
          SizedBox(height: AppDimensions.spacingLarge),

          Text(
            'Describe what you want to create:',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMedium),

          NeomorphicTextField(
            controller: _promptController,
            hintText: 'e.g., A mystical warrior with golden armor...',
            maxLines: 4,
          ),

          SizedBox(height: AppDimensions.spacingMedium),

          // Suggestion button using Gemini
          GoldButton(
            text: '✨ Get AI Suggestions',
            onPressed: () => _getAISuggestions(),
            variant: ButtonVariant.secondary,
            icon: Icons.auto_awesome,
          ),

          SizedBox(height: AppDimensions.spacingLarge),

          // Show suggestions if available
          Consumer<AIGenerationProvider>(
            builder: (context, provider, child) {
              if (provider.suggestions.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggestions:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingSmall),
                    ...provider.suggestions.map((suggestion) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            _promptController.text = suggestion;
                          },
                          child: NeomorphicContainer(
                            padding: EdgeInsets.all(
                              AppDimensions.paddingMedium,
                            ),
                            child: Text(
                              suggestion,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationResult(AIGenerationProvider provider) {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          _buildStepIndicator(4, 'Your Asset is Ready!'),
          SizedBox(height: AppDimensions.spacingLarge),

          Expanded(
            child: provider.isGenerating
                ? _buildGeneratingState()
                : provider.generatedImage != null
                ? _buildGeneratedImageView(provider.generatedImage!)
                : _buildErrorState(provider.errorMessage),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
          SizedBox(height: AppDimensions.spacingLarge),
          Text(
            'Creating your masterpiece...',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryGold,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMedium),
          Text(
            'This may take 15-30 seconds',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedImageView(String imageBase64) {
    return Column(
      children: [
        Expanded(
          child: NeomorphicContainer(
            padding: EdgeInsets.all(AppDimensions.paddingSmall),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: Image.memory(
                base64Decode(imageBase64),
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spacingLarge),
        Row(
          children: [
            Expanded(
              child: GoldButton(
                text: '💾 Save to Library',
                onPressed: _saveToLibrary,
                variant: ButtonVariant.primary,
              ),
            ),
            SizedBox(width: AppDimensions.spacingMedium),
            Expanded(
              child: GoldButton(
                text: '🔄 Generate Another',
                onPressed: _generateAnother,
                variant: ButtonVariant.secondary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.spacingMedium),
        GoldButton(
          text: '🔄 Start Over',
          onPressed: _startOver,
          variant: ButtonVariant.outline,
        ),
      ],
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.accentDeepOrange,
          ),
          SizedBox(height: AppDimensions.spacingLarge),
          Text(
            'Image Preview Error',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.accentDeepOrange,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMedium),
          Text(
            errorMessage ??
                'Generated image could not be displayed.\nTry generating again.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppDimensions.spacingLarge),
          GoldButton(
            text: '🔄 Try Again',
            onPressed: _tryAgain,
            variant: ButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryGold,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: AppDimensions.spacingMedium),
        Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(
    AIGenerationProvider aiProvider,
    UserProvider userProvider,
  ) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusLarge),
          topRight: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      child: _currentStep < 3
          ? GoldButton(
              text: _getNextButtonText(),
              onPressed: _canProceed() ? _goToNextStep : null,
              variant: ButtonVariant.primary,
            )
          : _currentStep == 3 && !aiProvider.isGenerating
          ? GoldButton(
              text: '🎨 Generate',
              onPressed: () => _generateImage(aiProvider, userProvider),
              variant: ButtonVariant.primary,
            )
          : const SizedBox.shrink(),
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continue →';
      case 1:
        return 'Continue →';
      case 2:
        return 'Continue →';
      default:
        return 'Generate';
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedAssetType != null;
      case 1:
        return _selectedStyle != null && _selectedColor != null;
      case 2:
        return _promptController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _goToNextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _getAISuggestions() async {
    if (_selectedAssetType == null) return;

    final provider = Provider.of<AIGenerationProvider>(context, listen: false);
    await provider.generateSuggestions();
  }

  Future<void> _generateImage(
    AIGenerationProvider aiProvider,
    UserProvider userProvider,
  ) async {
    // Check gemstone count
    if (userProvider.gemstoneCount <= 0) {
      _showInsufficientGemstonesDialog();
      return;
    }

    // Build enhanced prompt
    final colorName = _getColorName(_selectedColor);
    final enhancedPrompt = _buildEnhancedPrompt(colorName);

    try {
      await aiProvider.generateImage(customPrompt: enhancedPrompt);

      if (aiProvider.generatedImage != null) {
        // Deduct gemstone
        userProvider.spendGemstones(1);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generation failed: $e'),
          backgroundColor: AppColors.accentDeepOrange,
        ),
      );
    }
  }

  String _buildEnhancedPrompt(String? colorName) {
    final prompt = _promptController.text.trim();
    final style = _selectedStyle?.toLowerCase() ?? 'photographic';
    final assetType = _selectedAssetType ?? 'character';

    String enhancedPrompt = prompt;

    if (colorName != null) {
      enhancedPrompt += ', with $colorName tones';
    }

    enhancedPrompt += ', $style style, high quality, detailed';

    // Add asset-specific enhancements
    switch (assetType) {
      case 'character':
        enhancedPrompt += ', character design, full body';
        break;
      case 'environment':
        enhancedPrompt += ', landscape, environment art';
        break;
      case 'ui_element':
        enhancedPrompt += ', UI design, clean interface';
        break;
      case 'icon':
        enhancedPrompt += ', icon design, simple, clear';
        break;
      case 'texture':
        enhancedPrompt += ', texture pattern, tileable';
        break;
      case 'logo':
        enhancedPrompt += ', logo design, professional';
        break;
    }

    return enhancedPrompt;
  }

  String? _getColorName(Color? color) {
    if (color == null) return null;

    if (color == AppColors.primaryGold) return 'golden';
    if (color == AppColors.accentDeepOrange) return 'orange';
    if (color == AppColors.accentTeal) return 'teal';
    if (color == AppColors.accentPurple) return 'purple';
    if (color == AppColors.accentPink) return 'pink';
    if (color == AppColors.accentBlue) return 'blue';

    return null;
  }

  void _showInsufficientGemstonesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Gemstones'),
        content: const Text(
          'You need at least 1 gemstone to generate an image. Visit the store to get more!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to store screen
              // Navigator.pushNamed(context, '/store');
            },
            child: const Text('Get Gemstones'),
          ),
        ],
      ),
    );
  }

  void _saveToLibrary() {
    final provider = Provider.of<AIGenerationProvider>(context, listen: false);
    if (provider.generatedImage != null) {
      provider.saveToLibrary(provider.generatedImage!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Saved to your library!'),
          backgroundColor: AppColors.primaryGold,
        ),
      );
    }
  }

  void _generateAnother() {
    setState(() {
      _currentStep = 2; // Go back to prompt input
    });
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _startOver() {
    setState(() {
      _currentStep = 0;
      _selectedAssetType = null;
      _selectedStyle = null;
      _selectedColor = null;
      _promptController.clear();
    });

    final provider = Provider.of<AIGenerationProvider>(context, listen: false);
    provider.clearGeneration();

    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _tryAgain() {
    final provider = Provider.of<AIGenerationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _generateImage(provider, userProvider);
  }
}
