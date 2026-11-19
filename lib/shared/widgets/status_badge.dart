import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Displays a booking status pill with an icon, text label, and semantic colour.
///
/// Adheres to "The Not Colour Alone Rule" and "The Waiting Rule" in DESIGN.md.
class StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final tone = status.tone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 15,
            color: tone.foreground,
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: AppTheme.text(
              size: 12.5,
              weight: FontWeight.w600,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
