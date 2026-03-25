import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.indigo : AppTheme.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: isUser ? const Radius.circular(24) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(24),
          ),
          border: isUser
              ? null
              : Border.all(color: AppTheme.borderLight.withOpacity(0.1)),
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.indigo.withOpacity(0.04),
                    blurRadius: 40,
                  ),
                ],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
