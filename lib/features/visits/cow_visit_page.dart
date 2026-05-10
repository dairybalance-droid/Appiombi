import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class CowVisitPage extends ConsumerStatefulWidget {
  const CowVisitPage({
    super.key,
    required this.farmId,
    this.cowVisitId,
    this.sessionId,
    this.sessionType,
    this.cowNumber,
    this.isEditing = false,
  });

  final String farmId;
  final String? cowVisitId;
  final String? sessionId;
  final String? sessionType;
  final String? cowNumber;
  final bool isEditing;

  @override
  ConsumerState<CowVisitPage> createState() => _CowVisitPageState();
}

class _CowVisitPageState extends ConsumerState<CowVisitPage> {
  final _formKey = GlobalKey<FormState>();
  final _cowIdController = TextEditingController();
  final _soleCountController = TextEditingController();
  final _bandageCountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _antibiotic = false;
  bool _antiInflammatory = false;
  bool _strawBox = false;
  late final Future<CowVisitDetail?> _visitFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cowIdController.text = widget.cowNumber ?? '';
    _visitFuture = _loadVisit();
  }

  @override
  void dispose() {
    _cowIdController.dispose();
    _soleCountController.dispose();
    _bandageCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showPlaceholderMessage(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action disponibile come placeholder nello scheletro MVP.')),
    );
  }

  Future<CowVisitDetail?> _loadVisit() async {
    if (widget.cowVisitId == null) {
      return null;
    }

    final service = ref.read(supabaseServiceProvider);
    final visit = await service.fetchCowVisit(widget.cowVisitId!).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Timeout caricamento visita vacca'),
    );

    _cowIdController.text = visit.cowNumber.toString();
    _soleCountController.text = visit.solesCount.toString();
    _bandageCountController.text = visit.bandagesCount.toString();
    _notesController.text = visit.notes;
    _antibiotic = visit.antibioticCode.isNotEmpty;
    _antiInflammatory = visit.antiInflammatoryCode.isNotEmpty;

    return visit;
  }

  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.cowVisitId == null) {
      _showPlaceholderMessage(
        widget.isEditing ? 'Aggiornamento capo' : 'Salvataggio capo',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(supabaseServiceProvider).saveCowVisitBasic(
            cowVisitId: widget.cowVisitId!,
            solesCount: int.tryParse(_soleCountController.text.trim()) ?? 0,
            bandagesCount: int.tryParse(_bandageCountController.text.trim()) ?? 0,
            antibiotic: _antibiotic,
            antiInflammatory: _antiInflammatory,
            notes: _notesController.text,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Capo aggiornato.' : 'Capo salvato.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore salvataggio visita: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageTitle = widget.isEditing ? 'Modifica visita vacca' : 'Nuova visita vacca';
    final sessionType = widget.sessionType ?? 'Sessione operativa';

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: FutureBuilder<CowVisitDetail?>(
        future: _visitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Caricamento visita vacca...');
          }

          if (snapshot.hasError) {
            final message = snapshot.error.toString()
                .replaceFirst('Exception: ', '')
                .replaceFirst('TimeoutException: ', '');
            return ErrorView(
              title: 'Impossibile aprire la visita',
              message: message,
            );
          }

          final visit = snapshot.data;

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionType,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Dati generici', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cowIdController,
                          readOnly: widget.cowVisitId != null,
                          decoration: const InputDecoration(labelText: 'ID capo'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'ID capo obbligatorio.';
                            }
                            if (!RegExp(r'^-?\d+$').hasMatch(value.trim())) {
                              return 'Inserisci un numero intero valido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: (visit?.visitDate ?? DateTime.now())
                              .toIso8601String()
                              .split('T')
                              .first,
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'Data visita'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _soleCountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Numero suole'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _bandageCountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Numero bende'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trattamenti e note', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _antibiotic,
                          onChanged: (value) => setState(() => _antibiotic = value),
                          title: const Text('Antibiotico'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _antiInflammatory,
                          onChanged: (value) => setState(() => _antiInflammatory = value),
                          title: const Text('Antinfiammatorio'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _strawBox,
                          onChanged: (value) => setState(() => _strawBox = value),
                          title: const Text('Box paglia'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: const InputDecoration(labelText: 'Note'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Predisposizione futura', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Mappa podale, storico capo completo e sync offline non sono ancora implementati in questo primo blocco reale.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppPrimaryButton(
                    label: _saving
                        ? 'Salvataggio...'
                        : widget.isEditing
                            ? 'Aggiorna capo'
                            : 'Salva capo',
                    onPressed: _saving ? null : _saveVisit,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showPlaceholderMessage('Capo precedente'),
                          child: const Text('Precedente'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showPlaceholderMessage('Capo successivo'),
                          child: const Text('Successivo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
