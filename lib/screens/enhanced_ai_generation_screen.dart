import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/services/ai_image_service.dart';
import '../core/utils/logger.dart';
import '../usable/widgets/containers/enhanced_containers.dart';
import '../usable/widgets/buttons/enhanced_buttons.dart';
import '../usable/widgets/inputs/enhanced_inputs.dart';

/// Enhanced AI Generation Screen with premium neomorphic design
class EnhancedAIGenerationScreen extends StatefulWidget {
  const EnhancedAIGenerationScreen({super.key});

  @override
  State<EnhancedAIGenerationScreen> createState() =>
      _EnhancedAIGenerationScreenState();
}

class _EnhancedAIGenerationScreenState extends State<EnhancedAIGenerationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final PageController _pageController = PageController();

  // Generation state
  int _currentStep = 0;
  bool _isGenerating = false;
  String? _selectedAssetType;
  String? _selectedStyle;
  String _aspectRatio = "1:1";
  List<AIGeneratedImage> _generatedImages = [];
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Asset types with enhanced styling
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

  // Art styles
  final List<String> _artStyles = [
    'Realistic',
    'Cartoon',
    'Anime',
    'Pixel Art',
    'Watercolor',
    'Oil Painting',
    'Digital Art',
    'Minimalist',
  ];

  // Aspect ratios
  final List<String> _aspectRatios = ['1:1', '16:9', '9:16', '4:3', '3:4'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    AppLogger.info(
      'AI Generation Screen initialized',
      tag: 'AIGenerationScreen',
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 768;
              final isMobile = constraints.maxWidth <= 480;

              return _buildResponsiveLayout(context, isTablet, isMobile);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    bool isTablet,
    bool isMobile,
  ) {
    if (isTablet) {
      // Tablet/Desktop layout - side by side
      return Row(
        children: [
          // Left panel - Configuration
          Expanded(flex: 2, child: _buildConfigurationPanel(context, isTablet)),
          // Right panel - Preview/Results
          Expanded(flex: 3, child: _buildPreviewPanel(context, isTablet)),
        ],
      );
    } else {
      // Mobile layout - stepper
      return _buildMobileLayout(context, isMobile);
    }
  }

  Widget _buildMobileLayout(BuildContext context, bool isMobile) {
    return Column(
      children: [
        // Header with progress
        _buildHeader(context, isMobile),
        // Content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            children: [
              _buildAssetTypeSelection(context, isMobile),
              _buildStyleSelection(context, isMobile),
              _buildPromptInput(context, isMobile),
              _buildResults(context, isMobile),
            ],
          ),
        ),
        // Navigation buttons
        _buildNavigationButtons(context, isMobile),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return EnhancedGlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'AI Asset Generator',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index <= _currentStep;

        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.symmetric(
              horizontal: index == 0 || index == 3 ? 0 : 4,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryGold : AppColors.neuShadowDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAssetTypeSelection(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of asset would you like to create?',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: _assetTypes.length,
            itemBuilder: (context, index) {
              final assetType = _assetTypes[index];
              final isSelected = _selectedAssetType == assetType['id'];

              return EnhancedGlassContainer(
                hasGoldTint: isSelected,
                hasGlow: isSelected,
                onTap: () {
                  setState(() {
                    _selectedAssetType = assetType['id'];
                  });
                },
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      assetType['icon'],
                      size: 40,
                      color: isSelected
                          ? AppColors.primaryGold
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      assetType['title'],
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryGold
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assetType['description'],
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSelection(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose your art style', style: AppTextStyles.headingSmall),
          const SizedBox(height: 24),
          // Art styles
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _artStyles.map((style) {
              final isSelected = _selectedStyle == style;
              return EnhancedGlassContainer(
                hasGoldTint: isSelected,
                onTap: () {
                  setState(() {
                    _selectedStyle = style;
                  });
                },
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  style,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.primaryGold
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Aspect ratio
          Text(
            'Aspect Ratio',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          EnhancedDropdown<String>(
            value: _aspectRatio,
            items: _aspectRatios.map((ratio) {
              return DropdownMenuItem(value: ratio, child: Text(ratio));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _aspectRatio = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromptInput(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Describe your vision', style: AppTextStyles.headingSmall),
          const SizedBox(height: 24),
          EnhancedTextField(
            controller: _promptController,
            labelText: 'Prompt',
            hintText: 'Describe what you want to create...',
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            EnhancedGlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generated Images', style: AppTextStyles.headingSmall),
          const SizedBox(height: 24),
          if (_generatedImages.isEmpty && !_isGenerating) _buildEmptyState(),
          if (_isGenerating) _buildLoadingState(),
          if (_generatedImages.isNotEmpty) _buildImageGrid(isMobile),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EnhancedGlassContainer(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.image, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No images generated yet',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return EnhancedGlassContainer(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
          const SizedBox(height: 16),
          Text('Generating your image...', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _generatedImages.length,
      itemBuilder: (context, index) {
        final image = _generatedImages[index];
        return _buildImageCard(image);
      },
    );
  }

  Widget _buildImageCard(AIGeneratedImage image) {
    return EnhancedGlassContainer(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                image.imageBytes,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: EnhancedGoldenButton(
                  text: 'Save',
                  icon: Icons.download,
                  isSecondary: true,
                  onPressed: () => _saveImage(image),
                ),
              ),
              const SizedBox(width: 8),
              EnhancedIconButton(
                icon: Icons.share,
                onPressed: () => _shareImage(image),
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, bool isMobile) {
    return EnhancedGlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: EnhancedGoldenButton(
                text: 'Back',
                isSecondary: true,
                onPressed: _goBack,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: EnhancedGoldenButton(
              text: _getNextButtonText(),
              isLoading: _isGenerating,
              onPressed: _canProceed() ? _goNext : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationPanel(BuildContext context, bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssetTypeSelection(context, false),
          const SizedBox(height: 32),
          _buildStyleSelection(context, false),
          const SizedBox(height: 32),
          _buildPromptInput(context, false),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: EnhancedGoldenButton(
              text: 'Generate Image',
              isLoading: _isGenerating,
              onPressed: _canGenerate() ? _generateImage : null,
              height: 56,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(BuildContext context, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: _buildResults(context, false),
    );
  }

  // Navigation methods
  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goNext() {
    if (_currentStep < 3) {
      if (_currentStep == 2) {
        // Generate image
        _generateImage();
      } else {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continue';
      case 1:
        return 'Continue';
      case 2:
        return 'Generate';
      case 3:
        return 'Generate Again';
      default:
        return 'Continue';
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedAssetType != null;
      case 1:
        return _selectedStyle != null;
      case 2:
        return _promptController.text.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  bool _canGenerate() {
    return _selectedAssetType != null &&
        _selectedStyle != null &&
        _promptController.text.isNotEmpty &&
        !_isGenerating;
  }

  // Image generation
  Future<void> _generateImage() async {
    if (!_canGenerate()) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    AppLogger.info('Starting image generation', tag: 'AIGenerationScreen');

    try {
      final enhancedPrompt = _buildEnhancedPrompt();

      final result = await AIImageService.generateImage(
        prompt: enhancedPrompt,
        aspectRatio: _aspectRatio,
      );

      if (result.success) {
        setState(() {
          _generatedImages = result.images;
          _currentStep = 3;
        });

        if (mounted) {
          _pageController.animateToPage(
            3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Failed to generate image';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _buildEnhancedPrompt() {
    final parts = <String>[];

    if (_selectedAssetType != null) {
      parts.add(_selectedAssetType!);
    }

    parts.add(_promptController.text);

    if (_selectedStyle != null) {
      parts.add('in ${_selectedStyle!.toLowerCase()} style');
    }

    parts.add('high quality, detailed');

    return parts.join(', ');
  }

  // Image actions
  void _saveImage(AIGeneratedImage image) {
    AppLogger.info('Saving image', tag: 'AIGenerationScreen');
    // TODO: Implement image saving
  }

  void _shareImage(AIGeneratedImage image) {
    AppLogger.info('Sharing image', tag: 'AIGenerationScreen');
    // TODO: Implement image sharing
  }
}
