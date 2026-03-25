import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final bool isNegative;

  const ActivityItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.isNegative,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNegative
                  ? Icons.shopping_cart_outlined
                  : Icons.payments_outlined,
              color: AppTheme.indigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isNegative ? AppTheme.error : AppTheme.success,
                ),
              ),
              Text(
                status.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
