import 'package:flutter/material.dart';
import '../app_widgets.dart';

/// Example usage file for Enhanced Glassmorphism and Neumorphism Containers
///
/// This file demonstrates how to easily use the enhanced containers
/// across different pages and screens in your app.

class EnhancedContainersExample extends StatelessWidget {
  const EnhancedContainersExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced Containers Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Example 1: Enhanced Glass Container for main content
            EnhancedGlassContainer(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              hasGoldTint: true,
              hasGlow: true,
              onTap: () {
                // Handle tap
              },
              child: const Column(
                children: [
                  Text(
                    'Enhanced Glass Container',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This container has strong glassmorphism effects with gold tint and glow.',
                  ),
                ],
              ),
            ),

            // Example 2: Enhanced Neu Container for buttons or cards
            EnhancedNeuContainer(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              hasGoldAccent: true,
              onTap: () {
                // Handle tap
              },
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enhanced Neu Container',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Example 3: Grid of Enhanced Card Containers
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                EnhancedCardContainer(
                  padding: const EdgeInsets.all(16),
                  isSelected: true,
                  onTap: () {
                    // Handle selection
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EnhancedIconContainer(
                        icon: Icons.photo_library,
                        hasStrongGlow: true,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Gallery',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                EnhancedCardContainer(
                  padding: const EdgeInsets.all(16),
                  onTap: () {
                    // Handle selection
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EnhancedIconContainer(
                        icon: Icons.camera_alt,
                        hasStrongGlow: true,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Camera',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Example 4: Enhanced Input Container
            EnhancedInputContainer(
              padding: const EdgeInsets.all(16),
              hasFocus: false,
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your message...',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Example 5: Enhanced Cost Container
            EnhancedCostContainer(
              isHighlighted: true,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diamond, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Cost: 5 Gems',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Example 6: Row of Enhanced Badge Containers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                EnhancedBadgeContainer(
                  hasGlow: true,
                  child: const Text(
                    '1',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                EnhancedBadgeContainer(
                  hasGlow: true,
                  child: const Text(
                    '2',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                EnhancedBadgeContainer(
                  hasGlow: true,
                  child: const Text(
                    '3',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick usage examples for common patterns:

class QuickExamples {
  /// Create a glassmorphic button
  static Widget glassButton({
    required String text,
    required VoidCallback onPressed,
    bool hasGlow = true,
  }) {
    return EnhancedGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      hasGoldTint: true,
      hasGlow: hasGlow,
      onTap: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  /// Create a neumorphic card
  static Widget neuCard({
    required Widget child,
    VoidCallback? onTap,
    bool isPressed = false,
  }) {
    return EnhancedNeuContainer(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(8),
      pressed: isPressed,
      hasGoldAccent: true,
      onTap: onTap,
      child: child,
    );
  }

  /// Create an icon with glow effect
  static Widget glowIcon({
    required IconData icon,
    double size = 24,
    Color? color,
    VoidCallback? onTap,
  }) {
    return EnhancedIconContainer(
      icon: icon,
      size: size,
      iconColor: color,
      hasStrongGlow: true,
      onTap: onTap,
    );
  }

  /// Create a text input with glassmorphism
  static Widget glassInput({
    String? hintText,
    TextEditingController? controller,
    bool hasFocus = false,
  }) {
    return EnhancedInputContainer(
      hasFocus: hasFocus,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// Create a cost display
  static Widget costDisplay({
    required int cost,
    required String currency,
    bool isHighlighted = true,
  }) {
    return EnhancedCostContainer(
      isHighlighted: isHighlighted,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            'Cost: $cost $currency',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
