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

/// Homeowner detail/status page for a submitted quote request (QUOTE-1).
class QuoteRequestDetailScreen extends ConsumerWidget {
  const QuoteRequestDetailScreen({
    super.key,
    required this.quoteId,
    this.initialQuote,
  });

  final String quoteId;
  final QuoteRequestModel? initialQuote;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/customer');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quoteAsync = ref.watch(liveQuoteDetailProvider(quoteId));
    final quote = quoteAsync.valueOrNull ?? initialQuote;

    if (quoteAsync.isLoading && quote == null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            semanticsLabel: l10n.quoteDetailLoading,
            color: AppTheme.primary,
          ),
        ),
      );
    }

    if (quote == null) {
      return SpFlowPage(
        title: l10n.quoteDetailTitle,
        onBack: () => _goBack(context),
        bottom: SpSecondaryButton(
          label: l10n.bookingSentBackHome,
          onPressed: () => context.go('/home/customer'),
        ),
        children: [
          SpNotice(
            icon: Icons.search_off_rounded,
            message: l10n.quoteDetailNotFound,
            tone: SpTone.neutral,
          ),
        ],
      );
    }

    return SpFlowPage(
      title: l10n.quoteDetailTitle,
      onBack: () => _goBack(context),
      bottom: SpSecondaryButton(
        key: const Key('quote_detail_back_home_button'),
        label: l10n.bookingSentBackHome,
        onPressed: () => context.go('/home/customer'),
      ),
      children: [
        SpPageHeader(
          title: quote.offeringTitle,
          subtitle: quote.providerName,
        ),
        const SizedBox(height: 16),
        QuoteStatusBadge(
          key: const Key('quote_detail_status_badge'),
          status: quote.status,
        ),
        if (quote.status == QuoteStatus.requested) ...[
          const SizedBox(height: 16),
          SpNotice(
            icon: Icons.hourglass_top_rounded,
            message: l10n.quoteDetailWaitingMessage(quote.providerName),
            tone: SpTone.waiting,
          ),
        ],
        const SizedBox(height: 24),
        const Divider(height: 1),
        _DetailRow(
          label: l10n.quoteSummaryProvider,
          value: quote.providerName,
        ),
        _DetailRow(
          label: l10n.bookingSummaryService,
          value: quote.offeringTitle,
        ),
        _DetailRow(
          label: l10n.quoteStatusLabel,
          value: quote.status.localizedLabel(l10n),
        ),
        _DetailRow(
          label: l10n.quoteSummaryDescription,
          value: quote.description,
        ),
        if (quote.photoUrls.isNotEmpty)
          _DetailRow(
            label: l10n.bookingSummaryPhotos,
            value: l10n.bookingPhotoCount(quote.photoUrls.length),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
