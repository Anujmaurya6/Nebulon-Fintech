import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/security/lock_service.dart';
import '../theme/app_theme.dart';


class LockScreen extends ConsumerStatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with WidgetsBindingObserver {
  bool _isLocked = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lock();
    } else if (state == AppLifecycleState.resumed) {
      _checkLockStatus();
    }
  }

  Future<void> _lock() async {
    final lockService = ref.read(lockServiceProvider);
    if (await lockService.isBiometricEnabled()) {
      setState(() => _isLocked = true);
    }
  }

  Future<void> _checkLockStatus() async {
    final lockService = ref.read(lockServiceProvider);
    if (await lockService.isBiometricEnabled()) {
      _authenticate();
    } else {
      setState(() => _isLocked = false);
    }
  }

  Future<void> _authenticate() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    
    final lockService = ref.read(lockServiceProvider);
    final success = await lockService.authenticate();
    
    if (success) {
      setState(() {
        _isLocked = false;
        _isChecking = false;
      });
    } else {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) return widget.child;

    return Scaffold(
      body: Stack(
        children: [
          // Background content (blurred)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: widget.child,
          ),
          
          // Glass Overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.indigo.withValues(alpha: 0.8),
            ),
          ),
          
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 20))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Nebulon Vault',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white, fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'AUTHORIZED ACCESS ONLY',
                        style: TextStyle(color: AppTheme.mint, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 48),
                      if (_isChecking)
                        const CircularProgressIndicator(color: AppTheme.mint)
                      else
                        ElevatedButton.icon(
                          onPressed: _authenticate,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Unlock Vault'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.indigo,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

