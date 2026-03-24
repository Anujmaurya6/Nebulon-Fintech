import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../theme/app_theme.dart';

class SuccessOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onComplete;

  const SuccessOverlay({
    super.key,
    required this.message,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.indigo.withValues(alpha: 0.9),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://assets10.lottiefiles.com/packages/lf20_ovws8and.json', // Standard success check
            repeat: false,
            onLoaded: (composition) {
              Future.delayed(composition.duration + const Duration(milliseconds: 500), onComplete);
            },
            errorBuilder: (context, error, stackTrace) {
              // Fallback if network fails
              return const Icon(Icons.check_circle, color: AppTheme.emerald, size: 100);
            },
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
