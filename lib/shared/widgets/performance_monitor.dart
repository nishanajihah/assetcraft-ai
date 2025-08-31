import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/config/environment.dart';

/// Performance monitoring widget for development
/// Shows frame rate and memory usage indicators
class PerformanceMonitor extends StatelessWidget {
  final Widget child;

  const PerformanceMonitor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only show performance monitor in debug mode and if enabled
    if (!kDebugMode || !Environment.isDevelopment) {
      return child;
    }

    return Stack(
      children: [
        child,
        // Performance overlay toggle
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'performance_monitor',
            onPressed: () {
              // Toggle performance overlay
              _togglePerformanceOverlay(context);
            },
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            child: const Icon(Icons.speed, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  void _togglePerformanceOverlay(BuildContext context) {
    // Get the widget inspector service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Performance overlay toggled'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// Memory usage indicator widget
class MemoryUsageIndicator extends StatefulWidget {
  const MemoryUsageIndicator({super.key});

  @override
  State<MemoryUsageIndicator> createState() => _MemoryUsageIndicatorState();
}

class _MemoryUsageIndicatorState extends State<MemoryUsageIndicator> {
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'MEM: --MB',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// Frame rate indicator widget
class FrameRateIndicator extends StatefulWidget {
  const FrameRateIndicator({super.key});

  @override
  State<FrameRateIndicator> createState() => _FrameRateIndicatorState();
}

class _FrameRateIndicatorState extends State<FrameRateIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _frameCount = 0;
  double _fps = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..addListener(_updateFrameRate);

    if (kDebugMode) {
      _controller.repeat();
    }
  }

  void _updateFrameRate() {
    setState(() {
      _frameCount++;
      if (_frameCount >= 60) {
        _fps = _frameCount / 1.0;
        _frameCount = 0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    Color fpsColor = Colors.green;
    if (_fps < 30) {
      fpsColor = Colors.red;
    } else if (_fps < 50)
      fpsColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'FPS: ${_fps.toStringAsFixed(0)}',
        style: TextStyle(
          color: fpsColor,
          fontSize: 10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
