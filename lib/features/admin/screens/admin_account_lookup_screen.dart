import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/features/admin/providers/admin_provider_approval_provider.dart';
import 'package:service_pilot/features/admin/services/admin_account_lookup_service.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

class AdminAccountLookupScreen extends ConsumerWidget {
  const AdminAccountLookupScreen({super.key});

  static const path = '/admin/accounts/lookup';

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/admin');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actor = ref.watch(activeAdminActorProvider);
    if (actor == null || !actor.isAdmin || !actor.isActive) {
      return SpFlowPage(
        title: l10n.adminAccountLookupTitle,
        onBack: () => _back(context),
        children: [
          SpStatusHero(
            icon: Icons.lock_outline_rounded,
            title: l10n.adminAccessDeniedTitle,
            message: l10n.adminAccountLookupDenied,
            tone: SpTone.danger,
          ),
        ],
      );
    }
    return _LookupForm(key: ValueKey(actor.id), actor: actor);
  }
}

class _LookupForm extends ConsumerStatefulWidget {
  const _LookupForm({super.key, required this.actor});

  final UserModel actor;

  @override
  ConsumerState<_LookupForm> createState() => _LookupFormState();
}

class _LookupFormState extends ConsumerState<_LookupForm> {
  final _formKey = GlobalKey<FormState>();
  final _accountId = TextEditingController();
  AsyncValue<AdminAccountSummary?>? _lookup;

  @override
  void dispose() {
    _accountId.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_lookup?.isLoading == true || !_formKey.currentState!.validate()) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _lookup = const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref.read(adminAccountLookupServiceProvider).lookup(
            _accountId.text,
            actor: widget.actor,
          ),
    );
    if (mounted) setState(() => _lookup = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loading = _lookup?.isLoading == true;

    return Form(
      key: _formKey,
      child: SpFlowPage(
        title: l10n.adminAccountLookupTitle,
        onBack: () => AdminAccountLookupScreen._back(context),
        bottom: SpPrimaryButton(
          label: l10n.adminAccountLookupSearch,
          onPressed: loading ? null : _search,
          isLoading: loading,
          wrapLabel: true,
        ),
        children: [
          SpPageHeader(title: l10n.adminAccountLookupTitle),
          const SizedBox(height: 24),
          SpTextField(
            key: const Key('admin_account_id'),
            label: l10n.adminAccountLookupId,
            hint: l10n.adminAccountLookupIdHint,
            controller: _accountId,
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.search,
            readOnly: loading,
            onFieldSubmitted: (_) => _search(),
            onChanged: (_) {
              if (_lookup != null) setState(() => _lookup = null);
            },
            validator: (value) =>
                AdminAccountLookupService.isValidAccountId(value ?? '')
                    ? null
                    : l10n.adminAccountLookupInvalid,
          ),
          if (_lookup case final result?) ...[
            const SizedBox(height: 24),
            Semantics(
              liveRegion: true,
              child: result.when(
                loading: () => const SizedBox.shrink(),
                error: (error, _) => SpNotice(
                  icon: Icons.error_outline_rounded,
                  message: error is FirebaseException &&
                          error.code == 'permission-denied'
                      ? l10n.adminAccountLookupDenied
                      : l10n.adminAccountLookupError,
                  tone: SpTone.danger,
                ),
                data: (summary) => summary == null
                    ? SpNotice(
                        icon: Icons.search_off_rounded,
                        message: l10n.adminAccountLookupEmpty,
                        tone: SpTone.neutral,
                      )
                    : _AccountSummary(summary: summary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.summary});

  final AdminAccountSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = switch (summary.role) {
      'homeowner' => l10n.roleHomeowner,
      'independent_provider' ||
      'independentProvider' =>
        l10n.roleIndependentProvider,
      'company' => l10n.roleCompany,
      'company_technician' || 'companyTechnician' => l10n.roleCompanyTechnician,
      'admin' => l10n.roleAdmin,
      _ => l10n.adminAccountLookupUnknown,
    };
    final status = switch (summary.status) {
      'active' => l10n.adminAccountStatusActive,
      'pending_verification' => l10n.adminPendingBadge,
      'suspended' => l10n.adminAccountStatusSuspended,
      _ => l10n.adminAccountLookupUnknown,
    };
    return SpFormSection(
      title: l10n.adminAccountLookupResult,
      children: [
        Text(l10n.adminAccountLookupRole(role)),
        const SizedBox(height: 8),
        Text(l10n.adminAccountLookupStatus(status)),
      ],
    );
  }
}
