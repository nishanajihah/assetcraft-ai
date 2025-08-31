import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/app_logger.dart';

/// Mock authentication service for development and testing
/// Provides fake authentication without requiring Supabase
class MockAuthService {
  static const bool isEnabled = true;

  // Mock user data
  static const String _mockUserId = 'mock_user_123';

  // Track mock authentication state
  static bool _isAuthenticated = false;
  static User? _currentUser;

  /// Simulate login with email and password
  static Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    AppLogger.info('🎭 [MOCK AUTH] Simulating login for: $email');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple validation - any email with "test" and any password works
    if (email.contains('test') || email.contains('demo')) {
      _isAuthenticated = true;
      _currentUser = _createMockUser(email);

      AppLogger.info('✅ [MOCK AUTH] Login successful for: $email');

      return AuthResponse(session: _createMockSession(), user: _currentUser);
    } else {
      AppLogger.info('❌ [MOCK AUTH] Login failed for: $email');
      throw AuthException('Invalid email or password (mock)');
    }
  }

  /// Simulate signup with email and password
  static Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    AppLogger.info('🎭 [MOCK AUTH] Simulating signup for: $email');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

    _isAuthenticated = true;
    _currentUser = _createMockUser(email);

    AppLogger.info('✅ [MOCK AUTH] Signup successful for: $email');

    return AuthResponse(session: _createMockSession(), user: _currentUser);
  }

  /// Simulate logout
  static Future<void> signOut() async {
    AppLogger.info('🎭 [MOCK AUTH] Simulating logout');

    await Future.delayed(const Duration(milliseconds: 500));

    _isAuthenticated = false;
    _currentUser = null;

    AppLogger.info('✅ [MOCK AUTH] Logout successful');
  }

  /// Get current mock user
  static User? get currentUser => _currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => _isAuthenticated;

  /// Create a mock user object
  static User _createMockUser(String email) {
    return User(
      id: _mockUserId,
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      email: email,
      emailConfirmedAt: DateTime.now().toIso8601String(),
      createdAt: DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Create a mock session
  static Session _createMockSession() {
    final now = DateTime.now();

    return Session(
      accessToken: 'mock_access_token_${now.millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token_${now.millisecondsSinceEpoch}',
      expiresIn: 3600,
      tokenType: 'bearer',
      user: _currentUser!,
    );
  }

  /// Stream of auth state changes (for testing)
  static Stream<AuthState> get authStateChanges async* {
    // For mock purposes, just yield current state periodically
    while (true) {
      if (_isAuthenticated && _currentUser != null) {
        yield AuthState(AuthChangeEvent.signedIn, _createMockSession());
      } else {
        yield AuthState(AuthChangeEvent.signedOut, null);
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Clear mock authentication state (for testing)
  static void clearMockState() {
    _isAuthenticated = false;
    _currentUser = null;
    AppLogger.debug('🧹 [MOCK AUTH] Cleared mock authentication state');
  }

  /// Get mock statistics for testing
  static Map<String, dynamic> getMockStats() {
    return {
      'isAuthenticated': _isAuthenticated,
      'currentUserId': _currentUser?.id,
      'currentUserEmail': _currentUser?.email,
      'sessionCreated': _currentUser?.createdAt,
    };
  }
}
