import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SelectionCard extends StatelessWidget {
  final String label;
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectionCard({
    super.key,
    required this.label,
    required this.title,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.indigo : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.indigo
                  : AppTheme.borderLight.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.indigo,
                size: 20,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? Colors.white.withOpacity(0.7)
                      : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
