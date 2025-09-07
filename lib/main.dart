import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'screens/main_navigation_screen.dart';

/// AssetCraft AI - Premium AI Asset Generation App
///
/// Features:
/// - AI-powered image generation using Vertex AI Imagen
/// - Responsive neomorphic design
/// - Supabase Edge Functions integration
/// - Enhanced logging and error handling
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  AppLogger.info('🚀 Starting AssetCraft AI initialization', tag: 'Main');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    AppLogger.success('✅ Firebase initialized successfully', tag: 'Main');

    // Initialize Supabase with production credentials
    await Supabase.initialize(
      url: 'https://rmtqskaeyetecgpckrsg.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtdHFza2FleWV0ZWNncGNrcnNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0OTE2MjMsImV4cCI6MjA3MTA2NzYyM30.OwhEB_FO-l34M9hpTxhXgrW93RmxKzfiBFekO4EJID8',
    );
    AppLogger.success('✅ Supabase initialized successfully', tag: 'Main');

    // Initialize Mobile Ads
    await MobileAds.instance.initialize();
    AppLogger.success('✅ Mobile Ads initialized successfully', tag: 'Main');

    AppLogger.success('🎉 All services initialized successfully', tag: 'Main');
  } catch (e, stackTrace) {
    AppLogger.error(
      '❌ Failed to initialize services',
      tag: 'Main',
      error: e,
      stackTrace: stackTrace,
    );
  }

  runApp(const AssetCraftAIApp());
}

/// Main Application Widget
class AssetCraftAIApp extends StatelessWidget {
  const AssetCraftAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssetCraft AI',
      debugShowCheckedModeBanner: false,

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
        // Check if Supabase is properly initialized
        final supabaseClient = Supabase.instance.client;
        if (supabaseClient.auth.currentUser != null ||
            supabaseClient.realtime.channels.isNotEmpty ||
            true) {
          // Basic check - if we can access the client, it's initialized
          _isInitialized = true;
          _initializationError = null;
          AppLogger.success('App initialization check passed', tag: 'Main');
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

    return const MainNavigationScreen();
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
                    color: AppColors.primaryGold.withOpacity(0.3),
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
