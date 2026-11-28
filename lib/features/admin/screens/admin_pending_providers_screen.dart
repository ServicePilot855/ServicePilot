import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/admin/providers/admin_provider_approval_provider.dart';
import 'package:service_pilot/features/admin/widgets/pending_provider_card.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Screen allowing Platform Admins to review provider applications organized into
/// `Pending` (awaiting approval) and `Active` (verified & listed) tabs.
///
/// Uses the unified live Firestore streams from [pendingProvidersProvider] and
/// [approvedProvidersProvider] so approvals immediately update both tabs and counts.
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

    final pendingAsync = ref.watch(pendingProvidersProvider);
    final approvedAsync = ref.watch(approvedProvidersProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;
    final approvedCount = approvedAsync.valueOrNull?.length ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          leading: SpBackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home/admin');
              }
            },
          ),
          title: Text(
            'Provider Applications',
            style: AppTheme.display(size: 18),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: AppTheme.text(size: 14.5, weight: FontWeight.w700),
            unselectedLabelStyle: AppTheme.text(
              size: 14.5,
              weight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                key: const Key('admin_tab_pending'),
                text: pendingCount > 0 ? 'Pending ($pendingCount)' : 'Pending',
              ),
              Tab(
                key: const Key('admin_tab_active'),
                text: approvedCount > 0 ? 'Active ($approvedCount)' : 'Active',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProviderTabList(
              asyncValue: pendingAsync,
              isPendingTab: true,
              emptyMessage:
                  'All provider applications have been reviewed. There are no accounts pending verification.',
              emptyIcon: Icons.verified_user_rounded,
              onRefresh: () async {
                ref.invalidate(pendingProvidersProvider);
              },
            ),
            _ProviderTabList(
              asyncValue: approvedAsync,
              isPendingTab: false,
              emptyMessage: 'No active providers listed yet.',
              emptyIcon: Icons.business_center_outlined,
              onRefresh: () async {
                ref.invalidate(approvedProvidersProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderTabList extends StatelessWidget {
  const _ProviderTabList({
    required this.asyncValue,
    required this.isPendingTab,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  final AsyncValue<List<ProviderModel>> asyncValue;
  final bool isPendingTab;
  final String emptyMessage;
  final IconData emptyIcon;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: onRefresh,
      child: SpContentWidth(
        child: asyncValue.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                children: [
                  const SizedBox(height: 60),
                  SpNotice(
                    icon: emptyIcon,
                    tone: isPendingTab ? SpTone.success : SpTone.neutral,
                    message: emptyMessage,
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
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isPendingTab
                                ? 'Applications awaiting review'
                                : 'Active service providers',
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
                            color: isPendingTab
                                ? AppTheme.primarySoft
                                : AppTheme.successSoft,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusChip),
                          ),
                          child: Text(
                            isPendingTab
                                ? '${providers.length} pending'
                                : '${providers.length} active',
                            style: AppTheme.text(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: isPendingTab
                                  ? AppTheme.onPrimarySoft
                                  : AppTheme.successDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final provider = providers[index - 1];
                return PendingProviderCard(
                  provider: provider,
                  onTap: () => context.push(
                    '/admin/providers/${provider.id}',
                    extra: provider,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
