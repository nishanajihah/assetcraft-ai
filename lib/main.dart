import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'providers/user_session.dart';
import 'pages/ai_generate_page.dart';
import 'pages/login_page.dart';
import 'utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    AppLogger.log('🚀 Starting AssetCraft AI application');

    // Initialize configuration from .env file
    AppLogger.log('📄 Loading environment configuration');
    await AppConfig.initialize();

    // Log configuration in development
    AppConfig.logConfiguration();

    // Initialize Supabase with configuration
    AppLogger.log('🔧 Initializing Supabase');
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    AppLogger.log('✅ Application initialized successfully');
    runApp(const App());
  } catch (e) {
    AppLogger.error('❌ Failed to initialize application: $e');
    rethrow;
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserSessionProvider(),
      child: MaterialApp(
        title: 'AssetCraft AI',
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD700), // Gold
            secondary: Color(0xFFFFA500), // Orange
            surface: Color(0xFF1E1E1E),
            onPrimary: Colors.black,
            onSecondary: Colors.black,
            onSurface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Color(0xFFFFD700),
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Wait a frame to ensure everything is properly initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  void _initializeProvider() {
    // Now navigate to the main app content - Provider is already available
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => Consumer<UserSessionProvider>(
          builder: (context, userSession, child) {
            AppLogger.log(
              'Checking authentication status: ${userSession.isAuthenticated}',
            );

            if (userSession.isAuthenticated) {
              return const AIGeneratePage();
            } else {
              return const LoginPage();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFFFD700)),
            SizedBox(height: 16),
            Text(
              'Initializing AssetCraft AI...',
              style: TextStyle(color: Color(0xFFFFD700), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
