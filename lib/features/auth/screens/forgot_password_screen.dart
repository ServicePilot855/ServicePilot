import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Forgot password: ask for the account email, then confirm the link was sent.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;
  String _sentEmail = '';

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    await ref.read(authProvider.notifier).requestPasswordReset(email);

    if (!mounted) return;

    setState(() {
      _emailSent = true;
      _sentEmail = email;
      _resendCountdown = 60;
    });
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    await ref.read(authProvider.notifier).requestPasswordReset(_sentEmail);
    if (!mounted) return;
    setState(() => _resendCountdown = 60);
    _startResendTimer();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthStateLoading;
    final l10n = context.l10n;

    if (_emailSent) {
      return SpFlowPage(
        title: l10n.forgotPasswordTitle,
        onBack: _back,
        bottom: SpPrimaryButton(
          label: l10n.commonBackToLogin,
          onPressed: () => context.go('/login'),
        ),
        children: [
          const SizedBox(height: 12),
          SpStatusHero(
            icon: Icons.mark_email_read_outlined,
            tone: SpTone.success,
            title: l10n.forgotPasswordSentTitle,
            message: l10n.forgotPasswordSentMessage,
            detail: _sentEmail,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SpTextButton(
              label: _resendCountdown > 0
                  ? l10n.forgotPasswordResendCountdown(_resendCountdown)
                  : l10n.forgotPasswordResend,
              onPressed: _resendCountdown == 0 ? _handleResend : null,
            ),
          ),
        ],
      );
    }

    return SpFlowPage(
      title: l10n.forgotPasswordTitle,
      onBack: _back,
      bottom: SpPrimaryButton(
        label: l10n.forgotPasswordSubmit,
        onPressed: _handleSubmit,
        isLoading: isLoading,
      ),
      children: [
        SpPageHeader(
          title: l10n.forgotPasswordHeaderTitle,
          subtitle: l10n.forgotPasswordHeaderSubtitle,
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: SpTextField(
            label: l10n.commonEmailAddressLabel,
            hint: l10n.forgotPasswordEmailHint,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            prefixIcon: Icons.mail_outline_rounded,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n.commonEmailRequired;
              }
              if (!EmailValidator.validate(v.trim())) {
                return l10n.commonEmailInvalid;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
