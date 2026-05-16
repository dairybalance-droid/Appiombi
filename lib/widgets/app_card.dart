import 'package:flutter/material.dart';

import '../theme/app_responsive.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardChild = Padding(
      padding: AppResponsive.cardPadding(context),
      child: child,
    );

    return Card(
      child: onTap == null
          ? cardChild
          : InkWell(
              borderRadius: BorderRadius.circular(
                AppResponsive.isCompact(context) ? 10 : 12,
              ),
              onTap: onTap,
              child: cardChild,
            ),
    );
  }
}
