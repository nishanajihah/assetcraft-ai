import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sign up form state
@immutable
class SignUpFormState {
  final String email;
  final String password;
  final String confirmPassword;
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;

  const SignUpFormState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
  });

  SignUpFormState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
  }) {
    return SignUpFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SignUpFormState &&
        other.email == email &&
        other.password == password &&
        other.confirmPassword == confirmPassword &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.isPasswordVisible == isPasswordVisible &&
        other.isConfirmPasswordVisible == isConfirmPasswordVisible;
  }

  @override
  int get hashCode {
    return email.hashCode ^
        password.hashCode ^
        confirmPassword.hashCode ^
        isLoading.hashCode ^
        errorMessage.hashCode ^
        isPasswordVisible.hashCode ^
        isConfirmPasswordVisible.hashCode;
  }
}

/// Sign up form notifier
class SignUpFormNotifier extends StateNotifier<SignUpFormState> {
  SignUpFormNotifier() : super(const SignUpFormState());

  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(
      confirmPassword: confirmPassword,
      errorMessage: null,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  void clearForm() {
    state = const SignUpFormState();
  }

  void initializeWithEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  /// Validate form
  bool get isFormValid {
    return state.email.isNotEmpty &&
        state.password.isNotEmpty &&
        state.confirmPassword.isNotEmpty &&
        _isValidEmail(state.email) &&
        _isValidPassword(state.password) &&
        _passwordsMatch();
  }

  /// Basic email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Password validation (at least 6 characters)
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Check if passwords match
  bool _passwordsMatch() {
    return state.password == state.confirmPassword;
  }

  /// Get password validation error
  String? get passwordError {
    if (state.password.isEmpty) return null;
    if (!_isValidPassword(state.password)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Get confirm password validation error
  String? get confirmPasswordError {
    if (state.confirmPassword.isEmpty) return null;
    if (!_passwordsMatch()) {
      return 'Passwords do not match';
    }
    return null;
  }
}

/// Provider for sign up form state
final signUpFormProvider =
    StateNotifierProvider<SignUpFormNotifier, SignUpFormState>((ref) {
      return SignUpFormNotifier();
    });
