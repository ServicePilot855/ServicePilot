import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:service_pilot/features/quotes/services/quote_service.dart';
import 'package:service_pilot/features/quotes/widgets/quote_status_badge.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Provider view of an incoming request and the homeowner's latest decision.
///
/// While the request is `Requested`, the addressed provider can send a price
/// and move it to `Quoted` (QUOTE-3 / SCRUM-85).
class ProviderQuoteDetailScreen extends ConsumerStatefulWidget {
  const ProviderQuoteDetailScreen({
    super.key,
    required this.quoteId,
  });

  final String quoteId;

  @override
  ConsumerState<ProviderQuoteDetailScreen> createState() =>
      _ProviderQuoteDetailScreenState();
}

class _ProviderQuoteDetailScreenState
    extends ConsumerState<ProviderQuoteDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  bool _attempted = false;
  bool _sending = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String? _validatePrice(AppLocalizations l10n, String? value) {
    return switch (QuotePriceValidator.validateInput(value)) {
      QuotePriceError.required => l10n.providerQuotePriceRequired,
      QuotePriceError.invalid => l10n.offeringPricePositive,
      null => null,
    };
  }

  Future<void> _sendPrice(QuoteRequestModel quote, String providerId) async {
    setState(() => _attempted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = context.l10n;
    setState(() => _sending = true);
    try {
      await ref.read(quoteServiceProvider).submitQuotePrice(
            quoteId: quote.id,
            providerId: providerId,
            price: QuotePriceValidator.parse(_priceController.text)!,
          );
      // The live record now reads Quoted and shows the waiting notice.
    } on InvalidQuotePriceException {
      _formKey.currentState?.validate();
    } on InvalidQuoteStateException {
      if (mounted) showSpError(context, l10n.providerQuoteErrorAlreadyPriced);
    } on UnauthorizedQuoteActionException {
      if (mounted) showSpError(context, l10n.providerQuoteErrorNotAllowed);
    } on QuoteNotFoundException {
      if (mounted) showSpError(context, l10n.providerQuoteErrorNotAllowed);
    } catch (error) {
      debugPrint('[ProviderQuoteDetailScreen] price failed: $error');
      if (mounted) showSpError(context, l10n.providerQuoteErrorSaveFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);

    Widget unavailable() => SpFlowPage(
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

    if (user == null || !user.canViewBookingInbox) return unavailable();

    final quoteAsync =
        ref.watch(liveProviderQuoteDetailProvider(widget.quoteId));
    if (quoteAsync.isLoading) {
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

    final quote = quoteAsync.asData?.value;
    if (quote == null) return unavailable();

    final providerId = ref.watch(currentProviderIdProvider);
    final canPrice = quote.canBeQuotedBy(providerId);
    final priceText = quote.quotedPrice != null
        ? formatQuoteAmount(quote.quotedPrice!)
        : l10n.providerQuotePriceNotSet;

    final page = SpFlowPage(
      title: l10n.providerQuoteDetailTitle,
      onBack: () => _goBack(context, user),
      bottom: canPrice
          ? SpPrimaryButton(
              key: const Key('provider_quote_send_price_button'),
              label: l10n.providerQuoteSendPrice,
              icon: Icons.send_rounded,
              isLoading: _sending,
              onPressed: () => _sendPrice(quote, providerId),
            )
          : SpSecondaryButton(
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
        if (quote.customerName != null && quote.customerName!.trim().isNotEmpty)
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
        if (quote.photoUrls.isNotEmpty) ...[
          _DetailRow(
            label: l10n.bookingSummaryPhotos,
            value: l10n.bookingPhotoCount(quote.photoUrls.length),
          ),
          for (final (index, url) in quote.photoUrls.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _RequestPhoto(url: url, number: index + 1),
            ),
        ],
        if (canPrice) ...[
          const SizedBox(height: 32),
          SpFormSection(
            title: l10n.providerQuotePriceSection,
            children: [
              SpTextField(
                key: const Key('provider_quote_price_field'),
                label: l10n.providerQuotePriceInputLabel,
                hint: l10n.providerQuotePriceInputHint,
                helper: l10n.providerQuotePriceInputHelper,
                controller: _priceController,
                prefixIcon: Icons.attach_money_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _sendPrice(quote, providerId),
                validator: (value) => _validatePrice(l10n, value),
              ),
            ],
          ),
        ],
      ],
    );

    if (!canPrice) return page;
    return Form(
      key: _formKey,
      autovalidateMode: _attempted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: page,
    );
  }
}

class _RequestPhoto extends StatelessWidget {
  const _RequestPhoto({required this.url, required this.number});

  final String url;
  final int number;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unavailable = SpNotice(
      icon: Icons.broken_image_outlined,
      message: l10n.providerQuotePhotoUnavailable(number),
      tone: SpTone.neutral,
    );
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'res.cloudinary.com' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty) {
      return unavailable;
    }

    return Image.network(
      uri.toString(),
      height: 200,
      width: double.infinity,
      fit: BoxFit.contain,
      semanticLabel: l10n.providerQuotePhotoLabel(number),
      errorBuilder: (_, __, ___) => unavailable,
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
