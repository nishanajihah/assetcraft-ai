import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/login_form_provider.dart';
import '../providers/signup_form_provider.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';

/// Navigation utilities for auth screens with proper state management
class AuthNavigation {
  /// Navigate to login screen and clear any existing form state
  static void toLogin(BuildContext context, WidgetRef ref) {
    // Clear login form state before navigation
    ref.read(loginFormProvider.notifier).clearForm();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  /// Navigate to signup screen and clear any existing form state
  static void toSignUp(
    BuildContext context,
    WidgetRef ref, {
    String? prefilledEmail,
  }) {
    // Clear signup form state before navigation
    ref.read(signUpFormProvider.notifier).clearForm();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignUpScreen(prefilledEmail: prefilledEmail),
      ),
    );
  }

  /// Navigate to signup screen from login (when user not found)
  static void toSignUpFromLogin(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) {
    // Clear both form states
    ref.read(loginFormProvider.notifier).clearForm();
    ref.read(signUpFormProvider.notifier).clearForm();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SignUpScreen(prefilledEmail: email)),
    );
  }
}
