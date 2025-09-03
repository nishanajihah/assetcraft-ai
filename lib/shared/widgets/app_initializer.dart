import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/assets_provider.dart';
import '../../core/providers/generation_provider.dart';
import '../../core/utils/app_logger.dart';
import '../../core/constants/app_constants.dart';
import 'environment_banner.dart';

/// App initialization widget that handles provider setup and loading
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize the app providers and data
  Future<void> _initializeApp() async {
    if (_isInitializing || _isInitialized) return;

    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      AppLogger.info('🚀 Initializing app providers...');

      // Get providers
      final userProvider = context.read<UserProvider>();
      final assetsProvider = context.read<AssetsProvider>();
      final generationProvider = context.read<GenerationProvider>();

      // Initialize user provider first
      await userProvider.initialize();

      // Initialize other providers if user exists
      if (userProvider.isAuthenticated) {
        final userId = userProvider.currentUser!.id;
        await Future.wait([
          assetsProvider.initialize(userId),
          generationProvider.initialize(userId),
        ]);
      }

      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });

      AppLogger.info('✅ App initialization complete');
    } catch (e, stackTrace) {
      AppLogger.error('❌ App initialization failed', e, stackTrace);
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during initialization
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    // Show error screen if initialization failed
    if (_error != null) {
      return _buildErrorScreen();
    }

    // Show main app once initialized
    if (_isInitialized) {
      return const MainApp();
    }

    // Fallback loading screen
    return _buildLoadingScreen();
  }

  /// Build loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing AssetCraft AI...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error screen
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Initialization Failed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main app widget after initialization
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main app content
          _buildMainContent(context),

          // Environment banner (if in development)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: EnvironmentBanner(child: SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    // Check if user is authenticated
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isAuthenticated) {
          return _buildMainAppInterface(context);
        } else {
          return _buildWelcomeScreen(context);
        }
      },
    );
  }

  Widget _buildMainAppInterface(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to ${AppConstants.appName}!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Text(
                'Hello, ${userProvider.currentUser?.displayName ?? userProvider.currentUser?.email ?? 'User'}!',
                style: Theme.of(context).textTheme.bodyLarge,
              );
            },
          ),
          const SizedBox(height: 32),
          Consumer<AssetsProvider>(
            builder: (context, assetsProvider, child) {
              return Text(
                'Assets: ${assetsProvider.assetsCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            },
          ),
          const SizedBox(height: 8),
          Consumer<GenerationProvider>(
            builder: (context, generationProvider, child) {
              return Text(
                'Generations: ${generationProvider.generationsCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to main interface
              AppLogger.info('🎯 Navigate to main interface');
            },
            child: const Text('Start Creating'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to ${AppConstants.appName}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.appDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to authentication
              AppLogger.info('🔑 Navigate to authentication');
            },
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
