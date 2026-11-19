import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Screen displaying comprehensive details and profile of a service provider.
///
/// Implements US-11 (SCRUM-54) Acceptance Criteria:
/// 1. Provider name, description, bio, and service specialties.
/// 2. Service coverage area (e.g., Toul Kork, Sen Sok, Chamkarmon).
/// 3. Profile identifies independent technician vs. repair company.
/// 4. Direct action to initiate a booking request (`/providers/:providerId/book`).
/// 5. Unavailable providers have the booking CTA disabled.
class ProviderDetailScreen extends ConsumerWidget {
  final String providerId;
  final ProviderModel? initialProvider;

  const ProviderDetailScreen({
    super.key,
    required this.providerId,
    this.initialProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(providerDetailsProvider(providerId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: SpBackButton(onPressed: () => context.pop()),
        title: Text(
          'Provider Profile',
          style: AppTheme.display(size: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
      body: providerAsync.when(
        data: (fetchedProvider) {
          final provider = fetchedProvider ?? initialProvider;
          if (provider == null) {
            return _buildNotFoundState(context);
          }
          return _ProviderDetailContent(provider: provider);
        },
        loading: () {
          if (initialProvider != null) {
            return _ProviderDetailContent(provider: initialProvider!);
          }
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primary,
            ),
          );
        },
        error: (err, _) {
          if (initialProvider != null) {
            return _ProviderDetailContent(provider: initialProvider!);
          }
          return _buildErrorState(context, err.toString());
        },
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
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
                  color: AppTheme.errorSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  size: 32,
                  color: AppTheme.errorDeep,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Provider Not Found',
                style: AppTheme.display(size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested service provider could not be located or is no longer listed.',
                style: AppTheme.text(
                  size: 14.5,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SpSecondaryButton(
                label: 'Back to Providers',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: SpContentWidth(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpNotice(
                icon: Icons.error_outline_rounded,
                message: 'Failed to load provider profile: $message',
                tone: SpTone.danger,
              ),
              const SizedBox(height: 20),
              SpSecondaryButton(
                label: 'Go Back',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderDetailContent extends StatelessWidget {
  final ProviderModel provider;

  const _ProviderDetailContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final canBook = provider.canAcceptBookings;

    return Column(
      children: [
        // Scrollable profile content
        Expanded(
          child: SingleChildScrollView(
            child: SpContentWidth(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.gutter,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 14),
                    _buildAvailabilityBanner(),
                    const SizedBox(height: 20),
                    _buildAboutSection(),
                    const SizedBox(height: 20),
                    _buildSpecialtiesSection(),
                    const SizedBox(height: 20),
                    _buildCoverageAreaSection(),
                    const SizedBox(height: 20),
                    _buildContactAndTrustSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Pinned Bottom Booking Bar
        _buildBottomBookingBar(context, canBook),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              // Avatar box
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: provider.isCompany
                      ? AppTheme.primarySoft
                      : AppTheme.successSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                ),
                child: Icon(
                  provider.isCompany
                      ? Icons.apartment_rounded
                      : Icons.person_rounded,
                  size: 32,
                  color: provider.isCompany
                      ? AppTheme.primary
                      : AppTheme.successDeep,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: AppTheme.display(size: 19),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.description,
                      style: AppTheme.text(
                        size: 13.5,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),
          // Badges row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ProviderTypeBadge(type: provider.type),
              if (provider.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Provider',
                        style: AppTheme.text(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.star_rounded,
                iconColor: AppTheme.accentDeep,
                value: provider.formattedRating,
                label: '${provider.reviewCount} reviews',
              ),
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.task_alt_rounded,
                iconColor: AppTheme.primary,
                value: '${provider.completedJobsCount}',
                label: 'Jobs done',
              ),
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.history_edu_rounded,
                iconColor: AppTheme.success,
                value: '${provider.yearsExperience} yrs',
                label: 'Experience',
              ),
            ],
          ),
        ],
      ),
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
            Text(
              value,
              style: AppTheme.text(
                size: 15,
                weight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.text(
            size: 11.5,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppTheme.border,
    );
  }

  /// Availability Banner satisfying AC #5.
  Widget _buildAvailabilityBanner() {
    if (provider.canAcceptBookings) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.successSoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppTheme.successDeep,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Available for Booking · Accepting new requests',
                style: AppTheme.text(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppTheme.successDeep,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Unavailable state
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.access_time_filled_rounded,
            size: 20,
            color: AppTheme.accentDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently Unavailable for Bookings',
                  style: AppTheme.text(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: AppTheme.accentDeep,
                  ),
                ),
                if (provider.unavailableReason != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    provider.unavailableReason!,
                    style: AppTheme.text(
                      size: 12.5,
                      color: AppTheme.accentDeep,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// About and Bio section satisfying AC #1.
  Widget _buildAboutSection() {
    return _buildCardSection(
      title: 'About Provider',
      icon: Icons.info_outline_rounded,
      child: Text(
        provider.bio.isNotEmpty ? provider.bio : provider.description,
        style: AppTheme.text(
          size: 14,
          color: AppTheme.textBody,
          height: 1.55,
        ),
      ),
    );
  }

  /// Service Specialties section satisfying AC #1.
  Widget _buildSpecialtiesSection() {
    return _buildCardSection(
      title: 'Service Specialties',
      icon: Icons.handyman_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verified skills and repair capabilities offered by this provider:',
            style: AppTheme.text(
              size: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.specialties.map((specialty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        specialty,
                        style: AppTheme.text(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Service Coverage Area section satisfying AC #2 (e.g., Toul Kork, Sen Sok, Chamkarmon).
  Widget _buildCoverageAreaSection() {
    return _buildCardSection(
      title: 'Service Coverage Area',
      icon: Icons.location_on_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'On-site technical service is available across the following Phnom Penh districts:',
            style: AppTheme.text(
              size: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.coverageAreas.map((area) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      size: 13,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        area,
                        style: AppTheme.text(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppTheme.onPrimarySoft,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAndTrustSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                Icons.shield_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trust & Safety Guarantee',
                  style: AppTheme.display(size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Identity verified and background-checked by ServicePilot. Customer payment is held securely and only settled after repair confirmation.',
            style: AppTheme.text(
              size: 13,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
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
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.display(size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Pinned bottom bar satisfying AC #4 (Book Service CTA) and AC #5 (Guard against unavailable providers).
  Widget _buildBottomBookingBar(BuildContext context, bool canBook) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
        boxShadow: AppTheme.floatShadow,
      ),
      child: SafeArea(
        top: false,
        child: SpContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.gutter,
              vertical: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!canBook)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppTheme.accentDeep,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Provider is currently unavailable for new bookings',
                            style: AppTheme.text(
                              size: 12,
                              color: AppTheme.accentDeep,
                              weight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                SpPrimaryButton(
                  label: canBook ? 'Book Service' : 'Currently Unavailable',
                  icon: canBook
                      ? Icons.calendar_month_rounded
                      : Icons.block_rounded,
                  enabled: canBook,
                  onPressed: canBook
                      ? () => context.push('/providers/${provider.id}/book')
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
