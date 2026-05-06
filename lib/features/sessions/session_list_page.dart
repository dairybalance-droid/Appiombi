import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';

class SessionListPage extends StatelessWidget {
  const SessionListPage({
    super.key,
    required this.farmId,
  });

  final String farmId;

  @override
  Widget build(BuildContext context) {
    final sessions = const [
      ('new-session', 'Nuova sessione placeholder'),
      ('session-demo-1', 'Sessione demo 1'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Sessioni di Pareggio')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppPrimaryButton(
            label: 'Apri nuova sessione',
            onPressed: () => context.go('/farms/$farmId/sessions/new-session'),
          ),
          const SizedBox(height: 16),
          ...sessions.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => context.go('/farms/$farmId/sessions/${session.$1}'),
                child: Row(
                  children: [
                    const Icon(Icons.content_cut_rounded),
                    const SizedBox(width: 12),
                    Expanded(child: Text(session.$2)),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
