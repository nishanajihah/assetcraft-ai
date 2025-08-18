import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/environment.dart';

part 'auth_repository.g.dart';

/// Auth Repository for handling authentication operations
class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository(this._supabaseClient);

  /// Login with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _supabaseClient.auth.currentUser;

  /// Auth state stream
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
}

/// Provider for AuthRepository using riverpod_annotation
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  try {
    // Try to get Supabase client if available
    final client = Supabase.instance.client;
    if (Environment.hasSupabaseConfig &&
        !Environment.supabaseUrl.contains('placeholder')) {
      return AuthRepository(client);
    }
  } catch (e) {
    // Supabase not initialized, will cause errors but app should continue
  }

  // This will cause auth operations to fail, but that's expected in development
  // without proper Supabase configuration
  return AuthRepository(Supabase.instance.client);
}

/// Current user provider using riverpod_annotation
@riverpod
Stream<User?> currentUser(CurrentUserRef ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges.map(
    (authState) => authState.session?.user,
  );
}

/// Authentication state provider using riverpod_annotation
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final user = ref.watch(currentUserProvider);
  return user.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
}
