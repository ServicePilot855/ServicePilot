import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/quotes/providers/quote_provider.dart';
import 'package:service_pilot/features/quotes/widgets/quote_status_badge.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Provider view for inspecting the quoted price and the homeowner's latest
/// decision on an owned quote request (QUOTE-7 / SCRUM-88).
class ProviderQuoteDetailScreen extends ConsumerWidget {
  const ProviderQuoteDetailScreen({
    super.key,
    required this.quoteId,
    this.initialQuote,
  });

  final String quoteId;
  final QuoteRequestModel? initialQuote;

  void _goBack(BuildContext context, UserModel? user) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(user?.role.homeRoute ?? AppRole.independentProvider.homeRoute);
    }
  }

  SpNotice _decisionNotice(AppLocalizations l10n, QuoteStatus status) {
    switch (status) {
      case QuoteStatus.approved:
        return SpNotice(
          icon: Icons.check_circle_outline_rounded,
          message: l10n.providerQuoteDecisionApproved,
          tone: SpTone.success,
        );
      case QuoteStatus.rejected:
        return SpNotice(
          icon: Icons.cancel_outlined,
          message: l10n.providerQuoteDecisionRejected,
          tone: SpTone.danger,
        );
      case QuoteStatus.quoted:
        return SpNotice(
          icon: Icons.hourglass_top_rounded,
          message: l10n.providerQuoteDecisionWaiting,
          tone: SpTone.waiting,
        );
      case QuoteStatus.requested:
        return SpNotice(
          icon: Icons.request_quote_outlined,
          message: l10n.providerQuoteDecisionRequested,
          tone: SpTone.neutral,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);

    if (user == null || !user.canViewBookingInbox) {
      return SpFlowPage(
        title: l10n.providerQuoteDetailTitle,
        onBack: () => _goBack(context, user),
        bottom: SpSecondaryButton(
          label: l10n.bookingSentBackHome,
          onPressed: () => _goBack(context, user),
        ),
        children: [
          SpNotice(
            key: const Key('provider_quote_inaccessible_notice'),
            icon: Icons.lock_outline_rounded,
            message: l10n.providerQuoteNotFoundOrInaccessible,
            tone: SpTone.neutral,
          ),
        ],
      );
    }

    final quoteAsync = ref.watch(liveQuoteDetailProvider(quoteId));
    final resolvedProviderId = ref.watch(currentProviderIdProvider);
    final providerId =
        resolvedProviderId.isNotEmpty ? resolvedProviderId : user.id;
    final fallback = initialQuote != null &&
            initialQuote!.isAddressedToProvider(providerId)
        ? initialQuote
        : null;
    final quote = quoteAsync.valueOrNull ?? fallback;

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

    if (quoteAsync.hasError && quote == null) {
      return SpFlowPage(
        title: l10n.providerQuoteDetailTitle,
        onBack: () => _goBack(context, user),
        bottom: SpSecondaryButton(
          label: l10n.bookingSentBackHome,
          onPressed: () => _goBack(context, user),
        ),
        children: [
          SpNotice(
            key: const Key('provider_quote_inaccessible_notice'),
            icon: Icons.lock_outline_rounded,
            message: l10n.providerQuoteNotFoundOrInaccessible,
            tone: SpTone.neutral,
          ),
        ],
      );
    }

    if (quote == null || !quote.isAddressedToProvider(providerId)) {
      return SpFlowPage(
        title: l10n.providerQuoteDetailTitle,
        onBack: () => _goBack(context, user),
        bottom: SpSecondaryButton(
          label: l10n.bookingSentBackHome,
          onPressed: () => _goBack(context, user),
        ),
        children: [
          SpNotice(
            key: const Key('provider_quote_inaccessible_notice'),
            icon: Icons.lock_outline_rounded,
            message: l10n.providerQuoteNotFoundOrInaccessible,
            tone: SpTone.neutral,
          ),
        ],
      );
    }

    final priceText = quote.quotedPrice != null
        ? '\$${quote.quotedPrice!.toStringAsFixed(2)}'
        : l10n.providerQuotePriceNotSet;

    return SpFlowPage(
      title: l10n.providerQuoteDetailTitle,
      onBack: () => _goBack(context, user),
      bottom: SpSecondaryButton(
        key: const Key('provider_quote_back_button'),
        label: l10n.bookingSentBackHome,
        onPressed: () => context.go(user.role.homeRoute),
      ),
      children: [
        SpPageHeader(
          title: quote.offeringTitle,
          subtitle: quote.customerName?.trim().isNotEmpty == true
              ? quote.customerName!.trim()
              : null,
        ),
        const SizedBox(height: 16),
        QuoteStatusBadge(
          key: const Key('provider_quote_detail_status_badge'),
          status: quote.status,
        ),
        const SizedBox(height: 16),
        _decisionNotice(l10n, quote.status),
        const SizedBox(height: 24),
        const Divider(height: 1),
        _DetailRow(
          valueKey: const Key('provider_quote_detail_price'),
          label: l10n.providerQuotePriceLabel,
          value: priceText,
          tabularFigures: quote.quotedPrice != null,
        ),
        _DetailRow(
          label: l10n.quoteStatusLabel,
          value: quote.status.localizedLabel(l10n),
        ),
        if (quote.customerName != null &&
            quote.customerName!.trim().isNotEmpty)
          _DetailRow(
            label: l10n.providerQuoteCustomerLabel,
            value: quote.customerName!.trim(),
          ),
        _DetailRow(
          label: l10n.bookingSummaryService,
          value: quote.offeringTitle,
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
                fontFeatures:
                    tabularFigures ? const [FontFeature.tabularFigures()] : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
