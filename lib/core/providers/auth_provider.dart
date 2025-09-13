import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

/// Authentication Provider
///
/// Manages authentication state throughout the app using Provider pattern
/// Handles login, signup, logout, and user session management
class AuthProvider extends ChangeNotifier {
  static const String _logTag = 'AuthProvider';

  // Authentication state
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // User info getters
  String? get userEmail => _currentUser?.email;
  String? get userId => _currentUser?.id;
  String? get displayName =>
      _userProfile?['display_name'] ?? _userProfile?['email'];
  int get gemstoneCount => _userProfile?['gemstone_count'] ?? 0;
  String get premiumTier => _userProfile?['premium_tier'] ?? 'free';

  AuthProvider() {
    _initialize();
  }

  /// Initialize authentication provider
  Future<void> _initialize() async {
    try {
      AppLogger.info('Initializing authentication provider', tag: _logTag);

      // Set current user from session
      _currentUser = AuthService.currentUser;

      if (_currentUser != null) {
        await _loadUserProfile();
      }

      // Listen to auth state changes
      AuthService.authStateChanges.listen(_onAuthStateChange);

      _isInitialized = true;
      _error = null;
      notifyListeners();

      AppLogger.success('Authentication provider initialized', tag: _logTag);
    } catch (e) {
      _error = e.toString();
      _isInitialized = true;
      notifyListeners();
      AppLogger.error(
        'Failed to initialize auth provider: $e',
        tag: _logTag,
        error: e,
      );
    }
  }

  /// Handle authentication state changes
  void _onAuthStateChange(AuthState authState) async {
    AppLogger.info('Auth state changed: ${authState.event}', tag: _logTag);

    switch (authState.event) {
      case AuthChangeEvent.signedIn:
        _currentUser = authState.session?.user;
        if (_currentUser != null) {
          await _loadUserProfile();
        }
        break;
      case AuthChangeEvent.signedOut:
        _currentUser = null;
        _userProfile = null;
        break;
      case AuthChangeEvent.userUpdated:
        _currentUser = authState.session?.user;
        if (_currentUser != null) {
          await _loadUserProfile();
        }
        break;
      default:
        break;
    }

    _error = null;
    notifyListeners();
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final metadata = displayName != null
          ? {'display_name': displayName}
          : null;

      final response = await AuthService.signUp(
        email: email,
        password: password,
        metadata: metadata,
      );

      if (response.user != null) {
        _currentUser = response.user;
        await _loadUserProfile();
        return true;
      }

      return false;
    } catch (e) {
      _error = _getErrorMessage(e);
      AppLogger.error('Sign up failed: $e', tag: _logTag, error: e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await AuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        await _loadUserProfile();
        return true;
      }

      return false;
    } catch (e) {
      _error = _getErrorMessage(e);
      AppLogger.error('Sign in failed: $e', tag: _logTag, error: e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await AuthService.signOut();

      _currentUser = null;
      _userProfile = null;
    } catch (e) {
      _error = _getErrorMessage(e);
      AppLogger.error('Sign out failed: $e', tag: _logTag, error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      AppLogger.error('Password reset failed: $e', tag: _logTag, error: e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user password
  Future<bool> updatePassword(String newPassword) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await AuthService.updatePassword(newPassword);
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      AppLogger.error('Password update failed: $e', tag: _logTag, error: e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await AuthService.updateUserProfile(updates);
      await _loadUserProfile();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      AppLogger.error('Profile update failed: $e', tag: _logTag, error: e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Spend gemstones
  Future<bool> spendGemstones(int amount) async {
    if (gemstoneCount < amount) {
      _error = 'Insufficient gemstones';
      notifyListeners();
      return false;
    }

    try {
      final newCount = gemstoneCount - amount;
      return await updateProfile({'gemstone_count': newCount});
    } catch (e) {
      _error = 'Failed to spend gemstones';
      AppLogger.error('Failed to spend gemstones: $e', tag: _logTag, error: e);
      notifyListeners();
      return false;
    }
  }

  /// Add gemstones
  Future<bool> addGemstones(int amount) async {
    try {
      final newCount = gemstoneCount + amount;
      return await updateProfile({'gemstone_count': newCount});
    } catch (e) {
      _error = 'Failed to add gemstones';
      AppLogger.error('Failed to add gemstones: $e', tag: _logTag, error: e);
      notifyListeners();
      return false;
    }
  }

  /// Increment generation count
  Future<void> incrementGenerationCount() async {
    try {
      final currentCount = _userProfile?['total_generated'] ?? 0;
      await updateProfile({'total_generated': currentCount + 1});
    } catch (e) {
      AppLogger.warning('Failed to update generation count: $e', tag: _logTag);
      // Don't show error to user as this is not critical
    }
  }

  /// Load user profile from database
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await AuthService.getUserProfile();
      AppLogger.info('User profile loaded successfully', tag: _logTag);
    } catch (e) {
      AppLogger.warning('Failed to load user profile: $e', tag: _logTag);
      // Don't set error as this shouldn't block authentication
    }
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid login credentials':
          return 'Invalid email or password';
        case 'user not found':
          return 'No account found with this email';
        case 'email not confirmed':
          return 'Please check your email and confirm your account';
        case 'password is too weak':
          return 'Password must be at least 6 characters';
        case 'email already in use':
          return 'An account with this email already exists';
        default:
          return error.message;
      }
    }

    return error.toString();
  }
}
