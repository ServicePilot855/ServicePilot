import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Result returned when the user interacts with [CancelBookingDialog].
class CancelBookingDialogResult {
  final bool confirmed;
  final String? reason;

  const CancelBookingDialogResult({
    required this.confirmed,
    this.reason,
  });
}

/// Confirmation modal dialog before cancelling a repair booking.
///
/// Implements US-14 (SCRUM-45) AC:
/// "Customers must confirm their decision before cancellation."
class CancelBookingDialog extends StatefulWidget {
  final BookingModel booking;

  const CancelBookingDialog({
    super.key,
    required this.booking,
  });

  /// Shows the confirmation modal and returns a [CancelBookingDialogResult]
  /// if confirmed, or `null` if the customer chooses to keep the booking.
  static Future<CancelBookingDialogResult?> show(
    BuildContext context, {
    required BookingModel booking,
  }) {
    return showDialog<CancelBookingDialogResult>(
      context: context,
      builder: (_) => CancelBookingDialog(booking: booking),
    );
  }

  @override
  State<CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<CancelBookingDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('cancel_booking_confirmation_dialog'),
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.errorSoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorDeep,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cancel Repair Booking?',
              style: AppTheme.display(size: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your "${widget.booking.serviceTitle}" booking with ${widget.booking.providerName}?',
              style: AppTheme.text(
                size: 14.5,
                color: AppTheme.textBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const SpNotice(
              icon: Icons.info_outline_rounded,
              message:
                  'Once cancelled, this booking cannot be reopened, accepted, or started.',
              tone: SpTone.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Reason for cancellation (optional)',
              style: AppTheme.text(
                size: 13.5,
                weight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('cancel_booking_reason_field'),
              controller: _reasonController,
              maxLines: 2,
              style: AppTheme.text(size: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Issue resolved or schedule changed',
                hintStyle: AppTheme.text(
                  size: 13.5,
                  color: AppTheme.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpSecondaryButton(
              key: const Key('cancel_dialog_confirm_button'),
              label: 'Confirm Cancellation',
              icon: Icons.cancel_outlined,
              foregroundColor: AppTheme.errorDeep,
              onPressed: () {
                Navigator.of(context).pop(
                  CancelBookingDialogResult(
                    confirmed: true,
                    reason: _reasonController.text.trim(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            SpPrimaryButton(
              key: const Key('cancel_dialog_keep_button'),
              label: 'Keep Booking',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}
