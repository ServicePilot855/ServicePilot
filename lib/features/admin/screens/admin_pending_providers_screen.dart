import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/admin/providers/admin_provider.dart';
import 'package:service_pilot/features/admin/widgets/pending_provider_card.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Screen allowing Platform Admins to review pending technician and company applications.
///
/// Implements Sprint 3 SCRUM-93 (ADM-1: View pending provider applications).
/// Strictly enforces Role-Based Access Control (RBAC): only [AppRole.admin] can view this queue.
class AdminPendingProvidersScreen extends ConsumerWidget {
  const AdminPendingProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    // ── RBAC Security Guard ─────────────────────────────────────────────────
    if (currentUser?.role != AppRole.admin) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Access Restricted'),
          backgroundColor: AppTheme.surface,
          elevation: 0,
        ),
        body: const SafeArea(
          child: SpContentWidth(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingXl),
              child: Center(
                child: SpNotice(
                  icon: Icons.gpp_bad_rounded,
                  tone: SpTone.danger,
                  message:
                      'Access Restricted. Only platform administrators have permission to review provider applications.',
                ),
              ),
            ),
          ),
        ),
      );
    }

    final pendingAsync = ref.watch(pendingProvidersStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Provider Applications',
          style: AppTheme.text(
            size: 18,
            weight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            ref.invalidate(pendingProvidersStreamProvider);
          },
          child: SpContentWidth(
            child: pendingAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  child: SpNotice(
                    icon: Icons.error_outline_rounded,
                    tone: SpTone.danger,
                    message: 'Failed to load provider applications: $err',
                  ),
                ),
              ),
              data: (providers) {
                if (providers.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(AppTheme.spacingXl),
                    children: const [
                      SizedBox(height: 60),
                      SpNotice(
                        icon: Icons.verified_user_rounded,
                        tone: SpTone.success,
                        message:
                            'All provider applications have been reviewed. There are no accounts pending verification.',
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingXl,
                  ),
                  itemCount: providers.length + 1,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.spacingLg),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Applications awaiting review',
                                style: AppTheme.text(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusChip),
                              ),
                              child: Text(
                                '${providers.length} pending',
                                style: AppTheme.text(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                  color: AppTheme.onPrimarySoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final provider = providers[index - 1];
                    return PendingProviderCard(provider: provider);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
