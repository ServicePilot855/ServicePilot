import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/features/auth/widgets/registration_flow.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Sign-up for customers (homeowners): details on one page, password on the
/// next. Google sign-up is offered first on the details page.
class RegisterCustomerScreen extends ConsumerStatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  ConsumerState<RegisterCustomerScreen> createState() =>
      _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState
    extends ConsumerState<RegisterCustomerScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/role-select');
    }
  }

  void _showAuthError() {
    final state = ref.read(authProvider);
    if (state is AuthStateError) {
      showSpError(context, state.message);
      ref.read(authProvider.notifier).clearError();
    }
  }

  Future<void> _handleRegister(String password) async {
    final success = await ref.read(authProvider.notifier).registerCustomer(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: password,
        );

    if (!mounted) return;
    final l10n = context.l10n;

    if (success) {
      await showSpResultSheet(
        context,
        icon: Icons.check_circle_outline_rounded,
        tone: SpTone.success,
        title: l10n.registerCustomerSuccessTitle,
        message: l10n.registerCustomerSuccessMessage,
        actionLabel: l10n.registerCustomerGoToLogin,
      );
      if (mounted) context.go('/login');
    } else {
      _showAuthError();
    }
  }

  Future<void> _handleGoogleSignUp() async {
    await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;

    final state = ref.read(authProvider);
    if (state is AuthStateAuthenticated) {
      context.go(state.user.role.homeRoute);
    } else {
      _showAuthError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLoading = ref.watch(authProvider) is AuthStateLoading;

    return RegistrationFlow(
      flowTitle: l10n.registerCustomerTitle,
      detailsTitle: l10n.registerCustomerHeaderTitle,
      detailsSubtitle: l10n.registerCustomerHeaderSubtitle,
      emailOf: () => _emailController.text.trim(),
      submitLabel: l10n.registerCustomerSubmit,
      isLoading: isLoading,
      onSubmit: _handleRegister,
      onExit: _back,
      onLogIn: () => context.go('/login'),
      detailsLead: [
        SpGoogleButton(
          label: l10n.registerCustomerGoogleButton,
          onPressed: isLoading ? null : _handleGoogleSignUp,
        ),
        const SizedBox(height: 20),
        SpOrDivider(label: l10n.registerCustomerOrUseEmail),
        const SizedBox(height: 20),
      ],
      detailsFields: [
        SpTextField(
          label: l10n.commonFullNameLabel,
          hint: l10n.registerCustomerNameHint,
          controller: _nameController,
          keyboardType: TextInputType.name,
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return l10n.commonFullNameRequired;
            }
            if (v.trim().length > 100) {
              return l10n.registerCustomerNameTooLong;
            }
            return null;
          },
        ),
        SpTextField(
          label: l10n.commonEmailAddressLabel,
          hint: l10n.registerCustomerEmailHint,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
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
        SpTextField(
          label: l10n.commonPhoneCambodiaLabel,
          hint: l10n.registerCustomerPhoneHint,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return l10n.commonPhoneRequired;
            }
            final cleaned = v.replaceAll(RegExp(r'[\s\-]'), '');
            if (!RegExp(r'^(\+855|0)[0-9]{8,9}$').hasMatch(cleaned)) {
              return l10n.commonPhoneInvalid;
            }
            return null;
          },
        ),
      ],
    );
  }
}
