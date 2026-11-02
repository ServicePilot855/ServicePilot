import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Screen for company technicians activating their account via invite link.
/// Styled in Figma Dark Theme (`#0A0A0A`, `#17181B`, `#FF5000`).
class TechnicianActivationScreen extends ConsumerStatefulWidget {
  const TechnicianActivationScreen({super.key, required this.token});

  final String token;

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
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  late final bool _isTokenValid;

  @override
  void initState() {
    super.initState();
    _isTokenValid =
        ref.read(mockAuthServiceProvider).validateInviteToken(widget.token);
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

    final success =
        await ref.read(authProvider.notifier).activateTechnicianAccount(
              token: widget.token,
              fullName: _nameController.text.trim(),
              password: _passwordController.text,
            );

    if (!mounted) return;

    if (success) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            side: const BorderSide(color: AppTheme.border, width: 1),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
              const SizedBox(width: 10),
              Text(
                'Account Activated!',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Your company technician account is active. You can now log in to view assigned repair jobs.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/login');
    } else {
      final state = ref.read(authProvider);
      if (state is AuthStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.message,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    }
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
            onPressed: () => context.go('/login'),
          ),
        ),
        title: Text(
          'Activate Account',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _isTokenValid ? _buildForm(isLoading) : _buildInvalidTokenState(),
        ),
      ),
    );
  }

  Widget _buildInvalidTokenState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.error.withValues(alpha: 0.3), width: 1),
          ),
          child: const Icon(
            Icons.link_off_rounded,
            size: 36,
            color: AppTheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Invalid or Expired Link',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This technician invitation link is invalid or has expired. Please ask your company administrator to send you a new invitation.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 36),
        SpPrimaryButton(
          label: 'Back to Login',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    size: 22,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phnom Penh Fix Co.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Invited Company Technician',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Complete your account',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set your full name and password to activate your company technician profile.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // ── Pre-filled email ───────────────────────────────────────
          const SpTextField(
            label: 'Email Address (From invitation)',
            initialValue: 'tech.invited@company.com',
            readOnly: true,
            prefixIcon: Icon(Icons.email_outlined),
          ),
          const SizedBox(height: 16),

          // ── Full name ─────────────────────────────────────────────
          SpTextField(
            label: 'Full Name',
            hint: 'Borey Nhem',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Password ──────────────────────────────────────────────
          SpTextField(
            label: 'Create Password',
            hint: 'Min. 8 characters',
            controller: _passwordController,
            obscureText: !_passwordVisible,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Confirm password ──────────────────────────────────────
          SpTextField(
            label: 'Confirm Password',
            hint: 'Repeat your password',
            controller: _confirmPasswordController,
            obscureText: !_confirmPasswordVisible,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: () => setState(
                  () => _confirmPasswordVisible = !_confirmPasswordVisible),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleActivate(),
            validator: (v) {
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ── Activate button ───────────────────────────────────────
          SpPrimaryButton(
            label: 'Activate Account',
            onPressed: _handleActivate,
            isLoading: isLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
