import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Forgot password screen.
/// Styled in Figma Dark Theme (`#0A0A0A`, `#17181B`, `#FF5000`).
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthStateLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            color: AppTheme.textPrimary,
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _emailSent
              ? _buildEmailSentState()
              : _buildFormState(isLoading),
        ),
      ),
    );
  }

  Widget _buildFormState(bool isLoading) {
    return SingleChildScrollView(
      key: const ValueKey('form_state'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 28,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Forgot your password?',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your registered email address below. We will send you a link to reset your password.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),

            SpTextField(
              label: 'Email Address',
              hint: 'customer@test.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSubmit(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!EmailValidator.validate(v.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            SpPrimaryButton(
              label: 'Send Reset Link',
              onPressed: _handleSubmit,
              isLoading: isLoading,
            ),
            const SizedBox(height: 16),

            SpSecondaryButton(
              label: 'Simulate Click on Reset Link (Dev)',
              onPressed: () {
                context.push('/reset-password?token=RESET-MOCK-TOKEN');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSentState() {
    return SingleChildScrollView(
      key: const ValueKey('sent_state'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 36,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Check your inbox',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'We sent a time-limited password reset link to:',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _sentEmail,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 36),

          SpPrimaryButton(
            label: 'Open Reset Link (Dev Demo)',
            onPressed: () {
              context.push('/reset-password?token=RESET-MOCK-TOKEN');
            },
          ),
          const SizedBox(height: 12),

          SpSecondaryButton(
            label: 'Back to Login',
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(height: 24),

          TextButton(
            onPressed: _resendCountdown == 0 ? _handleResend : null,
            child: Text(
              _resendCountdown > 0
                  ? 'Resend email in ${_resendCountdown}s'
                  : 'Didn\'t get it? Resend email',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _resendCountdown > 0
                    ? AppTheme.textMuted
                    : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
