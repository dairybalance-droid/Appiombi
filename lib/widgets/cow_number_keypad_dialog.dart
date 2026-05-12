import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum CowNumberSubmitStatus {
  success,
  duplicate,
  invalid,
  error,
}

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
  static const _keypadLabels = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '-',
    '0',
    'backspace',
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 420;

    return SafeArea(
      child: AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 20,
          vertical: compact ? 16 : 24,
        ),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 14,
                    vertical: compact ? 12 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color:
                          _errorText == null ? AppColors.border : AppColors.danger,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _displayValue.isEmpty ? 'Numero capo' : _displayValue,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _displayValue.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _keypadLabels.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: compact ? 50 : 54,
                  ),
                  itemBuilder: (context, index) {
                    final label = _keypadLabels[index];
                    return _KeypadButton(
                      label: label,
                      enabled: !_submitting,
                      onTap: () {
                        if (label == 'backspace') {
                          _onBackspace();
                        } else if (label == '-') {
                          _onToggleNegative();
                        } else {
                          _onDigit(label);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: isBackspace
          ? const Icon(Icons.backspace_outlined)
          : Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
    );
  }
}
