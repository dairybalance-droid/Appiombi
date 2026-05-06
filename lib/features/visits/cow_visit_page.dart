import 'package:flutter/material.dart';

import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';

class CowVisitPage extends StatefulWidget {
  const CowVisitPage({
    super.key,
    required this.farmId,
  });

  final String farmId;

  @override
  State<CowVisitPage> createState() => _CowVisitPageState();
}

class _CowVisitPageState extends State<CowVisitPage> {
  final _formKey = GlobalKey<FormState>();
  final _cowIdController = TextEditingController();
  final _soleCountController = TextEditingController();
  final _bandageCountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _antibiotic = false;
  bool _antiInflammatory = false;
  bool _strawBox = false;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visita Vacca Base'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dati generici', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cowIdController,
                      decoration: const InputDecoration(labelText: 'ID capo'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'ID capo obbligatorio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: DateTime.now().toIso8601String().split('T').first,
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
                      'Mappa podale, storico capo completo e sync offline non sono ancora implementati in questo primo scheletro.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Salva capo',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _showPlaceholderMessage('Salvataggio capo');
                  }
                },
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
      ),
    );
  }
}
