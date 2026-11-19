import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_providers.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Screen displaying the full profile, bio, specialties, and booking action for a provider.
///
/// Implements US-11 (SCRUM-54): View Service Provider Details.
class ProviderDetailScreen extends ConsumerWidget {
  final String providerId;
  final ProviderModel? provider;

  const ProviderDetailScreen({
    super.key,
    required this.providerId,
    this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(providerDetailsProvider(providerId));
    final resolvedProvider = provider ?? providerAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: SpBackButton(onPressed: () => context.pop()),
        title: Text(
          resolvedProvider?.displayName ?? 'Provider Profile',
          style: AppTheme.display(size: 17),
        ),
      ),
      body: resolvedProvider == null && providerAsync.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : resolvedProvider == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.gutter),
                    child: SpNotice(
                      icon: Icons.error_outline_rounded,
                      message: 'Provider profile not found.',
                      tone: SpTone.danger,
                    ),
                  ),
                )
              : _buildProfileContent(context, resolvedProvider),
    );
  }

  Widget _buildProfileContent(BuildContext context, ProviderModel p) {
    final isCompany = p.isCompany;
    final canBook = p.canAcceptBookings;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.gutter),
            child: SpContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: AppTheme.border, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isCompany
                                    ? AppTheme.primarySoft
                                    : AppTheme.successSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                p.displayName.isNotEmpty
                                    ? p.displayName.substring(0, 1).toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: isCompany
                                      ? AppTheme.primary
                                      : AppTheme.successDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.displayName,
                                    style: AppTheme.display(size: 19),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isCompany
                                              ? AppTheme.primarySoft
                                              : AppTheme.successSoft,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p.typeBadgeLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isCompany
                                                ? AppTheme.primary
                                                : AppTheme.successDeep,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: p.isAvailable
                                              ? AppTheme.successSoft
                                              : AppTheme.surfaceElevated,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: p.isAvailable
                                                    ? AppTheme.success
                                                    : AppTheme.textMuted,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              p.isAvailable
                                                  ? 'Available'
                                                  : 'Busy',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: p.isAvailable
                                                    ? AppTheme.successDeep
                                                    : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              value: p.rating.toStringAsFixed(1),
                              label: '${p.reviewCount} reviews',
                            ),
                            _buildStatItem(
                              icon: Icons.task_alt_rounded,
                              iconColor: AppTheme.primary,
                              value: '${p.completedJobs}',
                              label: 'Completed',
                            ),
                            _buildStatItem(
                              icon: Icons.payments_outlined,
                              iconColor: AppTheme.success,
                              value: '\$${p.hourlyRate.toStringAsFixed(0)}',
                              label: 'Hourly rate',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Service Coverage Area',
                    icon: Icons.location_on_outlined,
                    child: Text(
                      p.serviceArea,
                      style: AppTheme.text(size: 14.5, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (p.bio.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'About the Provider',
                      icon: Icons.person_outline_rounded,
                      child: Text(
                        p.bio,
                        style: AppTheme.text(
                          size: 14,
                          color: AppTheme.textBody,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionCard(
                    title: 'Supported Categories',
                    icon: Icons.category_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.categoryIds.map((cId) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: AppTheme.border, width: 1),
                          ),
                          child: Text(
                            cId.replaceAll('cat-', '').toUpperCase(),
                            style: AppTheme.text(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (!canBook) ...[
                    const SizedBox(height: 16),
                    const SpNotice(
                      icon: Icons.event_busy_rounded,
                      message:
                          'This provider is currently fully booked or unavailable for new service appointments.',
                      tone: SpTone.waiting,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
          ),
          child: SafeArea(
            child: SpContentWidth(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Estimated Rate',
                        style: AppTheme.text(size: 12, color: AppTheme.textMuted),
                      ),
                      Text(
                        '\$${p.hourlyRate.toStringAsFixed(0)} / hr',
                        style: AppTheme.display(size: 18, color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SpPrimaryButton(
                      label: canBook ? 'Book Service' : 'Unavailable',
                      onPressed: canBook
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Booking flow with ${p.displayName} selected! Ready for US-12.',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: AppTheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(value, style: AppTheme.text(size: 15, weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.text(size: 11.5, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.text(size: 15, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
