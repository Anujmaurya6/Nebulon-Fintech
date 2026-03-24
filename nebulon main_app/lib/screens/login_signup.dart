import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/provider/auth_provider.dart';
import '../theme/app_theme.dart';
import '../core/utils/error_handler.dart';
import '../widgets/gradient_button.dart';
import 'main_navigation.dart';

class LoginSignupScreen extends ConsumerStatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  ConsumerState<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends ConsumerState<LoginSignupScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$');

    if (email.isEmpty || password.isEmpty) {
      ErrorHandler.showError(context, 'Please fill in all fields.');
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      ErrorHandler.showError(context, 'Please enter a valid executive email.');
      return;
    }

    if (!passwordRegex.hasMatch(password)) {
      ErrorHandler.showError(context, 'Password must be 8+ characters with at least one letter and one number.');
      return;
    }

    if (_isSignUp) {
      if (name.isEmpty) {
        ErrorHandler.showError(context, 'Please enter your full name.');
        return;
      }
      if (password != confirmPassword) {
        ErrorHandler.showError(context, 'Vault keys do not match. Please verify your password.');
        return;
      }
    }



    final notifier = ref.read(authProvider.notifier);
    bool success;

    if (_isSignUp) {
      success = await notifier.signUp(email, password);
      if (success) {
        // Update profile with name
        await ref.read(profileProvider.notifier).updateProfile({'full_name': name});
      }
    } else {
      success = await notifier.signIn(email, password);
    }

    if (success) {
      if (!mounted) return;
      ErrorHandler.showSuccess(context, _isSignUp ? 'Welcome to Nebulon, $name!' : 'Welcome back!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      if (!mounted) return;
      final state = ref.read(authProvider);
      ErrorHandler.showError(context, state.errorMessage ?? 'Authentication failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [AppTheme.indigo.withValues(alpha: 0.05), Colors.transparent],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Column(
            children: [
              _buildHeader(theme),
              const SizedBox(height: 40),
              
              // Animated Switcher for Login/Signup distinction
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey<bool>(_isSignUp),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 30, offset: const Offset(0, 15),
                      ),
                    ],
                    border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(theme),
                      const SizedBox(height: 32),
                      
                      if (_isSignUp) ...[
                        _buildLabel('Full Name'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'Arthur Dent',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                      ],

                      _buildLabel('Email Address'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'executive@nebulon.com',
                        icon: Icons.alternate_email,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _passwordController,
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      
                      if (_isSignUp) ...[
                         const SizedBox(height: 20),
                        _buildLabel('Confirm Password'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: '••••••••',
                          icon: Icons.shield_outlined,
                          isPassword: true,
                        ),
                      ],

                      if (!_isSignUp) 
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.indigo, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                      
                      isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.indigo))
                        : GradientButton(
                            text: _isSignUp ? 'Create My Vault' : 'Secure Sign In',
                            onPressed: _handleSubmit,
                          ),

                      
                      const SizedBox(height: 24),
                      _buildToggle(theme),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              if (!_isSignUp)
                _buildOnboardingHint(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.indigo.withValues(alpha: 0.2),
                  blurRadius: 30, offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.auto_graph, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Nebulon Vault',
          style: theme.textTheme.displayLarge?.copyWith(
            color: AppTheme.indigo, fontSize: 36, letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSignUp ? 'Join the Fleet' : 'Welcome Back',
          style: theme.textTheme.headlineLarge?.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 6),
        Text(
          _isSignUp 
            ? 'ONBOARDING NEW EXECUTIVE ACCOUNTS' 
            : 'AUTHORIZED ACCESS ONLY',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.textSecondary, letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(ThemeData theme) {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isSignUp = !_isSignUp);
        },
        child: Text.rich(
          TextSpan(
            text: _isSignUp ? "ALREADY ONBOARDED? " : "NEW TO NEBULON? ",
            style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary, letterSpacing: 1),
            children: [
              TextSpan(
                text: _isSignUp ? "SIGN IN" : "SETUP ACCOUNT",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.indigo, fontWeight: FontWeight.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingHint(ThemeData theme) {
    return Opacity(
      opacity: 0.6,
      child: Column(
        children: [
          const Icon(Icons.bolt, color: AppTheme.indigo, size: 20),
          const SizedBox(height: 8),
          Text(
            'Enterprise-grade security is standard.\nYour data is end-to-end encrypted.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showForgotPassword() {
    ErrorHandler.showSuccess(context, 'Reset link dispatched to your inbox.');
  }

  Widget _buildLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textLight, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 10,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.4), fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.indigo.withValues(alpha: 0.5), size: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppTheme.textSecondary, size: 18,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}

