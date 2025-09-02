import 'package:flutter/material.dart';
import '../app_widgets.dart';
import '../../../../core/theme/app_theme.dart';

/// Example page showing how to use Enhanced Containers in other screens
///
/// This demonstrates how easy it is to apply the same beautiful
/// glassmorphism and neumorphism effects to any page in your app.

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  int selectedIndex = 0;
  bool isInputFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        isInputFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neuBackground,
      appBar: AppBar(
        title: const Text('Enhanced Containers Demo'),
        backgroundColor: AppColors.backgroundPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Example 1: Hero Section with Enhanced Glass Container
            EnhancedGlassContainer(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 24),
              hasGoldTint: true,
              hasGlow: true,
              child: Column(
                children: [
                  EnhancedIconContainer(
                    icon: Icons.auto_awesome,
                    containerSize: 64,
                    size: 32,
                    hasStrongGlow: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to Enhanced Containers',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Beautiful glassmorphism and neumorphism effects made easy',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Example 2: Settings Section with Neu Containers
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            EnhancedNeuContainer(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              hasGoldAccent: true,
              child: const Row(
                children: [
                  Icon(Icons.notifications, color: AppColors.primaryGold),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Manage your notification preferences',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),

            // Example 3: Feature Grid with Enhanced Card Containers
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                EnhancedCardContainer(
                  padding: const EdgeInsets.all(16),
                  isSelected: selectedIndex == 0,
                  onTap: () {
                    setState(() {
                      selectedIndex = 0;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EnhancedIconContainer(
                        icon: Icons.photo_library,
                        hasStrongGlow: selectedIndex == 0,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gallery',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'View assets',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                EnhancedCardContainer(
                  padding: const EdgeInsets.all(16),
                  isSelected: selectedIndex == 1,
                  onTap: () {
                    setState(() {
                      selectedIndex = 1;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EnhancedIconContainer(
                        icon: Icons.create,
                        hasStrongGlow: selectedIndex == 1,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Generate AI assets',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                EnhancedCardContainer(
                  padding: const EdgeInsets.all(16),
                  isSelected: selectedIndex == 2,
                  onTap: () {
                    setState(() {
                      selectedIndex = 2;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EnhancedIconContainer(
                        icon: Icons.share,
                        hasStrongGlow: selectedIndex == 2,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Export & share',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                EnhancedCardContainer(
                  padding: const EdgeInsets.all(16),
                  isSelected: selectedIndex == 3,
                  onTap: () {
                    setState(() {
                      selectedIndex = 3;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EnhancedIconContainer(
                        icon: Icons.star,
                        hasStrongGlow: selectedIndex == 3,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Upgrade account',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Example 4: Search Input with Enhanced Input Container
            const Text(
              'Search',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            EnhancedInputContainer(
              hasFocus: isInputFocused,
              minHeight: 56,
              child: TextField(
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'Search for assets, templates, or tools...',
                  prefixIcon: Icon(Icons.search, color: AppColors.primaryGold),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textHint),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),

            const SizedBox(height: 24),

            // Example 5: Pricing Section with Enhanced Cost Container
            const Text(
              'Pricing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: EnhancedCostContainer(
                    isHighlighted: false,
                    child: const Column(
                      children: [
                        Text(
                          'Basic',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.diamond,
                              color: AppColors.primaryGold,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '100 Gems',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EnhancedCostContainer(
                    isHighlighted: true,
                    child: const Column(
                      children: [
                        Text(
                          'Premium',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.diamond,
                              color: AppColors.primaryGold,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '500 Gems',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Example 6: Status Badges with Enhanced Badge Container
            const Text(
              'Status Indicators',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    EnhancedBadgeContainer(
                      size: 32,
                      hasGlow: true,
                      child: const Text(
                        '5',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Generated',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    EnhancedBadgeContainer(
                      size: 32,
                      hasGlow: true,
                      child: const Text(
                        '12',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    EnhancedBadgeContainer(
                      size: 32,
                      hasGlow: true,
                      child: const Text(
                        '3',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Shared',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
