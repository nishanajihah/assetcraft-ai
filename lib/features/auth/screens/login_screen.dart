import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../repositories/auth_repository.dart';
import '../providers/login_form_provider.dart';
import 'signup_screen.dart';
import '../../../shared/widgets/app_shell.dart';

/// Login Screen with Neumorphism and Glassmorphism design
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginFormState = ref.watch(loginFormProvider);
    final loginFormNotifier = ref.read(loginFormProvider.notifier);
    final authRepository = ref.read(authRepositoryProvider);

    // Clear form state when screen is initialized to prevent loading state issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loginFormState.isLoading) {
        loginFormNotifier.clearForm();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.neuBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // App Logo/Title Section
              _buildHeaderSection(context),

              const SizedBox(height: 60),

              // Login Form Container
              _buildLoginFormContainer(
                context,
                loginFormState,
                loginFormNotifier,
                authRepository,
              ),

              const SizedBox(height: 32),

              // Sign Up Navigation
              _buildSignUpSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Header section with app branding
  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      children: [
        // App Logo Container with Neumorphism
        Container(
          width: 100,
          height: 100,
          decoration: NeuStyles.neuContainer(borderRadius: 50, depth: 6),
          child: const Icon(
            Icons.auto_awesome,
            size: 48,
            color: AppColors.primaryGold,
          ),
        ),

        const SizedBox(height: 24),

        // App Title
        Text(
          'AssetCraft AI',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Create stunning assets with AI',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Main login form container with glassmorphism effect
  Widget _buildLoginFormContainer(
    BuildContext context,
    LoginFormState loginFormState,
    LoginFormNotifier loginFormNotifier,
    AuthRepository authRepository,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.glassBackground.withValues(alpha: 0.2),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neuShadowDark.withValues(alpha: 0.1),
            offset: const Offset(0, 8),
            blurRadius: 32,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Text
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Sign in to continue creating',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Email Field
              _buildEmailField(loginFormState, loginFormNotifier),

              const SizedBox(height: 20),

              // Password Field
              _buildPasswordField(loginFormState, loginFormNotifier),

              const SizedBox(height: 12),

              // Error Message
              if (loginFormState.errorMessage != null)
                _buildErrorMessage(loginFormState.errorMessage!),

              const SizedBox(height: 32),

              // Login Button
              _buildLoginButton(
                context,
                loginFormState,
                loginFormNotifier,
                authRepository,
              ),

              const SizedBox(height: 16),

              // Forgot Password
              _buildForgotPasswordButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Email input field with neumorphism
  Widget _buildEmailField(
    LoginFormState loginFormState,
    LoginFormNotifier loginFormNotifier,
  ) {
    return Container(
      decoration: NeuStyles.neuContainer(
        color: AppColors.backgroundCard,
        borderRadius: 16,
        depth: 2,
      ),
      child: TextField(
        onChanged: loginFormNotifier.updateEmail,
        keyboardType: TextInputType.emailAddress,
        enabled: !loginFormState.isLoading,
        decoration: InputDecoration(
          labelText: 'Email',
          hintText: 'Enter your email address',
          prefixIcon: const Icon(
            Icons.email_outlined,
            color: AppColors.primaryGold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  /// Password input field with neumorphism
  Widget _buildPasswordField(
    LoginFormState loginFormState,
    LoginFormNotifier loginFormNotifier,
  ) {
    return Container(
      decoration: NeuStyles.neuContainer(
        color: AppColors.backgroundCard,
        borderRadius: 16,
        depth: 2,
      ),
      child: TextField(
        onChanged: loginFormNotifier.updatePassword,
        obscureText: !loginFormState.isPasswordVisible,
        enabled: !loginFormState.isLoading,
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'Enter your password',
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.primaryGold,
          ),
          suffixIcon: IconButton(
            onPressed: loginFormNotifier.togglePasswordVisibility,
            icon: Icon(
              loginFormState.isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  /// Error message display
  Widget _buildErrorMessage(String errorMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Login button with neumorphism effect
  Widget _buildLoginButton(
    BuildContext context,
    LoginFormState loginFormState,
    LoginFormNotifier loginFormNotifier,
    AuthRepository authRepository,
  ) {
    final isFormValid = loginFormNotifier.isFormValid;
    final canProceed = isFormValid && !loginFormState.isLoading;

    return Container(
      height: 56,
      decoration: NeuStyles.neuContainer(
        color: canProceed ? AppColors.primaryGold : AppColors.textHint,
        borderRadius: 16,
        depth: canProceed ? 4 : 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canProceed
              ? () => _handleLogin(
                  context,
                  loginFormState,
                  loginFormNotifier,
                  authRepository,
                )
              : null,
          child: Center(
            child: loginFormState.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textOnGold,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Sign In',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: canProceed
                          ? AppColors.textOnGold
                          : AppColors.backgroundCard,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Forgot password button
  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        // TODO: Navigate to forgot password screen
      },
      child: Text(
        'Forgot Password?',
        style: TextStyle(
          color: AppColors.primaryGold,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Sign up section
  Widget _buildSignUpSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: GlassStyles.glassContainer(borderRadius: 20, opacity: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Don\'t have an account? ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle login action
  Future<void> _handleLogin(
    BuildContext context,
    LoginFormState loginFormState,
    LoginFormNotifier loginFormNotifier,
    AuthRepository authRepository,
  ) async {
    // Double-check form validity before proceeding
    if (!loginFormNotifier.isFormValid || loginFormState.isLoading) {
      return;
    }

    loginFormNotifier.setLoading(true);

    try {
      AppLogger.info(
        'Attempting login for email: ${loginFormState.email.trim()}',
      );

      final response = await authRepository.signInWithEmailAndPassword(
        email: loginFormState.email.trim(),
        password: loginFormState.password,
      );

      if (response.user != null) {
        // Login successful
        AppLogger.info('Login successful for user: ${response.user!.email}');

        if (context.mounted) {
          // Navigate to main app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppShell()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${response.user!.email}!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        AppLogger.warning(
          'Login failed: No user returned from Supabase but no exception thrown',
        );
        loginFormNotifier.setError('Login failed. Please try again.');
      }
    } catch (e) {
      await _handleLoginError(context, e, loginFormState, loginFormNotifier);
    }
  }

  /// Handle different types of login errors
  Future<void> _handleLoginError(
    BuildContext context,
    dynamic error,
    LoginFormState loginFormState,
    LoginFormNotifier loginFormNotifier,
  ) async {
    final errorMessage = error.toString().toLowerCase();

    // Debug: Log the actual error message to understand what Supabase returns
    AppLogger.debug('Login Error Details', error);
    AppLogger.info('Login Error Message: $errorMessage');

    // Improved error handling for Supabase authentication
    if (errorMessage.contains('email not confirmed')) {
      // User exists but email not confirmed
      AppLogger.info('Login failed: Email not confirmed');
      loginFormNotifier.setError(
        'Please check your email and click the verification link to activate your account.',
      );
    } else if (errorMessage.contains('invalid_credentials') ||
        errorMessage.contains('invalid login credentials')) {
      // This could be either wrong password OR non-existent user
      // Don't automatically assume user doesn't exist
      AppLogger.info(
        'Login failed: Invalid credentials (could be wrong password or non-existent user)',
      );
      loginFormNotifier.setError(
        'Invalid email or password. Please check your credentials and try again.',
      );

      // Optional: Add a help text suggesting signup if the user continues to have issues
      // But don't automatically redirect to signup
    } else if (errorMessage.contains('user_not_found')) {
      // Explicitly user not found (rare in Supabase)
      AppLogger.info('Login failed: User not found');
      await _showUserNotFoundDialog(context, loginFormState.email);
    } else if (errorMessage.contains('too_many_requests')) {
      AppLogger.warning('Login failed: Too many requests');
      loginFormNotifier.setError(
        'Too many login attempts. Please try again later.',
      );
    } else if (errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      AppLogger.warning('Login failed: Network error');
      loginFormNotifier.setError(
        'Network error. Please check your connection.',
      );
    } else {
      // Generic error with the actual error message for debugging
      loginFormNotifier.setError('Login failed: ${error.toString()}');
    }
  }

  /// Show dialog when user is not found
  Future<void> _showUserNotFoundDialog(
    BuildContext context,
    String email,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.person_add_outlined, color: AppColors.primaryGold),
              const SizedBox(width: 12),
              Text(
                'Account Not Found',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No account found with this email address.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Would you like to create a new account?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Container(
              decoration: NeuStyles.neuContainer(
                color: AppColors.primaryGold,
                borderRadius: 12,
                depth: 2,
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToSignUpWithEmail(context, email);
                },
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppColors.textOnGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Navigate to sign up screen with pre-filled email
  void _navigateToSignUpWithEmail(BuildContext context, String email) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SignUpScreen(prefilledEmail: email)),
    );
  }
}
