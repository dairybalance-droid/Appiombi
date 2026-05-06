import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';

class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({
    super.key,
    required this.farmId,
    required this.sessionId,
  });

  final String farmId;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio Sessione'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sessione', style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(sessionId, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Placeholder per lista capi visitati, ordinamenti, stato sessione e riapertura.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Apri visita vacca',
            onPressed: () => context.go('/farms/$farmId/visits/new'),
          ),
        ],
      ),
    );
  }
}
