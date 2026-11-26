import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/incoming_booking_request.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

/// Provider booking detail screen where an authorized provider reviews an
/// incoming booking request and confirms the customer's appointment.
///
/// Implements BOOK-2 (SCRUM-104 / SCRUM-189).
class ProviderBookingDetailScreen extends ConsumerStatefulWidget {
  const ProviderBookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  ConsumerState<ProviderBookingDetailScreen> createState() =>
      _ProviderBookingDetailScreenState();
}

class _ProviderBookingDetailScreenState
    extends ConsumerState<ProviderBookingDetailScreen> {
  bool _isConfirming = false;
  String? _successMessage;
  String? _errorMessage;

  Future<void> _confirmBooking(
    DateTime preferredTime,
    String providerId,
  ) async {
    final l10n = context.l10n;
    setState(() {
      _isConfirming = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final service = ref.read(bookingServiceProvider);
      await service.acceptBooking(
        bookingId: widget.bookingId,
        providerId: providerId,
        confirmedAppointmentAt: preferredTime,
      );

      if (!mounted) return;
      ref.invalidate(incomingBookingRequestsProvider);
      ref.invalidate(incomingBookingRequestProvider(widget.bookingId));
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(liveBookingDetailProvider(widget.bookingId));
      ref.invalidate(providerBookingsProvider(providerId));
      ref.invalidate(liveProviderBookingsProvider(providerId));

      setState(() {
        _isConfirming = false;
        _successMessage = l10n.providerBookingConfirmSuccess;
      });
    } on UnauthorizedBookingConfirmationException {
      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _errorMessage = l10n.providerBookingNotAuthorized;
      });
    } on InvalidBookingTransitionException {
      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _errorMessage = l10n.providerBookingIneligible;
      });
    } on BookingSubmissionException catch (e) {
      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _errorMessage = l10n.providerBookingsLoadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final providerId = user?.id ?? '';
    final pendingProvider = incomingBookingRequestProvider(widget.bookingId);
    final Widget body;
    if (user?.canViewBookingInbox != true) {
      body = _unavailable(context);
    } else {
      body = ref.watch(pendingProvider).when(
            skipLoadingOnRefresh: false,
            data: (pending) {
              if (pending != null) {
                return _buildPending(context, pending, providerId);
              }

              return ref
                  .watch(liveBookingDetailProvider(widget.bookingId))
                  .when(
                    data: (booking) => booking != null &&
                            booking.isOwnedByProvider(providerId) &&
                            booking.status.exposesAcceptedDetails
                        ? _buildBody(context, booking, providerId)
                        : _unavailable(context),
                    loading: _loading,
                    error: (_, __) => _unavailable(context),
                  );
            },
            loading: _loading,
            error: (_, __) => Center(
              child: SpContentWidth(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpNotice(
                        icon: Icons.error_outline_rounded,
                        message: l10n.providerBookingsLoadError,
                        tone: SpTone.danger,
                      ),
                      const SizedBox(height: 12),
                      SpSecondaryButton(
                        label: l10n.bookingInboxRetry,
                        onPressed: () => ref.invalidate(pendingProvider),
                        wrapLabel: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
    }

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
              context.go(user?.role.homeRoute ?? '/home/technician');
            }
          },
        ),
        title: Text(
          l10n.providerBookingDetailTitle,
          style: AppTheme.display(size: 18),
        ),
      ),
      body: body,
    );
  }

  Widget _loading() => Center(
        child: CircularProgressIndicator(
          semanticsLabel: context.l10n.bookingInboxLoading,
        ),
      );

  Widget _unavailable(BuildContext context) => Center(
        child: SpContentWidth(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.gutter),
            child: SpNotice(
              icon: Icons.lock_outline_rounded,
              tone: SpTone.neutral,
              message: context.l10n.bookingInboxUnavailable,
            ),
          ),
        ),
      );

  Widget _buildPending(
    BuildContext context,
    IncomingBookingRequest pending,
    String providerId,
  ) {
    final l10n = context.l10n;
    final date = pending.appointmentDate;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.gutter),
      child: SpContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpPageHeader(
              title: pending.serviceTitle.isEmpty
                  ? l10n.bookingInboxDetailTitle
                  : pending.serviceTitle,
            ),
            const SizedBox(height: 16),
            SpNotice(
              icon: Icons.schedule_rounded,
              tone: SpTone.waiting,
              message: l10n.bookingInboxPending,
            ),
            const SizedBox(height: 24),
            SpFormSection(
              title: l10n.bookingSummaryWhen,
              children: [
                Text(
                  date == null
                      ? l10n.bookingInboxDateUnavailable
                      : DateFormat.yMMMd(
                              Localizations.localeOf(context).toString())
                          .add_jm()
                          .format(date.toLocal()),
                  style: AppTheme.text(),
                ),
              ],
            ),
            if (pending.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              SpFormSection(
                title: l10n.bookingInboxJobDetails,
                children: [Text(pending.description, style: AppTheme.text())],
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              SpNotice(
                icon: Icons.error_outline_rounded,
                message: _errorMessage!,
                tone: SpTone.danger,
              ),
            ],
            const SizedBox(height: 24),
            SpPrimaryButton(
              key: const Key('provider_confirm_booking_button'),
              label: l10n.providerBookingConfirmButton,
              isLoading: _isConfirming,
              wrapLabel: true,
              onPressed: _isConfirming || date == null
                  ? null
                  : () => _confirmBooking(date, providerId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BookingModel booking,
    String activeProviderId,
  ) {
    final l10n = context.l10n;
    final isOwned = activeProviderId.isNotEmpty &&
        booking.isOwnedByProvider(activeProviderId);
    final canConfirm = isOwned && booking.canBeConfirmed;

    final preferredFormatted = DateFormat('EEE, d MMM yyyy • h:mm a')
        .format(booking.preferredDateTime);
    final confirmedFormatted = booking.confirmedAppointmentAt != null
        ? DateFormat('EEE, d MMM yyyy • h:mm a')
            .format(booking.confirmedAppointmentAt!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.gutter),
      child: SpContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_successMessage != null &&
                booking.status == BookingStatus.confirmed) ...[
              SpNotice(
                key: const Key('provider_booking_confirmed_notice'),
                icon: Icons.check_circle_outline_rounded,
                message: _successMessage!,
                tone: SpTone.success,
              ),
              const SizedBox(height: 16),
            ],
            if (_errorMessage != null) ...[
              SpNotice(
                key: const Key('provider_booking_error_notice'),
                icon: Icons.error_outline_rounded,
                message: _errorMessage!,
                tone: SpTone.danger,
              ),
              const SizedBox(height: 16),
            ],
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
                        key: const Key('provider_detail_status_badge'),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: l10n.bookingPreferredAppointmentLabel,
                    value: preferredFormatted,
                  ),
                  if (confirmedFormatted != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      key: const Key('provider_confirmed_appointment_row'),
                      icon: Icons.event_available_rounded,
                      label: l10n.bookingConfirmedAppointmentLabel,
                      value: confirmedFormatted,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Service Address',
                    value: booking.address,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.description_outlined,
                    label: 'Problem Description',
                    value: booking.description,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Estimated Fee',
                    value: '\$${booking.totalPrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isOwned)
              SpNotice(
                key: const Key('provider_booking_unauthorized_notice'),
                icon: Icons.lock_outline_rounded,
                message: l10n.providerBookingNotAuthorized,
                tone: SpTone.danger,
              )
            else if (canConfirm)
              SpPrimaryButton(
                key: const Key('provider_confirm_booking_button'),
                label: l10n.providerBookingConfirmButton,
                isLoading: _isConfirming,
                onPressed: _isConfirming
                    ? null
                    : () => _confirmBooking(
                        booking.preferredDateTime, activeProviderId),
              )
            else if (booking.status != BookingStatus.confirmed)
              SpNotice(
                key: const Key('provider_booking_ineligible_notice'),
                icon: Icons.info_outline_rounded,
                message: l10n.providerBookingIneligible,
                tone: SpTone.neutral,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
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
