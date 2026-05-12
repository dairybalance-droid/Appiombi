import 'package:flutter/material.dart';

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
    final compact = MediaQuery.sizeOf(context).width < 520;
    final cardChild = Padding(
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: child,
    );

    return Card(
      child: onTap == null
          ? cardChild
          : InkWell(
              borderRadius: BorderRadius.circular(compact ? 10 : 12),
              onTap: onTap,
              child: cardChild,
            ),
    );
  }
}
