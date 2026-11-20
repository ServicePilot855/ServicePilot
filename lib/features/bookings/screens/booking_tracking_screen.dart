import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/widgets/cancel_booking_dialog.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

/// Screen displaying a repair booking's status, details, and cancellation workflow.
///
/// Implements US-14 (SCRUM-45: Cancel a repair booking) and integrates with
/// booking status tracking (US-13 / SCRUM-44).
class BookingTrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final BookingModel? initialBooking;

  const BookingTrackingScreen({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  @override
  ConsumerState<BookingTrackingScreen> createState() =>
      _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends ConsumerState<BookingTrackingScreen> {
  BookingModel? _currentBooking;
  bool _isCancelling = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.initialBooking;
  }

  Future<void> _handleCancelPressed(
    BookingModel booking,
    String currentUserId,
  ) async {
    final result = await CancelBookingDialog.show(
      context,
      booking: booking,
    );

    if (result == null || !result.confirmed || !mounted) {
      return;
    }

    setState(() {
      _isCancelling = true;
      _feedbackMessage = null;
    });

    try {
      final service = ref.read(bookingServiceProvider);
      final updated = await service.cancelBooking(
        bookingId: booking.id,
        customerId: currentUserId,
        reason: result.reason,
      );

      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(customerBookingsProvider);

      if (mounted) {
        setState(() {
          _currentBooking = updated;
          _isCancelling = false;
          _feedbackMessage =
              'Your repair booking has been cancelled successfully.';
        });
      }
    } on CannotCancelBookingException catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        showSpError(context, e.message);
      }
    } on UnauthorizedBookingCancellationException catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        showSpError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        showSpError(context, 'Failed to cancel booking: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(activeCustomerIdProvider);
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));

    return Scaffold(
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
          'Booking Details',
          style: AppTheme.display(size: 18),
        ),
      ),
      body: bookingAsync.when(
        data: (fetchedBooking) {
          final booking = _currentBooking ?? fetchedBooking;
          if (booking == null) {
            return Center(
              child: SpContentWidth(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SpStatusHero(
                        icon: Icons.event_busy_rounded,
                        title: 'Booking Not Found',
                        message:
                            'We could not locate this repair booking record.',
                        tone: SpTone.danger,
                      ),
                      const SizedBox(height: 20),
                      SpPrimaryButton(
                        label: 'Back to Home',
                        onPressed: () => context.go('/home/customer'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return _buildBookingContent(context, booking, currentUserId);
        },
        loading: () {
          if (_currentBooking != null) {
            return _buildBookingContent(
              context,
              _currentBooking!,
              currentUserId,
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        },
        error: (err, _) => Center(
          child: SpContentWidth(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.gutter),
              child: SpNotice(
                icon: Icons.error_outline_rounded,
                message: 'Could not load booking: $err',
                tone: SpTone.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingContent(
    BuildContext context,
    BookingModel booking,
    String currentUserId,
  ) {
    final canCancel = booking.canBeCancelledBy(currentUserId);
    final isOwner = booking.isOwnedBy(currentUserId);
    final dateFormatted = DateFormat(
      'EEE, d MMM yyyy • h:mm a',
    ).format(booking.preferredDateTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.gutter),
      child: SpContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_feedbackMessage != null) ...[
              SpNotice(
                key: const Key('booking_cancelled_success_notice'),
                icon: Icons.check_circle_outline_rounded,
                message: _feedbackMessage!,
                tone: SpTone.success,
              ),
              const SizedBox(height: 16),
            ],

            // Status & Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID: ${booking.id}',
                        style: AppTheme.text(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      StatusBadge(
                        key: const Key('booking_detail_status_badge'),
                        status: booking.status,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    booking.serviceTitle,
                    style: AppTheme.display(size: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.serviceCategory,
                    style: AppTheme.text(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SpNotice(
                    icon: booking.status.icon,
                    message: booking.status.description,
                    tone: booking.status.tone,
                  ),
                  if (booking.status == BookingStatus.cancelled &&
                      booking.cancellationReason != null &&
                      booking.cancellationReason!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Cancellation reason: ${booking.cancellationReason}',
                      key: const Key('booking_cancellation_reason_text'),
                      style: AppTheme.text(
                        size: 13.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Service Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment & Provider',
                    style: AppTheme.display(size: 17),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    icon: Icons.storefront_rounded,
                    label: 'Service Provider',
                    value: booking.providerName,
                  ),
                  if (booking.assignedTechnicianName != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.engineering_rounded,
                      label: 'Assigned Technician',
                      value: booking.assignedTechnicianName!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Preferred Date & Time',
                    value: dateFormatted,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Service Address',
                    value: booking.address,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.description_outlined,
                    label: 'Problem Description',
                    value: booking.description,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Estimated Fee',
                    value: '\$${booking.totalPrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cancellation Action / Guard Section (US-14 / SCRUM-45)
            if (canCancel)
              SpSecondaryButton(
                key: const Key('cancel_booking_button'),
                label: _isCancelling ? 'Cancelling...' : 'Cancel Booking',
                icon: Icons.cancel_outlined,
                foregroundColor: AppTheme.errorDeep,
                onPressed: _isCancelling
                    ? null
                    : () => _handleCancelPressed(booking, currentUserId),
              )
            else if (!isOwner)
              const SpNotice(
                key: Key('cancellation_restricted_notice'),
                icon: Icons.lock_outline_rounded,
                message:
                    'Only the customer who created this booking can cancel it.',
                tone: SpTone.neutral,
              )
            else
              SpNotice(
                key: const Key('cancellation_restricted_notice'),
                icon: Icons.block_rounded,
                message: _restrictionMessageForStatus(booking.status),
                tone: SpTone.neutral,
              ),
          ],
        ),
      ),
    );
  }

  String _restrictionMessageForStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return 'This booking cannot be cancelled because the repair is already In Progress.';
      case BookingStatus.completed:
        return 'This booking cannot be cancelled because the repair has already been Completed.';
      case BookingStatus.cancelled:
        return 'This booking has already been Cancelled and cannot be modified, accepted, assigned, or started.';
      case BookingStatus.declined:
        return 'This booking was Declined by the provider and cannot be cancelled.';
      case BookingStatus.pending:
      case BookingStatus.assigned:
      case BookingStatus.confirmed:
        return '';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.text(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.text(
                  size: 14.5,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
