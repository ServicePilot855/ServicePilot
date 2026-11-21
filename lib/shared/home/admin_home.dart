import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/admin/providers/admin_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_brand.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Platform Admin dashboard home screen.
///
/// Provides access to provider application verification (ADM-1 / SCRUM-93)
/// and administrative oversight tools.
class AdminHome extends ConsumerWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final name = user?.fullName ?? l10n.homeFallbackName;
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    final pendingCount = ref.watch(pendingProvidersCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: SpContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar: Logo & Role Pill ───────────────────────────────
                Row(
                  children: [
                    const SpLogoMark(size: 36),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip),
                      ),
                      child: Text(
                        AppRole.admin.displayName,
                        style: AppTheme.text(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Greeting Header ─────────────────────────────────────────
                Semantics(
                  header: true,
                  child: Text(
                    l10n.homeGreeting(firstName),
                    style: AppTheme.display(size: 30),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? name,
                  style: AppTheme.text(
                    size: 15,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // ── ADM-1: Provider Verification Queue Action Card ──────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySoft,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusControl),
                            ),
                            child: const Icon(
                              Icons.assignment_ind_rounded,
                              size: 24,
                              color: AppTheme.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: pendingCount > 0
                                  ? AppTheme.accentSoft
                                  : AppTheme.surfaceElevated,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusChip),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (pendingCount > 0) ...[
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: AppTheme.accentDeep,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  pendingCount > 0
                                      ? '$pendingCount Pending'
                                      : 'All Reviewed',
                                  style: AppTheme.text(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                    color: pendingCount > 0
                                        ? AppTheme.accentDeep
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Provider Applications',
                        style: AppTheme.headline(size: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review incoming technician and company registrations awaiting platform verification.',
                        style: AppTheme.text(
                          size: 14,
                          color: AppTheme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SpPrimaryButton(
                        label: 'View Pending Applications',
                        icon: Icons.checklist_rounded,
                        onPressed: () {
                          context.push('/admin/providers/pending');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Platform Notice (Future Tools) ──────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 22,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.homeSignedIn,
                            style: AppTheme.headline(size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SpNotice(
                        icon: Icons.hourglass_top_rounded,
                        tone: SpTone.waiting,
                        message: l10n.homeComingSoonNotice,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Log Out Button ──────────────────────────────────────────
                SpSecondaryButton(
                  label: l10n.homeLogOut,
                  icon: Icons.logout_rounded,
                  foregroundColor: AppTheme.errorDeep,
                  onPressed: () {
                    authNotifier.logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
