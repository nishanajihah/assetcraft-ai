import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

// Constants for spacing
class _Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
}

/// In-app notification widget for daily gemstones and other gemstone-related events
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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      reverseDuration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the animation
    _animationController.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration).then((_) {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: _Spacing.md,
                  vertical: _Spacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.backgroundColor != null
                        ? [
                            widget.backgroundColor!.withValues(alpha: 0.95),
                            widget.backgroundColor!.withValues(alpha: 0.85),
                          ]
                        : [
                            AppColors.primaryGold.withValues(alpha: 0.95),
                            AppColors.primaryGold.withValues(alpha: 0.85),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.backgroundColor ?? AppColors.primaryGold)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: widget.onTap ?? _dismiss,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(_Spacing.md),
                    child: Row(
                      children: [
                        // Icon with animation
                        Container(
                          padding: const EdgeInsets.all(_Spacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: _Spacing.md),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Gemstones display
                        if (widget.gemstonesReceived > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _Spacing.sm,
                              vertical: _Spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${widget.gemstonesReceived}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: _Spacing.sm),
                        ],

                        // Dismiss button
                        InkWell(
                          onTap: _dismiss,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
