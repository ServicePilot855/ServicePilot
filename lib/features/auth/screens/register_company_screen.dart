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

/// Sign-up for service companies: company details on one page, password on
/// the next, with the verification notice shown before the account is created.
class RegisterCompanyScreen extends ConsumerStatefulWidget {
  const RegisterCompanyScreen({super.key});

  @override
  ConsumerState<RegisterCompanyScreen> createState() =>
      _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends ConsumerState<RegisterCompanyScreen> {
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _serviceAreaController = TextEditingController();

  @override
  void dispose() {
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
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
    final success = await ref.read(authProvider.notifier).registerCompany(
          ownerFullName: _ownerNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          companyName: _companyNameController.text.trim(),
          serviceArea: _serviceAreaController.text.trim(),
          password: password,
        );

    if (!mounted) return;
    final l10n = context.l10n;

    if (success) {
      await showSpResultSheet(
        context,
        icon: Icons.apartment_rounded,
        tone: SpTone.waiting,
        title: l10n.registerCompanySuccessTitle,
        message: l10n.registerCompanySuccessMessage,
        actionLabel: l10n.registerOk,
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
      flowTitle: l10n.registerCompanyTitle,
      detailsTitle: l10n.registerCompanyHeaderTitle,
      detailsSubtitle: l10n.registerCompanyHeaderSubtitle,
      emailOf: () => _emailController.text.trim(),
      submitLabel: l10n.registerCompanySubmit,
      isLoading: isLoading,
      onSubmit: _handleRegister,
      onExit: _back,
      onLogIn: () => context.go('/login'),
      passwordNotice: SpNotice(
        icon: Icons.hourglass_top_rounded,
        tone: SpTone.waiting,
        message: l10n.registerCompanyNotice,
      ),
      detailsFields: [
        SpTextField(
          label: l10n.registerCompanyOwnerNameLabel,
          hint: l10n.registerCompanyOwnerNameHint,
          controller: _ownerNameController,
          keyboardType: TextInputType.name,
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return l10n.registerCompanyOwnerNameRequired;
            }
            return null;
          },
        ),
        SpTextField(
          label: l10n.registerCompanyNameLabel,
          hint: l10n.registerCompanyNameHint,
          controller: _companyNameController,
          prefixIcon: Icons.apartment_rounded,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.organizationName],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return l10n.registerCompanyNameRequired;
            }
            if (v.trim().length > 150) {
              return l10n.registerCompanyNameTooLong;
            }
            return null;
          },
        ),
        SpTextField(
          label: l10n.registerCompanyEmailLabel,
          hint: l10n.registerCompanyEmailHint,
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
          label: l10n.registerCompanyPhoneLabel,
          hint: l10n.registerCompanyPhoneHint,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return l10n.commonPhoneRequired;
            }
            return null;
          },
        ),
        SpTextField(
          label: l10n.registerCompanyAddressLabel,
          hint: l10n.registerCompanyAddressHint,
          controller: _serviceAreaController,
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return l10n.registerCompanyAddressRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
