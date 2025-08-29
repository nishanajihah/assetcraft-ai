import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';

/// Mock AI service for testing and development
///
/// This service provides fake AI image generation without requiring
/// actual API calls or gemstones. Useful for development and testing.
class MockAIService {
  static const bool isEnabled = true;

  /// Generate a mock image with the given parameters
  static Future<Uint8List> generateMockImage({
    required String prompt,
    int width = 512,
    int height = 512,
    String style = 'realistic',
  }) async {
    AppLogger.info('🎭 [MOCK AI] Generating mock image for: "$prompt"');
    AppLogger.debug('🎭 [MOCK AI] Style: $style, Size: ${width}x$height');

    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 2, milliseconds: 500));

    try {
      // Create a mock image with different patterns based on style
      final bytes = await _createStyledMockImage(prompt, style, width, height);

      AppLogger.info(
        '✅ [MOCK AI] Generated mock image (${bytes.length} bytes)',
      );
      return bytes;
    } catch (e) {
      AppLogger.error('❌ [MOCK AI] Error creating mock image: $e');
      return _createFallbackImage();
    }
  }

  /// Create a styled mock image based on the prompt and style
  static Future<Uint8List> _createStyledMockImage(
    String prompt,
    String style,
    int width,
    int height,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Background color based on style
    final backgroundColor = _getBackgroundColor(style, prompt);
    paint.color = backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    // Add style-specific patterns
    _drawStylePattern(canvas, paint, style, width, height);

    // Add prompt-based elements
    _drawPromptElements(canvas, paint, prompt, width, height);

    // Add mock watermark
    _drawMockWatermark(canvas, width, height);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Get background color based on style and prompt
  static Color _getBackgroundColor(String style, String prompt) {
    final promptLower = prompt.toLowerCase();
    final styleLower = style.toLowerCase();

    // Style-based colors
    if (styleLower.contains('cyberpunk')) {
      return const Color(0xFF1a0d2e);
    } else if (styleLower.contains('cartoon')) {
      return const Color(0xFF87CEEB);
    } else if (styleLower.contains('realistic')) {
      return const Color(0xFF708090);
    }

    // Prompt-based colors
    if (promptLower.contains('sunset') || promptLower.contains('orange')) {
      return const Color(0xFFFF6347);
    } else if (promptLower.contains('ocean') || promptLower.contains('blue')) {
      return const Color(0xFF4169E1);
    } else if (promptLower.contains('forest') ||
        promptLower.contains('green')) {
      return const Color(0xFF228B22);
    } else if (promptLower.contains('night') || promptLower.contains('dark')) {
      return const Color(0xFF2F4F4F);
    }

    // Random gradient background
    return Color(
      (Random().nextDouble() * 0xFFFFFF).toInt(),
    ).withValues(alpha: 0.8);
  }

  /// Draw style-specific patterns
  static void _drawStylePattern(
    Canvas canvas,
    Paint paint,
    String style,
    int width,
    int height,
  ) {
    final styleLower = style.toLowerCase();

    if (styleLower.contains('cyberpunk')) {
      _drawCyberpunkPattern(canvas, paint, width, height);
    } else if (styleLower.contains('cartoon')) {
      _drawCartoonPattern(canvas, paint, width, height);
    } else if (styleLower.contains('realistic')) {
      _drawRealisticPattern(canvas, paint, width, height);
    } else {
      _drawGenericPattern(canvas, paint, width, height);
    }
  }

  /// Draw cyberpunk-style pattern
  static void _drawCyberpunkPattern(
    Canvas canvas,
    Paint paint,
    int width,
    int height,
  ) {
    // Neon grid lines
    paint.color = const Color(0xFF00FFFF);
    paint.strokeWidth = 2.0;
    paint.style = PaintingStyle.stroke;

    for (int i = 0; i < width; i += 50) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), height.toDouble()),
        paint,
      );
    }
    for (int i = 0; i < height; i += 50) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(width.toDouble(), i.toDouble()),
        paint,
      );
    }

    // Glowing circles
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFFF00FF).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(width * 0.3, height * 0.3), 40, paint);
    canvas.drawCircle(Offset(width * 0.7, height * 0.7), 30, paint);
  }

  /// Draw cartoon-style pattern
  static void _drawCartoonPattern(
    Canvas canvas,
    Paint paint,
    int width,
    int height,
  ) {
    // Fluffy clouds
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;

    final cloudPositions = [
      Offset(width * 0.2, height * 0.2),
      Offset(width * 0.6, height * 0.15),
      Offset(width * 0.8, height * 0.3),
    ];

    for (final pos in cloudPositions) {
      canvas.drawCircle(pos, 25, paint);
      canvas.drawCircle(Offset(pos.dx + 20, pos.dy), 20, paint);
      canvas.drawCircle(Offset(pos.dx - 15, pos.dy + 5), 18, paint);
    }

    // Simple sun
    paint.color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(width * 0.85, height * 0.15), 35, paint);
  }

  /// Draw realistic-style pattern
  static void _drawRealisticPattern(
    Canvas canvas,
    Paint paint,
    int width,
    int height,
  ) {
    // Gradient overlay
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(width.toDouble(), height.toDouble()),
      [
        const Color(0xFF87CEEB).withValues(alpha: 0.3),
        const Color(0xFF4682B4).withValues(alpha: 0.3),
      ],
    );

    paint.shader = gradient;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    // Texture-like pattern
    paint.shader = null;
    paint.color = Colors.white.withValues(alpha: 0.1);
    final random = Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 3 + 1, paint);
    }
  }

  /// Draw generic pattern
  static void _drawGenericPattern(
    Canvas canvas,
    Paint paint,
    int width,
    int height,
  ) {
    // Simple geometric shapes
    paint.color = Colors.white.withValues(alpha: 0.3);
    paint.style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(width * 0.1, height * 0.1, width * 0.3, height * 0.2),
      paint,
    );

    canvas.drawCircle(Offset(width * 0.7, height * 0.6), 50, paint);

    final path = Path();
    path.moveTo(width * 0.2, height * 0.7);
    path.lineTo(width * 0.4, height * 0.5);
    path.lineTo(width * 0.6, height * 0.8);
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Draw prompt-based elements
  static void _drawPromptElements(
    Canvas canvas,
    Paint paint,
    String prompt,
    int width,
    int height,
  ) {
    final promptLower = prompt.toLowerCase();

    if (promptLower.contains('cat') || promptLower.contains('animal')) {
      _drawSimpleCat(canvas, paint, width, height);
    } else if (promptLower.contains('mountain')) {
      _drawSimpleMountains(canvas, paint, width, height);
    } else if (promptLower.contains('building') ||
        promptLower.contains('city')) {
      _drawSimpleBuildings(canvas, paint, width, height);
    }
  }

  /// Draw a simple cat representation
  static void _drawSimpleCat(
    Canvas canvas,
    Paint paint,
    int width,
    int height,
  ) {
    paint.color = const Color(0xFF8B4513);
    paint.style = PaintingStyle.fill;

    final centerX = width * 0.5;
    final centerY = height * 0.6;

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY), width: 80, height: 60),
      paint,
    );

    // Head
    canvas.drawCircle(Offset(centerX, centerY - 40), 35, paint);

    // Ears
    final path = Path();
    path.moveTo(centerX - 25, centerY - 65);
    path.lineTo(centerX - 10, centerY - 45);
    path.lineTo(centerX - 35, centerY - 45);
    path.close();
    canvas.drawPath(path, paint);

    path.reset();
    path.moveTo(centerX + 25, centerY - 65);
    path.lineTo(centerX + 35, centerY - 45);
    path.lineTo(centerX + 10, centerY - 45);
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Draw simple mountains
  static void _drawSimpleMountains(
    Canvas canvas,
    Paint paint,
    int width,
    int height,
  ) {
    paint.color = const Color(0xFF696969);
    paint.style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, height.toDouble());
    path.lineTo(width * 0.2, height * 0.4);
    path.lineTo(width * 0.4, height * 0.6);
    path.lineTo(width * 0.6, height * 0.3);
    path.lineTo(width * 0.8, height * 0.5);
    path.lineTo(width.toDouble(), height * 0.4);
    path.lineTo(width.toDouble(), height.toDouble());
    path.close();

    canvas.drawPath(path, paint);
  }

  /// Draw simple buildings
  static void _drawSimpleBuildings(
    Canvas canvas,
    Paint paint,
    int width,
    int height,
  ) {
    paint.style = PaintingStyle.fill;

    final buildings = [
      {
        'x': 0.1,
        'width': 0.15,
        'height': 0.6,
        'color': const Color(0xFF708090),
      },
      {
        'x': 0.3,
        'width': 0.12,
        'height': 0.8,
        'color': const Color(0xFF556B2F),
      },
      {
        'x': 0.5,
        'width': 0.18,
        'height': 0.7,
        'color': const Color(0xFF8B4513),
      },
      {
        'x': 0.75,
        'width': 0.2,
        'height': 0.5,
        'color': const Color(0xFF2F4F4F),
      },
    ];

    for (final building in buildings) {
      paint.color = building['color'] as Color;
      final rect = Rect.fromLTWH(
        width * (building['x'] as double),
        height * (1 - (building['height'] as double)),
        width * (building['width'] as double),
        height * (building['height'] as double),
      );
      canvas.drawRect(rect, paint);
    }
  }

  /// Draw mock watermark
  static void _drawMockWatermark(Canvas canvas, int width, int height) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Simple "MOCK" text representation using basic shapes
    final mockX = width * 0.85;
    final mockY = height * 0.9;

    // Draw simple letters using rectangles and circles
    canvas.drawRect(Rect.fromLTWH(mockX, mockY, 2, 10), paint);
    canvas.drawRect(Rect.fromLTWH(mockX + 4, mockY, 2, 10), paint);
    canvas.drawRect(Rect.fromLTWH(mockX + 1, mockY + 3, 4, 2), paint);
  }

  /// Create a simple fallback image
  static Uint8List _createFallbackImage() {
    // Return a simple 1x1 pixel image as fallback
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 image
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
      0x54, 0x08, 0x57, 0x63, 0xF8, 0x0F, 0x00, 0x00,
      0x01, 0x00, 0x01, 0x5C, 0xCD, 0x90, 0x0A, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]);
  }

  /// Get available mock styles
  static List<String> getAvailableStyles() {
    return [
      'realistic',
      'cartoon',
      'cyberpunk',
      'anime',
      'oil_painting',
      'watercolor',
      'sketch',
      'digital_art',
    ];
  }

  /// Get sample prompts for testing
  static List<String> getSamplePrompts() {
    return [
      'A beautiful sunset over mountains',
      'Cyberpunk city at night with neon lights',
      'Cute cartoon cat wearing a wizard hat',
      'Majestic dragon flying over a castle',
      'Peaceful forest with sunlight streaming through trees',
      'Futuristic spaceship in deep space',
      'Vintage car on an empty highway',
      'Colorful bird perched on a tree branch',
      'Abstract geometric shapes in bright colors',
      'Medieval knight standing in front of a castle',
    ];
  }
}
