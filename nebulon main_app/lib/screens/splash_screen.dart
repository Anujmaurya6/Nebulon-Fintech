import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/provider/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_signup.dart';
import 'main_navigation.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.checkAuthStatus();

    if (!mounted) return;
    final authState = ref.read(authProvider);

    if (authState.status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.indigo, Color(0xFF2B348D), AppTheme.emerald],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SMART VAULT',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'EXECUTIVE ASSISTANT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.mint,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
