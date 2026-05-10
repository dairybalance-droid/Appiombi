import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'session_mock_data.dart';

class SessionListPage extends ConsumerStatefulWidget {
  const SessionListPage({
    super.key,
    required this.farmId,
    required this.farmName,
  });

  final String farmId;
  final String farmName;

  @override
  ConsumerState<SessionListPage> createState() => _SessionListPageState();
}

class _SessionListPageState extends ConsumerState<SessionListPage> {
  late Future<List<SessionHistoryRow>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _loadSessions();
  }

  Future<List<SessionHistoryRow>> _loadSessions() {
    final service = ref.read(supabaseServiceProvider);
    return service.fetchSessionsForFarm(widget.farmId).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Timeout caricamento sessioni'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Visite precedenti')),
      body: FutureBuilder<List<SessionHistoryRow>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Caricamento sessioni...');
          }

          if (snapshot.hasError) {
            final message = snapshot.error.toString()
                .replaceFirst('Exception: ', '')
                .replaceFirst('TimeoutException: ', '');
            return ErrorView(
              title: 'Impossibile caricare le sessioni',
              message: message,
            );
          }

          final sessions = snapshot.data ?? const <SessionHistoryRow>[];
          if (sessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nessuna sessione disponibile per questa azienda.'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppPrimaryButton(
                label: 'Apri ultima sessione',
                onPressed: () => _openSession(context, sessions.first),
              ),
              const SizedBox(height: 16),
              ...sessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => _openSession(context, session),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatItalianDate(session.startedAt),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          session.sessionTypeLabel,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Stato: ${sessionStatusCodeToLabel(session.status)}',
                          style: theme.textTheme.bodySmall,
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
          );
        },
      ),
    );
  }

  void _openSession(BuildContext context, SessionHistoryRow session) {
    context.go(
      '/farms/${widget.farmId}/sessions/${session.id}'
      '?type=${Uri.encodeComponent(session.sessionTypeLabel)}'
      '&farmName=${Uri.encodeComponent(widget.farmName)}',
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
