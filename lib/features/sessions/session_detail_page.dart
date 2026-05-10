import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';
import 'session_mock_data.dart';

class SessionDetailPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedType = sessionType.isEmpty ? 'Pareggio di mandria' : sessionType;
    final resolvedFarmName = farmName.isEmpty ? 'Azienda selezionata' : farmName;

    return Scaffold(
      appBar: AppBar(
        title: Text(resolvedType),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(
          '/farms/$farmId/visits/new'
          '?sessionId=${Uri.encodeComponent(sessionId)}'
          '&sessionType=${Uri.encodeComponent(resolvedType)}'
          '&farmName=${Uri.encodeComponent(resolvedFarmName)}',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolvedFarmName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Data sessione: 10 maggio 2026',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tipo sessione: $resolvedType',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capi registrati nella sessione',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                      columnWidths: const {
                        0: FixedColumnWidth(62),
                        1: FixedColumnWidth(92),
                        2: FixedColumnWidth(180),
                        3: FixedColumnWidth(120),
                        4: FixedColumnWidth(80),
                        5: FixedColumnWidth(80),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F3F4),
                          ),
                          children: [
                            _tableHeaderCell('Mod.'),
                            _tableHeaderCell('N. Capo'),
                            _tableHeaderCell('Lesione piu grave'),
                            _tableHeaderCell('Farmaci'),
                            _tableHeaderCell('Suole'),
                            _tableHeaderCell('Bende'),
                          ],
                        ),
                        for (var i = 0; i < sessionCowEntries.length; i++)
                          TableRow(
                            decoration: BoxDecoration(
                              color: i.isEven ? Colors.white : const Color(0xFFF9FAFA),
                            ),
                            children: [
                              _tableEditCell(
                                context: context,
                                farmId: farmId,
                                sessionId: sessionId,
                                sessionType: resolvedType,
                                cowNumber: sessionCowEntries[i].cowNumber,
                                farmName: resolvedFarmName,
                              ),
                              _tableValueCell(sessionCowEntries[i].cowNumber),
                              _tableValueCell(sessionCowEntries[i].worstLesion),
                              _tableValueCell(sessionCowEntries[i].medications),
                              _tableCheckCell(sessionCowEntries[i].hasSole),
                              _tableCheckCell(sessionCowEntries[i].hasBandage),
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
            label: 'Fine sessione',
            onPressed: () => _showCloseSessionDialog(
              context: context,
              sessionType: resolvedType,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _tableHeaderCell(String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

Widget _tableValueCell(String value) {
  return Container(
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: AppColors.border),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    child: Text(
      value,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
      ),
    ),
  );
}

Widget _tableCheckCell(bool value) {
  return Container(
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: AppColors.border),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    child: value
        ? const Icon(Icons.check_rounded, size: 18, color: AppColors.success)
        : const SizedBox.shrink(),
  );
}

Widget _tableEditCell({
  required BuildContext context,
  required String farmId,
  required String sessionId,
  required String sessionType,
  required String cowNumber,
  required String farmName,
}) {
  return Container(
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: AppColors.border),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: IconButton(
      tooltip: 'Modifica capo',
      onPressed: () => context.go(
        '/farms/$farmId/visits/new'
        '?mode=edit'
        '&sessionId=${Uri.encodeComponent(sessionId)}'
        '&sessionType=${Uri.encodeComponent(sessionType)}'
        '&cowNumber=${Uri.encodeComponent(cowNumber)}'
        '&farmName=${Uri.encodeComponent(farmName)}',
      ),
      icon: const Icon(Icons.edit_outlined, size: 18),
    ),
  );
}

Future<void> _showCloseSessionDialog({
  required BuildContext context,
  required String sessionType,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Fine sessione'),
        content: const Text('Vuoi concludere la sessione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showSessionSummaryDialog(
                context: context,
                sessionType: sessionType,
              );
            },
            child: const Text('Prosegui'),
          ),
        ],
      );
    },
  );
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
                    child: const Text('Chiudi'),
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
