import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../repositories/auth_repository.dart';
import '../providers/signup_form_provider.dart';
import 'login_screen.dart';
import '../../../shared/widgets/app_shell.dart';

/// Sign Up Screen with Neumorphism and Glassmorphism design
class SignUpScreen extends ConsumerWidget {
  final String? prefilledEmail;

  const SignUpScreen({super.key, this.prefilledEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signUpFormState = ref.watch(signUpFormProvider);
    final signUpFormNotifier = ref.read(signUpFormProvider.notifier);
    final authRepository = ref.read(authRepositoryProvider);

    // Pre-fill email if provided, or clear form if in loading state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (signUpFormState.isLoading && prefilledEmail == null) {
        // Clear form if in loading state and no prefilled email
        signUpFormNotifier.clearForm();
      } else if (prefilledEmail != null && prefilledEmail!.isNotEmpty) {
        signUpFormNotifier.initializeWithEmail(prefilledEmail!);
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
              const SizedBox(height: 40),

              // Back Button
              _buildBackButton(context),

              const SizedBox(height: 40),

              // App Logo/Title Section
              _buildHeaderSection(context),

              // Show notification if redirected from login
              if (prefilledEmail != null) _buildRedirectNotification(),

              const SizedBox(height: 60), // Sign Up Form Container
              _buildSignUpFormContainer(
                context,
                signUpFormState,
                signUpFormNotifier,
                authRepository,
              ),

              const SizedBox(height: 32),

              // Login Navigation
              _buildLoginSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Back button
  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 48,
        height: 48,
        decoration: NeuStyles.neuContainer(borderRadius: 24, depth: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.primaryGold,
              size: 20,
            ),
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
          'Join AssetCraft AI',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Start creating amazing assets today',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Notification for users redirected from login
  Widget _buildRedirectNotification() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Not Found',
                  style: TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Let\'s create a new account with this email address.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Main sign up form container with glassmorphism effect
  Widget _buildSignUpFormContainer(
    BuildContext context,
    SignUpFormState signUpFormState,
    SignUpFormNotifier signUpFormNotifier,
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
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Get started with your creative journey',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Email Field
              _buildEmailField(signUpFormState, signUpFormNotifier),

              const SizedBox(height: 20),

              // Password Field
              _buildPasswordField(signUpFormState, signUpFormNotifier),

              const SizedBox(height: 20),

              // Confirm Password Field
              _buildConfirmPasswordField(signUpFormState, signUpFormNotifier),

              const SizedBox(height: 12),

              // Error Message
              if (signUpFormState.errorMessage != null)
                _buildErrorMessage(signUpFormState.errorMessage!),

              const SizedBox(height: 32),

              // Sign Up Button
              _buildSignUpButton(
                context,
                signUpFormState,
                signUpFormNotifier,
                authRepository,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Email input field with neumorphism
  Widget _buildEmailField(
    SignUpFormState signUpFormState,
    SignUpFormNotifier signUpFormNotifier,
  ) {
    return Container(
      decoration: NeuStyles.neuContainer(
        color: AppColors.backgroundCard,
        borderRadius: 16,
        depth: 2,
      ),
      child: TextField(
        controller: TextEditingController(text: signUpFormState.email),
        onChanged: signUpFormNotifier.updateEmail,
        keyboardType: TextInputType.emailAddress,
        enabled: !signUpFormState.isLoading,
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
    SignUpFormState signUpFormState,
    SignUpFormNotifier signUpFormNotifier,
  ) {
    return Container(
      decoration: NeuStyles.neuContainer(
        color: AppColors.backgroundCard,
        borderRadius: 16,
        depth: 2,
      ),
      child: TextField(
        onChanged: signUpFormNotifier.updatePassword,
        obscureText: !signUpFormState.isPasswordVisible,
        enabled: !signUpFormState.isLoading,
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'Create a password (6+ characters)',
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.primaryGold,
          ),
          suffixIcon: IconButton(
            onPressed: signUpFormNotifier.togglePasswordVisibility,
            icon: Icon(
              signUpFormState.isPasswordVisible
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
          errorText: signUpFormNotifier.passwordError,
        ),
      ),
    );
  }

  /// Confirm password input field with neumorphism
  Widget _buildConfirmPasswordField(
    SignUpFormState signUpFormState,
    SignUpFormNotifier signUpFormNotifier,
  ) {
    return Container(
      decoration: NeuStyles.neuContainer(
        color: AppColors.backgroundCard,
        borderRadius: 16,
        depth: 2,
      ),
      child: TextField(
        onChanged: signUpFormNotifier.updateConfirmPassword,
        obscureText: !signUpFormState.isConfirmPasswordVisible,
        enabled: !signUpFormState.isLoading,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          hintText: 'Confirm your password',
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.primaryGold,
          ),
          suffixIcon: IconButton(
            onPressed: signUpFormNotifier.toggleConfirmPasswordVisibility,
            icon: Icon(
              signUpFormState.isConfirmPasswordVisible
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
          errorText: signUpFormNotifier.confirmPasswordError,
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
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
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

  /// Sign up button with neumorphism effect
  Widget _buildSignUpButton(
    BuildContext context,
    SignUpFormState signUpFormState,
    SignUpFormNotifier signUpFormNotifier,
    AuthRepository authRepository,
  ) {
    final isFormValid = signUpFormNotifier.isFormValid;
    final canProceed = isFormValid && !signUpFormState.isLoading;

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
              ? () => _handleSignUp(
                  context,
                  signUpFormState,
                  signUpFormNotifier,
                  authRepository,
                )
              : null,
          child: Center(
            child: signUpFormState.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textOnGold,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Create Account',
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

  /// Login section
  Widget _buildLoginSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: GlassStyles.glassContainer(borderRadius: 20, opacity: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'Sign In',
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

  /// Handle sign up action
  Future<void> _handleSignUp(
    BuildContext context,
    SignUpFormState signUpFormState,
    SignUpFormNotifier signUpFormNotifier,
    AuthRepository authRepository,
  ) async {
    // Double-check form validity before proceeding
    if (!signUpFormNotifier.isFormValid || signUpFormState.isLoading) {
      return;
    }

    signUpFormNotifier.setLoading(true);

    try {
      AppLogger.info(
        'Attempting signup for email: ${signUpFormState.email.trim()}',
      );

      final response = await authRepository.signUpWithEmailAndPassword(
        email: signUpFormState.email.trim(),
        password: signUpFormState.password,
      );

      if (response.user != null) {
        // Sign up successful
        AppLogger.info('Signup successful for user: ${response.user!.email}');

        if (context.mounted) {
          // Check if email confirmation is required
          if (response.session == null) {
            // Email confirmation required
            AppLogger.info(
              'Email confirmation required for: ${response.user!.email}',
            );
            _showEmailConfirmationDialog(context, signUpFormState.email);
          } else {
            // Account created and signed in
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Account created successfully! Welcome, ${response.user!.email}!',
                ),
                backgroundColor: AppColors.success,
              ),
            );

            // Navigate to main app
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AppShell()),
            );
          }
        }
      } else {
        signUpFormNotifier.setError(
          'Account creation failed. Please try again.',
        );
      }
    } catch (e) {
      _handleSignUpError(e, signUpFormNotifier);
    }
  }

  /// Handle different types of signup errors
  void _handleSignUpError(
    dynamic error,
    SignUpFormNotifier signUpFormNotifier,
  ) {
    final errorMessage = error.toString().toLowerCase();

    // Log the signup error for debugging
    AppLogger.debug('Signup Error Details', error);
    AppLogger.info('Signup Error Message: $errorMessage');

    if (errorMessage.contains('user_already_registered') ||
        errorMessage.contains('email_address_already_in_use') ||
        errorMessage.contains('user already registered')) {
      AppLogger.info('Signup failed: Email already exists');
      signUpFormNotifier.setError(
        'An account with this email already exists. Try signing in instead.',
      );
    } else if (errorMessage.contains('password') &&
        errorMessage.contains('weak')) {
      AppLogger.info('Signup failed: Weak password');
      AppLogger.debug('Sign up failed - weak password: $errorMessage');
      signUpFormNotifier.setError(
        'Password is too weak. Please use a stronger password.',
      );
    } else if (errorMessage.contains('email') &&
        errorMessage.contains('invalid')) {
      AppLogger.debug('Sign up failed - invalid email: $errorMessage');
      signUpFormNotifier.setError('Please enter a valid email address.');
    } else if (errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      AppLogger.warning('Sign up failed - network error: $errorMessage');
      signUpFormNotifier.setError(
        'Network error. Please check your connection.',
      );
    } else {
      // Generic error
      AppLogger.error('Sign up failed - generic error: $errorMessage');
      signUpFormNotifier.setError('Sign up failed. Please try again.');
    }
  }

  /// Show email confirmation dialog
  Future<void> _showEmailConfirmationDialog(
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
              Icon(Icons.email_outlined, color: AppColors.primaryGold),
              const SizedBox(width: 12),
              Text(
                'Verify Your Email',
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
                'We\'ve sent a verification email to:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
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
                'Please check your email and click the verification link to activate your account.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            Container(
              decoration: NeuStyles.neuContainer(
                color: AppColors.primaryGold,
                borderRadius: 12,
                depth: 2,
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(
                  'Go to Login',
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
}
