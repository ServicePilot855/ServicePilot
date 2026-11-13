import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Two pages for every sign-up: first who you are, then your password.
///
/// The role choice before it is step 1, so these pages are steps 2 and 3.
/// The details fields belong to the calling screen (it owns their
/// controllers); this widget owns the page switch, the password fields and
/// the pinned buttons. Back, on screen or from the system, returns from the
/// password page to the details page before leaving the flow.
class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({
    super.key,
    required this.flowTitle,
    required this.detailsTitle,
    required this.detailsSubtitle,
    required this.detailsFields,
    required this.emailOf,
    required this.submitLabel,
    required this.isLoading,
    required this.onSubmit,
    required this.onExit,
    required this.onLogIn,
    this.detailsLead = const [],
    this.passwordNotice,
    this.submitKey,
    this.continueKey,
    this.passwordKey,
    this.confirmPasswordKey,
    this.confirmRequiredMessage,
  });

  /// Short name of the flow, shown in the top bar.
  final String flowTitle;
  final String detailsTitle;
  final String detailsSubtitle;

  /// Shown above the details fields (for example "Sign up with Google").
  final List<Widget> detailsLead;
  final List<Widget> detailsFields;

  /// The email entered on the details page, shown on the password page.
  final String Function() emailOf;

  /// Shown above the password fields (for example the verification notice).
  final Widget? passwordNotice;

  final String submitLabel;
  final bool isLoading;

  /// Called with the chosen password once both pages are valid.
  final Future<void> Function(String password) onSubmit;

  /// Leaves the flow from the details page.
  final VoidCallback onExit;
  final VoidCallback onLogIn;

  final Key? submitKey;
  final Key? continueKey;
  final Key? passwordKey;
  final Key? confirmPasswordKey;

  /// Message when the confirmation is left empty. Defaults to the mismatch
  /// message.
  final String? confirmRequiredMessage;

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  final _detailsKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _onPasswordPage = false;

  @override
  void initState() {
    super.initState();
    // Redraw the requirement checklist as the user types.
    _password.addListener(_refresh);
    _confirm.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    if (_detailsKey.currentState!.validate()) {
      setState(() => _onPasswordPage = true);
    }
  }

  void _back() {
    if (_onPasswordPage) {
      setState(() => _onPasswordPage = false);
    } else {
      widget.onExit();
    }
  }

  Future<void> _submit() async {
    if (_passwordFormKey.currentState!.validate()) {
      await widget.onSubmit(_password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: !_onPasswordPage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _onPasswordPage = false);
      },
      child: SpFlowPage(
        title: widget.flowTitle,
        onBack: _back,
        step: _onPasswordPage ? 3 : 2,
        totalSteps: 3,
        bottom: _onPasswordPage
            ? SpPrimaryButton(
                key: widget.submitKey,
                label: widget.submitLabel,
                onPressed: _submit,
                isLoading: widget.isLoading,
              )
            : SpPrimaryButton(
                key: widget.continueKey,
                label: l10n.registerContinue,
                onPressed: _continue,
              ),
        children: _onPasswordPage
            ? _passwordPage(context)
            : _detailsPage(context),
      ),
    );
  }

  List<Widget> _detailsPage(BuildContext context) {
    final l10n = context.l10n;
    return [
      SpPageHeader(
        title: widget.detailsTitle,
        subtitle: widget.detailsSubtitle,
      ),
      const SizedBox(height: 28),
      ...widget.detailsLead,
      Form(
        key: _detailsKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, field) in widget.detailsFields.indexed) ...[
              if (i > 0) const SizedBox(height: 18),
              field,
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      Center(
        child: SpFooterLink(
          prompt: l10n.commonAlreadyHaveAccount,
          action: l10n.commonLogInLink,
          onTap: widget.onLogIn,
        ),
      ),
    ];
  }

  List<Widget> _passwordPage(BuildContext context) {
    final l10n = context.l10n;
    final longEnough = _password.text.length >= 8;
    final matches = _password.text.isNotEmpty && _password.text == _confirm.text;

    return [
      SpPageHeader(
        title: l10n.registerPasswordTitle,
        subtitle: l10n.registerPasswordSubtitle(widget.emailOf()),
      ),
      const SizedBox(height: 28),
      if (widget.passwordNotice != null) ...[
        widget.passwordNotice!,
        const SizedBox(height: 24),
      ],
      Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SpPasswordField(
              key: widget.passwordKey,
              label: l10n.commonPasswordLabel,
              hint: l10n.commonPasswordHint,
              controller: _password,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.commonPasswordRequired;
                if (v.length < 8) return l10n.commonPasswordMinLength;
                return null;
              },
            ),
            const SizedBox(height: 18),
            SpPasswordField(
              key: widget.confirmPasswordKey,
              label: l10n.commonConfirmPasswordLabel,
              hint: l10n.commonRepeatPasswordHint,
              controller: _confirm,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if ((v == null || v.isEmpty) &&
                    widget.confirmRequiredMessage != null) {
                  return widget.confirmRequiredMessage;
                }
                if (v != _password.text) return l10n.commonPasswordsDoNotMatch;
                return null;
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _Requirement(met: longEnough, label: l10n.registerRuleLength),
      const SizedBox(height: 8),
      _Requirement(met: matches, label: l10n.registerRuleMatch),
    ];
  }
}

/// One line of the password checklist: a tick once the rule is met.
class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: met ? context.l10n.registerRuleMet : context.l10n.registerRuleNotMet,
      excludeSemantics: true,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              met
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(met),
              size: 20,
              color: met ? AppTheme.success : AppTheme.fieldBorder,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTheme.text(
                size: 14,
                color: met ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
