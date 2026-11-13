import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Reset password: set a new password from an emailed link.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// 0 = empty, 1 = weak, 2 = good, 3 = strong.
  int _passwordStrength = 0;

  bool get _isTokenValid => widget.token.isNotEmpty;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String value) {
    int strength = 0;
    if (value.length >= 8) strength++;
    if (value.contains(RegExp(r'[A-Z]'))) strength++;
    if (value.contains(RegExp(r'[0-9]'))) strength++;
    setState(() => _passwordStrength = strength);
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final success = await ref.read(authProvider.notifier).resetPassword(
          token: widget.token,
          newPassword: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      await showSpResultSheet(
        context,
        icon: Icons.check_circle_outline_rounded,
        title: l10n.resetPasswordSuccessTitle,
        message: l10n.resetPasswordSuccessMessage,
        actionLabel: l10n.resetPasswordGoToLogin,
      );
      if (mounted) context.go('/login');
    } else {
      final state = ref.read(authProvider);
      if (state is AuthStateError) {
        showSpError(context, state.message);
        ref.read(authProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthStateLoading;
    final l10n = context.l10n;

    if (!_isTokenValid) {
      return SpFlowPage(
        title: l10n.resetPasswordTitle,
        onBack: () => context.go('/login'),
        bottom: SpPrimaryButton(
          label: l10n.resetPasswordRequestNewLink,
          onPressed: () => context.push('/forgot-password'),
        ),
        children: [
          const SizedBox(height: 12),
          SpStatusHero(
            icon: Icons.link_off_rounded,
            tone: SpTone.danger,
            title: l10n.commonInvalidLinkTitle,
            message: l10n.resetPasswordInvalidLinkMessage,
          ),
        ],
      );
    }

    return SpFlowPage(
      title: l10n.resetPasswordTitle,
      onBack: () => context.go('/login'),
      bottom: SpPrimaryButton(
        label: l10n.resetPasswordSubmit,
        onPressed: _handleReset,
        isLoading: isLoading,
      ),
      children: [
        SpPageHeader(
          title: l10n.resetPasswordHeaderTitle,
          subtitle: l10n.resetPasswordHeaderSubtitle,
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpPasswordField(
                label: l10n.resetPasswordNewPasswordLabel,
                hint: l10n.commonPasswordHint,
                controller: _passwordController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: _updatePasswordStrength,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return l10n.commonPasswordRequired;
                  }
                  if (v.length < 8) return l10n.commonPasswordMinLength;
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _StrengthMeter(level: _passwordStrength),
              const SizedBox(height: 16),
              SpPasswordField(
                label: l10n.resetPasswordConfirmLabel,
                hint: l10n.resetPasswordConfirmHint,
                controller: _confirmPasswordController,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _handleReset(),
                validator: (v) {
                  if (v != _passwordController.text) {
                    return l10n.commonPasswordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Three flat segments plus the level in words, so strength never relies on
/// colour alone.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.level});

  final int level;

  static const _fills = [
    AppTheme.border,
    AppTheme.error,
    AppTheme.accent,
    AppTheme.success,
  ];
  static const _textColors = [
    AppTheme.textSecondary,
    AppTheme.errorDeep,
    AppTheme.accentDeep,
    AppTheme.successDeep,
  ];

  String _label(AppLocalizations l10n) => switch (level) {
        1 => l10n.resetPasswordStrengthWeak,
        2 => l10n.resetPasswordStrengthGood,
        3 => l10n.resetPasswordStrengthStrong,
        _ => l10n.resetPasswordStrengthHint,
      };

  @override
  Widget build(BuildContext context) {
    final text = _label(context.l10n);

    return Semantics(
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < level ? _fills[level] : AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTheme.text(
              size: 13,
              weight: level == 0 ? FontWeight.w400 : FontWeight.w600,
              color: _textColors[level],
            ),
          ),
        ],
      ),
    );
  }
}
