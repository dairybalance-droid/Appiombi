import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';

class FarmDashboardPage extends StatelessWidget {
  const FarmDashboardPage({
    super.key,
    required this.farmId,
  });

  final String farmId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Azienda'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Azienda selezionata', style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  farmId,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Placeholder MVP per dashboard azienda, task aperti, ultime sessioni e ricerca capo.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: _DashboardMetric(
                    title: 'Task aperti',
                    value: '4',
                    accentColor: AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  child: _DashboardMetric(
                    title: 'Ultime sessioni',
                    value: '2',
                    accentColor: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'Nuova sessione',
            onPressed: () => context.go('/farms/$farmId/sessions/new-session'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/farms/$farmId/cows'),
            icon: const Icon(Icons.pets_outlined),
            label: const Text('Lista vacche'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/farms/$farmId/sessions'),
            icon: const Icon(Icons.event_note_outlined),
            label: const Text('Sessioni'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/farms/$farmId/visits/new'),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Visita vacca base'),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  final String title;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Text(
          value,
          style: theme.textTheme.headlineLarge?.copyWith(color: accentColor),
        ),
      ],
    );
  }
}
