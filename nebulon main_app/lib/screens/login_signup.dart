import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../features/auth/provider/auth_provider.dart';
import '../features/profile/provider/profile_provider.dart';
import '../theme/app_theme.dart';
import '../core/utils/error_handler.dart';
import 'main_navigation.dart';
import '../core/widgets/premium_pressable.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import 'package:dio/dio.dart';

class LoginSignupScreen extends ConsumerStatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  ConsumerState<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends ConsumerState<LoginSignupScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSignUp = false;
  String? _codeVerifier; // PKCE code verifier

  @override
  void initState() {
    super.initState();
    // Check URL for OAuth callback (insforge_code)
    _handleOAuthCallback();
  }

  /// Handle the OAuth callback when the page loads with insforge_code
  Future<void> _handleOAuthCallback() async {
    final uri = Uri.parse(html.window.location.href);
    final insforgeCode = uri.queryParameters['insforge_code'];

    if (insforgeCode != null && insforgeCode.isNotEmpty) {
      // Retrieve the stored code_verifier
      final storedVerifier = html.window.sessionStorage['pkce_code_verifier'];

      if (storedVerifier != null && storedVerifier.isNotEmpty) {
        // Exchange code for tokens
        try {
          final apiClient = ApiClient();
          final result = await apiClient.post(
            ApiConstants.oauthExchange,
            data: {'code': insforgeCode, 'code_verifier': storedVerifier},
          );

          if (result['error'] == null && result['data'] != null) {
            final data = result['data'];
            final accessToken = data['accessToken'];

            if (accessToken != null) {
              await apiClient.saveToken(accessToken);

              // Clean up
              html.window.sessionStorage.remove('pkce_code_verifier');
              // Remove query params from URL
              html.window.history.replaceState(null, '', '/');

              if (mounted) {
                ErrorHandler.showSuccess(context, 'Login successful!');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                );
              }
              return;
            }
          }

          if (mounted) {
            ErrorHandler.showError(
              context,
              result['error'] ?? 'OAuth exchange failed',
            );
          }
        } catch (e) {
          if (mounted) ErrorHandler.showError(context, 'OAuth error: $e');
        }

        // Clean up on failure
        html.window.sessionStorage.remove('pkce_code_verifier');
        html.window.history.replaceState(null, '', '/');
      }
    }
  }

  /// Generate a random code_verifier for PKCE
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// Generate code_challenge from code_verifier using SHA256
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<void> _launchOAuth(String provider) async {
    try {
      // 1. Generate PKCE code verifier and challenge
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // 2. Store code_verifier in sessionStorage for use after redirect
      html.window.sessionStorage['pkce_code_verifier'] = codeVerifier;

      // 3. Set redirect_uri to current origin (Flutter web app)
      final redirectUri = html.window.location.origin;

      // 4. Call Insforge API to get the auth URL
      final apiClient = ApiClient();
      final result = await apiClient.get(
        ApiConstants.oauthInitiate(provider),
        queryParams: {
          'redirect_uri': redirectUri,
          'code_challenge': codeChallenge,
        },
      );

      if (result['error'] != null) {
        if (mounted)
          ErrorHandler.showError(context, 'OAuth error: ${result['error']}');
        return;
      }

      final data = result['data'];
      final authUrl = data?['authUrl'] ?? data?['url'];

      if (authUrl != null) {
        // 5. Redirect user to provider's auth page
        html.window.location.href = authUrl;
      } else {
        if (mounted) ErrorHandler.showError(context, 'Could not get auth URL');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'OAuth error: $e');
    }
  }

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

    if (email.isEmpty || password.isEmpty) {
      ErrorHandler.showError(context, 'Field keys required.');
      return;
    }

    if (_isSignUp) {
      if (name.isEmpty) {
        ErrorHandler.showError(context, 'Name required for onboarding.');
        return;
      }
      if (password != confirmPassword) {
        ErrorHandler.showError(context, 'Vault keys mismatch.');
        return;
      }
    }

    final notifier = ref.read(authProvider.notifier);
    bool success;

    if (_isSignUp) {
      success = await notifier.signUp(email, password);
      if (success) {
        await ref.read(profileProvider.notifier).updateProfile({
          'full_name': name,
        });
      }
    } else {
      success = await notifier.signIn(email, password);
    }

    if (success) {
      if (!mounted) return;
      ErrorHandler.showSuccess(
        context,
        _isSignUp ? 'Welcome, $name' : 'Access Granted',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      if (!mounted) return;
      final state = ref.read(authProvider);
      ErrorHandler.showError(context, state.errorMessage ?? 'Auth failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 40),
                  _buildAuthCard(context, theme, isLoading),
                  const SizedBox(height: 32),
                  _buildFooterToggle(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.indigo.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: AppTheme.s24),
        Text(
          'Smart Vault',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: AppTheme.slate900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Secure Financial Intelligence',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1.5,
            color: AppTheme.slate600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard(BuildContext context, ThemeData theme, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Create Vault' : 'Welcome Back',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSignUp
                ? 'Start your journey towards financial freedom'
                : 'Sign in to access your secure vault',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.slate400,
            ),
          ),
          const SizedBox(height: 32),

          if (_isSignUp) ...[
            _buildInputField(
              context,
              'FULL NAME',
              _nameController,
              Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
          ],
          _buildInputField(
            context,
            'EMAIL',
            _emailController,
            Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            context,
            'VAULT KEY',
            _passwordController,
            Icons.lock_outline_rounded,
            isPassword: true,
          ),

          if (_isSignUp) ...[
            const SizedBox(height: 20),
            _buildInputField(
              context,
              'CONFIRM KEY',
              _confirmPasswordController,
              Icons.shield_outlined,
              isPassword: true,
            ),
          ],

          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5B5DF5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isSignUp ? 'INITIALIZE VAULT' : 'AUTHORIZE ACCESS',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider(color: AppTheme.slate200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR LOGIN USING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.slate400,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppTheme.slate200)),
            ],
          ),
          const SizedBox(height: 24),
          _buildOAuthButton(
            'Google',
            '🔵',
            Colors.transparent,
            () => _launchOAuth('google'),
          ),
          const SizedBox(height: 12),
          _buildOAuthButton(
            'GitHub',
            '⚫',
            Colors.transparent,
            () => _launchOAuth('github'),
          ),

          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔒', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Text(
                'Secured by Insforge',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.slate400,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOAuthButton(
    String provider,
    String symbol,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(symbol, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(
              'Continue with $provider',
              style: const TextStyle(
                color: AppTheme.slate800,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: AppTheme.slate400, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: AppTheme.slate400),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 18,
                      color: AppTheme.slate400,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF5B5DF5),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterToggle(ThemeData theme) {
    return PremiumPressable(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isSignUp = !_isSignUp);
      },
      child: Text.rich(
        TextSpan(
          text: _isSignUp ? "Already have a vault? " : "First time here? ",
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.slate400),
          children: [
            TextSpan(
              text: _isSignUp ? "Sign In" : "Initialize Now",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
