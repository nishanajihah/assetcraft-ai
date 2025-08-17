import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/environment.dart';
import '../../core/services/app_services.dart';
import '../../core/utils/app_logger.dart';
import '../../features/splash/splash_screen.dart';
import '../widgets/app_shell.dart';
import '../widgets/environment_banner.dart';

/// Provider for app initialization state
final appInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    // Initialize environment first
    await Environment.initialize();

    // Initialize logger after environment is loaded
    AppLogger.initialize(
      isDevelopment: Environment.isDevelopment,
      isStaging: Environment.isStaging,
    );

    AppLogger.info(
      'Environment initialized for stage: ${Environment.currentStage}',
    );

    // Print environment configuration in development
    Environment.printConfig();

    // Initialize core services
    await AppServices.initialize();
    AppLogger.info('Core services initialized successfully');

    return true;
  } catch (e, stackTrace) {
    AppLogger.error('App initialization failed', e, stackTrace);
    return false;
  }
});

/// Widget that handles app initialization and shows appropriate screens
class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializationAsync = ref.watch(appInitializationProvider);

    return initializationAsync.when(
      data: (initialized) {
        if (!initialized) {
          return const _InitializationErrorScreen();
        }

        // Now we can safely check environment flags
        final Widget mainScreen;
        if (Environment.enableSplashScreen) {
          mainScreen = const SplashScreen();
        } else {
          mainScreen = const AppShell();
        }

        // Wrap with environment banner for development
        return EnvironmentBanner(child: mainScreen);
      },
      loading: () => const _InitializationLoadingScreen(),
      error: (error, stackTrace) => _InitializationErrorScreen(error: error),
    );
  }
}

/// Loading screen shown during initialization
class _InitializationLoadingScreen extends StatelessWidget {
  const _InitializationLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFECECEC), // AppColors.neuBackground
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6AF2E), Color(0xFFF5D061)],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Color(0xFF282F44),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'AssetCraft AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF282F44),
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE6AF2E)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Initializing...',
                style: TextStyle(color: Color(0xFF282F44), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error screen shown if initialization fails
class _InitializationErrorScreen extends StatelessWidget {
  final Object? error;

  const _InitializationErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFECECEC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFE53935),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF282F44),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error?.toString() ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF282F44),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // You could add retry logic here
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
