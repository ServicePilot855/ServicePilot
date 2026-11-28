import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/cart/screens/cart_screen.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// "Request sent" page shown after a booking request is saved.
///
/// US-12 (SCRUM-43) AC: the customer is told the request was submitted.
/// From here they go to booking status (`/bookings/:bookingId`) or home.
class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  final String bookingId;

  /// The booking just created, passed by the form. Loaded by [bookingId]
  /// when missing (for example after a browser refresh on web).
  final BookingModel? booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = booking;
    if (known != null) return _Content(booking: known);

    return ref.watch(bookingDetailProvider(bookingId)).when(
          data: (loaded) => loaded == null
              ? _Content(booking: null, bookingId: bookingId)
              : _Content(booking: loaded),
          loading: () => const Scaffold(
            backgroundColor: AppTheme.surface,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
          error: (_, __) => _Content(booking: null, bookingId: bookingId),
        );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.booking, this.bookingId});

  final BookingModel? booking;
  final String? bookingId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final b = booking;
    final id = b?.id ?? bookingId ?? '';

    return SpFlowPage(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpPrimaryButton(
            key: const Key('booking_view_status_button'),
            label: l10n.bookingSentViewStatus,
            onPressed: () => context.go('/bookings/$id', extra: b),
          ),
          const SizedBox(height: 8),
          SpSecondaryButton(
            key: const Key('booking_back_home_button'),
            label: l10n.bookingSentBackHome,
            onPressed: () => context.go('/home/customer'),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 24),
        SpStatusHero(
          key: const Key('booking_request_sent_hero'),
          icon: Icons.send_rounded,
          title: l10n.bookingSentTitle,
          message: b == null
              ? l10n.bookingSentMessageGeneric
              : l10n.bookingSentMessage(b.providerName),
          // Tape Yellow: the request is waiting for the provider.
          tone: SpTone.waiting,
        ),
        if (b != null) ...[
          const SizedBox(height: 32),
          const Divider(height: 1),
          // Identifies the saved booking (CART-3 / SCRUM-132).
          _SummaryRow(
            key: const Key('booking_sent_reference'),
            label: l10n.bookingSummaryReference,
            value: b.id,
          ),
          if (b.items.isEmpty)
            _SummaryRow(
              label: l10n.bookingSummaryService,
              value: b.serviceTitle,
            )
          else ...[
            _SummaryRow(
              key: const Key('booking_sent_services'),
              label: l10n.bookingSummaryServices,
              value: [
                for (final item in b.items)
                  l10n.bookingSummaryItemLine(
                    item.title,
                    item.quantity > 1
                        ? l10n.cartItemQuantityPrice(
                            item.quantity,
                            formatCartPrice(item.unitPrice),
                          )
                        : formatCartPrice(item.unitPrice),
                  ),
              ].join('\n'),
            ),
            _SummaryRow(
              key: const Key('booking_sent_total'),
              label: l10n.bookingSummaryTotal,
              value: formatCartPrice(b.totalPrice),
            ),
          ],
          _SummaryRow(
            label: l10n.bookingSummaryWhen,
            value: '${material.formatFullDate(b.preferredDateTime)}, '
                '${material.formatTimeOfDay(TimeOfDay.fromDateTime(b.preferredDateTime))}',
          ),
          _SummaryRow(
            label: l10n.bookingSummaryAddress,
            value: b.hasLocation
                ? '${b.address}\n${l10n.bookingLocationPinned}'
                : b.address,
          ),
          if (b.photoUrls.isNotEmpty)
            _SummaryRow(
              label: l10n.bookingSummaryPhotos,
              value: l10n.bookingPhotoCount(b.photoUrls.length),
            ),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.text(
                size: 15.5,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
