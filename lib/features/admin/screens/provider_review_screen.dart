import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/admin/providers/admin_provider_approval_provider.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/services/provider_service.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Platform Admin screen for reviewing a provider application and approving
/// a `Pending Verification` provider (`SCRUM-94` / `ADM-2`, Subtask `SCRUM-163`).
class ProviderReviewScreen extends ConsumerStatefulWidget {
  const ProviderReviewScreen({
    super.key,
    required this.providerId,
    this.initialProvider,
  });

  final String providerId;
  final ProviderModel? initialProvider;

  @override
  ConsumerState<ProviderReviewScreen> createState() =>
      _ProviderReviewScreenState();
}

class _ProviderReviewScreenState extends ConsumerState<ProviderReviewScreen> {
  ProviderModel? _currentProvider;
  bool _isApproving = false;
  bool _justApproved = false;

  @override
  void initState() {
    super.initState();
    _currentProvider = widget.initialProvider;
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/admin');
    }
  }

  Future<void> _handleApprove(
    ProviderModel provider,
    UserModel? actor,
  ) async {
    setState(() => _isApproving = true);

    try {
      final service = ref.read(providerServiceProvider);
      final approved = await service.approveProvider(
        providerId: provider.id,
        actor: actor,
      );

      ref.invalidate(providerDetailsProvider(widget.providerId));
      ref.invalidate(pendingProvidersProvider);
      ref.invalidate(approvedProvidersProvider);
      for (final categoryId in approved.categoryIds) {
        ref.invalidate(categoryProvidersProvider(categoryId));
      }

      if (mounted) {
        setState(() {
          _currentProvider = approved;
          _isApproving = false;
          _justApproved = true;
        });
      }
    } on UnauthorizedProviderApprovalException catch (e) {
      if (mounted) {
        setState(() => _isApproving = false);
        showSpError(context, e.message);
      }
    } on InvalidProviderApprovalStateException catch (e) {
      if (mounted) {
        setState(() => _isApproving = false);
        showSpError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApproving = false);
        showSpError(context, context.l10n.providerProfileError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actor = ref.watch(activeAdminActorProvider);
    final isAdmin = actor != null && actor.isAdmin;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.browseBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          leading: SpBackButton(onPressed: () => _goBack(context)),
          title: Text(
            l10n.adminProviderReviewTitle,
            style: AppTheme.display(size: 18, color: AppTheme.browseInk),
          ),
        ),
        body: Center(
          child: SpContentWidth(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.gutter),
              child: SpStatusHero(
                key: const Key('admin_access_denied_hero'),
                icon: Icons.lock_outline_rounded,
                title: l10n.adminAccessDeniedTitle,
                message: l10n.adminAccessDeniedMessage,
                tone: SpTone.danger,
              ),
            ),
          ),
        ),
      );
    }

    final providerAsync = ref.watch(providerDetailsProvider(widget.providerId));

    return Scaffold(
      backgroundColor: AppTheme.browseBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: SpBackButton(onPressed: () => _goBack(context)),
        title: Text(
          l10n.adminProviderReviewTitle,
          style: AppTheme.display(size: 18, color: AppTheme.browseInk),
        ),
      ),
      body: providerAsync.when(
        data: (fetched) {
          final provider = _currentProvider ?? fetched;
          if (provider == null) {
            return Center(
              child: SpContentWidth(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: SpStatusHero(
                    icon: Icons.person_off_rounded,
                    title: l10n.providerProfileNotFound,
                    message: l10n.providerProfileNotFoundBody,
                    tone: SpTone.neutral,
                  ),
                ),
              ),
            );
          }
          return _buildReviewBody(context, provider, actor);
        },
        loading: () {
          if (_currentProvider != null) {
            return _buildReviewBody(context, _currentProvider!, actor);
          }
          return Center(
            child: CircularProgressIndicator(
              semanticsLabel: l10n.providerProfileLoading,
            ),
          );
        },
        error: (_, __) {
          if (_currentProvider != null) {
            return _buildReviewBody(context, _currentProvider!, actor);
          }
          return Center(
            child: SpContentWidth(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.gutter),
                child: SpNotice(
                  icon: Icons.error_outline_rounded,
                  message: l10n.providerProfileError,
                  tone: SpTone.danger,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewBody(
    BuildContext context,
    ProviderModel provider,
    UserModel actor,
  ) {
    final l10n = context.l10n;
    final isPending = provider.isPendingVerification;
    final areas = provider.coverageAreas.isEmpty
        ? [provider.serviceArea]
        : provider.coverageAreas;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SpContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_justApproved || provider.isApprovedAndActive)
                    SpNotice(
                      key: const Key('admin_provider_approved_notice'),
                      icon: Icons.verified_rounded,
                      message: l10n.adminProviderApprovedNotice(
                        provider.displayName,
                      ),
                      tone: SpTone.success,
                    )
                  else if (isPending)
                    SpNotice(
                      key: const Key('admin_provider_pending_notice'),
                      icon: Icons.hourglass_top_rounded,
                      message: l10n.adminPendingVerificationNotice,
                      tone: SpTone.waiting,
                    ),
                  const SizedBox(height: 16),

                  // Identity & Status Card
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: AppTheme.browseBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ProviderTypeBadge(type: provider.type),
                              _VerificationStatusChip(provider: provider),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.displayName,
                            style: AppTheme.display(
                              size: 24,
                              color: AppTheme.browseInk,
                            ),
                          ),
                          if (provider.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              provider.description.trim(),
                              style: AppTheme.text(
                                size: 15,
                                color: AppTheme.browseSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Verification Checklist Card
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: AppTheme.browseBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.adminVerificationChecklistTitle,
                            style: AppTheme.display(
                              size: 17,
                              color: AppTheme.browseInk,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (provider.email.trim().isNotEmpty) ...[
                            _ReviewFieldRow(
                              icon: Icons.mail_outline_rounded,
                              label: l10n.adminContactEmailLabel,
                              value: provider.email.trim(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (provider.phone.trim().isNotEmpty) ...[
                            _ReviewFieldRow(
                              icon: Icons.call_outlined,
                              label: l10n.adminContactPhoneLabel,
                              value: provider.phone.trim(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _ReviewFieldRow(
                            icon: Icons.location_on_outlined,
                            label: l10n.providerAreas,
                            value: areas.join(', '),
                          ),
                          if (provider.specialties.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ReviewFieldRow(
                              icon: Icons.handyman_outlined,
                              label: l10n.providerSpecialties,
                              value: provider.specialties.join(', '),
                            ),
                          ],
                          if (provider.bio.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ReviewFieldRow(
                              icon: Icons.info_outline_rounded,
                              label: l10n.providerAbout,
                              value: provider.bio.trim(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Pinned Action Bar (follows DESIGN.md "The One Fill Rule")
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.browseBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SpContentWidth(
                child: isPending
                    ? SpPrimaryButton(
                        key: const Key('admin_approve_provider_button'),
                        label: l10n.adminApproveProviderButton,
                        icon: Icons.verified_user_outlined,
                        isLoading: _isApproving,
                        onPressed: () => _handleApprove(provider, actor),
                      )
                    : SpSecondaryButton(
                        key: const Key('admin_preview_customer_profile_button'),
                        label: l10n.adminViewCustomerProfileButton,
                        outlineColor: AppTheme.browseControlBorder,
                        wrapLabel: true,
                        onPressed: () => context.push(
                          '/providers/${provider.id}',
                          extra: provider,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationStatusChip extends StatelessWidget {
  const _VerificationStatusChip({required this.provider});

  final ProviderModel provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isApproved = provider.isApprovedAndActive;
    final tone = isApproved ? SpTone.success : SpTone.waiting;
    final label = isApproved ? l10n.adminApprovedBadge : l10n.adminPendingBadge;
    final icon = isApproved
        ? Icons.check_circle_rounded
        : Icons.schedule_rounded;

    return DecoratedBox(
      key: const Key('admin_provider_status_chip'),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: tone.foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTheme.text(
                  size: 13,
                  weight: FontWeight.w600,
                  color: tone.foreground,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewFieldRow extends StatelessWidget {
  const _ReviewFieldRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.text(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppTheme.browseSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.text(
                  size: 14.5,
                  color: AppTheme.browseInk,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
