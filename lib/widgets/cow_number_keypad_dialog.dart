import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_responsive.dart';

enum CowNumberSubmitStatus { success, duplicate, invalid, error }

class CowNumberSubmitResult<T> {
  const CowNumberSubmitResult._({
    required this.status,
    this.value,
    this.message,
  });

  final CowNumberSubmitStatus status;
  final T? value;
  final String? message;

  const CowNumberSubmitResult.success(T value)
    : this._(status: CowNumberSubmitStatus.success, value: value);

  const CowNumberSubmitResult.duplicate([String? message])
    : this._(
        status: CowNumberSubmitStatus.duplicate,
        message: message ?? 'Capo già presente.',
      );

  const CowNumberSubmitResult.invalid([String? message])
    : this._(
        status: CowNumberSubmitStatus.invalid,
        message: message ?? 'Inserisci un numero intero valido.',
      );

  const CowNumberSubmitResult.error(String message)
    : this._(status: CowNumberSubmitStatus.error, message: message);
}

Future<T?> showCowNumberKeypadDialog<T>({
  required BuildContext context,
  required String title,
  String? initialValue,
  required Future<CowNumberSubmitResult<T>> Function(int cowNumber) onConfirm,
  required VoidCallback onMicTap,
}) {
  return showDialog<T?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _CowNumberKeypadDialog<T>(
        title: title,
        initialValue: initialValue,
        onConfirm: onConfirm,
        onMicTap: onMicTap,
      );
    },
  );
}

class _CowNumberKeypadDialog<T> extends StatefulWidget {
  const _CowNumberKeypadDialog({
    required this.title,
    required this.initialValue,
    required this.onConfirm,
    required this.onMicTap,
  });

  final String title;
  final String? initialValue;
  final Future<CowNumberSubmitResult<T>> Function(int cowNumber) onConfirm;
  final VoidCallback onMicTap;

  @override
  State<_CowNumberKeypadDialog<T>> createState() =>
      _CowNumberKeypadDialogState<T>();
}

class _CowNumberKeypadDialogState<T> extends State<_CowNumberKeypadDialog<T>> {
  static const _keypadRows = <List<String>>[
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['-', '0', 'backspace'],
  ];

  late String _displayValue;
  String? _errorText;
  bool _submitting = false;
  bool _replaceOnNextDigit = false;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.initialValue?.trim() ?? '';
  }

  void _onDigit(String digit) {
    setState(() {
      if (_replaceOnNextDigit) {
        _displayValue = digit;
        _replaceOnNextDigit = false;
      } else if (_displayValue == '0') {
        _displayValue = digit;
      } else if (_displayValue == '-0') {
        _displayValue = '-$digit';
      } else {
        _displayValue += digit;
      }
      _errorText = null;
    });
  }

  void _onToggleNegative() {
    setState(() {
      if (_replaceOnNextDigit) {
        _displayValue = _displayValue.startsWith('-') ? '' : '-';
        _replaceOnNextDigit = false;
      } else if (_displayValue.startsWith('-')) {
        _displayValue = _displayValue.substring(1);
      } else {
        _displayValue = '-$_displayValue';
      }
      _errorText = null;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_displayValue.isNotEmpty) {
        _displayValue = _displayValue.substring(0, _displayValue.length - 1);
      }
      _replaceOnNextDigit = false;
      _errorText = null;
    });
  }

  Future<void> _submit() async {
    final rawValue = _displayValue.trim();
    if (rawValue.isEmpty ||
        rawValue == '-' ||
        !RegExp(r'^-?\d+$').hasMatch(rawValue)) {
      setState(() {
        _errorText = 'Inserisci un numero intero valido.';
        _replaceOnNextDigit = true;
      });
      return;
    }

    final cowNumber = int.parse(rawValue);
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    late final CowNumberSubmitResult<T> result;
    try {
      result = await widget.onConfirm(cowNumber);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText = 'Errore inserimento capo: $error';
        _replaceOnNextDigit = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    switch (result.status) {
      case CowNumberSubmitStatus.success:
        Navigator.of(context).pop(result.value);
        return;
      case CowNumberSubmitStatus.duplicate:
        setState(() {
          _submitting = false;
          _errorText = result.message ?? 'Capo già presente.';
          _replaceOnNextDigit = true;
        });
        return;
      case CowNumberSubmitStatus.invalid:
      case CowNumberSubmitStatus.error:
        setState(() {
          _submitting = false;
          _errorText = result.message ?? 'Errore inserimento capo.';
          _replaceOnNextDigit = false;
        });
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        titlePadding: const EdgeInsets.fromLTRB(
          AppResponsive.screenPadding,
          12,
          AppResponsive.screenPadding,
          0,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppResponsive.screenPadding,
          12,
          AppResponsive.screenPadding,
          AppResponsive.controlGap,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppResponsive.screenPadding,
          0,
          AppResponsive.screenPadding,
          12,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: _submitting ? null : widget.onMicTap,
              icon: const Icon(Icons.mic_none_rounded),
              tooltip: 'Microfono',
              constraints: const BoxConstraints(
                minWidth: AppResponsive.minTouchTarget,
                minHeight: AppResponsive.minTouchTarget,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        content: SizedBox(
          width: AppResponsive.dialogMaxWidth(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: AppResponsive.primaryActionHeight,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _errorText == null
                        ? AppColors.border
                        : AppColors.danger,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _displayValue.isEmpty ? 'Numero capo' : _displayValue,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: _displayValue.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppResponsive.controlGap),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: AppResponsive.secondaryFontSize,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              for (
                var rowIndex = 0;
                rowIndex < _keypadRows.length;
                rowIndex++
              ) ...[
                Row(
                  children: [
                    for (
                      var columnIndex = 0;
                      columnIndex < _keypadRows[rowIndex].length;
                      columnIndex++
                    ) ...[
                      Expanded(
                        child: SizedBox(
                          height: AppResponsive.primaryActionHeight,
                          child: _KeypadButton(
                            label: _keypadRows[rowIndex][columnIndex],
                            enabled: !_submitting,
                            onTap: () {
                              final label = _keypadRows[rowIndex][columnIndex];
                              if (label == 'backspace') {
                                _onBackspace();
                              } else if (label == '-') {
                                _onToggleNegative();
                              } else {
                                _onDigit(label);
                              }
                            },
                          ),
                        ),
                      ),
                      if (columnIndex < _keypadRows[rowIndex].length - 1)
                        const SizedBox(width: AppResponsive.controlGap),
                    ],
                  ],
                ),
                if (rowIndex < _keypadRows.length - 1)
                  const SizedBox(height: AppResponsive.controlGap),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size(96, AppResponsive.normalButtonHeight),
              textStyle: AppResponsive.buttonTextStyle(context),
            ),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(
                96,
                AppResponsive.largePrimaryButtonHeight,
              ),
              textStyle: AppResponsive.buttonTextStyle(context),
            ),
            child: Text(_submitting ? 'Attendere...' : 'OK'),
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == 'backspace';
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(
          AppResponsive.minTouchTarget,
          AppResponsive.minTouchTarget,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: isBackspace
          ? const Icon(Icons.backspace_outlined)
          : Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: AppResponsive.buttonFontSize,
              ),
            ),
    );
  }
}
