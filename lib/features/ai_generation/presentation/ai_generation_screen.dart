import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'dart:math';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/credits_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/neu_container.dart';
import '../../../shared/widgets/enhanced_containers.dart';

/// Generation steps for progressive UI flow
enum GenerationStep {
  assetTypeSelection,
  assetSubtypeSelection,
  colorInput, // New step for color selection
  promptInput,
  generating,
  preview,
}

class AIGenerationScreen extends ConsumerStatefulWidget {
  const AIGenerationScreen({super.key});

  @override
  ConsumerState<AIGenerationScreen> createState() => _AIGenerationScreenState();
}

class _AIGenerationScreenState extends ConsumerState<AIGenerationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocusNode = FocusNode();

  // Progressive UI state
  GenerationStep _currentStep = GenerationStep.assetTypeSelection;
  String _selectedAssetType = '';
  String _selectedAssetSubtype = '';
  int? _selectedColorCount;
  List<String> _selectedColors = []; // Track user-input colors
  List<String> _availableSubtypes = [];
  bool _isGenerating = false;
  Uint8List? _generatedImageData;
  String? _error;
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Listen to prompt changes to clear errors
    _promptController.addListener(() {
      if (_error != null) {
        setState(() {
          _error = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _promptFocusNode.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _generateAsset() async {
    if (_promptController.text.trim().isEmpty) {
      _showError('Please enter a description for your asset');
      return;
    }

    final creditsNotifier = ref.read(userCreditsNotifierProvider.notifier);

    // Check if user has enough credits
    if (!creditsNotifier.deductCredits(1)) {
      _showError(
        'Insufficient credits. You need 1 Gemstone to generate an asset.',
      );
      return;
    }

    setState(() {
      _currentStep = GenerationStep.generating;
      _isGenerating = true;
      _error = null;
      _generatedImageData = null;
    });

    _loadingController.repeat();

    try {
      final aiService = ref.read(aiServiceProvider);
      final prompt = '$_selectedAssetType: ${_promptController.text.trim()}';

      final imageData = await aiService.generateAssetFromPrompt(prompt);

      if (imageData != null) {
        setState(() {
          _generatedImageData = imageData;
          _currentStep = GenerationStep.preview;
          _isGenerating = false;
        });
        _showSuccess('Asset generated successfully!');
      } else {
        setState(() {
          _error = 'Failed to generate asset. Please try again.';
          _currentStep = GenerationStep.promptInput;
          _isGenerating = false;
        });
        // Refund credits on failure
        creditsNotifier.addCredits(1);
      }
    } catch (e) {
      setState(() {
        _error = 'Error generating asset: ${e.toString()}';
        _currentStep = GenerationStep.promptInput;
        _isGenerating = false;
      });
      // Refund credits on error
      creditsNotifier.addCredits(1);
    } finally {
      _loadingController.stop();
    }
  }

  void _onAssetTypeSelected(String assetType) {
    setState(() {
      _selectedAssetType = assetType;
      _availableSubtypes = _getAssetSubtypes(assetType);
      _currentStep = GenerationStep.assetSubtypeSelection;
      _selectedAssetSubtype = '';
      _selectedColorCount = null;
    });
  }

  void _onAssetSubtypeSelected(String subtype) {
    AppLogger.debug('Selected subtype: "$subtype"');
    AppLogger.debug('Selected asset type: "$_selectedAssetType"');

    setState(() {
      _selectedAssetSubtype = subtype;

      // Check if this asset type/subtype needs color input
      if (_needsColorInput(_selectedAssetType, subtype)) {
        AppLogger.debug(
          'Going to color count selection for $_selectedAssetType - $subtype',
        );
        // Stay on subtype selection to show color selection
      } else {
        AppLogger.debug('Skipping color input, going directly to prompt input');
        _currentStep = GenerationStep.promptInput;
      }
    });
  }

  String _getColorInputTitle() {
    switch (_selectedAssetType) {
      case 'Logo':
        return 'What colors would you like for your ${_selectedAssetSubtype.toLowerCase()}?';
      case 'Character':
        return 'What colors should your ${_selectedAssetSubtype.toLowerCase()} have?';
      case 'UI Element':
        return 'What colors would you like for your ${_selectedAssetSubtype.toLowerCase()}?';
      case 'Icon':
        return 'What colors should your ${_selectedAssetSubtype.toLowerCase()} icon use?';
      case 'Background':
        return 'What colors would you like for your ${_selectedAssetSubtype.toLowerCase()} background?';
      case 'Object':
        return 'What colors should your ${_selectedAssetSubtype.toLowerCase()} have?';
      default:
        return 'What colors would you like for your ${_selectedAssetSubtype.toLowerCase()}?';
    }
  }

  // Helper method to determine which asset types need color input
  bool _needsColorInput(String assetType, String subtype) {
    switch (assetType) {
      case 'Logo':
        return true; // All logo types can benefit from color specification
      case 'Character':
        return true; // Characters need color schemes
      case 'UI Element':
        return true; // UI elements need color themes
      case 'Icon':
        return true; // Icons often need specific colors
      case 'Background':
        return true; // Backgrounds are all about colors
      case 'Object':
        return true; // Objects can have specific colors
      case 'Environment':
        return false; // Environments are more about mood/lighting than specific colors
      case 'Texture':
        return false; // Textures are more about patterns than specific colors
      default:
        return false;
    }
  }

  void _onColorCountSelected(int colorCount) {
    setState(() {
      _selectedColorCount = colorCount;
      _selectedColors = List.filled(colorCount, ''); // Initialize color slots
      _currentStep = GenerationStep.colorInput; // Go to color input step
    });
  }

  void _goBackToAssetTypeSelection() {
    setState(() {
      _currentStep = GenerationStep.assetTypeSelection;
      _selectedAssetType = '';
      _selectedAssetSubtype = '';
      _selectedColorCount = null;
      _availableSubtypes = [];
    });
  }

  void _goBackToAssetSubtypeSelection() {
    setState(() {
      _currentStep = GenerationStep.assetSubtypeSelection;
      _selectedAssetSubtype = '';
      _selectedColorCount = null;
    });
  }

  void _goBackToPromptInput() {
    setState(() {
      _currentStep = GenerationStep.promptInput;
      _generatedImageData = null;
      _error = null;
    });
  }

  void _saveToLibrary() {
    // TODO: Implement save to asset library
    _showSuccess('Asset saved to library!');
  }

  void _showError(String message) {
    setState(() {
      _error = message;
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCredits = ref.watch(totalAvailableCreditsProvider);
    final isAiAvailable = ref.watch(isAiServiceAvailableProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              AppColors.backgroundPrimary.withValues(alpha: 0.95),
              AppColors.backgroundPrimary,
              AppColors.backgroundSecondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Floating Header with Stats
              _buildFloatingHeader(totalCredits),

              // Main Content Area - Progressive UI Flow
              Expanded(
                child: _buildProgressiveContent(
                  isAiAvailable,
                  totalCredits,
                  isLargeScreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Progressive Content Based on Current Step
  Widget _buildProgressiveContent(
    bool isAiAvailable,
    int totalCredits,
    bool isLargeScreen,
  ) {
    switch (_currentStep) {
      case GenerationStep.assetTypeSelection:
        return _buildAssetTypeSelectionStep(isLargeScreen);
      case GenerationStep.assetSubtypeSelection:
        return _buildAssetSubtypeSelectionStep(isLargeScreen);
      case GenerationStep.colorInput:
        return _buildColorInputStep(isLargeScreen);
      case GenerationStep.promptInput:
        return _buildPromptInputStep(
          isAiAvailable,
          totalCredits,
          isLargeScreen,
        );
      case GenerationStep.generating:
        return _buildGeneratingStep(isLargeScreen);
      case GenerationStep.preview:
        return _buildPreviewStep(isLargeScreen);
    }
  }

  // Step 1: Asset Type Selection (Full Screen)
  Widget _buildAssetTypeSelectionStep(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Step Indicator
          _buildStepIndicator(1, "Choose Asset Type"),
          const SizedBox(height: 24),

          // Description
          Text(
            'What type of asset would you like to create?',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Large Asset Type Selection
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 900 : double.infinity,
              ),
              child: _buildLargeAssetTypeSelector(),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Prompt Input (Condensed + Input)
  Widget _buildPromptInputStep(
    bool isAiAvailable,
    int totalCredits,
    bool isLargeScreen,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Step Indicator
          _buildStepIndicator(4, "Describe Your Vision"),
          const SizedBox(height: 20),

          // Condensed Asset Type Display
          _buildCondensedAssetTypeDisplay(),
          const SizedBox(height: 24),

          // Prompt Input
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 600 : double.infinity,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _buildPromptInput(isAiAvailable, totalCredits),
                  ),
                  const SizedBox(height: 20),
                  _buildGenerationControls(isAiAvailable, totalCredits),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Generating (Loading)
  Widget _buildGeneratingStep(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStepIndicator(5, "Creating Your Asset"),
          const SizedBox(height: 32),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Generating your $_selectedAssetType...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This may take a few moments',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Preview (Condensed + Preview + Actions)
  Widget _buildPreviewStep(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStepIndicator(6, "Your Asset is Ready!"),
          const SizedBox(height: 20),

          // Condensed Info
          _buildCondensedGenerationInfo(),
          const SizedBox(height: 24),

          // Preview and Actions
          Expanded(
            child: Row(
              children: [
                // Preview Area
                Expanded(flex: 2, child: _buildPreviewArea()),
                const SizedBox(width: 24),

                // Action Panel
                Container(
                  width: isLargeScreen ? 300 : 200,
                  child: _buildPreviewActions(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildStepIndicator(int step, String title) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryGold,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: AppColors.textOnGold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (_currentStep != GenerationStep.assetTypeSelection)
          IconButton(
            onPressed: _currentStep == GenerationStep.promptInput
                ? _goBackToAssetTypeSelection
                : _goBackToPromptInput,
            icon: Icon(Icons.arrow_back, color: AppColors.textSecondary),
          ),
      ],
    );
  }

  Widget _buildCondensedAssetTypeDisplay() {
    return Column(
      children: [
        // Enhanced Asset Type Row with glassmorphism
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            // Enhanced glassmorphism gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundSecondary.withValues(alpha: 0.5),
                AppColors.backgroundSecondary.withValues(alpha: 0.2),
                AppColors.backgroundSecondary.withValues(alpha: 0.4),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(12),
            // Glassmorphism border
            border: Border.all(
              color: AppColors.primaryGold.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              // Strong neumorphic dark shadow
              BoxShadow(
                color: AppColors.neuShadowDark.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(6, 6),
                spreadRadius: 0,
              ),
              // Neumorphic light shadow
              BoxShadow(
                color: AppColors.neuHighlight.withValues(alpha: 0.9),
                blurRadius: 16,
                offset: const Offset(-3, -3),
                spreadRadius: 0,
              ),
              // Enhanced depth
              BoxShadow(
                color: AppColors.neuShadowDark.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              // Inner glow
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 2,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _getAssetTypeIcon(_selectedAssetType),
                color: AppColors.primaryGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asset Type',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _selectedAssetType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _goBackToAssetTypeSelection,
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Asset Subtype Row (if selected)
        if (_selectedAssetSubtype.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              // Enhanced glassmorphism with gold tint
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGold.withValues(alpha: 0.2),
                  AppColors.primaryGold.withValues(alpha: 0.05),
                  AppColors.primaryYellow.withValues(alpha: 0.15),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                // Strong neumorphic dark shadow
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(6, 6),
                  spreadRadius: 0,
                ),
                // Neumorphic light shadow
                BoxShadow(
                  color: AppColors.neuHighlight.withValues(alpha: 0.9),
                  blurRadius: 16,
                  offset: const Offset(-3, -3),
                  spreadRadius: 0,
                ),
                // Gold glow effect
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                  spreadRadius: 1,
                ),
                // Enhanced depth
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _getSubtypeIcon(_selectedAssetSubtype),
                  color: AppColors.primaryGold,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtype',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _selectedAssetSubtype,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_selectedAssetSubtype == 'Logo only' &&
                          _selectedColorCount != null)
                        Text(
                          '$_selectedColorCount color${_selectedColorCount! > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = GenerationStep.assetSubtypeSelection;
                      _availableSubtypes = _getAssetSubtypes(
                        _selectedAssetType,
                      );
                    });
                  },
                  child: Text(
                    'Change',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCondensedGenerationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _getAssetTypeIcon(_selectedAssetType),
            color: AppColors.primaryGold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _selectedAssetType,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _promptController.text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _goBackToPromptInput,
            child: Text('Edit', style: TextStyle(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewActions() {
    return Column(
      children: [
        // Save to Library Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveToLibrary,
            icon: const Icon(Icons.save),
            label: const Text('Save to Library'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.textOnGold,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Generate Another Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _goBackToPromptInput,
            icon: const Icon(Icons.refresh),
            label: const Text('Generate Another'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGold,
              side: BorderSide(color: AppColors.primaryGold),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Start Over Button
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _goBackToAssetTypeSelection,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Start Over'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // Large Asset Type Selector for Step 1
  Widget _buildLargeAssetTypeSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine grid layout based on screen size
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final childAspectRatio = constraints.maxWidth > 600 ? 1.1 : 0.9;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: AppConstants.assetTypes.length,
          itemBuilder: (context, index) {
            final assetType = AppConstants.assetTypes[index];
            return _buildLargeAssetTypeCard(assetType);
          },
        );
      },
    );
  }

  Widget _buildLargeAssetTypeCard(String assetType) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onAssetTypeSelected(assetType),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            // Enhanced glassmorphism background
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundSecondary.withValues(alpha: 0.6),
                AppColors.backgroundSecondary.withValues(alpha: 0.3),
                AppColors.backgroundSecondary.withValues(alpha: 0.5),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            // Enhanced glassmorphism border
            border: Border.all(
              color: AppColors.primaryGold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              // Strong neumorphic dark shadow (bottom-right)
              BoxShadow(
                color: AppColors.neuShadowDark.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(8, 8),
                spreadRadius: 0,
              ),
              // Neumorphic light shadow (top-left)
              BoxShadow(
                color: AppColors.neuHighlight.withValues(alpha: 0.9),
                blurRadius: 16,
                offset: const Offset(-4, -4),
                spreadRadius: 0,
              ),
              // Enhanced depth shadow
              BoxShadow(
                color: AppColors.neuShadowDark.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: 2,
              ),
              // Inner glow for glassmorphism
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 2,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced Icon Container with strong glassmorphism
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    // Multi-layer gradient for depth
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryGold.withValues(alpha: 0.4),
                        AppColors.primaryGold.withValues(alpha: 0.1),
                        AppColors.primaryYellow.withValues(alpha: 0.2),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      // Strong neumorphic shadows
                      BoxShadow(
                        color: AppColors.neuShadowDark.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(4, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: AppColors.neuHighlight.withValues(alpha: 0.8),
                        blurRadius: 12,
                        offset: const Offset(-2, -2),
                        spreadRadius: 0,
                      ),
                      // Enhanced glow effect
                      BoxShadow(
                        color: AppColors.primaryGold.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getAssetTypeIcon(assetType),
                    size: 24,
                    color: AppColors.primaryGold,
                  ),
                ),

                const SizedBox(height: 8),

                // Asset Type Name
                Text(
                  assetType,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Description - Flexible instead of Expanded to avoid overflow
                Flexible(
                  child: Text(
                    _getAssetTypeDescription(assetType),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAssetTypeDescription(String assetType) {
    switch (assetType) {
      case 'Character':
        return 'Create NPCs, heroes, and creatures';
      case 'Environment':
        return 'Build worlds and landscapes';
      case 'UI Element':
        return 'Design interface components';
      case 'Icon':
        return 'Craft symbols and indicators';
      case 'Texture':
        return 'Generate materials and patterns';
      case 'Logo':
        return 'Design brand identities';
      case 'Background':
        return 'Create scenic backdrops';
      case 'Object':
        return 'Design items and props';
      default:
        return 'Create amazing assets';
    }
  }

  // Asset subtype definitions
  List<String> _getAssetSubtypes(String assetType) {
    switch (assetType) {
      case 'Logo':
        return [
          'Logo only',
          'Logo + Name',
          'Name only',
          'Logo, Name, & Tagline',
        ];
      case 'Character':
        return [
          'Humanoid',
          'Fantasy Creature',
          'Robot/Mech',
          'Animal Character',
        ];
      case 'Environment':
        return [
          'Natural Landscape',
          'Urban Scene',
          'Fantasy World',
          'Sci-Fi Setting',
        ];
      case 'UI Element':
        return ['Button', 'Icon Set', 'Card Design', 'Navigation Menu'];
      case 'Icon':
        return ['Minimalist', 'Detailed', 'Flat Design', '3D Style'];
      case 'Texture':
        return ['Fabric', 'Stone/Metal', 'Wood/Natural', 'Abstract Pattern'];
      case 'Background':
        return ['Solid Color', 'Gradient', 'Pattern', 'Scene Background'];
      case 'Object':
        return ['Weapon/Tool', 'Furniture', 'Vehicle', 'Decorative Item'];
      default:
        return [];
    }
  }

  // Step 2: Asset Subtype Selection
  Widget _buildAssetSubtypeSelectionStep(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Step Indicator
          _buildStepIndicator(2, "Choose Specific Type"),
          const SizedBox(height: 20),

          // Condensed Asset Type Display
          _buildCondensedAssetTypeDisplay(),
          const SizedBox(height: 24),

          // Subtype Selection
          Expanded(
            child: () {
              final shouldShowColorSelection =
                  _selectedAssetSubtype.isNotEmpty &&
                  _needsColorInput(_selectedAssetType, _selectedAssetSubtype);
              AppLogger.debug(
                'Should show color selection? $shouldShowColorSelection',
              );
              AppLogger.debug(
                'Asset type: "$_selectedAssetType", Subtype: "$_selectedAssetSubtype"',
              );

              return shouldShowColorSelection
                  ? _buildColorCountSelection(isLargeScreen)
                  : _buildSubtypeGrid(isLargeScreen);
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtypeGrid(bool isLargeScreen) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLargeScreen ? 2 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isLargeScreen ? 2.5 : 3.5,
      ),
      itemCount: _availableSubtypes.length,
      itemBuilder: (context, index) {
        final subtype = _availableSubtypes[index];
        return _buildSubtypeCard(subtype);
      },
    );
  }

  Widget _buildSubtypeCard(String subtype) {
    return GestureDetector(
      onTap: () => _onAssetSubtypeSelected(subtype),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Enhanced glassmorphism gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundSecondary.withValues(alpha: 0.5),
              AppColors.backgroundSecondary.withValues(alpha: 0.2),
              AppColors.backgroundSecondary.withValues(alpha: 0.4),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          // Glassmorphism border
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            // Strong neumorphic dark shadow
            BoxShadow(
              color: AppColors.neuShadowDark.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(6, 6),
              spreadRadius: 0,
            ),
            // Neumorphic light shadow
            BoxShadow(
              color: AppColors.neuHighlight.withValues(alpha: 0.9),
              blurRadius: 16,
              offset: const Offset(-3, -3),
              spreadRadius: 0,
            ),
            // Enhanced depth
            BoxShadow(
              color: AppColors.neuShadowDark.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            // Inner glow
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.6),
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Icon(
                _getSubtypeIcon(subtype),
                size: 28,
                color: AppColors.primaryGold,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                subtype,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                _getSubtypeDescription(subtype),
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCountSelection(bool isLargeScreen) {
    return Column(
      children: [
        Text(
          'How many colors would you like for your ${_selectedAssetSubtype.toLowerCase()}?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Color Suggestion Button
        TextButton.icon(
          onPressed: _generateColorCountSuggestion,
          icon: Icon(
            Icons.palette_outlined,
            color: AppColors.primaryGold,
            size: 18,
          ),
          label: Text(
            'Suggest Color Count',
            style: TextStyle(
              color: AppColors.primaryGold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.primaryGold.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: AppColors.primaryGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isLargeScreen ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final colorCount = index + 1;
              return _buildColorCountCard(colorCount);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorCountCard(int colorCount) {
    return GestureDetector(
      onTap: () => _onColorCountSelected(colorCount),
      child: Container(
        decoration: BoxDecoration(
          // Enhanced glassmorphism gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundSecondary.withValues(alpha: 0.5),
              AppColors.backgroundSecondary.withValues(alpha: 0.2),
              AppColors.backgroundSecondary.withValues(alpha: 0.4),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          // Glassmorphism border
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            // Strong neumorphic dark shadow
            BoxShadow(
              color: AppColors.neuShadowDark.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(6, 6),
              spreadRadius: 0,
            ),
            // Neumorphic light shadow
            BoxShadow(
              color: AppColors.neuHighlight.withValues(alpha: 0.9),
              blurRadius: 16,
              offset: const Offset(-3, -3),
              spreadRadius: 0,
            ),
            // Enhanced depth
            BoxShadow(
              color: AppColors.neuShadowDark.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            // Inner glow
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.6),
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$colorCount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                '$colorCount Color${colorCount > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Color Input (for applicable asset types)
  Widget _buildColorInputStep(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Step Indicator
          _buildStepIndicator(3, "Choose Your Colors"),
          const SizedBox(height: 20),

          // Condensed Asset Type and Subtype Display
          _buildCondensedAssetTypeDisplay(),
          const SizedBox(height: 24),

          // Color Input Section
          Expanded(
            child: Column(
              children: [
                Text(
                  _getColorInputTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Color Suggestion Button
                TextButton.icon(
                  onPressed: _generateColorInputSuggestion,
                  icon: Icon(
                    Icons.color_lens_outlined,
                    color: AppColors.primaryGold,
                    size: 18,
                  ),
                  label: Text(
                    'Suggest Colors',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryGold.withValues(
                      alpha: 0.1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.primaryGold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Color Input Fields
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedColorCount ?? 0,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildColorInputField(index),
                      );
                    },
                  ),
                ),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _areAllColorsSelected()
                        ? _onColorsCompleted
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue to Vision Description',
                      style: TextStyle(
                        color: AppColors.backgroundPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildColorInputField(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Enhanced glassmorphism gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundSecondary.withValues(alpha: 0.5),
            AppColors.backgroundSecondary.withValues(alpha: 0.2),
            AppColors.backgroundSecondary.withValues(alpha: 0.4),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
        // Glassmorphism border
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          // Strong neumorphic dark shadow
          BoxShadow(
            color: AppColors.neuShadowDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(6, 6),
            spreadRadius: 0,
          ),
          // Neumorphic light shadow
          BoxShadow(
            color: AppColors.neuHighlight.withValues(alpha: 0.9),
            blurRadius: 16,
            offset: const Offset(-3, -3),
            spreadRadius: 0,
          ),
          // Enhanced depth
          BoxShadow(
            color: AppColors.neuShadowDark.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          // Inner glow
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Enhanced Number Badge with Glassmorphism
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGold.withValues(alpha: 0.4),
                  AppColors.primaryGold.withValues(alpha: 0.2),
                  AppColors.primaryYellow.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
                BoxShadow(
                  color: AppColors.neuHighlight.withValues(alpha: 0.8),
                  blurRadius: 2,
                  offset: const Offset(-0.5, -0.5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              onChanged: (value) => _updateColor(index, value),
              decoration: InputDecoration(
                hintText: 'e.g., Deep blue, Gold, Bright red...',
                hintStyle: TextStyle(
                  color: AppColors.textHint.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateColor(int index, String color) {
    setState(() {
      if (index < _selectedColors.length) {
        _selectedColors[index] = color;
      }
    });
  }

  bool _areAllColorsSelected() {
    return _selectedColors.every((color) => color.trim().isNotEmpty);
  }

  void _onColorsCompleted() {
    AppLogger.debug('Colors completed: $_selectedColors');
    setState(() {
      _currentStep = GenerationStep.promptInput;
    });
  }

  IconData _getSubtypeIcon(String subtype) {
    switch (subtype) {
      // Logo subtypes
      case 'Logo only':
        return Icons.graphic_eq;
      case 'Logo + Name':
        return Icons.text_fields;
      case 'Name only':
        return Icons.title;
      case 'Logo, Name, & Tagline':
        return Icons.layers;

      // Character subtypes
      case 'Humanoid':
        return Icons.person;
      case 'Fantasy Creature':
        return Icons.pets;
      case 'Robot/Mech':
        return Icons.smart_toy;
      case 'Animal Character':
        return Icons.cruelty_free;

      // Environment subtypes
      case 'Natural Landscape':
        return Icons.landscape;
      case 'Urban Scene':
        return Icons.location_city;
      case 'Fantasy World':
        return Icons.castle;
      case 'Sci-Fi Setting':
        return Icons.rocket_launch;

      default:
        return Icons.star;
    }
  }

  String _getSubtypeDescription(String subtype) {
    switch (subtype) {
      // Logo subtypes
      case 'Logo only':
        return 'Just the graphic symbol';
      case 'Logo + Name':
        return 'Symbol with brand name';
      case 'Name only':
        return 'Text-based wordmark';
      case 'Logo, Name, & Tagline':
        return 'Complete branding package';

      // Character subtypes
      case 'Humanoid':
        return 'Human-like characters';
      case 'Fantasy Creature':
        return 'Dragons, elves, orcs, etc.';
      case 'Robot/Mech':
        return 'Mechanical beings';
      case 'Animal Character':
        return 'Anthropomorphic animals';

      // Environment subtypes
      case 'Natural Landscape':
        return 'Forests, mountains, rivers';
      case 'Urban Scene':
        return 'Cities, buildings, streets';
      case 'Fantasy World':
        return 'Magical realms and settings';
      case 'Sci-Fi Setting':
        return 'Futuristic environments';

      default:
        return 'Custom subtype';
    }
  }

  // Simple AppBar-style Header
  Widget _buildFloatingHeader(int totalCredits) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Left Side - App Icon and Title
          Icon(Icons.auto_awesome, color: AppColors.primaryGold, size: 24),
          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Asset Studio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Enhanced Right Side - Glassmorphic Gemstone Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              // Enhanced glassmorphism gradient
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.backgroundSecondary.withValues(alpha: 0.7),
                  AppColors.backgroundSecondary.withValues(alpha: 0.4),
                  AppColors.primaryGold.withValues(alpha: 0.1),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(14),
              // Glassmorphism border
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                // Strong neumorphic dark shadow
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(6, 6),
                  spreadRadius: 0,
                ),
                // Neumorphic light shadow
                BoxShadow(
                  color: AppColors.neuHighlight.withValues(alpha: 0.9),
                  blurRadius: 16,
                  offset: const Offset(-3, -3),
                  spreadRadius: 0,
                ),
                // Gold glow effect
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                  spreadRadius: 1,
                ),
                // Enhanced depth
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.diamond,
                  color: Color(0xFFB8860B), // Dark yellow/gold
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalCredits',
                  style: const TextStyle(
                    color: Color(0xFFB8860B), // Dark yellow/gold
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Gemstones',
                  style: TextStyle(
                    color: Color(
                      0xFF8B6914,
                    ), // Darker yellow for better readability
                    fontSize: 12,
                    fontWeight: FontWeight.w700, // Heavier weight
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAssetTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'character':
        return Icons.person;
      case 'environment':
        return Icons.landscape;
      case 'ui element':
        return Icons.widgets;
      case 'icon':
        return Icons.apps;
      case 'texture':
        return Icons.texture;
      case 'logo':
        return Icons.star;
      case 'background':
        return Icons.wallpaper;
      case 'object':
        return Icons.category;
      default:
        return Icons.image;
    }
  }

  // Prompt Input Section
  Widget _buildPromptInput(bool isAiAvailable, int totalCredits) {
    return NeuContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      depth: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title and suggest button
          Row(
            children: [
              Icon(Icons.edit_outlined, color: AppColors.primaryGold, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Describe Your Vision',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Random Suggest Button
              TextButton.icon(
                onPressed: _generateRandomSuggestion,
                icon: Icon(
                  Icons.auto_awesome,
                  color: AppColors.primaryGold,
                  size: 18,
                ),
                label: Text(
                  'Suggest',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AppColors.primaryGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Enhanced Text Input with Strong Glassmorphism
          Container(
            constraints: const BoxConstraints(
              minHeight: 140, // Minimum height for better visibility
              maxHeight: 200, // Maximum height to prevent overflow
            ),
            padding: const EdgeInsets.all(18), // Increased padding
            decoration: BoxDecoration(
              // Enhanced glassmorphism gradient
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.backgroundSecondary.withValues(alpha: 0.6),
                  AppColors.backgroundSecondary.withValues(alpha: 0.3),
                  AppColors.backgroundSecondary.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
              // Enhanced glassmorphism border
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                // Strong neumorphic inset shadows for input field
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.2),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: AppColors.neuHighlight.withValues(alpha: 0.8),
                  offset: const Offset(-1, -1),
                  blurRadius: 3,
                  spreadRadius: 0,
                ),
                // Enhanced outer depth
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.15),
                  offset: const Offset(0, 8),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
                // Subtle glow
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: _promptController,
              focusNode: _promptFocusNode,
              maxLines: 6, // Fixed lines for better control
              minLines: 4, // Minimum lines to show
              maxLength: AppConstants.maxPromptLength,
              enabled: !_isGenerating && isAiAvailable,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16, // Good size for readability
                height: 1.5, // Better line spacing
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: _getPromptHint(),
                hintStyle: TextStyle(
                  color: AppColors.textHint.withValues(alpha: 0.7),
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                counterText: '', // Hide the built-in counter
                contentPadding: const EdgeInsets.all(
                  4,
                ), // Small internal padding
                isDense: true,
              ),
              textAlignVertical: TextAlignVertical.top, // Start from top
            ),
          ),

          const SizedBox(height: 12),
          // Enhanced Character Counter and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_promptController.text.length}/${AppConstants.maxPromptLength} characters',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_error != null) ...[
                Icon(Icons.error_outline, color: AppColors.error, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Error',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else if (_promptController.text.isNotEmpty) ...[
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryGold,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ready',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Generation Controls
  Widget _buildGenerationControls(bool isAiAvailable, int totalCredits) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (isSmallScreen) {
      // Stack vertically on small screens with high contrast cost display
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced High Contrast Cost Display with Strong Glassmorphism
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              // Multi-layer glassmorphism gradient
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.backgroundPrimary.withValues(alpha: 0.9),
                  AppColors.backgroundSecondary.withValues(alpha: 0.6),
                  AppColors.primaryGold.withValues(alpha: 0.1),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.8),
                width: 2,
              ),
              boxShadow: [
                // Strong neumorphic dark shadow
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(8, 8),
                  spreadRadius: 0,
                ),
                // Neumorphic light shadow
                BoxShadow(
                  color: AppColors.neuHighlight.withValues(alpha: 1.0),
                  blurRadius: 20,
                  offset: const Offset(-4, -4),
                  spreadRadius: 0,
                ),
                // Enhanced gold glow
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 0),
                  spreadRadius: 2,
                ),
                // Deep shadow for more depth
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: AppColors.textOnGold,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Cost: 1 Gemstone',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Generate Button
          _buildGenerateButton(isAiAvailable, totalCredits),
        ],
      );
    }

    // Row layout for larger screens with high contrast
    return Row(
      children: [
        // Enhanced High Contrast Cost Display with Strong Glassmorphism
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Multi-layer glassmorphism gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundPrimary.withValues(alpha: 0.9),
                AppColors.backgroundSecondary.withValues(alpha: 0.6),
                AppColors.primaryGold.withValues(alpha: 0.1),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryGold.withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              // Strong neumorphic dark shadow
              BoxShadow(
                color: AppColors.neuShadowDark.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(8, 8),
                spreadRadius: 0,
              ),
              // Neumorphic light shadow
              BoxShadow(
                color: AppColors.neuHighlight.withValues(alpha: 1.0),
                blurRadius: 20,
                offset: const Offset(-4, -4),
                spreadRadius: 0,
              ),
              // Enhanced gold glow
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 0),
                spreadRadius: 2,
              ),
              // Deep shadow for more depth
              BoxShadow(
                color: AppColors.neuShadowDark.withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
                spreadRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.diamond,
                  color: AppColors.textOnGold,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Cost: 1 Gem',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Generate Button - Takes remaining space
        Expanded(child: _buildGenerateButton(isAiAvailable, totalCredits)),
      ],
    );
  }

  Widget _buildGenerateButton(bool isAiAvailable, int totalCredits) {
    return GestureDetector(
      onTap:
          (_promptController.text.trim().isNotEmpty &&
              !_isGenerating &&
              isAiAvailable &&
              totalCredits > 0)
          ? _generateAsset
          : null,
      child: Container(
        height: 56,
        decoration:
            (_promptController.text.trim().isNotEmpty &&
                !_isGenerating &&
                isAiAvailable &&
                totalCredits > 0)
            ? NeuStyles.neuContainer(borderRadius: 16, depth: 8).copyWith(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGold, AppColors.primaryYellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : NeuStyles.neuContainer(
                borderRadius: 16,
                depth: 2,
              ).copyWith(color: AppColors.textHint.withValues(alpha: 0.3)),
        child: Center(
          child: _isGenerating
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textOnGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        'Creating...',
                        style: TextStyle(
                          color: AppColors.textOnGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color:
                          (_promptController.text.trim().isNotEmpty &&
                              !_isGenerating &&
                              isAiAvailable &&
                              totalCredits > 0)
                          ? AppColors.textOnGold
                          : AppColors.textHint,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Generate Asset',
                        style: TextStyle(
                          color:
                              (_promptController.text.trim().isNotEmpty &&
                                  !_isGenerating &&
                                  isAiAvailable &&
                                  totalCredits > 0)
                              ? AppColors.textOnGold
                              : AppColors.textHint,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // Preview Area - Large Display
  Widget _buildPreviewArea() {
    return NeuContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      depth: 12,
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.preview, color: AppColors.primaryGold, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_generatedImageData != null)
                Text(
                  _selectedAssetType,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Preview Content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  // Inset effect - inner shadows
                  BoxShadow(
                    color: AppColors.neuShadowDark.withValues(alpha: 0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: AppColors.neuHighlight.withValues(alpha: 0.8),
                    offset: const Offset(-2, -2),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: _generatedImageData != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        _generatedImageData!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : _buildPreviewPlaceholder(),
            ),
          ),

          // Error Display
          if (_error != null) ...[
            const SizedBox(height: 20),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: 12,
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Preview Placeholder
  Widget _buildPreviewPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isGenerating ? Icons.auto_awesome : Icons.image_outlined,
            size: 64,
            color: _isGenerating
                ? AppColors.primaryGold
                : AppColors.textHint.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 20),
          Text(
            _isGenerating
                ? 'Creating your asset...'
                : 'Your generated asset will appear here',
            style: TextStyle(
              fontSize: 18,
              color: _isGenerating ? AppColors.primaryGold : AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isGenerating) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGold,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Select an asset type and describe your vision to get started',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to generate random suggestions based on selected asset type and subtype
  void _generateRandomSuggestion() {
    List<String> suggestions = _getPromptSuggestions();
    if (suggestions.isNotEmpty) {
      final random = Random();
      final suggestion = suggestions[random.nextInt(suggestions.length)];
      setState(() {
        _promptController.text = suggestion;
      });
    }
  }

  // Get dynamic hint text based on asset type and subtype
  String _getPromptHint() {
    String baseHint = 'Describe the asset you want to create...\n\n';

    if (_selectedAssetType.isNotEmpty) {
      if (_selectedAssetSubtype.isNotEmpty) {
        switch (_selectedAssetSubtype) {
          case 'Logo only':
            return '${baseHint}Example: "A minimalist geometric logo with clean lines and modern styling"';
          case 'Logo + Name':
            return '${baseHint}Example: "A tech company logo with the name \'TechFlow\' in a modern sans-serif font"';
          case 'Name only':
            return '${baseHint}Example: "A wordmark for \'Creative Studio\' with elegant typography and artistic flair"';
          case 'Logo, Name, & Tagline':
            return '${baseHint}Example: "Complete branding for \'EcoGreen\' with tagline \'Sustainable Future\'"';
          case 'Humanoid':
            return '${baseHint}Example: "A fantasy warrior character with detailed armor and mystical weapons"';
          case 'Fantasy Creature':
            return '${baseHint}Example: "A majestic dragon with iridescent scales and glowing eyes"';
          case 'Natural Landscape':
            return '${baseHint}Example: "A serene mountain landscape with a crystal clear lake at sunset"';
          case 'Urban Scene':
            return '${baseHint}Example: "A futuristic cityscape with flying cars and neon-lit skyscrapers"';
          default:
            break;
        }
      }

      switch (_selectedAssetType) {
        case 'Logo':
          return '${baseHint}Example: "A minimalist tech logo with geometric shapes and modern colors"';
        case 'Character':
          return '${baseHint}Example: "A friendly cartoon character with vibrant colors and expressive features"';
        case 'Environment':
          return '${baseHint}Example: "A mystical forest scene with glowing plants and magical atmosphere"';
        case 'Icon':
          return '${baseHint}Example: "A simple weather icon set with cloud, sun, and rain symbols"';
        default:
          break;
      }
    }

    return '${baseHint}Example: "A minimalist calendar icon with clean lines and modern styling"';
  }

  // Helper method to generate color count suggestions
  void _generateColorCountSuggestion() {
    final suggestions = _getColorCountSuggestions(
      _selectedAssetType,
      _selectedAssetSubtype,
    );

    final random = Random();
    final suggestion = suggestions[random.nextInt(suggestions.length)];

    // Show as a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(suggestion, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryGold,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Got it!',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  List<String> _getColorCountSuggestions(String assetType, String subtype) {
    switch (assetType) {
      case 'Logo':
        return [
          'Use 1-2 colors for a clean, professional look',
          'Try 2-3 colors for brand recognition and versatility',
          'Consider 1 color for timeless simplicity',
          '3-4 colors can work for complex brand identities',
        ];
      case 'Character':
        return [
          'Use 2-3 main colors for character design',
          'Try 3-4 colors for detailed character variations',
          'Consider 2 colors for simple, iconic characters',
          '4 colors allow for rich character details',
        ];
      case 'UI Element':
        return [
          'Use 1-2 colors for consistent UI theming',
          'Try 2-3 colors for interactive state variations',
          'Consider 1 primary color for unified design',
          '3 colors work well for complex UI components',
        ];
      case 'Icon':
        return [
          'Use 1-2 colors for clear, recognizable icons',
          'Try 2 colors for depth and visual interest',
          'Consider 1 color for minimal, modern icons',
          '3 colors can add personality to icons',
        ];
      case 'Background':
        return [
          'Use 2-3 colors for gradient backgrounds',
          'Try 1-2 colors for subtle, elegant backgrounds',
          'Consider 3-4 colors for dynamic, vibrant backgrounds',
          '2 colors work great for professional backgrounds',
        ];
      case 'Object':
        return [
          'Use 2-3 colors for realistic object rendering',
          'Try 1-2 colors for minimalist object design',
          'Consider 3-4 colors for detailed, textured objects',
          '2 colors balance simplicity and detail',
        ];
      default:
        return [
          'Use 1-3 colors for most designs',
          'Try 2 colors for balanced visual appeal',
        ];
    }
  }

  // Helper method to generate color input suggestions
  void _generateColorInputSuggestion() {
    final colorCombinations = [
      ['Deep navy blue', 'Gold', 'White'],
      ['Forest green', 'Cream', 'Brown'],
      ['Royal purple', 'Silver', 'Black'],
      ['Crimson red', 'Charcoal gray'],
      ['Teal', 'Orange', 'White', 'Gray'],
      ['Burgundy', 'Gold'],
      ['Midnight blue', 'Bright yellow'],
      ['Emerald green', 'Black', 'White'],
      ['Coral pink', 'Navy blue', 'Gold'],
      ['Copper', 'Dark green', 'Cream'],
    ];

    final random = Random();
    final suggestion =
        colorCombinations[random.nextInt(colorCombinations.length)];

    // Fill in the color inputs with suggestions
    setState(() {
      for (
        int i = 0;
        i < suggestion.length && i < _selectedColors.length;
        i++
      ) {
        _selectedColors[i] = suggestion[i];
      }
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Color suggestion applied! You can edit any color as needed.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryGold,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Get curated prompt suggestions based on asset type and subtype
  List<String> _getPromptSuggestions() {
    if (_selectedAssetSubtype.isNotEmpty) {
      switch (_selectedAssetSubtype) {
        case 'Logo only':
          return [
            'A minimalist geometric logo with intersecting circles and gradient colors',
            'An abstract symbol combining a leaf and lightning bolt for energy brand',
            'A sophisticated monogram with elegant curves and gold accents',
            'A tech logo featuring connected dots forming a network pattern',
          ];
        case 'Logo + Name':
          return [
            'A modern logo for "InnovateTech" with circuit board patterns and blue tones',
            'A creative studio logo for "ArtFlow" with paintbrush stroke elements',
            'A fitness brand logo for "PowerFit" with dynamic motion lines',
            'A coffee shop logo for "BrewCraft" with stylized coffee bean design',
          ];
        case 'Humanoid':
          return [
            'A cyberpunk warrior with neon armor and glowing visor in dark cityscape',
            'A medieval knight with intricate plate armor and mystical sword',
            'A space explorer in futuristic suit with holographic interface',
            'An elegant elf archer with flowing robes and enchanted bow',
          ];
        case 'Fantasy Creature':
          return [
            'A majestic phoenix with flames trailing from its wings against starry sky',
            'A wise ancient dragon perched on crystal formations in a cave',
            'A mystical unicorn in an enchanted forest with glowing flowers',
            'A fierce griffin with eagle head and lion body on mountain peak',
          ];
        default:
          break;
      }
    }

    // Fallback suggestions based on asset type
    switch (_selectedAssetType) {
      case 'Logo':
        return [
          'A clean, professional logo with modern typography and subtle gradients',
          'An iconic symbol that represents innovation and creativity',
          'A versatile brand mark that works in both color and monochrome',
        ];
      case 'Character':
        return [
          'A charming animated character with expressive eyes and friendly smile',
          'A heroic figure with detailed costume and dynamic pose',
          'A cute mascot character with vibrant colors and playful design',
        ];
      case 'Environment':
        return [
          'A breathtaking landscape with dramatic lighting and rich colors',
          'An atmospheric scene that tells a story through visual elements',
          'A detailed environment with interesting architecture and mood',
        ];
      case 'Icon':
        return [
          'A clean, recognizable icon with consistent visual style',
          'A detailed symbol that communicates its purpose clearly',
          'A modern icon design with perfect pixel alignment',
        ];
      default:
        return [
          'A visually striking design with attention to detail and composition',
          'A creative concept with unique visual elements and style',
          'A professional-quality asset with polished finishing touches',
        ];
    }
  }
}
