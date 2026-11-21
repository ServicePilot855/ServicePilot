import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

/// Screen displaying a customer's repair booking history organized into
/// `Active` (upcoming/in-progress) and `Past` (completed/cancelled/declined) tabs.
///
/// Implements US-15 (SCRUM-46: View repair booking history).
class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(customerBookingsProvider);

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
                context.go('/home/customer');
              }
            },
          ),
          title: Text(
            'Booking History',
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
            tabs: const [
              Tab(
                key: Key('booking_history_tab_active'),
                text: 'Active',
              ),
              Tab(
                key: Key('booking_history_tab_past'),
                text: 'Past',
              ),
            ],
          ),
        ),
        body: bookingsAsync.when(
          data: (bookings) {
            final activeBookings =
                bookings.where((b) => b.status.isActive).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final pastBookings =
                bookings.where((b) => b.status.isTerminal).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return TabBarView(
              children: [
                _BookingTabList(
                  key: const Key('booking_history_list_active'),
                  bookings: activeBookings,
                  emptyMessage: 'You have no active repair bookings right now.',
                  emptyIcon: Icons.calendar_today_rounded,
                  onRefresh: () async {
                    ref.invalidate(customerBookingsProvider);
                  },
                ),
                _BookingTabList(
                  key: const Key('booking_history_list_past'),
                  bookings: pastBookings,
                  emptyMessage: 'You have no past repair booking history.',
                  emptyIcon: Icons.history_rounded,
                  onRefresh: () async {
                    ref.invalidate(customerBookingsProvider);
                  },
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, _) => Center(
            child: SpContentWidth(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.gutter),
                child: SpNotice(
                  icon: Icons.error_outline_rounded,
                  message: 'Could not load booking history: $err',
                  tone: SpTone.danger,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingTabList extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyMessage;
  final IconData emptyIcon;
  final RefreshCallback onRefresh;

  const _BookingTabList({
    super.key,
    required this.bookings,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: onRefresh,
      child: bookings.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: SpContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.gutter,
                      vertical: 60,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpNotice(
                          key: const Key('booking_history_empty_notice'),
                          icon: emptyIcon,
                          message: emptyMessage,
                          tone: SpTone.neutral,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.gutter),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _BookingHistoryCard(
                  key: Key('booking_history_card_${booking.id}'),
                  booking: booking,
                  onTap: () => context.push(
                    '/bookings/${booking.id}',
                    extra: booking,
                  ),
                );
              },
            ),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _BookingHistoryCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat(
      'EEE, d MMM yyyy • h:mm a',
    ).format(booking.preferredDateTime);

    return Material(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
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
                      style: AppTheme.display(size: 16),
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
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateFormatted,
                    style: AppTheme.text(
                      size: 12.5,
                      weight: FontWeight.w600,
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
