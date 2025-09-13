import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../ui/components/app_components.dart';
import 'login_screen.dart';

/// Sign Up Screen
///
/// Provides user registration with email/password and neomorphic gold design
/// Features:
/// - Email, password, and confirm password fields
/// - Display name input
/// - Sign up button with loading state
/// - Password strength indicator
/// - Navigate to login screen
/// - Error handling and validation
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  // Password strength
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _passwordController.addListener(_checkPasswordStrength);

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildSignUpForm(),
                  const SizedBox(height: 24),
                  _buildLoginPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Back button
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios, color: AppColors.textSecondary),
            ),
          ],
        ),

        // App logo/icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [AppColors.primaryShadow, AppColors.primaryGlow],
          ),
          child: const Icon(Icons.auto_awesome, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Create Account',
          style: AppTextStyles.headingLarge.copyWith(
            foreground: Paint()
              ..shader = AppColors.primaryGradient.createShader(
                const Rect.fromLTWH(0, 0, 200, 70),
              ),
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Join the AI asset creation revolution',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display name field
              NeomorphicContainer(
                padding: const EdgeInsets.all(20),
                child: TextFormField(
                  controller: _displayNameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Display Name (Optional)',
                    hintText: 'Enter your display name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.primaryGold,
                    ),
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),

              // Email field
              NeomorphicContainer(
                padding: const EdgeInsets.all(20),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryGold,
                    ),
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                  ),
                  style: AppTextStyles.bodyMedium,
                  validator: _validateEmail,
                ),
              ),
              const SizedBox(height: 20),

              // Password field
              NeomorphicContainer(
                padding: const EdgeInsets.all(20),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.primaryGold,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                  ),
                  style: AppTextStyles.bodyMedium,
                  validator: _validatePassword,
                ),
              ),
              const SizedBox(height: 12),

              // Password strength indicator
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 20),

              // Confirm password field
              NeomorphicContainer(
                padding: const EdgeInsets.all(20),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.primaryGold,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                  ),
                  style: AppTextStyles.bodyMedium,
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) => _handleSignUp(authProvider),
                ),
              ),
              const SizedBox(height: 20),

              // Terms and conditions checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    activeColor: AppColors.primaryGold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'I agree to the ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' and ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Error message
              if (authProvider.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentDeepOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentDeepOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.accentDeepOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authProvider.error!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentDeepOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Sign up button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: authProvider.isLoading
                      ? 'Creating Account...'
                      : 'Create Account',
                  onPressed: (authProvider.isLoading || !_acceptTerms)
                      ? null
                      : () => _handleSignUp(authProvider),
                  isLoading: authProvider.isLoading,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _passwordStrength,
                backgroundColor: AppColors.backgroundDark.withValues(
                  alpha: 0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getPasswordStrengthColor(),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _passwordStrengthText,
              style: AppTextStyles.bodySmall.copyWith(
                color: _getPasswordStrengthColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: Text(
            'Sign In',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    double strength = 0.0;
    String strengthText = '';

    if (password.isEmpty) {
      strength = 0.0;
      strengthText = '';
    } else if (password.length < 6) {
      strength = 0.2;
      strengthText = 'Too Short';
    } else if (password.length < 8) {
      strength = 0.4;
      strengthText = 'Weak';
    } else {
      strength = 0.6;
      strengthText = 'Good';

      // Check for additional criteria
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.1;
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.1;
      if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;

      if (strength >= 0.8) {
        strengthText = 'Strong';
      } else if (strength >= 0.7) {
        strengthText = 'Good';
      }
    }

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
      _passwordStrengthText = strengthText;
    });
  }

  Color _getPasswordStrengthColor() {
    if (_passwordStrength <= 0.3) {
      return AppColors.accentDeepOrange;
    } else if (_passwordStrength <= 0.6) {
      return Colors.orange;
    } else {
      return AppColors.accentTeal;
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  Future<void> _handleSignUp(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please accept the Terms of Service and Privacy Policy',
          ),
          backgroundColor: AppColors.accentDeepOrange,
        ),
      );
      return;
    }

    authProvider.clearError();

    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim().isNotEmpty
          ? _displayNameController.text.trim()
          : null,
    );

    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Account created successfully! Welcome to AssetCraft AI!',
          ),
          backgroundColor: AppColors.accentTeal,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigation will be handled by main.dart auth state listening
      Navigator.of(context).pop();
    }
  }
}
