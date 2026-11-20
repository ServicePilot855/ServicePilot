import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/widgets/provider_rating_summary.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Lists active repair providers for the selected category.
class ProviderListScreen extends ConsumerWidget {
  const ProviderListScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  final String categoryId;
  final CategoryModel? category;

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
    final directory = categoryProvidersProvider(categoryId);
    final categoryName = category?.name;

    return Scaffold(
      backgroundColor: AppTheme.browseBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: SpBackButton(onPressed: () => _goBack(context)),
        title: Text(
          l10n.providerDirectoryTitle,
          style: AppTheme.display(size: 18, color: AppTheme.browseInk),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SpContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (categoryName != null && categoryName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    categoryName,
                    style: AppTheme.display(
                      size: 22,
                      color: AppTheme.browseInk,
                      height: 1.5,
                    ),
                  ),
                ),
              Expanded(
                child: ref.watch(directory).when(
                      data: (providers) {
                        if (providers.isEmpty) {
                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              SpNotice(
                                icon: Icons.person_search_rounded,
                                message: l10n.providerDirectoryEmpty,
                                tone: SpTone.neutral,
                              ),
                              const SizedBox(height: 12),
                              SpSecondaryButton(
                                label: l10n.providerOtherCategories,
                            outlineColor: AppTheme.browseControlBorder,
                                wrapLabel: true,
                                onPressed: () => _goBack(context),
                              ),
                            ],
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: providers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
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
                        );
                      },
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: l10n.providerDirectoryLoading,
                        ),
                      ),
                      error: (_, __) => ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          SpNotice(
                            icon: Icons.error_outline_rounded,
                            message: l10n.providerDirectoryError,
                            tone: SpTone.danger,
                          ),
                          const SizedBox(height: 12),
                          SpSecondaryButton(
                            label: l10n.providerDirectoryRetry,
                        outlineColor: AppTheme.browseControlBorder,
                            wrapLabel: true,
                            onPressed: () => ref.invalidate(directory),
                          ),
                        ],
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onTap});

  final ProviderModel provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverage = provider.formattedCoverageAreas.trim();
    final metadataStyle = AppTheme.text(
      color: AppTheme.browseSecondary,
      height: 1.5,
    );
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            side: const BorderSide(color: AppTheme.browseBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            focusColor: AppTheme.primarySoft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.displayName,
                          style: AppTheme.display(
                            size: 18,
                            color: AppTheme.browseInk,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ProviderTypeBadge(type: provider.type),
                        const SizedBox(height: 8),
                        ProviderRatingSummary(provider: provider),
                        const SizedBox(height: 4),
                        if (coverage.isNotEmpty)
                          Text(coverage, style: metadataStyle),
                        if (!provider.canAcceptBookings)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.event_busy_rounded,
                                  size: 18,
                                  color: AppTheme.browseSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  context.l10n.providerUnavailable,
                                  style: metadataStyle,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
