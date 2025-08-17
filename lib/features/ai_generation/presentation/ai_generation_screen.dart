import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/neu_container.dart';

/// AI Generation Screen - Main feature for creating assets
class AIGenerationScreen extends ConsumerStatefulWidget {
  const AIGenerationScreen({super.key});

  @override
  ConsumerState<AIGenerationScreen> createState() => _AIGenerationScreenState();
}

class _AIGenerationScreenState extends ConsumerState<AIGenerationScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _selectedAssetType = 'Character';
  bool _isGenerating = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom App Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Create Asset',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: NeuStyles.neuContainer(borderRadius: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primaryGold,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '25', // TODO: Get from credits provider
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Body content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Card
                NeuContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: AppColors.primaryGold,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'AI Asset Generator',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Describe your vision and let AI bring it to life',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Asset Type Selector
                const Text(
                  'Asset Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                NeuContainer(
                  padding: const EdgeInsets.all(4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.assetTypes.map((type) {
                      final isSelected = _selectedAssetType == type;
                      return GestureDetector(
                        key: ValueKey('asset_type_$type'),
                        onTap: () {
                          setState(() {
                            _selectedAssetType = type;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: AppColors.primaryGold,
                                  borderRadius: BorderRadius.circular(20),
                                )
                              : BoxDecoration(
                                  color: AppColors.backgroundCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.textOnGold
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Prompt Input
                const Text(
                  'Describe Your Asset',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                NeuContainer(
                  child: TextField(
                    controller: _promptController,
                    maxLines: 4,
                    maxLength: AppConstants.maxPromptLength,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g., A medieval knight character with blue armor and a glowing sword...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),

                const SizedBox(height: 32),

                // Generate Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    key: const ValueKey('generate_asset_button'),
                    onPressed: _isGenerating ? null : _generateAsset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.textOnGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isGenerating
                        ? Row(
                            key: const ValueKey('generating_row'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textOnGold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Generating...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('generate_row'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Generate Asset (1 Credit)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tips Card
                NeuContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: AppColors.primaryYellow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pro Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Be specific about colors, style, and details\n'
                        '• Mention the intended use (game, app, web)\n'
                        '• Include mood and atmosphere descriptions',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _generateAsset() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description for your asset'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    // TODO: Implement actual AI generation
    // For now, simulate generation time
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isGenerating = false;
    });

    // TODO: Navigate to result screen or show generated asset
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Asset generated successfully! (Mock)')),
    );
  }
}
