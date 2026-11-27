import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';

// Appointment controls shared by the booking request form (US-12) and the
// approved-quote booking step (QUOTE-5 / SCRUM-87).

/// Date and time side by side, each opening the platform picker.
class BookingDateTimeRow extends StatelessWidget {
  const BookingDateTimeRow({
    super.key,
    required this.date,
    required this.time,
    required this.errorText,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime? date;
  final TimeOfDay? time;
  final String? errorText;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _PickerField(
                key: const Key('booking_date_picker'),
                label: l10n.bookingDateLabel,
                icon: Icons.calendar_today_rounded,
                value: date == null ? null : material.formatMediumDate(date!),
                placeholder: l10n.bookingDatePlaceholder,
                hasError: hasError,
                onTap: onPickDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _PickerField(
                key: const Key('booking_time_picker'),
                label: l10n.bookingTimeLabel,
                icon: Icons.schedule_rounded,
                value: time == null ? null : material.formatTimeOfDay(time!),
                placeholder: l10n.bookingTimePlaceholder,
                hasError: hasError,
                onTap: onPickTime,
              ),
            ),
          ],
        ),
        if (hasError) BookingFieldErrorText(errorText!),
      ],
    );
  }
}

/// Looks like a text field, opens a picker when tapped.
class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.hasError,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? value;
  final String placeholder;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppTheme.error : AppTheme.fieldBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.text(
            size: 14,
            weight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: '$label, ${value ?? placeholder}',
          excludeSemantics: true,
          child: Material(
            color: AppTheme.inputFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: AppTheme.controlHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          value ?? placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.text(
                            size: 16,
                            color: value == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BookingFieldErrorText extends StatelessWidget {
  const BookingFieldErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: AppTheme.text(size: 13, color: AppTheme.error),
        ),
      ),
    );
  }
}

/// Optional map pin for the address: a button before pinning, a status row
/// with change and remove actions after.
class BookingLocationPin extends StatelessWidget {
  const BookingLocationPin({
    super.key,
    required this.pin,
    required this.onPick,
    required this.onRemove,
  });

  final LatLng? pin;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final point = pin;

    if (point == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSecondaryButton(
            key: const Key('booking_pin_location'),
            label: l10n.bookingLocationAdd,
            icon: Icons.map_outlined,
            onPressed: onPick,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bookingLocationAddHelper,
            style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    return Container(
      key: const Key('booking_location_pinned'),
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppTheme.successSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.where_to_vote_rounded,
            size: 22,
            color: AppTheme.successDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bookingLocationPinned,
                  style: AppTheme.text(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${point.latitude.toStringAsFixed(5)}, '
                  '${point.longitude.toStringAsFixed(5)}',
                  style: AppTheme.text(
                    size: 12.5,
                    color: AppTheme.textSecondary,
                  ).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          SpTextButton(label: l10n.bookingLocationChange, onPressed: onPick),
          IconButton(
            key: const Key('booking_remove_pin'),
            tooltip: l10n.bookingLocationRemove,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppTheme.textSecondary,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
