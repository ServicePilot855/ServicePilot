import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Displays a quote request status pill with an icon, localized label, and
/// semantic colour pairing (DESIGN.md "Not Colour Alone" & "Waiting" rules).
class QuoteStatusBadge extends StatelessWidget {
  const QuoteStatusBadge({
    super.key,
    required this.status,
  });

  final QuoteStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = status.tone;
    final label = status.localizedLabel(context.l10n);

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
            label,
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
