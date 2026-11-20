import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/l10n/l10n.dart';

class ProviderTypeBadge extends StatelessWidget {
  const ProviderTypeBadge({super.key, required this.type});

  final ProviderType type;

  @override
  Widget build(BuildContext context) {
    final company = type == ProviderType.company;
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.browseFill,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                company ? Icons.apartment_rounded : Icons.person_rounded,
                size: 16,
                color: AppTheme.browseInk,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                company
                    ? l10n.providerTypeCompany
                    : l10n.providerTypeIndependent,
                style: AppTheme.text(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppTheme.browseInk,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
