import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class CowListPage extends ConsumerWidget {
  const CowListPage({
    super.key,
    required this.farmId,
  });

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cowsAsync = ref.watch(cowsByFarmProvider(farmId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lista Vacche')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: cowsAsync.when(
          data: (cows) {
            if (cows.isEmpty) {
              return Center(
                child: Text(
                  'Nessuna vacca disponibile.',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            return ListView.separated(
              itemCount: cows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cow = cows[index];
                return AppCard(
                  onTap: () => context.go('/farms/$farmId/visits/new'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(cow.displayIdentifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Capo ${cow.displayIdentifier}',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID interno: ${cow.identifier}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const LoadingView(message: 'Caricamento vacche...'),
          error: (error, _) => ErrorView(
            title: 'Impossibile caricare le vacche',
            message: error.toString(),
          ),
        ),
      ),
    );
  }
}
