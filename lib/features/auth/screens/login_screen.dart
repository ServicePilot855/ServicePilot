import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_brand.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Entry screen for returning users: email or phone and password, Google for
/// homeowners, and one link to create an account.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authProvider.notifier);
    await notifier.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    _afterSignIn();
  }

  Future<void> _handleGoogleSignIn() async {
    final notifier = ref.read(authProvider.notifier);
    await notifier.signInWithGoogle();

    _afterSignIn();
  }

  void _afterSignIn() {
    if (!mounted) return;

    final state = ref.read(authProvider);
    if (state is AuthStateAuthenticated) {
      context.go(state.user.role.homeRoute);
    } else if (state is AuthStateError) {
      showSpError(context, state.message);
      ref.read(authProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthStateLoading;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            20,
            AppTheme.gutter,
            24,
          ),
          child: SpContentWidth(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SpWordmark(),
                  const SizedBox(height: 32),
                  SpPageHeader(
                    title: l10n.loginTitle,
                    subtitle: l10n.loginSubtitle,
                  ),
                  const SizedBox(height: 28),

                  SpTextField(
                    label: l10n.loginIdentifierLabel,
                    hint: l10n.loginIdentifierHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.loginIdentifierRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SpPasswordField(
                    label: l10n.commonPasswordLabel,
                    hint: l10n.loginPasswordHint,
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return l10n.loginPasswordRequired;
                      }
                      if (v.length < 8) {
                        return l10n.loginPasswordMinLength;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),

                  // Remember me / forgot password
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Semantics(
                            checked: _rememberMe,
                            label: l10n.loginRememberMe,
                            excludeSemantics: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusChip,
                              ),
                              onTap: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(minHeight: 48),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox.square(
                                      dimension: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (val) => setState(
                                          () => _rememberMe = val ?? false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        l10n.loginRememberMe,
                                        style: AppTheme.text(size: 15),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SpTextButton(
                        label: l10n.loginForgotPassword,
                        onPressed: () => context.push('/forgot-password'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SpPrimaryButton(
                    label: l10n.loginSubmit,
                    onPressed: _handleLogin,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 20),
                  const SpOrDivider(),
                  const SizedBox(height: 20),
                  SpGoogleButton(
                    label: l10n.loginGoogle,
                    onPressed: isLoading ? null : _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: SpFooterLink(
                      prompt: l10n.loginNewPrompt,
                      action: l10n.loginCreateAccount,
                      onTap: () => context.go('/role-select'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
