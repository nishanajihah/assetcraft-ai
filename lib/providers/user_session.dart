import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class UserSessionProvider extends ChangeNotifier {
  SupabaseClient? _supabase;
  StreamSubscription<AuthState>? _authSubscription;

  User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  Timer? _initializationTimer;

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  UserSessionProvider() {
    // Start initialization immediately but safely
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Try to access Supabase instance
      _supabase = Supabase.instance.client;
      _initializeAuth();
    } catch (e) {
      // If Supabase is not initialized yet, wait for it
      AppLogger.log('Supabase not initialized yet, waiting...');
      _initializationTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        try {
          _supabase = Supabase.instance.client;
          timer.cancel();
          _initializationTimer = null;
          _initializeAuth();
        } catch (_) {
          // Continue waiting
        }
      });
    }
  }

  void _initializeAuth() {
    if (_supabase == null) {
      AppLogger.log('Supabase client not available for auth initialization');
      return;
    }

    AppLogger.log('Initializing authentication');
    _isInitialized = true;

    // Listen to auth state changes
    _authSubscription = _supabase!.auth.onAuthStateChange.listen(
      (data) async {
        AppLogger.log('Auth state changed: ${data.event}');

        final newUser = data.session?.user;

        if (newUser != null && _user?.id != newUser.id) {
          _user = newUser;
          await _handleNewSession(data.session!);
        } else if (newUser == null) {
          _user = null;
          _userProfile = null;
          AppLogger.log('User signed out');
        }

        notifyListeners();
      },
      onError: (error) {
        AppLogger.log('Auth state error: $error');
        _errorMessage = error.toString();
        notifyListeners();
      },
    );

    // Check if user is already signed in
    final session = _supabase!.auth.currentSession;
    if (session != null) {
      _user = session.user;
      _handleNewSession(session);
    }

    notifyListeners();
  }

  Future<void> _handleNewSession(Session session) async {
    try {
      AppLogger.log('Handling new session for user: ${session.user.id}');

      await _fetchUserProfile();

      // If profile doesn't exist, create one (new user)
      if (_userProfile == null) {
        await _createUserProfile(session.user);
      } else {
        // Check for daily gemstones grant
        await _checkDailyGemstones();
      }
    } catch (e) {
      AppLogger.log('Error handling new session: $e');
      _errorMessage = e.toString();
    }
  }

  Future<void> _fetchUserProfile() async {
    if (_supabase == null) return;

    try {
      AppLogger.log('Fetching user profile for user: ${_user?.id}');

      final response = await _supabase!
          .from('user_profiles')
          .select()
          .eq('user_id', _user!.id)
          .maybeSingle();

      _userProfile = response;
      AppLogger.log('User profile fetched: ${_userProfile != null}');
    } catch (e) {
      AppLogger.log('Error fetching user profile: $e');
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<void> _createUserProfile(User user) async {
    if (_supabase == null) return;

    try {
      AppLogger.log('Creating new user profile for: ${user.id}');

      final profileData = {
        'user_id': user.id,
        'email': user.email,
        'gemstones': 3,
        'last_free_gemstones_grant': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase!
          .from('user_profiles')
          .insert(profileData)
          .select()
          .single();

      _userProfile = response;
      AppLogger.log('User profile created successfully');
    } catch (e) {
      AppLogger.log('Error creating user profile: $e');
      throw Exception('Failed to create user profile');
    }
  }

  Future<void> _checkDailyGemstones() async {
    if (_userProfile == null || _supabase == null) return;

    try {
      final lastGrant = _userProfile!['last_free_gemstones_grant'];
      if (lastGrant == null) return;

      final lastGrantDate = DateTime.parse(lastGrant);
      final now = DateTime.now();
      final difference = now.difference(lastGrantDate);

      if (difference.inHours >= 24) {
        AppLogger.log('24 hours passed, granting daily gemstones');

        await _supabase!
            .from('user_profiles')
            .update({
              'gemstones': 3,
              'last_free_gemstones_grant': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .eq('user_id', _user!.id);

        await _fetchUserProfile(); // Refresh profile data
      }
    } catch (e) {
      AppLogger.log('Error checking daily gemstones: $e');
    }
  }

  Future<void> signInWithPassword(String email, String password) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      _setLoading(true);
      _clearError();

      AppLogger.log('Signing in with email: $email');

      final response = await _supabase!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        AppLogger.log('Sign in successful');
      }
    } catch (e) {
      AppLogger.log('Sign in error: $e');
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithIdToken(String idToken) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      _setLoading(true);
      _clearError();

      AppLogger.log('Signing in with Google ID token');

      final response = await _supabase!.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user != null) {
        AppLogger.log('Google sign in successful');
      }
    } catch (e) {
      AppLogger.log('Google sign in error: $e');
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      _setLoading(true);
      _clearError();

      AppLogger.log('Signing up with email: $email');

      final response = await _supabase!.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        AppLogger.log('Sign up successful');
      }
    } catch (e) {
      AppLogger.log('Sign up error: $e');
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      _setLoading(true);
      _clearError();

      AppLogger.log('Signing out user');

      await _supabase!.auth.signOut();
      AppLogger.log('Sign out successful');
    } catch (e) {
      AppLogger.log('Sign out error: $e');
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _initializationTimer?.cancel();
    super.dispose();
  }
}
