import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';

/// Renders a provider category badge according to ServicePilot specifications:
/// - Company: Blue (`primarySoft` / `onPrimarySoft`)
/// - Independent: Green (`successSoft` / `successDeep`)
///
/// Corresponds to US-10 (SCRUM-55) & US-11 (SCRUM-54).
class ProviderTypeBadge extends StatelessWidget {
  final ProviderType type;
  final bool isCompact;

  const ProviderTypeBadge({
    super.key,
    required this.type,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompany = type == ProviderType.company;
    final bg = isCompany ? AppTheme.primarySoft : AppTheme.successSoft;
    final fg = isCompany ? AppTheme.onPrimarySoft : AppTheme.successDeep;
    final icon = isCompany ? Icons.apartment_rounded : Icons.person_rounded;
    final label = isCompany ? 'Repair Company' : 'Independent';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 13 : 15,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.text(
              size: isCompact ? 11.5 : 12.5,
              weight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
