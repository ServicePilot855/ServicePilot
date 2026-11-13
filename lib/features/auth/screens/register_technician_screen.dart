import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/features/auth/widgets/registration_flow.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Sign-up for independent technicians: details on one page, password on
/// the next, with the verification notice shown before the account is created.
class RegisterTechnicianScreen extends ConsumerStatefulWidget {
  const RegisterTechnicianScreen({super.key});

  @override
  ConsumerState<RegisterTechnicianScreen> createState() =>
      _RegisterTechnicianScreenState();
}

class _RegisterTechnicianScreenState
    extends ConsumerState<RegisterTechnicianScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _serviceAreaController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _serviceAreaController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/role-select');
    }
  }

  Future<void> _handleRegister(String password) async {
    final success = await ref.read(authProvider.notifier).registerTechnician(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          serviceArea: _serviceAreaController.text.trim(),
          password: password,
        );

    if (!mounted) return;
    final l10n = context.l10n;

    if (success) {
      await showSpResultSheet(
        context,
        icon: Icons.hourglass_top_rounded,
        tone: SpTone.waiting,
        title: l10n.registerTechnicianSuccessTitle,
        message: l10n.registerTechnicianSuccessMessage,
        actionLabel: l10n.registerOk,
        actionKey: const Key('technician_dialog_ok_button'),
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
    final l10n = context.l10n;
    final isLoading = ref.watch(authProvider) is AuthStateLoading;

    return RegistrationFlow(
      flowTitle: l10n.registerTechnicianTitle,
      detailsTitle: l10n.registerTechnicianHeaderTitle,
      detailsSubtitle: l10n.registerTechnicianHeaderSubtitle,
      emailOf: () => _emailController.text.trim(),
      submitLabel: l10n.registerTechnicianSubmit,
      submitKey: const Key('technician_register_button'),
      continueKey: const Key('technician_continue_button'),
      passwordKey: const Key('technician_password_field'),
      confirmPasswordKey: const Key('technician_confirm_password_field'),
      confirmRequiredMessage: l10n.registerTechnicianConfirmPasswordRequired,
      isLoading: isLoading,
      onSubmit: _handleRegister,
      onExit: _back,
      onLogIn: () => context.go('/login'),
      passwordNotice: SpNotice(
        icon: Icons.hourglass_top_rounded,
        tone: SpTone.waiting,
        message: l10n.registerTechnicianNotice,
      ),
      detailsFields: [
        SpTextField(
          key: const Key('technician_name_field'),
          label: l10n.commonFullNameLabel,
          hint: l10n.registerTechnicianNameHint,
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
              return l10n.registerTechnicianNameTooLong;
            }
            return null;
          },
        ),
        SpTextField(
          key: const Key('technician_email_field'),
          label: l10n.commonEmailAddressLabel,
          hint: l10n.registerTechnicianEmailHint,
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
          key: const Key('technician_phone_field'),
          label: l10n.commonPhoneCambodiaLabel,
          hint: l10n.registerTechnicianPhoneHint,
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
        SpTextField(
          key: const Key('technician_service_area_field'),
          label: l10n.registerTechnicianServiceAreaLabel,
          hint: l10n.registerTechnicianServiceAreaHint,
          controller: _serviceAreaController,
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return l10n.registerTechnicianServiceAreaRequired;
            }
            if (v.trim().length > 300) {
              return l10n.registerTechnicianServiceAreaTooLong;
            }
            return null;
          },
        ),
      ],
    );
  }
}
