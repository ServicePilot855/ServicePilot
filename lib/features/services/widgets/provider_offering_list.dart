import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Dashboard section displaying published service offerings for a provider
/// with direct CTA to publish new offerings (supporting OFFER-2 quote mode).
class ProviderOfferingList extends ConsumerWidget {
  const ProviderOfferingList({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  final String providerId;
  final String providerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offeringsAsync = ref.watch(offeringsByProviderProvider(providerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.offeringDashboardTitle,
                style: AppTheme.display(size: 20, color: AppTheme.textPrimary),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: OutlinedButton.icon(
                key: const Key('add_offering_button'),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(l10n.offeringAddButton),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                  ),
                ),
                onPressed: () =>
                    context.push('/offerings/create?providerId=$providerId'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        offeringsAsync.when(
          data: (offerings) {
            if (offerings.isEmpty) {
              return SpNotice(
                icon: Icons.list_alt_rounded,
                message: l10n.offeringEmptyNotice,
                tone: SpTone.neutral,
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: offerings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final offering = offerings[index];
                return _OfferingCard(offering: offering);
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) {
            debugPrint('[ProviderOfferingList] offerings load error: $err');
            return SpNotice(
              icon: Icons.error_outline_rounded,
              message: l10n.offeringLoadError,
              tone: SpTone.danger,
            );
          },
        ),
      ],
    );
  }
}

class _OfferingCard extends StatelessWidget {
  const _OfferingCard({required this.offering});

  final OfferingModel offering;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isQuote = offering.isQuoteRequired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isQuote ? AppTheme.accent.withValues(alpha: 0.5) : AppTheme.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  offering.title,
                  style: AppTheme.display(
                    size: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isQuote)
                Container(
                  key: Key('badge_quote_required_${offering.id}'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.request_quote_rounded,
                        size: 14,
                        color: AppTheme.accentDeep,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.offeringBadgeQuoteRequired,
                        style: AppTheme.text(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppTheme.accentDeep,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  offering.priceDisplay,
                  style: AppTheme.display(
                    size: 15,
                    color: AppTheme.primary,
                  ),
                ),
            ],
          ),
          if (offering.categoryName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              offering.categoryName,
              style: AppTheme.text(
                size: 13,
                weight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            offering.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.text(
              size: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
