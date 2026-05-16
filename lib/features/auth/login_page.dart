import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_responsive.dart';
import '../../widgets/app_logo_placeholder.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../farms/farm_list_page.dart';

class AuthGatePage extends ConsumerWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final authUser = ref.watch(authUserProvider);

    if (config.devBypassLogin) {
      return const FarmListPage();
    }

    return authUser.when(
      data: (user) => user == null ? const LoginPage() : const FarmListPage(),
      loading: () =>
          const LoadingView(message: 'Controllo sessione in corso...'),
      error: (error, _) => ErrorView(
        title: 'Impossibile leggere la sessione',
        message: error.toString(),
      ),
    );
  }
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final service = ref.read(supabaseServiceProvider);
    final config = ref.read(appConfigProvider);

    try {
      if (!config.isSupabaseConfigured) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Configurazione Supabase placeholder: apro lo scheletro navigabile.',
            ),
          ),
        );
        context.go('/farms');
        return;
      }

      final success = await service.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        context.go('/farms');
      } else {
        setState(() {
          _errorText =
              'Login non riuscito. Verifica credenziali e configurazione.';
        });
      }
    } on AuthException catch (error) {
      setState(() {
        _errorText = error.message;
      });
    } catch (error) {
      setState(() {
        _errorText = 'Errore inatteso: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = constraints.maxWidth;
            final isPhone = viewportWidth < AppResponsive.compactBreakpoint;
            final horizontalPadding = viewportWidth <= 320
                ? 12.0
                : viewportWidth <= AppResponsive.smallPhoneWidth
                ? 14.0
                : AppResponsive.screenPadding;
            const verticalPadding = 16.0;
            final fieldTextStyle = theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
            );

            return SingleChildScrollView(
              primary: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                viewInsetsBottom + verticalPadding,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppResponsive.maxPhoneContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppLogoPlaceholder(compact: isPhone),
                        SizedBox(height: isPhone ? 20 : 24),
                        Text('Login', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          'App mobile nativa per la gestione delle sessioni podali in stalla.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: isPhone ? 20 : 24),
                        if (!config.isSupabaseConfigured)
                          _LoginInfoBanner(
                            color: AppColors.warning,
                            backgroundColor: AppColors.warning.withValues(
                              alpha: 0.12,
                            ),
                            message:
                                'Configurazione Supabase ancora placeholder. Il pulsante Login apre lo scheletro navigabile per la UI MVP.',
                          ),
                        if (config.devBypassLogin)
                          _LoginInfoBanner(
                            color: AppColors.secondary,
                            backgroundColor: AppColors.secondary.withValues(
                              alpha: 0.12,
                            ),
                            message:
                                'Dev bypass attivo. Questa schermata e\' bypassata automaticamente nello sviluppo locale.',
                          ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                style: fieldTextStyle,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 120,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'Email',
                                  hintText: 'allevatore.test@appiombi.local',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Inserisci una email.';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Inserisci una email valida.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                style: fieldTextStyle,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 140,
                                ),
                                onFieldSubmitted: (_) =>
                                    _isSubmitting ? null : _submit(),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'Password',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Inserisci la password.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _errorText!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                        SizedBox(height: isPhone ? 20 : 24),
                        AppPrimaryButton(
                          label: _isSubmitting
                              ? 'Accesso in corso...'
                              : 'Login',
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Appiombi by Dairy Balance',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginInfoBanner extends StatelessWidget {
  const _LoginInfoBanner({
    required this.color,
    required this.backgroundColor,
    required this.message,
  });

  final Color color;
  final Color backgroundColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
