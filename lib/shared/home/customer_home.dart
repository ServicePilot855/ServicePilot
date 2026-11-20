import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/features/services/widgets/category_card.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_brand.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

/// Customer Home Dashboard.
///
/// Features service categories discovery (US-09 / SCRUM-41) and direct
/// navigation to provider selection.
class CustomerHome extends ConsumerWidget {
  const CustomerHome({super.key});

  void _onCategorySelected(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    ref.read(selectedCategoryProvider.notifier).state = category;
    context.push('/categories/${category.id}/providers', extra: category);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authProvider.notifier).currentUser;
    final name = user?.fullName ?? l10n.homeFallbackName;
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    final categoriesAsync = ref.watch(categoriesListProvider);
    final bookingsAsync = ref.watch(customerBookingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.browseBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: SpContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            l10n.discoveryLocation,
                            style: AppTheme.text(
                              color: AppTheme.browseSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      color: AppTheme.browseSecondary,
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      tooltip: l10n.homeLogOut,
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.homeGreeting(firstName),
                  style: AppTheme.display(
                    size: 26,
                    color: AppTheme.browseInk,
                    height: 1.5,
                  ),
                ),
                Text(
                  l10n.discoveryHomePrompt,
                  style: AppTheme.text(
                    size: 15,
                    color: AppTheme.browseSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.discoveryHomeCategories,
                  style: AppTheme.display(size: 18, color: AppTheme.browseInk),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('customer_home_search_bar'),
                  onPressed: () => context.push('/categories'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 48),
                    alignment: Alignment.centerLeft,
                    backgroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusControl),
                    ),
                  ).copyWith(
                    side: WidgetStateBorderSide.resolveWith(
                      (states) => states.contains(WidgetState.focused)
                          ? const BorderSide(color: AppTheme.primary, width: 2)
                          : const BorderSide(color: AppTheme.browseControlBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l10n.discoveryBrowseServices)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Categories List / Stream
                categoriesAsync.when(
                  data: (categories) {
                    return Column(
                      children: categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CategoryCard(
                            key: Key('home_category_${cat.id}'),
                            category: cat,
                            onTap: () => _onCategorySelected(context, ref, cat),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        semanticsLabel: l10n.discoveryLoadingCategories,
                      ),
                    ),
                  ),
                  error: (_, __) => SpNotice(
                    icon: Icons.error_outline_rounded,
                    message: l10n.discoveryCategoriesError,
                    tone: SpTone.danger,
                  ),
                ),
                const SizedBox(height: 24),

                // My Repair Bookings Section (US-13 / US-14)
                Text(
                  l10n.discoveryHomeBookings,
                  style: AppTheme.display(size: 18, color: AppTheme.browseInk),
                ),
                const SizedBox(height: 10),
                bookingsAsync.when(
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return SpNotice(
                        icon: Icons.event_note_rounded,
                        message: l10n.discoveryNoBookings,
                        tone: SpTone.neutral,
                      );
                    }
                    return Column(
                      children: bookings.map((booking) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CustomerBookingCard(
                            key: Key('home_booking_${booking.id}'),
                            booking: booking,
                            onTap: () => context.push(
                              '/bookings/${booking.id}',
                              extra: booking,
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
                        semanticsLabel: l10n.discoveryLoadingBookings,
                      ),
                    ),
                  ),
                  error: (_, __) => SpNotice(
                    icon: Icons.error_outline_rounded,
                    message: l10n.discoveryBookingsError,
                    tone: SpTone.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _CustomerBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceTitle,
                      style: AppTheme.text(
                        size: 15.5,
                        weight: FontWeight.w600,
                        color: AppTheme.browseInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                booking.providerName,
                style: AppTheme.text(
                  size: 13.5,
                  color: AppTheme.browseSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppTheme.browseSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.address,
                      style: AppTheme.text(
                        size: 12.5,
                        color: AppTheme.browseSecondary,
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
      ),
    );
  }
}
