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
import 'session_mock_data.dart';

class SessionDetailPage extends ConsumerStatefulWidget {
  const SessionDetailPage({
    super.key,
    required this.farmId,
    required this.sessionId,
    required this.sessionType,
    required this.farmName,
  });

  final String farmId;
  final String sessionId;
  final String sessionType;
  final String farmName;

  @override
  ConsumerState<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends ConsumerState<SessionDetailPage> {
  late Future<_SessionDetailData> _sessionFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sessionClosing = false;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _loadSessionData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_SessionDetailData> _loadSessionData() async {
    final service = ref.read(supabaseServiceProvider);
    final results = await Future.wait([
      service.fetchSession(widget.sessionId),
      service.fetchSessionVisits(widget.sessionId),
    ]).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Timeout caricamento sessione'),
    );

    return _SessionDetailData(
      session: results[0] as TrimmingSessionSummary,
      visits: results[1] as List<SessionVisitRow>,
    );
  }

  Future<void> _reloadSessionData() async {
    setState(() {
      _sessionFuture = _loadSessionData();
    });
  }

  Future<void> _openAddCowDialog(_SessionDetailData data) async {
    final controller = TextEditingController();
    String? inlineError;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final navigator = Navigator.of(dialogContext);
              final rawValue = controller.text.trim();
              if (!RegExp(r'^-?\d+$').hasMatch(rawValue)) {
                setDialogState(() {
                  inlineError = 'Inserisci un numero intero valido.';
                });
                return;
              }

              final cowNumber = int.parse(rawValue);
              setDialogState(() {
                submitting = true;
                inlineError = null;
              });

              try {
                final visit = await ref.read(supabaseServiceProvider).createDraftVisit(
                      farmId: widget.farmId,
                      sessionId: widget.sessionId,
                      cowNumber: cowNumber,
                    );

                if (!mounted) {
                  return;
                }

                navigator.pop();
                await this.context.push(
                  '/farms/${widget.farmId}/visits/new'
                  '?cowVisitId=${Uri.encodeComponent(visit.id)}'
                  '&sessionId=${Uri.encodeComponent(widget.sessionId)}'
                  '&sessionType=${Uri.encodeComponent(data.session.sessionTypeLabel)}'
                  '&farmName=${Uri.encodeComponent(widget.farmName)}'
                  '&cowNumber=${Uri.encodeComponent(cowNumber.toString())}',
                );
                await _reloadSessionData();
              } on DuplicateCowNumberException {
                setDialogState(() {
                  inlineError = 'Capo già presente.';
                  submitting = false;
                });
              } catch (error) {
                setDialogState(() {
                  inlineError = 'Errore creazione visita: $error';
                  submitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Nuova visita vacca'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !submitting,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: false,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Numero capo',
                      hintText: 'Es. 101 o -12',
                      errorText: inlineError,
                      suffixIcon: IconButton(
                        onPressed: null,
                        icon: const Icon(Icons.mic_none_rounded),
                        tooltip: 'Microfono non disponibile',
                      ),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: Text(submitting ? 'Attendere...' : 'OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openExistingVisit({
    required String cowVisitId,
    required int cowNumber,
    required String sessionTypeLabel,
  }) async {
    await context.push(
      '/farms/${widget.farmId}/visits/new'
      '?cowVisitId=${Uri.encodeComponent(cowVisitId)}'
      '&sessionId=${Uri.encodeComponent(widget.sessionId)}'
      '&sessionType=${Uri.encodeComponent(sessionTypeLabel)}'
      '&farmName=${Uri.encodeComponent(widget.farmName)}'
      '&cowNumber=${Uri.encodeComponent(cowNumber.toString())}'
      '&mode=edit',
    );
    await _reloadSessionData();
  }

  Future<void> _closeSession(TrimmingSessionSummary session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Fine sessione'),
          content: const Text('Vuoi concludere la sessione?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Prosegui'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() => _sessionClosing = true);
    try {
      if (session.status != 'closed') {
        await ref.read(supabaseServiceProvider).closeSession(sessionId: session.id);
        await _reloadSessionData();
      }

      if (!mounted) {
        return;
      }

      await _showSessionSummaryDialog(
        context: context,
        sessionType: session.sessionTypeLabel,
      );
      if (!mounted) {
        return;
      }
      context.go('/farms/${widget.farmId}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore chiusura sessione: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sessionClosing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackType =
        widget.sessionType.isEmpty ? 'Pareggio di mandria' : widget.sessionType;
    final fallbackFarmName =
        widget.farmName.isEmpty ? 'Azienda selezionata' : widget.farmName;

    return Scaffold(
      appBar: AppBar(
        title: Text(fallbackType),
      ),
      floatingActionButton: FutureBuilder<_SessionDetailData>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          final sessionClosed = snapshot.data?.session.status == 'closed';
          return FloatingActionButton(
            onPressed: _sessionClosing || sessionClosed
                ? null
                : () async {
                    final data = await _sessionFuture;
                    if (!mounted) {
                      return;
                    }
                    await _openAddCowDialog(data);
                  },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.add_rounded),
          );
        },
      ),
      body: FutureBuilder<_SessionDetailData>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Caricamento sessione...');
          }

          if (snapshot.hasError) {
            final message = snapshot.error.toString()
                .replaceFirst('Exception: ', '')
                .replaceFirst('TimeoutException: ', '');
            return ErrorView(
              title: 'Impossibile caricare la sessione',
              message: message,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const ErrorView(
              title: 'Sessione non trovata',
              message: 'La sessione richiesta non è disponibile.',
            );
          }

          final session = data.session;
          final sessionTypeLabel =
              session.sessionTypeLabel.isEmpty ? fallbackType : session.sessionTypeLabel;
          final farmName = fallbackFarmName;
          final allVisits = data.visits;
          final visits = data.visits
              .where(
                (visit) => _searchQuery.isEmpty
                    ? true
                    : visit.cowNumber.toString().contains(_searchQuery),
              )
              .toList();
          final summary = _SessionSummaryMetrics.fromVisits(allVisits);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Data inizio sessione: ${formatItalianDate(session.startedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tipo sessione: $sessionTypeLabel',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Stato sessione: ${session.statusLabel}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SessionCounters(metrics: summary),
                        const SizedBox(height: 18),
                        Text(
                          'Capi registrati nella sessione',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            labelText: 'Cerca capo...',
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (visits.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'Nessun capo inserito in questa sessione.'
                                  : 'Nessun capo trovato con questo filtro.',
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Table(
                                border: TableBorder(
                                  horizontalInside: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  verticalInside: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                columnWidths: const {
                                  0: FixedColumnWidth(64),
                                  1: FixedColumnWidth(96),
                                  2: FixedColumnWidth(240),
                                  3: FixedColumnWidth(130),
                                  4: FixedColumnWidth(82),
                                  5: FixedColumnWidth(82),
                                },
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF0F3F4),
                                    ),
                                    children: const [
                                      _TableHeaderCell('Mod.'),
                                      _TableHeaderCell('N. Capo'),
                                      _TableHeaderCell('Lesione più grave'),
                                      _TableHeaderCell('Farmaci'),
                                      _TableHeaderCell('Suole'),
                                      _TableHeaderCell('Bende'),
                                    ],
                                  ),
                                  for (var i = 0; i < visits.length; i++)
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: i.isEven
                                            ? Colors.white
                                            : const Color(0xFFF9FAFA),
                                      ),
                                      children: [
                                        _TableEditCell(
                                          onPressed: () => _openExistingVisit(
                                            cowVisitId: visits[i].id,
                                            cowNumber: visits[i].cowNumber,
                                            sessionTypeLabel: sessionTypeLabel,
                                          ),
                                        ),
                                        _TableValueCell(visits[i].cowNumber.toString()),
                                        _TableValueCell(visits[i].worstLesion),
                                        _TableValueCell(visits[i].medicationsLabel),
                                        _TableCheckCell(visits[i].solesCount > 0),
                                        _TableCheckCell(visits[i].bandagesCount > 0),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    label: session.status == 'closed'
                        ? 'Sessione chiusa'
                        : 'Fine sessione',
                    onPressed: _sessionClosing || session.status == 'closed'
                        ? null
                        : () => _closeSession(session),
                  ),
                ],
              ),
              if (_sessionClosing)
                const ColoredBox(
                  color: Color(0x66FFFFFF),
                  child: LoadingView(message: 'Chiusura sessione...'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionDetailData {
  const _SessionDetailData({
    required this.session,
    required this.visits,
  });

  final TrimmingSessionSummary session;
  final List<SessionVisitRow> visits;
}

class _SessionSummaryMetrics {
  const _SessionSummaryMetrics({
    required this.totalCows,
    required this.todayCows,
    required this.totalSoles,
    required this.totalBandages,
  });

  final int totalCows;
  final int todayCows;
  final int totalSoles;
  final int totalBandages;

  factory _SessionSummaryMetrics.fromVisits(List<SessionVisitRow> visits) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var todayCows = 0;
    var totalSoles = 0;
    var totalBandages = 0;

    for (final visit in visits) {
      final visitDay = DateTime(
        visit.visitDate.year,
        visit.visitDate.month,
        visit.visitDate.day,
      );
      if (visitDay == today) {
        todayCows += 1;
      }
      totalSoles += visit.solesCount;
      totalBandages += visit.bandagesCount;
    }

    return _SessionSummaryMetrics(
      totalCows: visits.length,
      todayCows: todayCows,
      totalSoles: totalSoles,
      totalBandages: totalBandages,
    );
  }
}

class _SessionCounters extends StatelessWidget {
  const _SessionCounters({required this.metrics});

  final _SessionSummaryMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SessionCounterTile(
          label: 'Capi sessione',
          value: metrics.totalCows.toString(),
        ),
        _SessionCounterTile(
          label: 'Capi oggi',
          value: metrics.todayCows.toString(),
        ),
        _SessionCounterTile(
          label: 'Suole totali',
          value: metrics.totalSoles.toString(),
        ),
        _SessionCounterTile(
          label: 'Bende totali',
          value: metrics.totalBandages.toString(),
        ),
      ],
    );
  }
}

class _SessionCounterTile extends StatelessWidget {
  const _SessionCounterTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F9),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        label,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TableValueCell extends StatelessWidget {
  const _TableValueCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TableCheckCell extends StatelessWidget {
  const _TableCheckCell(this.value);

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Align(
        alignment: Alignment.center,
        child: value
            ? const Icon(Icons.check_rounded, size: 18, color: AppColors.success)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _TableEditCell extends StatelessWidget {
  const _TableEditCell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: IconButton(
        tooltip: 'Modifica capo',
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined, size: 18),
      ),
    );
  }
}

Future<void> _showSessionSummaryDialog({
  required BuildContext context,
  required String sessionType,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riepilogo sessione',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  sessionType,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                const _MockPieChart(),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: const [
                    _SummaryLabel(label: 'Capi visitati: 18'),
                    _SummaryLabel(label: 'Suole: 7'),
                    _SummaryLabel(label: 'Bende: 3'),
                    _SummaryLabel(label: 'Farmaci: 5'),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Torna alla dashboard azienda'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _MockPieChart extends StatelessWidget {
  const _MockPieChart();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CustomPaint(
            painter: _PieChartPainter(),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _LegendRow(color: AppColors.primary, label: 'Lesioni suola'),
              SizedBox(height: 8),
              _LegendRow(color: AppColors.secondary, label: 'Bende'),
              SizedBox(height: 8),
              _LegendRow(color: AppColors.accent, label: 'Terapie'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paints = [
      Paint()..color = AppColors.primary,
      Paint()..color = AppColors.secondary,
      Paint()..color = AppColors.accent,
    ];
    const sections = [2.8, 1.4, 2.0];
    var start = -1.57;
    final total = sections.reduce((a, b) => a + b);

    for (var i = 0; i < sections.length; i++) {
      final sweep = (sections[i] / total) * 6.28318;
      canvas.drawArc(rect.deflate(8), start, sweep, true, paints[i]);
      start += sweep;
    }

    canvas.drawCircle(
      size.center(Offset.zero),
      size.width * 0.22,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  const _SummaryLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
