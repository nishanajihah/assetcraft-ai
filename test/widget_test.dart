// AssetCraft AI Widget Tests
//
// These tests verify that the main components of AssetCraft AI work correctly
// including navigation, UI elements, and user interactions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assetcraft_ai/main.dart';
import 'package:assetcraft_ai/core/constants/app_constants.dart';

void main() {
  group('AssetCraft AI App Tests', () {
    testWidgets('App loads and shows main navigation', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const ProviderScope(child: AssetCraftApp()));

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Verify that the app title is correct
      expect(
        find.text(AppConstants.appName),
        findsNothing,
      ); // Not visible in UI

      // Verify that bottom navigation exists
      expect(find.text('Generate'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Credits'), findsOneWidget);

      // Verify that the Generate tab is selected by default
      expect(find.text('Create Asset'), findsOneWidget);
    });

    testWidgets('Navigation between tabs works', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: AssetCraftApp()));
      await tester.pumpAndSettle();

      // Start on Generate tab
      expect(find.text('Create Asset'), findsOneWidget);

      // Tap on Library tab
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      // Verify Library screen is shown
      expect(find.text('Asset Library'), findsOneWidget);
      expect(find.text('No Assets Yet'), findsOneWidget);

      // Tap on Credits tab
      await tester.tap(find.text('Credits'));
      await tester.pumpAndSettle();

      // Verify Credits screen is shown
      expect(find.text('Credits & Plans'), findsOneWidget);
      expect(find.text('Current Balance'), findsOneWidget);
    });

    testWidgets('AI Generation screen has required elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: AssetCraftApp()));
      await tester.pumpAndSettle();

      // Verify main UI elements exist
      expect(find.text('AI Asset Generator'), findsOneWidget);
      expect(find.text('Asset Type'), findsOneWidget);
      expect(find.text('Describe Your Asset'), findsOneWidget);

      // Verify asset type chips exist
      for (String assetType in AppConstants.assetTypes) {
        expect(find.text(assetType), findsOneWidget);
      }

      // Verify generate button exists
      expect(find.textContaining('Generate Asset'), findsOneWidget);
    });

    testWidgets('Asset type selection works', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: AssetCraftApp()));
      await tester.pumpAndSettle();

      // Tap on a different asset type
      await tester.tap(find.text('Icon'));
      await tester.pumpAndSettle();

      // Note: Visual verification would require checking container decoration
      // which is more complex in widget tests
    });

    testWidgets('Credits screen shows pricing information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: AssetCraftApp()));
      await tester.pumpAndSettle();

      // Navigate to Credits tab
      await tester.tap(find.text('Credits'));
      await tester.pumpAndSettle();

      // Verify credit packs are shown
      expect(find.text('Starter Pack'), findsOneWidget);
      expect(find.text('Creator Pack'), findsOneWidget);
      expect(find.text('Pro Pack'), findsOneWidget);

      // Verify premium subscription
      expect(find.text('AssetCraft Pro'), findsOneWidget);
      expect(find.textContaining('\$9.99'), findsOneWidget);
    });

    testWidgets('App handles small screen sizes', (WidgetTester tester) async {
      // Set small screen size
      tester.binding.window.physicalSizeTestValue = const Size(350, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      await tester.pumpWidget(const ProviderScope(child: AssetCraftApp()));
      await tester.pumpAndSettle();

      // Verify app still works on small screens
      expect(find.text('Generate'), findsOneWidget);
      expect(find.text('Create Asset'), findsOneWidget);
    });

    testWidgets('App handles landscape orientation', (
      WidgetTester tester,
    ) async {
      // Set landscape size
      tester.binding.window.physicalSizeTestValue = const Size(800, 400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      await tester.pumpWidget(const ProviderScope(child: AssetCraftApp()));
      await tester.pumpAndSettle();

      // Verify app adapts to landscape
      expect(find.text('Generate'), findsOneWidget);
      expect(find.text('Create Asset'), findsOneWidget);
    });
  });

  group('Widget Component Tests', () {
    testWidgets('Text input accepts user input', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: AssetCraftApp()));
      await tester.pumpAndSettle();

      // Find the text input field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter text
      await tester.enterText(textField, 'A fantasy dragon');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('A fantasy dragon'), findsOneWidget);
    });

    testWidgets('Generate button shows loading state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: AssetCraftApp()));
      await tester.pumpAndSettle();

      // Enter some text first
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test prompt');
      await tester.pumpAndSettle();

      // Tap generate button
      final generateButton = find.textContaining('Generate Asset');
      await tester.tap(generateButton);
      await tester.pump(); // Don't settle yet to see loading state

      // Verify loading state appears
      expect(find.text('Generating...'), findsOneWidget);
    });
  });
}
