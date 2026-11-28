import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/admin/providers/admin_provider_approval_provider.dart';
import 'package:service_pilot/features/admin/screens/admin_account_lookup_screen.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_brand.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Platform Admin Dashboard (`SCRUM-93` / `SCRUM-94` / `ADM-1` & `ADM-2`).
///
/// Features an executive metrics overview, priority pending applications preview
/// with direct link to the full review queue (`/admin/providers/pending`),
/// and approved active providers directory.
class AdminHome extends ConsumerWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actor = ref.watch(activeAdminActorProvider);
    final isAdmin = actor != null && actor.isAdmin;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.browseBackground,
        body: SafeArea(
          child: Center(
            child: SpContentWidth(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.gutter),
                child: SpStatusHero(
                  key: const Key('admin_home_access_denied'),
                  icon: Icons.lock_outline_rounded,
                  title: l10n.adminAccessDeniedTitle,
                  message: l10n.adminAccessDeniedMessage,
                  tone: SpTone.danger,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final pendingAsync = ref.watch(pendingProvidersProvider);
    final approvedAsync = ref.watch(approvedProvidersProvider);
    final firstName = actor.fullName.trim().isEmpty
        ? l10n.roleAdmin
        : actor.fullName.trim().split(RegExp(r'\s+')).first;

    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;
    final approvedCount = approvedAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.browseBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SpContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Navigation Bar ──────────────────────────────────────
                Row(
                  children: [
                    const SpLogoMark(size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appName,
                            style: AppTheme.display(
                              size: 18,
                              color: AppTheme.browseInk,
                            ),
                          ),
                          Text(
                            l10n.adminDashboardTitle,
                            style: AppTheme.text(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppTheme.browseSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.browseSecondary,
                        size: 20,
                      ),
                      tooltip: l10n.homeLogOut,
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Welcome Greeting ────────────────────────────────────────
                Text(
                  l10n.homeGreeting(firstName),
                  style: AppTheme.display(size: 26, color: AppTheme.browseInk),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review provider applications and oversee active services',
                  style: AppTheme.text(
                    size: 14,
                    color: AppTheme.browseSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                if (actor.isActive) ...[
                  SpSecondaryButton(
                    label: l10n.adminAccountLookupTitle,
                    icon: Icons.manage_search_rounded,
                    wrapLabel: true,
                    onPressed: () =>
                        context.push(AdminAccountLookupScreen.path),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Executive Metrics Row (Quick Overview) ──────────────────
                Row(
                  children: [
                    // Metric 1: Pending Applications
                    Expanded(
                      child: _MetricCard(
                        title: 'Awaiting review',
                        count: pendingCount,
                        badgeText: 'Action needed',
                        tone: SpTone.waiting,
                        icon: Icons.pending_actions_rounded,
                        onTap: () => context.push('/admin/providers/pending'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Metric 2: Active Providers
                    Expanded(
                      child: _MetricCard(
                        title: 'Active providers',
                        count: approvedCount,
                        badgeText: 'Listed',
                        tone: SpTone.success,
                        icon: Icons.verified_rounded,
                        onTap: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Section 1: Pending Applications Preview ─────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              l10n.adminPendingProvidersSection,
                              style: AppTheme.display(
                                size: 18,
                                color: AppTheme.browseInk,
                              ),
                            ),
                          ),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentSoft,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusChip),
                              ),
                              child: Text(
                                '$pendingCount pending',
                                style: AppTheme.text(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: AppTheme.accentDeep,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton(
                      key: const Key('admin_home_view_all_pending_button'),
                      onPressed: () => context.push('/admin/providers/pending'),
                      child: Text(
                        'View all ($pendingCount) →',
                        style: AppTheme.text(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                pendingAsync.when(
                  data: (pendingProviders) {
                    if (pendingProviders.isEmpty) {
                      return SpNotice(
                        key: const Key('admin_pending_empty_notice'),
                        icon: Icons.check_circle_outline_rounded,
                        message: l10n.adminPendingProvidersEmpty,
                        tone: SpTone.neutral,
                      );
                    }

                    // Render preview items (capped at 2 to avoid infinite home scroll)
                    final displayedPending = pendingProviders.take(2).toList();
                    return Column(
                      children: [
                        ...displayedPending.map((provider) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AdminProviderCard(
                              key: Key('admin_pending_provider_${provider.id}'),
                              provider: provider,
                              onTap: () => context.push(
                                '/admin/providers/${provider.id}',
                                extra: provider,
                              ),
                            ),
                          );
                        }),
                        if (pendingProviders.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: SpSecondaryButton(
                              label:
                                  'View all ${pendingProviders.length} pending applications',
                              icon: Icons.checklist_rounded,
                              onPressed: () =>
                                  context.push('/admin/providers/pending'),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => SpNotice(
                    icon: Icons.error_outline_rounded,
                    message: '${l10n.providerDirectoryError}\n$err',
                    tone: SpTone.danger,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Section 2: Approved Active Providers Preview ────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              l10n.adminApprovedProvidersSection,
                              style: AppTheme.display(
                                size: 18,
                                color: AppTheme.browseInk,
                              ),
                            ),
                          ),
                          if (approvedCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successSoft,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusChip),
                              ),
                              child: Text(
                                '$approvedCount active',
                                style: AppTheme.text(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: AppTheme.successDeep,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                approvedAsync.when(
                  data: (approvedProviders) {
                    final displayedApproved =
                        approvedProviders.take(2).toList();
                    return Column(
                      children: displayedApproved.map((provider) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AdminProviderCard(
                            key: Key('admin_approved_provider_${provider.id}'),
                            provider: provider,
                            onTap: () => context.push(
                              '/admin/providers/${provider.id}',
                              extra: provider,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact executive metric card shown on top of the dashboard.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.count,
    required this.badgeText,
    required this.tone,
    required this.icon,
    this.onTap,
  });

  final String title;
  final int count;
  final String badgeText;
  final SpTone tone;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.browseBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: tone.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    ),
                    child: Icon(icon, size: 18, color: tone.foreground),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: tone.background,
                        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTheme.text(
                          size: 11,
                          weight: FontWeight.w700,
                          color: tone.foreground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: AppTheme.display(size: 24, color: AppTheme.browseInk),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTheme.text(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppTheme.browseSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Refined provider preview card for the dashboard list.
class _AdminProviderCard extends StatelessWidget {
  const _AdminProviderCard({
    super.key,
    required this.provider,
    required this.onTap,
  });

  final ProviderModel provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isApproved = provider.isApprovedAndActive;
    final statusTone = isApproved ? SpTone.success : SpTone.waiting;
    final statusLabel =
        isApproved ? l10n.adminApprovedBadge : l10n.adminPendingBadge;
    final statusIcon =
        isApproved ? Icons.check_circle_rounded : Icons.schedule_rounded;

    return Material(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.browseBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ProviderTypeBadge(type: provider.type),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: statusTone.background,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusChip),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 14,
                                  color: statusTone.foreground,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: AppTheme.text(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                    color: statusTone.foreground,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppTheme.browseSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                provider.displayName,
                style: AppTheme.text(
                  size: 16.5,
                  weight: FontWeight.w700,
                  color: AppTheme.browseInk,
                  height: 1.3,
                ),
              ),
              if (provider.description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  provider.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(
                    size: 13.5,
                    color: AppTheme.browseSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppTheme.browseSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      provider.formattedCoverageAreas,
                      style: AppTheme.text(
                        size: 13,
                        color: AppTheme.browseSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  Text(
                    isApproved ? 'View details →' : 'Review application →',
                    style: AppTheme.text(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
