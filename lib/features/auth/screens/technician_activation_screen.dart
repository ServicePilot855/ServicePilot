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

/// Screen for company technicians activating their account via invite link.
class TechnicianActivationScreen extends ConsumerStatefulWidget {
  const TechnicianActivationScreen({
    super.key,
    required this.token,
    this.email,
    this.companyName,
  });

  final String token;
  final String? email;
  final String? companyName;

  @override
  ConsumerState<TechnicianActivationScreen> createState() =>
      _TechnicianActivationScreenState();
}

class _TechnicianActivationScreenState
    extends ConsumerState<TechnicianActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final bool _isTokenValid;

  @override
  void initState() {
    super.initState();
    _isTokenValid =
        ref.read(authServiceProvider).validateInviteToken(widget.token);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleActivate() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final success =
        await ref.read(authProvider.notifier).activateTechnicianAccount(
              token: widget.token,
              fullName: _nameController.text.trim(),
              password: _passwordController.text,
              email: widget.email,
            );

    if (!mounted) return;

    if (success) {
      await showSpResultSheet(
        context,
        icon: Icons.check_circle_outline_rounded,
        title: l10n.activationSuccessTitle,
        message: l10n.activationSuccessMessage,
        actionLabel: l10n.activationGoToLogin,
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
        title: l10n.activationTitle,
        onBack: () => context.go('/login'),
        bottom: SpPrimaryButton(
          label: l10n.commonBackToLogin,
          onPressed: () => context.go('/login'),
        ),
        children: [
          const SizedBox(height: 12),
          SpStatusHero(
            icon: Icons.link_off_rounded,
            tone: SpTone.danger,
            title: l10n.commonInvalidLinkTitle,
            message: l10n.activationInvalidLinkMessage,
          ),
        ],
      );
    }

    return SpFlowPage(
      title: l10n.activationTitle,
      onBack: () => context.go('/login'),
      bottom: SpPrimaryButton(
        label: l10n.activationSubmit,
        onPressed: _handleActivate,
        isLoading: isLoading,
      ),
      children: [
        SpPageHeader(
          title: l10n.activationHeaderTitle,
          subtitle: l10n.activationHeaderSubtitle,
        ),
        const SizedBox(height: 20),
        _CompanyRow(
          companyName: widget.companyName ?? l10n.activationDefaultCompanyName,
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpFormSection(
                title: l10n.commonYourDetails,
                children: [
                  SpTextField(
                    label: l10n.activationEmailLabel,
                    initialValue:
                        widget.email ?? 'tech.invited@servicepilot.app',
                    readOnly: true,
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  SpTextField(
                    label: l10n.commonFullNameLabel,
                    hint: l10n.activationFullNameHint,
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.commonFullNameRequired;
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SpFormSection(
                title: l10n.commonSecurity,
                children: [
                  SpPasswordField(
                    label: l10n.activationPasswordLabel,
                    hint: l10n.commonPasswordHint,
                    controller: _passwordController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return l10n.commonPasswordRequired;
                      }
                      if (v.length < 8) return l10n.commonPasswordMinLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SpPasswordField(
                    label: l10n.commonConfirmPasswordLabel,
                    hint: l10n.commonRepeatPasswordHint,
                    controller: _confirmPasswordController,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _handleActivate(),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return l10n.commonPasswordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Plain row naming the company that sent the invitation.
class _CompanyRow extends StatelessWidget {
  const _CompanyRow({required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.apartment_rounded,
            size: 24,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: AppTheme.text(
                    size: 16,
                    weight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.activationInvitedRole,
                  style: AppTheme.text(
                    size: 13.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
