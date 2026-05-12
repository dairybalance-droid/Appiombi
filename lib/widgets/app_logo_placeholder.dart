import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLogoPlaceholder extends StatelessWidget {
  const AppLogoPlaceholder({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: compact ? 76 : 92,
          height: compact ? 76 : 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.balance_rounded,
            color: Colors.white,
            size: compact ? 34 : 42,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          'Appiombi',
          style: compact ? theme.textTheme.headlineSmall : theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'by Dairy Balance',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
