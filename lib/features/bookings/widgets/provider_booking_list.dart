import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

/// Dashboard section displaying the provider's upcoming and active jobs
/// (`Confirmed`, `Assigned`, `In Progress`) along with appointment time,
/// status, and assigned technician when available.
///
/// Implements BOOK-4 (SCRUM-89 / SCRUM-151).
class ProviderBookingList extends ConsumerWidget {
  const ProviderBookingList({
    super.key,
    required this.providerId,
  });

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activeProvider = liveProviderActiveBookingsProvider(providerId);
    final bookingsAsync = ref.watch(activeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.providerActiveBookingsTitle,
            style: AppTheme.display(size: 20, color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(height: 12),
        bookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return SpNotice(
                key: const Key('provider_active_bookings_empty'),
                icon: Icons.event_note_rounded,
                message: l10n.providerActiveBookingsEmpty,
                tone: SpTone.neutral,
              );
            }

            final sorted = List<BookingModel>.from(bookings)
              ..sort((a, b) {
                final timeA = a.confirmedAppointmentAt ?? a.preferredDateTime;
                final timeB = b.confirmedAppointmentAt ?? b.preferredDateTime;
                return timeA.compareTo(timeB);
              });

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = sorted[index];
                return _ProviderBookingCard(booking: booking);
              },
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                semanticsLabel: l10n.providerActiveBookingsTitle,
              ),
            ),
          ),
          error: (err, _) {
            debugPrint('[ProviderBookingList] load error: $err');
            return Column(
              children: [
                SpNotice(
                  icon: Icons.error_outline_rounded,
                  message: l10n.providerBookingsLoadError,
                  tone: SpTone.danger,
                ),
                const SizedBox(height: 12),
                SpSecondaryButton(
                  label: l10n.bookingInboxRetry,
                  wrapLabel: true,
                  onPressed: () => ref.invalidate(activeProvider),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProviderBookingCard extends StatelessWidget {
  const _ProviderBookingCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayTime = booking.confirmedAppointmentAt ?? booking.preferredDateTime;
    final formattedTime = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_jm().format(displayTime.toLocal());
    final technicianName = booking.assignedTechnicianName?.trim() ?? '';

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        key: Key('provider_booking_card_${booking.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: () => context.push(
          '/provider/bookings/${Uri.encodeComponent(booking.id)}',
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceTitle,
                      style: AppTheme.display(
                        size: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    key: Key('provider_booking_status_${booking.id}'),
                    status: booking.status,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    booking.confirmedAppointmentAt != null
                        ? Icons.event_available_rounded
                        : Icons.schedule_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.confirmedAppointmentAt != null
                          ? '${l10n.bookingConfirmedAppointmentLabel}: $formattedTime'
                          : formattedTime,
                      style: AppTheme.text(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (technicianName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  key: Key('provider_booking_technician_${booking.id}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person_pin_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.providerBookingTechnicianValue(technicianName),
                        style: AppTheme.text(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (booking.address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  booking.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(
                    size: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: OutlinedButton(
                    key: Key('provider_booking_review_${booking.id}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(96, 48),
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusControl),
                      ),
                    ),
                    onPressed: () => context.push(
                      '/provider/bookings/${Uri.encodeComponent(booking.id)}',
                    ),
                    child: Text(l10n.providerBookingReviewAction),
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
