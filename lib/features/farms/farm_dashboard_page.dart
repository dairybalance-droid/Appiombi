import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class FarmDashboardPage extends ConsumerStatefulWidget {
  const FarmDashboardPage({
    super.key,
    required this.farmId,
  });

  final String farmId;

  @override
  ConsumerState<FarmDashboardPage> createState() => _FarmDashboardPageState();
}

class _FarmDashboardPageState extends ConsumerState<FarmDashboardPage> {
  late final Future<FarmSummary?> _farmFuture;

  @override
  void initState() {
    super.initState();
    _farmFuture = _loadFarm();
  }

  Future<FarmSummary?> _loadFarm() async {
    final service = ref.read(supabaseServiceProvider);
    final farms = await service.fetchAccessibleFarms().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Timeout caricamento azienda'),
    );

    for (final farm in farms) {
      if (farm.id == widget.farmId) {
        return farm;
      }
    }

    return null;
  }

  Future<void> _showNewSessionDialog(BuildContext context) async {
    final options = <String>[
      'Pareggio di mandria',
      'Pareggio su selezione',
      'Sessione urgenze',
      'Sessione ricontrolli',
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nuova sessione'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$option in preparazione.')),
                    );
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Indietro'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
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
      body: FutureBuilder<FarmSummary?>(
        future: _farmFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Caricamento azienda...');
          }

          if (snapshot.hasError) {
            final message = snapshot.error.toString()
                .replaceFirst('Exception: ', '')
                .replaceFirst('TimeoutException: ', '');

            return ErrorView(
              title: 'Impossibile aprire l\'azienda',
              message: message,
            );
          }

          final farm = snapshot.data;
          if (farm == null) {
            return const ErrorView(
              title: 'Azienda non trovata',
              message: 'La farm selezionata non e disponibile per questo utente.',
            );
          }

          return _DashboardBody(
            farm: farm,
            onNewSession: () => _showNewSessionDialog(context),
          );
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.farm,
    required this.onNewSession,
  });

  final FarmSummary farm;
  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 980;
        final mediumLayout = constraints.maxWidth >= 700;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            mediumLayout ? 28 : 20,
            8,
            mediumLayout ? 28 : 20,
            28,
          ),
          children: [
            _FarmHeroCard(
              farm: farm,
              onNewSession: onNewSession,
            ),
            const SizedBox(height: 18),
            _QuickActionsRow(farmId: farm.id),
            const SizedBox(height: 18),
            if (wideLayout)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    flex: 5,
                    child: _LatestChartCard(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _PreviousVisitsCard(farmId: farm.id),
                  ),
                ],
              )
            else ...[
              const _LatestChartCard(),
              const SizedBox(height: 16),
              _PreviousVisitsCard(farmId: farm.id),
            ],
            const SizedBox(height: 18),
            _ObservationSection(wideLayout: wideLayout),
          ],
        );
      },
    );
  }
}

class _FarmHeroCard extends StatelessWidget {
  const _FarmHeroCard({
    required this.farm,
    required this.onNewSession,
  });

  final FarmSummary farm;
  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            farm.name,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Indirizzo non impostato',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (farm.farmCode.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Codice azienda: ${farm.farmCode}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'Nuova sessione',
            onPressed: onNewSession,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _QuickActionCard(
          icon: Icons.pets_outlined,
          title: 'Lista vacche',
          subtitle: 'Apri l\'elenco capi e consulta rapidamente gli ID disponibili.',
          onTap: () => context.go('/farms/$farmId/cows'),
        ),
        _QuickActionCard(
          icon: Icons.history_rounded,
          title: 'Visite precedenti',
          subtitle: 'Accedi allo storico delle sessioni gia registrate.',
          onTap: () => context.go('/farms/$farmId/sessions'),
        ),
        _QuickActionCard(
          icon: Icons.edit_note_rounded,
          title: 'Visita vacca base',
          subtitle: 'Apri la compilazione base per una visita singola.',
          onTap: () => context.go('/farms/$farmId/visits/new'),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 280,
      child: AppCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviousVisitsCard extends StatelessWidget {
  const _PreviousVisitsCard({required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => context.go('/farms/$farmId/sessions'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Visite precedenti',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Apri l\'elenco delle sessioni archiviate con data, tipologia, capi visitati, suole, bende e accesso ai grafici.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/farms/$farmId/sessions'),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Apri storico sessioni'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestChartCard extends StatelessWidget {
  const _LatestChartCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const bars = <_ChartBarData>[
      _ChartBarData(
        label: 'Lesioni suola',
        value: 0.72,
        color: AppColors.primary,
      ),
      _ChartBarData(
        label: 'Bende',
        value: 0.34,
        color: AppColors.secondary,
      ),
      _ChartBarData(
        label: 'Terapie',
        value: 0.41,
        color: AppColors.accent,
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ultima sessione: Pareggio di mandria',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatItalianDate(DateTime(2026, 5, 6)),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Text(
            'Distribuzione lesioni / interventi',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Grafico dell\'ultima sessione di pareggio',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          for (final bar in bars) ...[
            _ChartBar(bar: bar),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ObservationSection extends StatelessWidget {
  const _ObservationSection({required this.wideLayout});

  final bool wideLayout;

  @override
  Widget build(BuildContext context) {
    final cards = [
      const _ObservationTableCard(
        title: 'Terapie farmacologiche',
        subtitle: 'Monitoraggio trattamenti da completare.',
        rows: [
          ['789', 'Si', 'Controllo serale', 'No'],
          ['234', 'No', 'Buona risposta', 'Si'],
          ['101', 'Si', 'Valutare zoppia', 'Si'],
        ],
        headers: ['Capo', 'Antibiotico', 'Suggerito', 'Antinfiammatorio'],
      ),
      const _ObservationTableCard(
        title: 'Ricontrolli 15/20 giorni',
        subtitle: 'Capi da rivedere nel medio periodo.',
        rows: [
          ['234', 'Posteriore destro', '2', '1'],
          ['101', 'Anteriore sinistro', '1', '0'],
          ['789', 'Posteriore sinistro', '2', '1'],
        ],
        headers: ['Capo', 'Sede', 'Suole', 'Bende'],
      ),
      const _ObservationTableCard(
        title: 'Togli bende 3/5 giorni',
        subtitle: 'Promemoria rapido per medicazioni in corso.',
        rows: [
          ['789', 'Posteriore destro'],
          ['234', 'Anteriore sinistro'],
          ['101', 'Posteriore sinistro'],
        ],
        headers: ['Capo', 'Sede'],
      ),
    ];

    if (wideLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    }

    if (!wideLayout && rowsCanSplit(context)) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 16),
          cards[2],
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i < cards.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  bool rowsCanSplit(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 760;
  }
}

class _ObservationTableCard extends StatelessWidget {
  const _ObservationTableCard({
    required this.title,
    required this.subtitle,
    required this.headers,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final widths = <double>[
      92,
      for (var i = 1; i < headers.length; i++)
        headers.length == 2 ? 180 : 140,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: {
                  for (var i = 0; i < widths.length; i++)
                    i: FixedColumnWidth(widths[i]),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F3F4),
                    ),
                    children: [
                      for (final header in headers)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            header,
                            textAlign: TextAlign.left,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: rowIndex.isEven
                            ? Colors.white
                            : const Color(0xFFF9FAFA),
                      ),
                      children: [
                        for (final cell in rows[rowIndex])
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.border),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Text(
                              cell,
                              textAlign: TextAlign.left,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.bar});

  final _ChartBarData bar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                bar.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${(bar.value * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: bar.value,
            minHeight: 12,
            backgroundColor: AppColors.border.withValues(alpha: 0.55),
            valueColor: AlwaysStoppedAnimation<Color>(bar.color),
          ),
        ),
      ],
    );
  }
}

class _ChartBarData {
  const _ChartBarData({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

String _formatItalianDate(DateTime date) {
  const months = [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];

  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
