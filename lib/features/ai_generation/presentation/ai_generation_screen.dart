import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/credits_provider.dart';
import '../../../shared/widgets/neu_container.dart';

class AIGenerationScreen extends ConsumerStatefulWidget {
  const AIGenerationScreen({super.key});

  @override
  ConsumerState<AIGenerationScreen> createState() => _AIGenerationScreenState();
}

class _AIGenerationScreenState extends ConsumerState<AIGenerationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocusNode = FocusNode();
  String _selectedAssetType = 'Icon';
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
      _isGenerating = true;
      _error = null;
      _generatedImageData = null;
    });

    _loadingController.repeat();

    try {
      final aiService = ref.read(aiServiceProvider);
      final prompt = '\$_selectedAssetType: \${_promptController.text.trim()}';

      final imageData = await aiService.generateAssetFromPrompt(prompt);

      if (imageData != null) {
        setState(() {
          _generatedImageData = imageData;
          _isGenerating = false;
        });
        _showSuccess('Asset generated successfully!');
      } else {
        setState(() {
          _error = 'Failed to generate asset. Please try again.';
          _isGenerating = false;
        });
        // Refund credits on failure
        creditsNotifier.addCredits(1);
      }
    } catch (e) {
      setState(() {
        _error = 'Error generating asset: \${e.toString()}';
        _isGenerating = false;
      });
      // Refund credits on error
      creditsNotifier.addCredits(1);
    } finally {
      _loadingController.stop();
    }
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

              // Main Content Area - Responsive Layout
              Expanded(
                child: isLargeScreen
                    ? Row(
                        children: [
                          // Left Panel - Creation Controls (Wider)
                          Expanded(
                            flex: 3,
                            child: _buildCreationPanel(
                              isAiAvailable,
                              totalCredits,
                            ),
                          ),

                          // Right Panel - Preview & Results
                          Expanded(flex: 2, child: _buildPreviewPanel()),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Stacked layout for smaller screens
                            _buildCreationPanel(isAiAvailable, totalCredits),
                            const SizedBox(height: 24),
                            SizedBox(height: 400, child: _buildPreviewPanel()),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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

          // Right Side - Subtle Gemstone Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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

  // Left Panel - Creation Controls
  Widget _buildCreationPanel(bool isAiAvailable, int totalCredits) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      margin: EdgeInsets.only(
        left: isSmallScreen ? 8 : 24,
        bottom: isSmallScreen ? 8 : 24,
        right: isSmallScreen ? 8 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Asset Type Selection
          Container(
            height: isSmallScreen ? 220 : 320,
            width: double.infinity,
            child: _buildAssetTypeSelector(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 20),

          // Prompt Input
          SizedBox(
            height: isSmallScreen ? 180 : 260,
            child: _buildPromptInput(isAiAvailable, totalCredits),
          ),

          SizedBox(height: isSmallScreen ? 12 : 20),

          // Generation Controls
          _buildGenerationControls(isAiAvailable, totalCredits),
        ],
      ),
    );
  }

  // Right Panel - Preview & Results
  Widget _buildPreviewPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      margin: EdgeInsets.only(
        right: isSmallScreen ? 8 : 24,
        bottom: isSmallScreen ? 8 : 24,
        left: isSmallScreen ? 8 : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview Area
          SizedBox(
            height: isSmallScreen ? 300 : 450,
            child: _buildPreviewArea(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 24),

          // Action Buttons (if asset generated)
          if (_generatedImageData != null) _buildActionButtons(),
        ],
      ),
    );
  }

  // New Asset Type Selector
  Widget _buildAssetTypeSelector() {
    return NeuContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 20,
      depth: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: AppColors.primaryGold,
                size: 24,
              ),
              const SizedBox(width: 14),
              Text(
                'Asset Type',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vertical Asset Type List
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppConstants.assetTypes.length,
              itemBuilder: (context, index) {
                final type = AppConstants.assetTypes[index];
                final isSelected = _selectedAssetType == type;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAssetType = type;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: isSelected
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGold.withValues(alpha: 0.2),
                                AppColors.primaryYellow.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: AppColors.primaryGold,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGold.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          )
                        : NeuStyles.neuContainer(borderRadius: 16, depth: 3),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGold
                                : AppColors.backgroundSecondary.withValues(
                                    alpha: 0.3,
                                  ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getAssetTypeIcon(type),
                            color: isSelected
                                ? AppColors.textOnGold
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryGold
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _getAssetTypeDescription(type),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppColors.textOnGold,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAssetTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'icon':
        return Icons.apps;
      case 'illustration':
        return Icons.brush;
      case 'logo':
        return Icons.star;
      case 'pattern':
        return Icons.grid_view;
      default:
        return Icons.image;
    }
  }

  String _getAssetTypeDescription(String type) {
    switch (type.toLowerCase()) {
      case 'icon':
        return 'Simple icons and symbols for apps and interfaces';
      case 'illustration':
        return 'Complex artwork and detailed illustrations';
      case 'logo':
        return 'Brand logos and business identity designs';
      case 'pattern':
        return 'Repeatable patterns and textures';
      default:
        return 'Custom asset type for your project';
    }
  }

  // Prompt Input Section
  Widget _buildPromptInput(bool isAiAvailable, int totalCredits) {
    return NeuContainer(
      padding: const EdgeInsets.all(16), // Reduced from 20
      borderRadius: 20,
      depth: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: AppColors.primaryGold,
                size: 20,
              ), // Reduced from 22
              const SizedBox(width: 10), // Reduced from 12
              Flexible(
                child: Text(
                  'Describe Your Vision',
                  style: TextStyle(
                    fontSize: 16, // Reduced from 18
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 16
          // Text Input with Inset Effect
          Container(
            height: 70, // Reduced from 80
            padding: const EdgeInsets.all(10), // Reduced from 12
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // Inset effect
                BoxShadow(
                  color: AppColors.neuShadowDark.withValues(alpha: 0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: AppColors.neuHighlight.withValues(alpha: 0.8),
                  offset: const Offset(-1, -1),
                  blurRadius: 3,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: TextField(
              controller: _promptController,
              focusNode: _promptFocusNode,
              maxLines: null,
              expands: true,
              maxLength: AppConstants.maxPromptLength,
              enabled: !_isGenerating && isAiAvailable,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14, // Reduced from 16
                height: 1.4, // Reduced from 1.5
              ),
              decoration: InputDecoration(
                hintText:
                    'Describe the asset you want to create...\\n\\nExample: "A minimalist calendar icon with clean lines and modern styling"',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 13, // Reduced from 15
                  height: 1.3, // Reduced from 1.4
                ),
                border: InputBorder.none,
                counterText: '',
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),

          const SizedBox(height: 8), // Reduced from 12
          // Character Counter
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_promptController.text.length}/${AppConstants.maxPromptLength}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11, // Reduced from 12
                  ),
                ),
              ),
              if (_error != null)
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 14,
                ), // Reduced from 16
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
          // High Contrast Cost Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
        // High Contrast Cost Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
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

  // Action Buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Download Button
        Expanded(
          child: GestureDetector(
            onTap: _downloadAsset,
            child: NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: 16,
              depth: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, color: AppColors.primaryGold, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'Download',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Share Button
        Expanded(
          child: GestureDetector(
            onTap: _shareAsset,
            child: NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: 16,
              depth: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share, color: AppColors.primaryGold, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'Share',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Generate New Button
        GestureDetector(
          onTap: _generateNew,
          child: NeuContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            depth: 6,
            child: Icon(Icons.refresh, color: AppColors.primaryGold, size: 24),
          ),
        ),
      ],
    );
  }

  // Helper methods for actions
  void _downloadAsset() {
    // TODO: Implement download functionality
    _showSuccess('Asset download started!');
  }

  void _shareAsset() {
    // TODO: Implement share functionality
    _showSuccess('Share options opened!');
  }

  void _generateNew() {
    setState(() {
      _generatedImageData = null;
      _error = null;
    });
    _promptController.clear();
  }
}
