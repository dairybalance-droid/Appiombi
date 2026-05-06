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
    final cardChild = Padding(
      padding: const EdgeInsets.all(18),
      child: child,
    );

    return Card(
      child: onTap == null
          ? cardChild
          : InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: cardChild,
            ),
    );
  }
}
