import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_providers.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Screen listing verified and active repair providers for a selected service category.
///
/// Implements US-10 (SCRUM-55): Browse and Select Service Providers.
/// Only approved and active service providers are displayed (`status == 'active'`).
class ProviderListScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final CategoryModel? category;

  const ProviderListScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  @override
  ConsumerState<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends ConsumerState<ProviderListScreen> {
  // Optional filter: null = all, AppRole.independentProvider, AppRole.company
  AppRole? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(categoryByIdProvider(widget.categoryId));
    final category = widget.category ?? categoryAsync.valueOrNull;

    final providersAsync =
        ref.watch(providersByCategoryProvider(widget.categoryId));

    final title = category?.name ?? 'Service Providers';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: SpBackButton(onPressed: () => context.pop()),
        title: Text(
          title,
          style: AppTheme.display(size: 17),
        ),
      ),
      body: Center(
        child: SpContentWidth(
          child: providersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(AppTheme.gutter),
              child: SpNotice(
                icon: Icons.error_outline_rounded,
                message: 'Unable to load providers: $err',
                tone: SpTone.danger,
              ),
            ),
            data: (allProviders) {
              final filteredProviders = _selectedTypeFilter == null
                  ? allProviders
                  : allProviders
                      .where((p) => p.type == _selectedTypeFilter)
                      .toList();

              return ListView(
                padding: const EdgeInsets.all(AppTheme.gutter),
                children: [
                  _buildCategoryBanner(category, title),
                  const SizedBox(height: 16),
                  _buildFilterSegments(allProviders.length),
                  const SizedBox(height: 16),
                  if (filteredProviders.isEmpty)
                    _buildEmptyState(title)
                  else ...[
                    Text(
                      'Available Providers (${filteredProviders.length})',
                      style: AppTheme.text(
                        size: 15,
                        weight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...filteredProviders.map(
                      (provider) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProviderCard(
                          provider: provider,
                          onTap: () {
                            context.push(
                              '/providers/${provider.id}',
                              extra: provider,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBanner(CategoryModel? category, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category?.iconData ?? Icons.build_rounded,
              color: AppTheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified Providers for $title',
                  style: AppTheme.display(size: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  category?.description ??
                      'Browse verified and background-checked technicians across Phnom Penh.',
                  style: AppTheme.text(
                    size: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSegments(int totalCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All ($totalCount)',
            isSelected: _selectedTypeFilter == null,
            onTap: () => setState(() => _selectedTypeFilter = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Independent Technicians',
            isSelected: _selectedTypeFilter == AppRole.independentProvider,
            onTap: () => setState(
                () => _selectedTypeFilter = AppRole.independentProvider),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Repair Companies',
            isSelected: _selectedTypeFilter == AppRole.company,
            onTap: () => setState(() => _selectedTypeFilter = AppRole.company),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String categoryName) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.engineering_outlined,
              size: 28,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No verified providers found',
            style: AppTheme.text(
              size: 16,
              weight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'There are currently no active providers matching your criteria in $categoryName. Please check other categories or clear filters.',
            style: AppTheme.text(
              size: 13.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedTypeFilter != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _selectedTypeFilter = null),
              child: const Text('Show all providers'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.text(
            size: 13,
            weight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textBody,
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
    final isCompany = provider.isCompany;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isCompany
                        ? AppTheme.primarySoft
                        : AppTheme.successSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    provider.displayName.isNotEmpty
                        ? provider.displayName.substring(0, 1).toUpperCase()
                        : 'P',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isCompany
                          ? AppTheme.primary
                          : AppTheme.successDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.displayName,
                        style: AppTheme.text(
                          size: 16,
                          weight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              provider.serviceArea,
                              style: AppTheme.text(
                                size: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompany
                        ? AppTheme.primarySoft
                        : AppTheme.successSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompany
                          ? AppTheme.primary.withValues(alpha: 0.25)
                          : AppTheme.success.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    provider.typeBadgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCompany
                          ? AppTheme.primary
                          : AppTheme.successDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.rating.toStringAsFixed(1),
                      style: AppTheme.text(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '(${provider.reviewCount})',
                      style: AppTheme.text(
                        size: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${provider.completedJobs} jobs done',
                  style: AppTheme.text(
                    size: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '\$${provider.hourlyRate.toStringAsFixed(0)} / hr',
                  style: AppTheme.text(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
