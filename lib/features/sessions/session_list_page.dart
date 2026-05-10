import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';
import 'session_mock_data.dart';

class SessionListPage extends StatelessWidget {
  const SessionListPage({
    super.key,
    required this.farmId,
    required this.farmName,
  });

  final String farmId;
  final String farmName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Visite precedenti')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppPrimaryButton(
            label: 'Apri ultima sessione',
            onPressed: () => context.go(
              '/farms/$farmId/sessions/${previousSessionRows.first.id}'
              '?type=${Uri.encodeComponent(previousSessionRows.first.sessionType)}'
              '&farmName=${Uri.encodeComponent(farmName)}',
            ),
          ),
          const SizedBox(height: 16),
          ...previousSessionRows.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => context.go(
                  '/farms/$farmId/sessions/${session.id}'
                  '?type=${Uri.encodeComponent(session.sessionType)}'
                  '&farmName=${Uri.encodeComponent(farmName)}',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.dateLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session.sessionType,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _SessionInfoLabel(
                          label: 'Capi visitati: ${session.cowsVisited}',
                        ),
                        _SessionInfoLabel(
                          label: 'Suole: ${session.soleCount}',
                        ),
                        _SessionInfoLabel(
                          label: 'Bende: ${session.bandageCount}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Grafici e statistiche in preparazione.'),
                          ),
                        ),
                        icon: const Icon(Icons.pie_chart_outline_rounded),
                        label: const Text('Grafici e statistiche'),
                      ),
                    ),
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

class _SessionInfoLabel extends StatelessWidget {
  const _SessionInfoLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF223035),
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
