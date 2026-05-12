import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'hoof_map_models.dart';
import 'hoof_map_widget.dart';

class CowVisitPage extends ConsumerStatefulWidget {
  const CowVisitPage({
    super.key,
    required this.farmId,
    this.cowVisitId,
    this.sessionId,
    this.sessionType,
    this.cowNumber,
    this.farmName,
    this.isEditing = false,
  });

  final String farmId;
  final String? cowVisitId;
  final String? sessionId;
  final String? sessionType;
  final String? cowNumber;
  final String? farmName;
  final bool isEditing;

  @override
  ConsumerState<CowVisitPage> createState() => _CowVisitPageState();
}

class _CowVisitPageState extends ConsumerState<CowVisitPage> {
  final _formKey = GlobalKey<FormState>();
  final _cowNumberController = TextEditingController();
  final _groupController = TextEditingController();
  final _notesController = TextEditingController();

  late Future<_CowVisitPageData> _visitFuture;

  DateTime? _visitDate;
  String _laminitisCode = '';
  String _antibioticCode = '';
  String _antiInflammatoryCode = '';
  String _recheckCode = '';
  int? _corkscrewCode;
  int _solesCount = 0;
  int _bandagesCount = 0;

  bool _saving = false;
  bool _savingMap = false;
  String? _cowNumberError;
  _VisitSection _currentSection = _VisitSection.generalData;
  Map<String, HoofZoneObservation> _hoofMapObservations = {};

  @override
  void initState() {
    super.initState();
    HoofMapDefinitions.debugValidate();
    _cowNumberController.text = widget.cowNumber ?? '';
    _visitFuture = _loadPageData();
  }

  @override
  void dispose() {
    _cowNumberController.dispose();
    _groupController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<_CowVisitPageData> _loadPageData() async {
    if (widget.cowVisitId == null || widget.sessionId == null) {
      throw Exception('Visita o sessione non disponibili.');
    }

    final service = ref.read(supabaseServiceProvider);
    final results = await Future.wait([
      service.fetchCowVisit(widget.cowVisitId!),
      service.fetchSessionVisits(widget.sessionId!),
      service.fetchCowVisitTextFlag(
        cowVisitId: widget.cowVisitId!,
        flagKey: 'hoof_map_v1_json',
      ),
    ]).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Timeout caricamento visita vacca'),
    );

    final visit = results[0] as CowVisitDetail;
    final sessionVisits = results[1] as List<SessionVisitRow>;
    final hoofMapFlag = results[2] as String;

    _cowNumberController.text = visit.cowNumber.toString();
    _groupController.text = visit.groupLabel;
    _notesController.text = visit.notes;
    _visitDate = visit.visitDate;
    _laminitisCode = visit.laminitisCode;
    _corkscrewCode = visit.corkscrewCode;
    _solesCount = visit.solesCount;
    _bandagesCount = visit.bandagesCount;
    _antibioticCode = visit.antibioticCode;
    _antiInflammatoryCode = visit.antiInflammatoryCode;
    _recheckCode = visit.recheckCode;
    _hoofMapObservations = decodeHoofMapObservations(hoofMapFlag);

    return _CowVisitPageData(
      visit: visit,
      sessionVisits: sessionVisits,
    );
  }

  Future<void> _selectVisitDate() async {
    final current = _visitDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _visitDate = picked;
    });
  }

  Future<void> _editVisitDateFromTopBar() async {
    await _selectVisitDate();
    if (!mounted) {
      return;
    }
    await _saveCurrentVisit();
  }

  Future<void> _editCowNumberFromTopBar() async {
    final controller = TextEditingController(text: _cowNumberController.text.trim());
    String? inlineError;
    bool saving = false;
    final previousValue = _cowNumberController.text.trim();

    final updatedValue = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final rawValue = controller.text.trim();
              if (!RegExp(r'^-?\d+$').hasMatch(rawValue)) {
                setDialogState(() {
                  inlineError = 'Inserisci un numero intero valido.';
                });
                return;
              }

              setDialogState(() {
                inlineError = null;
                saving = true;
              });
              Navigator.of(dialogContext).pop(rawValue);
            }

            return AlertDialog(
              title: const Text('Modifica numero capo'),
              content: TextField(
                controller: controller,
                autofocus: true,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: false,
                ),
                decoration: InputDecoration(
                  labelText: 'Capo',
                  hintText: 'Es. 101 o -12',
                  errorText: inlineError,
                ),
                onSubmitted: (_) => submit(),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : submit,
                  child: Text(saving ? 'Attendere...' : 'OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || updatedValue == null || updatedValue == previousValue) {
      return;
    }

    _cowNumberController.text = updatedValue;
    setState(() {
      _cowNumberError = null;
    });

    final saved = await _saveCurrentVisit();
    if (!mounted) {
      return;
    }

    if (!saved) {
      _cowNumberController.text = previousValue;
      setState(() {});
      return;
    }

    setState(() {});
  }

  Future<void> _navigateCycleBackward() async {
    switch (_currentSection) {
      case _VisitSection.generalData:
        await _changeSection(_VisitSection.otherInfo);
      case _VisitSection.hoofMap:
        await _changeSection(_VisitSection.generalData);
      case _VisitSection.otherInfo:
        await _changeSection(_VisitSection.hoofMap);
    }
  }

  Future<void> _navigateCycleForward() async {
    switch (_currentSection) {
      case _VisitSection.generalData:
        await _changeSection(_VisitSection.hoofMap);
      case _VisitSection.hoofMap:
        await _changeSection(_VisitSection.otherInfo);
      case _VisitSection.otherInfo:
        await _changeSection(_VisitSection.generalData);
    }
  }

  Future<bool> _saveCurrentVisit() async {
    final formState = _formKey.currentState;
    if (formState != null && !formState.validate()) {
      return false;
    }

    final rawCowNumber = _cowNumberController.text.trim();
    if (rawCowNumber.isEmpty) {
      setState(() {
        _cowNumberError = 'Capo obbligatorio.';
      });
      return false;
    }

    if (!RegExp(r'^-?\d+$').hasMatch(rawCowNumber)) {
      setState(() {
        _cowNumberError = 'Inserisci un numero intero valido.';
      });
      return false;
    }

    if (widget.cowVisitId == null || widget.sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita non disponibile.')),
      );
      return false;
    }

    final visitDate = _visitDate ?? DateTime.now();
    final cowNumber = int.parse(rawCowNumber);

    setState(() {
      _saving = true;
      _cowNumberError = null;
    });

    try {
      await ref.read(supabaseServiceProvider).saveCowVisitGeneralData(
            cowVisitId: widget.cowVisitId!,
            sessionId: widget.sessionId!,
            visitDate: visitDate,
            cowNumber: cowNumber,
            groupLabel: _groupController.text,
            laminitisCode: _laminitisCode,
            corkscrewCode: _corkscrewCode,
            solesCount: _solesCount,
            bandagesCount: _bandagesCount,
            antibioticCode: _antibioticCode,
            antiInflammatoryCode: _antiInflammatoryCode,
            recheckCode: _recheckCode,
            notes: _notesController.text,
          );
      return true;
    } on DuplicateCowNumberException {
      if (!mounted) {
        return false;
      }
      setState(() {
        _cowNumberError = 'Capo già presente.';
      });
      return false;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore salvataggio visita: $error')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _persistHoofMap() async {
    if (widget.cowVisitId == null) {
      return;
    }

    setState(() => _savingMap = true);
    try {
      await ref.read(supabaseServiceProvider).saveCowVisitTextFlag(
            cowVisitId: widget.cowVisitId!,
            flagKey: 'hoof_map_v1_json',
            value: encodeHoofMapObservations(_hoofMapObservations),
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore salvataggio mappa: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingMap = false);
      }
    }
  }

  void _goToSessionList() {
    if (widget.sessionId == null) {
      context.go('/farms/${widget.farmId}');
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true);
      return;
    }

    final type = widget.sessionType ?? '';
    final farmName = widget.farmName ?? '';
    context.go(
      '/farms/${widget.farmId}/sessions/${widget.sessionId}'
      '?type=${Uri.encodeComponent(type)}'
      '&farmName=${Uri.encodeComponent(farmName)}',
    );
  }

  Future<void> _openPreviousVisit(_CowVisitPageData data) async {
    final saved = await _saveCurrentVisit();
    if (!saved || !mounted) {
      return;
    }

    final currentIndex =
        data.sessionVisits.indexWhere((visit) => visit.id == widget.cowVisitId);
    if (currentIndex <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun capo precedente nella sessione.')),
      );
      return;
    }

    final previous = data.sessionVisits[currentIndex - 1];
    _goToVisit(previous);
  }

  Future<void> _saveAndReturnToList() async {
    final saved = await _saveCurrentVisit();
    if (!saved || !mounted) {
      return;
    }
    _goToSessionList();
  }

  Future<void> _confirmDelete() async {
    if (widget.cowVisitId == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Elimina capo'),
          content: const Text('Eliminare questo capo dalla sessione?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(supabaseServiceProvider).softDeleteCowVisit(
            cowVisitId: widget.cowVisitId!,
          );
      if (!mounted) {
        return;
      }
      _goToSessionList();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore eliminazione visita: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openNewCowFromRightAction() async {
    final saved = await _saveCurrentVisit();
    if (!saved || !mounted) {
      return;
    }

    final result = await _showCowNumberDialog();
    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }

    _goToVisitResult(result);
  }

  Future<_NewVisitNavigationResult?> _showCowNumberDialog() async {
    if (widget.sessionId == null) {
      return null;
    }

    final controller = TextEditingController();
    String? inlineError;
    bool submitting = false;

    return showDialog<_NewVisitNavigationResult?>(
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
                inlineError = null;
                submitting = true;
              });

              try {
                final visit = await ref.read(supabaseServiceProvider).createDraftVisit(
                      farmId: widget.farmId,
                      sessionId: widget.sessionId!,
                      cowNumber: cowNumber,
                    );
                if (!mounted) {
                  return;
                }
                navigator.pop(
                  _NewVisitNavigationResult(
                    cowVisitId: visit.id,
                    cowNumber: cowNumber,
                  ),
                );
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
              content: TextField(
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
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(null),
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

  void _goToVisit(SessionVisitRow visit) {
    context.go(
      '/farms/${widget.farmId}/visits/new'
      '?cowVisitId=${Uri.encodeComponent(visit.id)}'
      '&sessionId=${Uri.encodeComponent(widget.sessionId ?? '')}'
      '&sessionType=${Uri.encodeComponent(widget.sessionType ?? '')}'
      '&farmName=${Uri.encodeComponent(widget.farmName ?? '')}'
      '&cowNumber=${Uri.encodeComponent(visit.cowNumber.toString())}'
      '&mode=edit',
    );
  }

  void _goToVisitResult(_NewVisitNavigationResult result) {
    context.go(
      '/farms/${widget.farmId}/visits/new'
      '?cowVisitId=${Uri.encodeComponent(result.cowVisitId)}'
      '&sessionId=${Uri.encodeComponent(widget.sessionId ?? '')}'
      '&sessionType=${Uri.encodeComponent(widget.sessionType ?? '')}'
      '&farmName=${Uri.encodeComponent(widget.farmName ?? '')}'
      '&cowNumber=${Uri.encodeComponent(result.cowNumber.toString())}',
    );
  }

  Future<void> _showZoneDialog(HoofMapZoneDefinition zone) async {
    final existing = _hoofMapObservations[zone.zoneCode];
    String lesionTypeCode = existing?.lesionTypeCode ?? '';
    String extensionCode = existing?.extensionCode ?? '';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final lesionOptions = zone.popupKind == HoofPopupKind.horn
                ? _hornLesionTypeOptions
                : _skinLesionTypeOptions;

            Future<void> save() async {
              final navigator = Navigator.of(dialogContext);
              final active = lesionTypeCode.isNotEmpty || extensionCode.isNotEmpty;
              setDialogState(() => saving = true);

              setState(() {
                if (active) {
                  _hoofMapObservations[zone.zoneCode] = HoofZoneObservation(
                    zoneCode: zone.zoneCode,
                    zoneFamily: zone.zoneFamily,
                    anatomicalArea: zone.anatomicalArea,
                    anatomicalPosition: zone.anatomicalPosition,
                    popupKind: zone.popupKind,
                    lesionTypeCode: lesionTypeCode,
                    extensionCode: extensionCode,
                    isActive: true,
                  );
                } else {
                  _hoofMapObservations.remove(zone.zoneCode);
                }
              });

              await _persistHoofMap();
              if (!mounted) {
                return;
              }
              navigator.pop();
            }

            Future<void> remove() async {
              final navigator = Navigator.of(dialogContext);
              setDialogState(() => saving = true);
              setState(() {
                _hoofMapObservations.remove(zone.zoneCode);
              });
              await _persistHoofMap();
              if (!mounted) {
                return;
              }
              navigator.pop();
            }

            return AlertDialog(
              title: Text(hoofPopupTitle(zone.popupKind)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.zoneCode,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${zone.anatomicalArea} · ${zone.anatomicalPosition}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tipologia',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _OptionWrap(
                    options: lesionOptions,
                    selectedValue: lesionTypeCode,
                    onSelected: saving
                        ? null
                        : (value) {
                            setDialogState(() => lesionTypeCode = value);
                          },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Estensione',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _OptionWrap(
                    options: _extensionOptionItems,
                    selectedValue: extensionCode,
                    onSelected: saving
                        ? null
                        : (value) {
                            setDialogState(() => extensionCode = value);
                          },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : remove,
                  child: const Text('Rimuovi'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Attendere...' : 'Conferma'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeSection(_VisitSection target) async {
    if (_currentSection == target) {
      return;
    }

    final saved = await _saveCurrentVisit();
    if (!saved || !mounted) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentSection = target;
    });
  }

  void _showVoiceInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Microfono'),
          content: const Text('Registrazione vocale non ancora attiva.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(_CowVisitPageData data) {
    switch (_currentSection) {
      case _VisitSection.generalData:
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _openPreviousVisit(data),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Precedente'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _saveAndReturnToList,
                    child: const Text('Elenco'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    child: const Text('Elimina'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _openNewCowFromRightAction,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Prossima vacca'),
                  ),
                ),
              ],
            ),
          ),
        );
      case _VisitSection.hoofMap:
        return _MapBottomBar(
          onNextCow: _savingMap ? null : _openNewCowFromRightAction,
          busy: _savingMap || _saving,
        );
      case _VisitSection.otherInfo:
        return _MapBottomBar(
          onNextCow: _saving ? null : _openNewCowFromRightAction,
          busy: _saving,
        );
    }
  }

  Widget _buildVisitTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _TopBarIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _saving ? null : _navigateCycleBackward,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TopBarValueChip(
              label: _formatDate(_visitDate ?? DateTime.now()),
              icon: Icons.calendar_today_rounded,
              onTap: _saving ? null : _editVisitDateFromTopBar,
            ),
          ),
          const SizedBox(width: 8),
          _TopBarIconButton(
            icon: Icons.mic_none_rounded,
            onTap: _showVoiceInfo,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TopBarValueChip(
              label: _cowNumberController.text.trim().isEmpty
                  ? 'Capo'
                  : 'Capo ${_cowNumberController.text.trim()}',
              icon: Icons.pets_outlined,
              errorText: _cowNumberError,
              onTap: _saving ? null : _editCowNumberFromTopBar,
            ),
          ),
          const SizedBox(width: 8),
          _TopBarIconButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: _saving ? null : _navigateCycleForward,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralDataSection(String sessionType) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildVisitTopBar(),
        const SizedBox(height: 12),
        Text(
          sessionType,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compilazione visita',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'Data visita',
                value: _formatDate(_visitDate ?? DateTime.now()),
                onTap: _selectVisitDate,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cowNumberController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: false,
                ),
                decoration: InputDecoration(
                  labelText: 'Capo',
                  errorText: _cowNumberError,
                ),
                onChanged: (_) {
                  if (_cowNumberError != null) {
                    setState(() => _cowNumberError = null);
                  }
                },
                validator: (value) {
                  final rawValue = value?.trim() ?? '';
                  if (rawValue.isEmpty) {
                    return 'Capo obbligatorio.';
                  }
                  if (!RegExp(r'^-?\d+$').hasMatch(rawValue)) {
                    return 'Inserisci un numero intero valido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _groupController,
                decoration: const InputDecoration(
                  labelText: 'Gruppo',
                ),
              ),
              const SizedBox(height: 14),
              _AppDropdownField<String>(
                label: 'Laminite',
                value: _laminitisCode,
                items: _laminitisOptions,
                onChanged: (value) {
                  setState(() => _laminitisCode = value ?? '');
                },
              ),
              const SizedBox(height: 14),
              _AppDropdownField<int?>(
                label: 'Cavatappi',
                value: _corkscrewCode,
                items: _corkscrewOptions,
                onChanged: (value) {
                  setState(() => _corkscrewCode = value);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CounterField(
                      label: 'Suole',
                      value: _solesCount,
                      onIncrement: () => setState(() => _solesCount += 1),
                      onDecrement: () {
                        setState(() {
                          if (_solesCount > 0) {
                            _solesCount -= 1;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CounterField(
                      label: 'Bende',
                      value: _bandagesCount,
                      onIncrement: () => setState(() => _bandagesCount += 1),
                      onDecrement: () {
                        setState(() {
                          if (_bandagesCount > 0) {
                            _bandagesCount -= 1;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AppDropdownField<String>(
                label: 'Antibiotico',
                value: _antibioticCode,
                items: _antibioticOptions,
                onChanged: (value) {
                  setState(() => _antibioticCode = value ?? '');
                },
              ),
              const SizedBox(height: 14),
              _AppDropdownField<String>(
                label: 'Antinfiammatorio',
                value: _antiInflammatoryCode,
                items: _antiInflammatoryOptions,
                onChanged: (value) {
                  setState(() => _antiInflammatoryCode = value ?? '');
                },
              ),
              const SizedBox(height: 14),
              _AppDropdownField<String>(
                label: 'Ricontrollo',
                value: _recheckCode,
                items: _recheckOptions,
                onChanged: (value) {
                  setState(() => _recheckCode = value ?? '');
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Note',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHoofMapSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth > 860 ? 360.0 : constraints.maxWidth - 24;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVisitTopBar(),
              const SizedBox(height: 12),
              Text(
                widget.sessionType?.trim().isNotEmpty == true
                    ? widget.sessionType!
                    : 'Sessione operativa',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: mapWidth,
                  child: HoofPairMap(
                    footLabel: 'AS',
                    observations: _hoofMapObservations,
                    onZoneTap: _showZoneDialog,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: mapWidth,
                  child: HoofPairMap(
                    footLabel: 'AD',
                    observations: _hoofMapObservations,
                    onZoneTap: _showZoneDialog,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: mapWidth,
                  child: HoofPairMap(
                    footLabel: 'PS',
                    observations: _hoofMapObservations,
                    onZoneTap: _showZoneDialog,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: mapWidth,
                  child: HoofPairMap(
                    footLabel: 'PD',
                    observations: _hoofMapObservations,
                    onZoneTap: _showZoneDialog,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOtherInfoSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildVisitTopBar(),
        const SizedBox(height: 12),
        Text(
          widget.sessionType?.trim().isNotEmpty == true
              ? widget.sessionType!
              : 'Sessione operativa',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Altre info',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sezione dedicata ai campi operativi complementari della visita.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionType = widget.sessionType?.trim().isNotEmpty == true
        ? widget.sessionType!
        : 'Sessione operativa';

    return Scaffold(
      bottomNavigationBar: FutureBuilder<_CowVisitPageData>(
        future: _visitFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          return _buildBottomBar(snapshot.data!);
        },
      ),
      body: FutureBuilder<_CowVisitPageData>(
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

          final data = snapshot.data;
          if (data == null) {
            return const ErrorView(
              title: 'Visita non trovata',
              message: 'La visita richiesta non è disponibile.',
            );
          }

          return Form(
            key: _formKey,
            child: switch (_currentSection) {
              _VisitSection.generalData => _buildGeneralDataSection(sessionType),
              _VisitSection.hoofMap => _buildHoofMapSection(),
              _VisitSection.otherInfo => _buildOtherInfoSection(),
            },
          );
        },
      ),
    );
  }
}

enum _VisitSection {
  generalData('Dati generici'),
  hoofMap('Mappa unghioni'),
  otherInfo('Altre info');

  const _VisitSection(this.label);
  final String label;
}

class _CowVisitPageData {
  const _CowVisitPageData({
    required this.visit,
    required this.sessionVisits,
  });

  final CowVisitDetail visit;
  final List<SessionVisitRow> sessionVisits;
}

class _NewVisitNavigationResult {
  const _NewVisitNavigationResult({
    required this.cowVisitId,
    required this.cowNumber,
  });

  final String cowVisitId;
  final int cowNumber;
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(value),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                onPressed: onIncrement,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppDropdownField<T> extends StatelessWidget {
  const _AppDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _MapBottomBar extends StatelessWidget {
  const _MapBottomBar({
    required this.onNextCow,
    required this.busy,
  });

  final VoidCallback? onNextCow;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: busy ? null : onNextCow,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Prossima vacca'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFF2F4F5) : Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _TopBarValueChip extends StatelessWidget {
  const _TopBarValueChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: hasError ? AppColors.danger : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<_PopupOption> options;
  final String selectedValue;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option.label.isEmpty ? 'Vuoto' : option.label),
            selected: option.value == selectedValue,
            onSelected: onSelected == null ? null : (_) => onSelected!(option.value),
            selectedColor: const Color(0xFFEFE6D9),
            side: BorderSide(
              color: option.value == selectedValue
                  ? AppColors.primary
                  : AppColors.border,
            ),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: option.value == selectedValue
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
      ],
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year';
}

class _PopupOption {
  const _PopupOption(this.value, this.label);

  final String value;
  final String label;
}

const List<_PopupOption> _hornLesionTypeOptions = [
  _PopupOption('', ''),
  _PopupOption('hemorrhage', 'Emorragia'),
  _PopupOption('ulcer', 'Ulcera'),
  _PopupOption('protrusion', 'Protrusione'),
  _PopupOption('pus', 'Pus'),
  _PopupOption('necrosis', 'Necrosi'),
  _PopupOption('deep_plane', 'Piani profondi'),
];

const List<_PopupOption> _skinLesionTypeOptions = [
  _PopupOption('', ''),
  _PopupOption('m1', '1 - Precoce'),
  _PopupOption('m2', '2 - Acuta'),
  _PopupOption('m3', '3 - Guarigione'),
  _PopupOption('m4', '4 - Cronica'),
  _PopupOption('m41', '4.1 - Riacutizzata'),
];

const List<_PopupOption> _extensionOptionItems = [
  _PopupOption('', ''),
  _PopupOption('focal', 'Focale'),
  _PopupOption('broad', 'Ampio'),
  _PopupOption('multi', 'Multi-zona'),
];

const List<DropdownMenuItem<String>> _laminitisOptions = [
  DropdownMenuItem(value: '', child: Text('')),
  DropdownMenuItem(value: 'subacute', child: Text('Subacuta')),
  DropdownMenuItem(value: 'chronic_mild', child: Text('Cronica lieve')),
  DropdownMenuItem(value: 'reactivated_mild', child: Text('Riacutiz lieve')),
  DropdownMenuItem(value: 'acute_severe', child: Text('Grave')),
  DropdownMenuItem(value: 'chronic_severe', child: Text('Cronica grave')),
  DropdownMenuItem(value: 'reactivated_severe', child: Text('Riacutiz grave')),
];

const List<DropdownMenuItem<int?>> _corkscrewOptions = [
  DropdownMenuItem<int?>(value: null, child: Text('')),
  DropdownMenuItem<int?>(value: 1, child: Text('Lieve')),
  DropdownMenuItem<int?>(value: 2, child: Text('Moderato')),
  DropdownMenuItem<int?>(value: 3, child: Text('Grave')),
];

const List<DropdownMenuItem<String>> _antibioticOptions = [
  DropdownMenuItem(value: '', child: Text('')),
  DropdownMenuItem(value: 'yes', child: Text('Sì')),
  DropdownMenuItem(value: 'sulfamidics', child: Text('Sulfamidici')),
  DropdownMenuItem(value: 'penicillins', child: Text('Penicilline')),
];

const List<DropdownMenuItem<String>> _antiInflammatoryOptions = [
  DropdownMenuItem(value: '', child: Text('')),
  DropdownMenuItem(value: 'yes', child: Text('Sì')),
  DropdownMenuItem(value: 'ketoprofen', child: Text('Ketoprofene')),
  DropdownMenuItem(
    value: 'flunixin_meglumine',
    child: Text('Flunixin meglumine'),
  ),
  DropdownMenuItem(value: 'meloxicam', child: Text('Meloxicam')),
];

const List<DropdownMenuItem<String>> _recheckOptions = [
  DropdownMenuItem(value: '', child: Text('')),
  DropdownMenuItem(value: 'yes', child: Text('Sì')),
  DropdownMenuItem(value: '10d', child: Text('10 gg')),
  DropdownMenuItem(value: '30d', child: Text('30 gg')),
  DropdownMenuItem(value: '90d', child: Text('90 gg')),
];

