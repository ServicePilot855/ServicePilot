import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/quotes/providers/quote_provider.dart';
import 'package:service_pilot/features/quotes/services/quote_service.dart';
import 'package:service_pilot/features/quotes/widgets/quote_status_badge.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Homeowner detail/status page for a submitted quote request (QUOTE-1).
///
/// - `Quoted`: shows the provider's price and an approve action (QUOTE-4 /
///   SCRUM-86).
/// - `Approved`: shows the agreed amount and opens the booking step
///   (QUOTE-5 / SCRUM-87), or the booking once one exists.
class QuoteRequestDetailScreen extends ConsumerStatefulWidget {
  const QuoteRequestDetailScreen({
    super.key,
    required this.quoteId,
    this.initialQuote,
  });

  final String quoteId;
  final QuoteRequestModel? initialQuote;

  @override
  ConsumerState<QuoteRequestDetailScreen> createState() =>
      _QuoteRequestDetailScreenState();
}

class _QuoteRequestDetailScreenState
    extends ConsumerState<QuoteRequestDetailScreen> {
  bool _approving = false;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/customer');
    }
  }

  Future<void> _approve(QuoteRequestModel quote) async {
    final l10n = context.l10n;
    setState(() => _approving = true);
    try {
      await ref.read(quoteServiceProvider).approveQuote(
            quoteId: quote.id,
            customerId: ref.read(activeCustomerIdProvider),
          );
      ref.invalidate(customerQuoteRequestsProvider);
      // The live record now reads Approved and offers the booking step.
    } on InvalidQuoteStateException {
      if (mounted) showSpError(context, l10n.quoteApproveErrorChanged);
    } on UnauthorizedQuoteActionException {
      if (mounted) showSpError(context, l10n.quoteBookingUnavailable);
    } catch (error) {
      debugPrint('[QuoteRequestDetailScreen] approval failed: $error');
      if (mounted) showSpError(context, l10n.quoteApproveErrorFailed);
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quoteAsync = ref.watch(liveQuoteDetailProvider(widget.quoteId));
    final quote = quoteAsync.valueOrNull ?? widget.initialQuote;

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

    final isOwner =
        quote.isOwnedByCustomer(ref.watch(activeCustomerIdProvider));
    final quotedText = quote.quotedPrice == null
        ? null
        : formatQuoteAmount(quote.quotedPrice!);
    final approvedText = quote.approvedPrice == null
        ? null
        : formatQuoteAmount(quote.approvedPrice!);
    final canApprove = isOwner && quote.canBeApprovedBy(quote.customerId);
    final canBook = isOwner &&
        quote.status == QuoteStatus.approved &&
        approvedText != null &&
        !quote.isBooked;

    return SpFlowPage(
      title: l10n.quoteDetailTitle,
      onBack: () => _goBack(context),
      bottom: _bottomAction(
        context,
        quote,
        canApprove: canApprove,
        canBook: canBook,
        quotedText: quotedText,
        showBooking: isOwner && quote.isBooked,
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
        if (canApprove) ...[
          const SizedBox(height: 16),
          SpNotice(
            key: const Key('quote_detail_review_notice'),
            icon: Icons.request_quote_rounded,
            message:
                l10n.quoteDetailReviewMessage(quote.providerName, quotedText!),
            tone: SpTone.brand,
          ),
        ],
        if (quote.status == QuoteStatus.approved && approvedText != null) ...[
          const SizedBox(height: 16),
          SpNotice(
            key: const Key('quote_detail_approved_notice'),
            icon: quote.isBooked
                ? Icons.event_available_rounded
                : Icons.check_circle_outline_rounded,
            message: quote.isBooked
                ? l10n.quoteBookedMessage
                : l10n.quoteApprovedMessage(approvedText, quote.providerName),
            tone: SpTone.success,
          ),
        ],
        const SizedBox(height: 24),
        const Divider(height: 1),
        if (approvedText != null)
          _DetailRow(
            valueKey: const Key('quote_detail_approved_price'),
            label: l10n.quoteApprovedPriceLabel,
            value: approvedText,
            tabularFigures: true,
          )
        else if (quotedText != null)
          _DetailRow(
            valueKey: const Key('quote_detail_quoted_price'),
            label: l10n.providerQuotePriceLabel,
            value: quotedText,
            tabularFigures: true,
          ),
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

  /// One pinned action per state; the filled button is the next step.
  Widget _bottomAction(
    BuildContext context,
    QuoteRequestModel quote, {
    required bool canApprove,
    required bool canBook,
    required String? quotedText,
    required bool showBooking,
  }) {
    final l10n = context.l10n;
    if (canApprove) {
      return SpPrimaryButton(
        key: const Key('quote_approve_button'),
        label: l10n.quoteApproveButton(quotedText!),
        icon: Icons.check_rounded,
        isLoading: _approving,
        onPressed: () => _approve(quote),
      );
    }
    if (canBook) {
      return SpPrimaryButton(
        key: const Key('quote_book_button'),
        label: l10n.quoteBookButton,
        icon: Icons.event_rounded,
        onPressed: () => context.push('/quotes/${quote.id}/book', extra: quote),
      );
    }
    if (showBooking) {
      return SpSecondaryButton(
        key: const Key('quote_view_booking_button'),
        label: l10n.quoteViewBooking,
        icon: Icons.receipt_long_rounded,
        onPressed: () => context.go('/bookings/${quote.bookingId}'),
      );
    }
    return SpSecondaryButton(
      key: const Key('quote_detail_back_home_button'),
      label: l10n.bookingSentBackHome,
      onPressed: () => context.go('/home/customer'),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    this.valueKey,
    required this.label,
    required this.value,
    this.tabularFigures = false,
  });

  final Key? valueKey;
  final String label;
  final String value;
  final bool tabularFigures;

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
              key: valueKey,
              style: AppTheme.text(
                size: 15.5,
                color: AppTheme.textPrimary,
                height: 1.5,
              ).copyWith(
                fontFeatures: tabularFigures
                    ? const [FontFeature.tabularFigures()]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
