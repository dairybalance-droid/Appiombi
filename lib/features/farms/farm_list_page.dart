import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class FarmListPage extends ConsumerStatefulWidget {
  const FarmListPage({super.key});

  @override
  ConsumerState<FarmListPage> createState() => _FarmListPageState();
}

class _FarmListPageState extends ConsumerState<FarmListPage> {
  String _searchQuery = '';
  late final Future<List<FarmSummary>> _farmsFuture;

  @override
  void initState() {
    super.initState();
    _farmsFuture = _loadFarms();
  }

  Future<List<FarmSummary>> _loadFarms() async {
    final service = ref.read(supabaseServiceProvider);

    try {
      return await service.fetchAccessibleFarms().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[Appiombi][Farms][UI] Timeout caricamento aziende.');
          throw TimeoutException('Timeout caricamento aziende');
        },
      );
    } on TimeoutException {
      rethrow;
    } catch (error) {
      debugPrint('[Appiombi][Farms][UI] Errore caricamento aziende: $error');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aziende'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final router = GoRouter.of(context);
              await service.signOut();
              if (!mounted) {
                return;
              }
              router.go('/');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Cerca azienda',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<FarmSummary>>(
                future: _farmsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingView(message: 'Caricamento aziende...');
                  }

                  if (snapshot.hasError) {
                    final message = snapshot.error.toString()
                        .replaceFirst('Exception: ', '')
                        .replaceFirst('TimeoutException: ', '');

                    return ErrorView(
                      title: 'Impossibile caricare le aziende',
                      message: message,
                    );
                  }

                  final farms = snapshot.data ?? const <FarmSummary>[];
                  final filtered = farms.where((farm) {
                    final haystack = '${farm.name} ${farm.farmCode}'.toLowerCase();
                    return haystack.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Nessuna azienda disponibile per questo utente.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final farm = filtered[index];
                      return AppCard(
                        onTap: () => context.go('/farms/${farm.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    farm.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                _AccessModeChip(
                                  accessMode: farm.accessMode,
                                  canWrite: farm.canWrite,
                                ),
                              ],
                            ),
                            if (farm.farmCode.isNotEmpty) const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (farm.farmCode.isNotEmpty)
                                  _InfoPill(label: farm.farmCode),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessModeChip extends StatelessWidget {
  const _AccessModeChip({
    required this.accessMode,
    required this.canWrite,
  });

  final String accessMode;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final color = canWrite ? AppColors.success : AppColors.warning;
    final label = canWrite ? 'Scrivibile' : accessMode == 'blocked' ? 'Bloccata' : 'Sola lettura';

    return Chip(
      label: Text(label),
      side: BorderSide(color: color),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
          ),
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
