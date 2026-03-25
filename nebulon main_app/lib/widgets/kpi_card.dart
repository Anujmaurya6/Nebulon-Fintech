import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double progress;
  final bool isAnimated;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.progress,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: theme.cardTheme.shape is RoundedRectangleBorder
            ? Border.fromBorderSide(
                (theme.cardTheme.shape as RoundedRectangleBorder).side,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 14),
              ),
              if (progress > 0)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.onSurface.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
