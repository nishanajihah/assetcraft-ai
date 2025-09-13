import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'core/services/app_initialization_service.dart';
import 'core/providers/ai_generation_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/gallery_provider.dart';
import 'core/providers/store_provider.dart';
import 'core/providers/auth_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';

/// AssetCraft AI - Premium AI Asset Generation App
///
/// Features:
/// - AI-powered image generation using Vertex AI Imagen
/// - Responsive neomorphic design
/// - Supabase Edge Functions integration
/// - Enhanced logging and error handling
/// - Environment-based configuration
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all app services using the centralized service
  final initSuccess = await AppInitializationService.initialize();

  if (!initSuccess) {
    AppLogger.error(
      '❌ Failed to initialize app: ${AppInitializationService.initializationError}',
      tag: 'Main',
    );
  }

  runApp(const AssetCraftAIApp());
}

/// Main Application Widget
class AssetCraftAIApp extends StatelessWidget {
  const AssetCraftAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AIGenerationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
      ],
      child: MaterialApp(
        title: 'AssetCraft AI',

        // Debug banner is disabled in release builds and can be toggled in debug
        debugShowCheckedModeBanner: kDebugMode ? false : false,

        // Enhanced theme with neomorphic design
        theme: AppTheme.goldTheme,

        // Home screen
        home: const AssetCraftHomePage(),

        // Error handling
        builder: (context, widget) {
          return MediaQuery(
            // Fix text scaling for better responsive design
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
              ),
            ),
            child: widget ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

/// Enhanced Home Page with initialization state management
class AssetCraftHomePage extends StatefulWidget {
  const AssetCraftHomePage({super.key});

  @override
  State<AssetCraftHomePage> createState() => _AssetCraftHomePageState();
}

class _AssetCraftHomePageState extends State<AssetCraftHomePage>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialization();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.debug('App lifecycle state changed: $state', tag: 'Main');
  }

  void _checkInitialization() {
    setState(() {
      try {
        // Check if the initialization service is properly initialized
        _isInitialized = AppInitializationService.isInitialized;
        _initializationError = AppInitializationService.initializationError;

        if (_isInitialized) {
          AppLogger.success('App initialization check passed', tag: 'Main');
        } else if (_initializationError != null) {
          AppLogger.error(
            'App initialization failed: $_initializationError',
            tag: 'Main',
          );
        } else {
          AppLogger.info('App is still initializing...', tag: 'Main');
        }
      } catch (e) {
        _initializationError = e.toString();
        AppLogger.error(
          'App initialization check failed',
          tag: 'Main',
          error: e,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized && _initializationError == null) {
      return _buildLoadingScreen();
    }

    if (_initializationError != null) {
      return _buildErrorScreen();
    }

    // Check authentication state
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isInitialized) {
          return _buildLoadingScreen();
        }

        if (authProvider.isLoggedIn) {
          return const MainNavigationScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGold, AppColors.primaryGoldLight],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'AssetCraft AI',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing AI services...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: AppColors.error),
              const SizedBox(height: 24),
              Text(
                'Initialization Error',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _initializationError ?? 'Unknown error occurred',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initializationError = null;
                    _isInitialized = false;
                  });
                  _checkInitialization();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
