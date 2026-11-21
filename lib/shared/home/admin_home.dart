import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/admin/providers/admin_provider_approval_provider.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_brand.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Platform Admin Dashboard (`SCRUM-94` / `ADM-2`).
///
/// Allows authorized Platform Admins to review pending provider applications
/// and approve them for customer discovery and booking.
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

    return Scaffold(
      backgroundColor: AppTheme.browseBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SpContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
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
                const SizedBox(height: 20),

                Text(
                  l10n.homeGreeting(firstName),
                  style: AppTheme.display(size: 26, color: AppTheme.browseInk),
                ),
                const SizedBox(height: 24),

                // Pending Provider Applications Section
                Text(
                  l10n.adminPendingProvidersSection,
                  style: AppTheme.display(size: 18, color: AppTheme.browseInk),
                ),
                const SizedBox(height: 12),
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
                    return Column(
                      children: pendingProviders.map((provider) {
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
                      }).toList(),
                    );
                  },
                  loading: () => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        semanticsLabel: l10n.providerDirectoryLoading,
                      ),
                    ),
                  ),
                  error: (_, __) => SpNotice(
                    icon: Icons.error_outline_rounded,
                    message: l10n.providerDirectoryError,
                    tone: SpTone.danger,
                  ),
                ),
                const SizedBox(height: 24),

                // Approved Active Providers Section
                Text(
                  l10n.adminApprovedProvidersSection,
                  style: AppTheme.display(size: 18, color: AppTheme.browseInk),
                ),
                const SizedBox(height: 12),
                approvedAsync.when(
                  data: (approvedProviders) {
                    return Column(
                      children: approvedProviders.map((provider) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    final statusLabel = isApproved
        ? l10n.adminApprovedBadge
        : l10n.adminPendingBadge;
    final statusIcon = isApproved
        ? Icons.check_circle_rounded
        : Icons.schedule_rounded;

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ProviderTypeBadge(type: provider.type),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: statusTone.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
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
                            size: 15,
                            color: statusTone.foreground,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              statusLabel,
                              style: AppTheme.text(
                                size: 13,
                                weight: FontWeight.w600,
                                color: statusTone.foreground,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                provider.displayName,
                style: AppTheme.text(
                  size: 16.5,
                  weight: FontWeight.w600,
                  color: AppTheme.browseInk,
                  height: 1.4,
                ),
              ),
              if (provider.description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  provider.description.trim(),
                  style: AppTheme.text(
                    size: 14,
                    color: AppTheme.browseSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.browseSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      provider.formattedCoverageAreas,
                      style: AppTheme.text(
                        size: 13.5,
                        color: AppTheme.browseSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppTheme.browseSecondary,
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
