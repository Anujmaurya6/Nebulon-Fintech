import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/widgets/animated_counter.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final String prefix;
  final String percent;
  final bool isPositive;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.prefix = '',
    required this.percent,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = isPositive ? AppTheme.emerald : AppTheme.rose;

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
            color: Colors.black.withOpacity(0.02),
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
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: statusColor,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      percent,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedCounter(
            value: value,
            prefix: prefix,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
