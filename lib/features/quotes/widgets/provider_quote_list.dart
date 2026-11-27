import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/quotes/providers/quote_provider.dart';
import 'package:service_pilot/features/quotes/widgets/quote_status_badge.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Dashboard section displaying quote requests addressed to a provider and
/// the homeowner's latest decision (QUOTE-7 / SCRUM-88).
class ProviderQuoteList extends ConsumerWidget {
  const ProviderQuoteList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quotesAsync = ref.watch(liveProviderQuoteRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.providerQuotesTitle,
            style: AppTheme.display(size: 20, color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(height: 12),
        quotesAsync.when(
          skipLoadingOnRefresh: false,
          data: (quotes) {
            if (quotes.isEmpty) {
              return SpNotice(
                icon: Icons.request_quote_outlined,
                message: l10n.providerQuotesEmpty,
                tone: SpTone.neutral,
              );
            }

            final sorted = List<QuoteRequestModel>.from(quotes)
              ..sort(
                (a, b) => (b.updatedAt ?? b.createdAt)
                    .compareTo(a.updatedAt ?? a.createdAt),
              );

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ProviderQuoteCard(
                quote: sorted[index],
              ),
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                semanticsLabel: l10n.providerQuotesTitle,
              ),
            ),
          ),
          error: (_, __) => Column(
            children: [
              SpNotice(
                icon: Icons.error_outline_rounded,
                message: l10n.providerQuotesLoadError,
                tone: SpTone.danger,
              ),
              const SizedBox(height: 12),
              SpSecondaryButton(
                label: l10n.bookingInboxRetry,
                wrapLabel: true,
                onPressed: () =>
                    ref.invalidate(liveProviderQuoteRequestsProvider),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderQuoteCard extends StatelessWidget {
  const _ProviderQuoteCard({required this.quote});

  final QuoteRequestModel quote;

  String _decisionSummary(AppLocalizations l10n) {
    switch (quote.status) {
      case QuoteStatus.approved:
        return l10n.providerQuoteDecisionApproved;
      case QuoteStatus.rejected:
        return l10n.providerQuoteDecisionRejected;
      case QuoteStatus.quoted:
        return l10n.providerQuoteDecisionWaiting;
      case QuoteStatus.requested:
        return l10n.providerQuoteDecisionRequested;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final priceText = quote.quotedPrice != null
        ? '\$${quote.quotedPrice!.toStringAsFixed(2)}'
        : l10n.providerQuotePriceNotSet;

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        key: Key('provider_quote_card_${quote.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: () => context.push(
          '/provider/quotes/${Uri.encodeComponent(quote.id)}',
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      quote.offeringTitle,
                      style: AppTheme.display(
                        size: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  QuoteStatusBadge(
                    key: Key('provider_quote_status_${quote.id}'),
                    status: quote.status,
                  ),
                ],
              ),
              if (quote.customerName != null &&
                  quote.customerName!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  quote.customerName!.trim(),
                  style: AppTheme.text(
                    size: 13.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${l10n.providerQuotePriceLabel}: ',
                    style: AppTheme.text(
                      size: 13.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      priceText,
                      key: Key('provider_quote_price_${quote.id}'),
                      style: AppTheme.text(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _decisionSummary(l10n),
                style: AppTheme.text(
                  size: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
