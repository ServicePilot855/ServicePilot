import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Screen listing verified providers for a selected service category.
///
/// Navigation target for US-09 (SCRUM-41); provider listing delivered in US-10 (SCRUM-55).
/// Tapping a provider navigates to US-11 (SCRUM-54) ProviderDetailScreen.
class ProviderListScreen extends ConsumerWidget {
  final String categoryId;
  final CategoryModel? category;

  const ProviderListScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/categories');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title = category?.name ?? l10n.providerDirectoryTitle;
    final providers = categoryProvidersProvider(categoryId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: SpBackButton(onPressed: () => _goBack(context)),
        title: Text(
          title,
          style: AppTheme.display(size: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
      body: ref.watch(providers).when(
            data: (providers) {
              if (providers.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildProviderList(context, providers, title);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primary,
              ),
            ),
            error: (_, __) => Center(
              child: SpContentWidth(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpNotice(
                        icon: Icons.error_outline_rounded,
                        message: l10n.providerDirectoryError,
                        tone: SpTone.danger,
                      ),
                      const SizedBox(height: 16),
                      SpSecondaryButton(
                        label: l10n.providerDirectoryRetry,
                        onPressed: () => ref.invalidate(providers),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SpContentWidth(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
                child: Icon(
                  category?.iconData ?? Icons.engineering_rounded,
                  size: 32,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.providerDirectoryEmpty,
                style: AppTheme.display(size: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SpSecondaryButton(
                label: 'Browse Other Categories',
                onPressed: () => _goBack(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderList(
    BuildContext context,
    List<ProviderModel> providers,
    String title,
  ) {
    return SingleChildScrollView(
      child: SpContentWidth(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verified Providers for $title',
                style: AppTheme.display(size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a technician or company to view rates, specialties, and schedule a repair.',
                style: AppTheme.text(
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: providers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final provider = providers[index];
                  return _ProviderCard(
                    provider: provider,
                    onTap: () => context.push(
                      '/providers/${Uri.encodeComponent(provider.id)}',
                      extra: provider,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.primary.withValues(alpha: 0.08),
        highlightColor: AppTheme.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: provider.isCompany
                          ? AppTheme.primarySoft
                          : AppTheme.successSoft,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusControl),
                    ),
                    child: Icon(
                      provider.isCompany
                          ? Icons.apartment_rounded
                          : Icons.person_rounded,
                      color: provider.isCompany
                          ? AppTheme.primary
                          : AppTheme.successDeep,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name,
                          style: AppTheme.display(size: 16),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          provider.description,
                          style: AppTheme.text(
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  ProviderTypeBadge(type: provider.type, isCompact: true),
                  const Spacer(),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 13,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      provider.formattedCoverageAreas,
                      style: AppTheme.text(
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: AppTheme.accentDeep,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    provider.formattedRating,
                    style: AppTheme.text(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppTheme.textPrimary,
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
