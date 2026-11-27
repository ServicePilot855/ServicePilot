import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/quotes/providers/quote_provider.dart';
import 'package:service_pilot/features/quotes/widgets/quote_status_badge.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Confirmation page shown after a homeowner submits a separate quote request
/// (QUOTE-1 / SCRUM-83).
class QuoteRequestConfirmationScreen extends ConsumerWidget {
  const QuoteRequestConfirmationScreen({
    super.key,
    required this.quoteId,
    this.quote,
  });

  final String quoteId;
  final QuoteRequestModel? quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final customerId = ref.watch(activeCustomerIdProvider);
    final known = quote;
    if (known != null &&
        known.id == quoteId &&
        known.isOwnedByCustomer(customerId)) {
      return _Content(quote: known);
    }

    final request = quoteDetailProvider(quoteId);
    return ref.watch(request).when(
          skipLoadingOnRefresh: false,
          data: (loaded) => loaded == null
              ? _Unavailable(message: l10n.quoteDetailNotFound)
              : _Content(quote: loaded),
          loading: () => Scaffold(
            backgroundColor: AppTheme.surface,
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                semanticsLabel: l10n.quoteDetailLoading,
              ),
            ),
          ),
          error: (_, __) => _Unavailable(
            message: l10n.quoteDetailLoadFailed,
            onRetry: () => ref.invalidate(request),
          ),
        );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SpFlowPage(
      title: l10n.quoteDetailTitle,
      onBack: () => context.go('/home/customer'),
      bottom: SpSecondaryButton(
        label: l10n.bookingSentBackHome,
        onPressed: () => context.go('/home/customer'),
      ),
      children: [
        SpNotice(
          icon: onRetry == null
              ? Icons.search_off_rounded
              : Icons.error_outline_rounded,
          message: message,
          tone: onRetry == null ? SpTone.neutral : SpTone.danger,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          SpSecondaryButton(label: l10n.bookingInboxRetry, onPressed: onRetry),
        ],
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.quote});

  final QuoteRequestModel quote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = quote;

    return SpFlowPage(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpPrimaryButton(
            key: const Key('quote_view_status_button'),
            label: l10n.quoteSentViewStatus,
            onPressed: () => context.go(
              '/quotes/${Uri.encodeComponent(q.id)}',
              extra: q,
            ),
          ),
          const SizedBox(height: 8),
          SpSecondaryButton(
            key: const Key('quote_back_home_button'),
            label: l10n.bookingSentBackHome,
            onPressed: () => context.go('/home/customer'),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 24),
        SpStatusHero(
          key: const Key('quote_request_sent_hero'),
          icon: Icons.request_quote_rounded,
          title: l10n.quoteSentTitle,
          message: l10n.quoteSentMessage(q.providerName),
          tone: SpTone.waiting,
        ),
        const SizedBox(height: 20),
        QuoteStatusBadge(
          key: const Key('quote_confirmation_status_badge'),
          status: q.status,
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        _SummaryRow(
          label: l10n.bookingSummaryService,
          value: q.offeringTitle,
        ),
        _SummaryRow(
          label: l10n.quoteSummaryProvider,
          value: q.providerName,
        ),
        _SummaryRow(
          label: l10n.quoteStatusLabel,
          value: q.status.localizedLabel(l10n),
        ),
        _SummaryRow(
          label: l10n.quoteSummaryDescription,
          value: q.description,
        ),
        if (q.photoUrls.isNotEmpty)
          _SummaryRow(
            label: l10n.bookingSummaryPhotos,
            value: l10n.bookingPhotoCount(q.photoUrls.length),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

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
