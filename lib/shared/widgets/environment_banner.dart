import 'package:flutter/material.dart';
import '../../core/config/environment.dart';

/// Environment status widget that shows current environment in development
/// This appears as a small banner in the corner for developers
class EnvironmentBanner extends StatelessWidget {
  final Widget child;

  const EnvironmentBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only show in development or staging, hidden in production
    if (Environment.isProduction) {
      return child;
    }

    return Stack(
      children: [
        child,
        // Position the environment banner in the top-right corner
        Positioned(
          top: 40, // Below status bar
          right: 10,
          child: _EnvironmentChip(),
        ),
      ],
    );
  }
}

class _EnvironmentChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stage = Environment.currentStage;
    final color = _getEnvironmentColor(stage);

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 1.5),
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
              Icon(_getEnvironmentIcon(stage), size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                stage.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEnvironmentColor(String stage) {
    switch (stage) {
      case 'development':
        return Colors.orange.shade600; // More vibrant orange
      case 'staging':
        return Colors.blue.shade600; // More vibrant blue
      case 'production':
      default:
        return Colors.green.shade600; // More vibrant green
    }
  }

  IconData _getEnvironmentIcon(String stage) {
    switch (stage) {
      case 'development':
        return Icons.code; // Code icon for development
      case 'staging':
        return Icons.science; // Science icon for staging
      case 'production':
      default:
        return Icons.rocket_launch; // Rocket icon for production
    }
  }
}
