import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Authentication Service for Supabase
///
/// Handles user authentication including:
/// - Email/password signup and login
/// - Session management
/// - Password reset
/// - User profile management
class AuthService {
  static const String _logTag = 'AuthService';

  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  /// Get current session
  static Session? get currentSession => _supabase.auth.currentSession;

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.info('Attempting to sign up user: $email', tag: _logTag);

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (response.user != null) {
        AppLogger.success(
          'User signed up successfully: ${response.user!.email}',
          tag: _logTag,
        );

        // Create user profile in database
        await _createUserProfile(response.user!);
      }

      return response;
    } catch (e) {
      AppLogger.error('Sign up failed: $e', tag: _logTag, error: e);
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting to sign in user: $email', tag: _logTag);

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        AppLogger.success(
          'User signed in successfully: ${response.user!.email}',
          tag: _logTag,
        );

        // Ensure user profile exists
        await _ensureUserProfile(response.user!);
      }

      return response;
    } catch (e) {
      AppLogger.error('Sign in failed: $e', tag: _logTag, error: e);
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      AppLogger.info('Signing out user', tag: _logTag);
      await _supabase.auth.signOut();
      AppLogger.success('User signed out successfully', tag: _logTag);
    } catch (e) {
      AppLogger.error('Sign out failed: $e', tag: _logTag, error: e);
      rethrow;
    }
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    try {
      AppLogger.info('Sending password reset email to: $email', tag: _logTag);

      await _supabase.auth.resetPasswordForEmail(email);

      AppLogger.success('Password reset email sent to: $email', tag: _logTag);
    } catch (e) {
      AppLogger.error('Password reset failed: $e', tag: _logTag, error: e);
      rethrow;
    }
  }

  /// Update user password
  static Future<void> updatePassword(String newPassword) async {
    try {
      AppLogger.info('Updating user password', tag: _logTag);

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      AppLogger.success('Password updated successfully', tag: _logTag);
    } catch (e) {
      AppLogger.error('Password update failed: $e', tag: _logTag, error: e);
      rethrow;
    }
  }

  /// Update user email
  static Future<void> updateEmail(String newEmail) async {
    try {
      AppLogger.info('Updating user email to: $newEmail', tag: _logTag);

      await _supabase.auth.updateUser(UserAttributes(email: newEmail));

      AppLogger.success('Email update initiated for: $newEmail', tag: _logTag);
    } catch (e) {
      AppLogger.error('Email update failed: $e', tag: _logTag, error: e);
      rethrow;
    }
  }

  /// Get user profile from database
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (e) {
      AppLogger.error('Failed to get user profile: $e', tag: _logTag, error: e);
      return null;
    }
  }

  /// Update user profile in database
  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await _supabase.from('users').update(updates).eq('id', currentUser!.id);

      AppLogger.success('User profile updated successfully', tag: _logTag);
    } catch (e) {
      AppLogger.error(
        'Failed to update user profile: $e',
        tag: _logTag,
        error: e,
      );
      rethrow;
    }
  }

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Create user profile in database after signup
  static Future<void> _createUserProfile(User user) async {
    try {
      final profile = {
        'id': user.id,
        'email': user.email,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'gemstone_count': 10, // Starting gemstones
        'total_generated': 0,
        'premium_tier': 'free',
        // Add other default profile fields
      };

      await _supabase.from('users').insert(profile);

      AppLogger.success('User profile created successfully', tag: _logTag);
    } catch (e) {
      AppLogger.warning('Failed to create user profile: $e', tag: _logTag);
      // Don't rethrow as this shouldn't block authentication
    }
  }

  /// Ensure user profile exists (create if missing)
  static Future<void> _ensureUserProfile(User user) async {
    try {
      final existing = await getUserProfile();

      if (existing == null) {
        AppLogger.info('User profile not found, creating...', tag: _logTag);
        await _createUserProfile(user);
      }
    } catch (e) {
      AppLogger.warning('Failed to ensure user profile: $e', tag: _logTag);
    }
  }
}
