import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/l10n/l10n.dart';

/// Shows a rating with its review count when both are supported by the record.
class ProviderRatingSummary extends StatelessWidget {
  const ProviderRatingSummary({super.key, required this.provider});

  final ProviderModel provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rating = provider.customerRating;
    final style = AppTheme.text(color: AppTheme.browseSecondary, height: 1.5);
    if (rating == null) {
      return Text(
        provider.recordedReviewCount == 0
            ? l10n.providerNoReviews
            : l10n.providerRatingUnavailable,
        style: style,
      );
    }

    final format = NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 1,
    );
    final score = format.format(rating);
    final reviews = l10n.providerReviewCount(provider.reviewCount);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.star_rounded, size: 18, color: AppTheme.browseInk),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            l10n.providerRatingSummary(score, reviews),
            semanticsLabel: l10n.providerRatingAnnouncement(score, reviews),
            style: style,
          ),
        ),
      ],
    );
  }
}
