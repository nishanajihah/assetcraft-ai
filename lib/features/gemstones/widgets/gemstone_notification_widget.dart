import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

// Constants for spacing
class _Spacing {
  static const double sm = 8.0;
  static const double md = 16.0;
}

/// Enhanced in-app notification widget for daily gemstones and other gemstone-related events
/// Features beautiful animations, gemstone sparkle effects, and gold-themed UI
class GemstoneNotificationWidget extends ConsumerStatefulWidget {
  final String title;
  final String message;
  final int gemstonesReceived;
  final IconData icon;
  final VoidCallback? onTap;
  final Duration duration;
  final Color? backgroundColor;

  const GemstoneNotificationWidget({
    super.key,
    required this.title,
    required this.message,
    required this.gemstonesReceived,
    this.icon = Icons.diamond,
    this.onTap,
    this.duration = const Duration(seconds: 4),
    this.backgroundColor,
  });

  @override
  ConsumerState<GemstoneNotificationWidget> createState() =>
      _GemstoneNotificationWidgetState();
}

class _GemstoneNotificationWidgetState
    extends ConsumerState<GemstoneNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _sparkleController;
  late AnimationController _pulseController;

  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller for entry/exit
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Sparkle animation controller for continuous sparkle effect
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse animation for gemstone icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Entry animations with beautiful easing
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Sparkle effect animation
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    // Pulse animation for gemstone icon
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _animationController.forward();
    _sparkleController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);

    // Auto-dismiss after duration
    Future.delayed(widget.duration).then((_) {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _sparkleController.stop();
    _pulseController.stop();
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sparkleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _animationController,
        _sparkleController,
        _pulseController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 120),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: _Spacing.md,
                    vertical: _Spacing.sm,
                  ),
                  child: Stack(
                    children: [
                      // Main notification container
                      _buildMainContainer(),

                      // Sparkle effects overlay
                      if (widget.gemstonesReceived > 0) _buildSparkleEffects(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContainer() {
    final isGolden = widget.backgroundColor == null;
    final primaryColor = widget.backgroundColor ?? AppColors.primaryGold;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGolden
              ? [
                  AppColors.primaryGold,
                  AppColors.primaryYellow,
                  AppColors.primaryGold,
                ]
              : [
                  primaryColor.withValues(alpha: 0.95),
                  primaryColor.withValues(alpha: 0.85),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: isGolden ? [0.0, 0.5, 1.0] : null,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Outer glow
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          // Inner shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          // Top highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: widget.onTap ?? _dismiss,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(_Spacing.md),
              child: Row(
                children: [
                  // Animated gemstone icon
                  _buildAnimatedIcon(),

                  const SizedBox(width: _Spacing.md),

                  // Content
                  Expanded(child: _buildContent()),

                  // Gemstones received badge
                  if (widget.gemstonesReceived > 0) ...[
                    _buildGemstonesBadge(),
                    const SizedBox(width: _Spacing.sm),
                  ],

                  // Dismiss button
                  _buildDismissButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Transform.scale(
      scale: _pulseAnimation.value,
      child: Container(
        padding: const EdgeInsets.all(_Spacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: 32,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            shadows: const [
              Shadow(
                color: Colors.black26,
                offset: Offset(0.5, 0.5),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGemstonesBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Spacing.md,
        vertical: _Spacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.diamond,
            color: Colors.white,
            size: 16,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
              ),
            ],
          ),
          const SizedBox(width: 4),
          Text(
            '+${widget.gemstonesReceived}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0.5, 0.5),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissButton() {
    return InkWell(
      onTap: _dismiss,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.close,
          color: Colors.white.withValues(alpha: 0.9),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSparkleEffects() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: SparklePainter(
            animation: _sparkleAnimation,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

/// Custom painter to create sparkle effects around the notification
class SparklePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  SparklePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: animation.value * 0.8)
      ..style = PaintingStyle.fill;

    // Create sparkle points at various positions
    final sparklePoints = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.6, size.height * 0.1),
      Offset(size.width * 0.3, size.height * 0.9),
    ];

    for (int i = 0; i < sparklePoints.length; i++) {
      final point = sparklePoints[i];
      final phase = (animation.value + i * 0.3) % 1.0;
      final sparkleSize = 2.0 + math.sin(phase * math.pi * 2) * 1.5;

      _drawSparkle(canvas, point, sparkleSize, paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw a 4-pointed star sparkle
    final path = Path();

    // Top point
    path.moveTo(center.dx, center.dy - size);
    // Right point
    path.lineTo(center.dx + size * 0.3, center.dy - size * 0.3);
    path.lineTo(center.dx + size, center.dy);
    // Bottom point
    path.lineTo(center.dx + size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx, center.dy + size);
    // Left point
    path.lineTo(center.dx - size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.3, center.dy - size * 0.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}

/// Helper class to show gemstone notifications as overlays
class GemstoneNotificationOverlay {
  static OverlayEntry? _currentOverlay;

  /// Show a daily gemstones notification
  static void showDailyGemstones(
    BuildContext context, {
    required int gemstonesReceived,
    required int totalGemstones,
  }) {
    _showNotification(
      context,
      title: '🎁 Daily Gemstones!',
      message:
          'You received $gemstonesReceived Gemstones! Total: $totalGemstones',
      gemstonesReceived: gemstonesReceived,
      icon: Icons.diamond,
    );
  }

  /// Show a purchase success notification
  static void showPurchaseSuccess(
    BuildContext context, {
    required int gemstonesReceived,
    required int totalGemstones,
  }) {
    _showNotification(
      context,
      title: '✅ Purchase Successful!',
      message:
          'You received $gemstonesReceived Gemstones! Total: $totalGemstones',
      gemstonesReceived: gemstonesReceived,
      icon: Icons.shopping_bag,
      backgroundColor: Colors.green,
    );
  }

  /// Show an ad reward notification
  static void showAdReward(
    BuildContext context, {
    required int gemstonesReceived,
    required int totalGemstones,
  }) {
    _showNotification(
      context,
      title: '🎉 Ad Reward Earned!',
      message:
          'Thanks for watching! You earned $gemstonesReceived Gemstones! Total: $totalGemstones',
      gemstonesReceived: gemstonesReceived,
      icon: Icons.play_circle_filled,
      backgroundColor: Colors.green,
    );
  }

  /// Show a low gemstones warning
  static void showLowGemstones(
    BuildContext context, {
    required int remainingGemstones,
  }) {
    _showNotification(
      context,
      title: '⚠️ Low on Gemstones',
      message:
          'Only $remainingGemstones Gemstones left. Get more to continue creating!',
      gemstonesReceived: 0,
      icon: Icons.warning_amber,
      backgroundColor: Colors.orange,
    );
  }

  /// Show a custom gemstone notification
  static void _showNotification(
    BuildContext context, {
    required String title,
    required String message,
    required int gemstonesReceived,
    required IconData icon,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    // Remove any existing notification
    _currentOverlay?.remove();

    // Create new overlay
    _currentOverlay = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: GemstoneNotificationWidget(
            title: title,
            message: message,
            gemstonesReceived: gemstonesReceived,
            icon: icon,
            backgroundColor: backgroundColor,
            onTap: onTap,
          ),
        ),
      ),
    );

    // Show the overlay
    Overlay.of(context).insert(_currentOverlay!);

    // Auto-remove after delay
    Future.delayed(const Duration(seconds: 4)).then((_) {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }

  /// Manually dismiss the current notification
  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
