import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/cart/models/cart_state.dart';
import 'package:service_pilot/features/cart/providers/cart_provider.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/widgets/provider_rating_summary.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

class ProviderDetailScreen extends ConsumerWidget {
  const ProviderDetailScreen({
    super.key,
    required this.providerId,
    ProviderModel? initialProvider,
    ProviderModel? provider,
  }) : initialProvider = initialProvider ?? provider;

  final String providerId;
  final ProviderModel? initialProvider;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/categories');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = providerDetailsProvider(providerId);
    final providerAsync = ref.watch(profile);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppTheme.browseBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: SpBackButton(onPressed: () => _goBack(context)),
        title: Text(
          l10n.providerProfileTitle,
          style: AppTheme.display(size: 18, color: AppTheme.browseInk),
        ),
        actions: [
          if (cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  key: const Key('provider_detail_cart_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 16,
                        color: AppTheme.onPrimarySoft,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.cartBadgeLabel(cart.itemCount),
                        style: AppTheme.text(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppTheme.onPrimarySoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: providerAsync.when(
        data: (fetched) {
          final provider = fetched ?? initialProvider;
          if (provider != null) {
            return _ProviderProfile(provider: provider);
          }
          return _ProviderMessage(
            message: SpStatusHero(
              icon: Icons.person_off_rounded,
              title: l10n.providerProfileNotFound,
              message: l10n.providerProfileNotFoundBody,
              tone: SpTone.neutral,
            ),
            action: SpSecondaryButton(
              label: l10n.providerBack,
              outlineColor: AppTheme.browseControlBorder,
              wrapLabel: true,
              onPressed: () => _goBack(context),
            ),
          );
        },
        loading: () {
          if (initialProvider != null) {
            return _ProviderProfile(provider: initialProvider!);
          }
          return Center(
            child: CircularProgressIndicator(
              semanticsLabel: l10n.providerProfileLoading,
            ),
          );
        },
        error: (_, __) {
          if (initialProvider != null) {
            return _ProviderProfile(provider: initialProvider!);
          }
          return _ProviderMessage(
            message: SpNotice(
              icon: Icons.error_outline_rounded,
              message: l10n.providerProfileError,
              tone: SpTone.danger,
            ),
            action: SpSecondaryButton(
              label: l10n.providerDirectoryRetry,
              outlineColor: AppTheme.browseControlBorder,
              wrapLabel: true,
              onPressed: () => ref.invalidate(profile),
            ),
          );
        },
      ),
    );
  }
}

class _ProviderProfile extends ConsumerWidget {
  const _ProviderProfile({required this.provider});

  final ProviderModel provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canBook = provider.canAcceptBookings;
    final unavailableReason = provider.unavailableReason?.trim();
    final about = provider.bio.trim();
    final description = provider.description.trim();
    final contactLinks = {
      l10n.companyProfileTelegram: provider.telegramUrl?.trim() ?? '',
      l10n.companyProfileMessenger: provider.messengerUrl?.trim() ?? '',
    }.entries.where((link) => link.value.isNotEmpty);
    final areas = provider.coverageAreas.isEmpty
        ? [provider.serviceArea]
        : provider.coverageAreas;
    final bodyStyle =
        AppTheme.text(color: AppTheme.browseSecondary, height: 1.5);

    return Column(
      children: [
        Expanded(
          child: SafeArea(
            top: false,
            bottom: false,
            child: SpContentWidth(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.browseBorder),
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              provider.displayName,
                              style: AppTheme.display(
                                color: AppTheme.browseInk,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ProviderTypeBadge(type: provider.type),
                          const SizedBox(height: 8),
                          ProviderRatingSummary(provider: provider),
                          const SizedBox(height: 12),
                          SpNotice(
                            icon: canBook
                                ? Icons.check_circle_outline_rounded
                                : Icons.event_busy_rounded,
                            message: canBook
                                ? l10n.providerAvailable
                                : l10n.providerUnavailable,
                            tone: canBook ? SpTone.success : SpTone.neutral,
                          ),
                          if (!canBook &&
                              unavailableReason != null &&
                              unavailableReason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(unavailableReason, style: bodyStyle),
                          ],
                          if (areas.any((item) => item.trim().isNotEmpty)) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.providerAreas,
                                style: AppTheme.display(
                                  size: 16,
                                  color: AppTheme.browseInk,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ProfileValues(values: areas),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (provider.specialties
                      .any((item) => item.trim().isNotEmpty))
                    _ProfileSection(
                      title: l10n.providerSpecialties,
                      child: _ProfileValues(values: provider.specialties),
                    ),
                  if (description.isNotEmpty || about.isNotEmpty)
                    _ProfileSection(
                      title: l10n.providerAbout,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description.isNotEmpty)
                            Text(description, style: bodyStyle),
                          if (about.isNotEmpty && about != description) ...[
                            if (description.isNotEmpty)
                              const SizedBox(height: 8),
                            Text(about, style: bodyStyle),
                          ],
                        ],
                      ),
                    ),
                  if (provider.isApprovedAndActive && contactLinks.isNotEmpty)
                    _ProfileSection(
                      title: l10n.companyProfileContacts,
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final link in contactLinks) ...[
                              Text(
                                link.key,
                                style: AppTheme.text(weight: FontWeight.w600),
                              ),
                              Text(link.value, style: bodyStyle),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  _OfferingsSection(provider: provider),
                ],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.browseBorder)),
          ),
          child: SafeArea(
            top: false,
            child: SpContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SpPrimaryButton(
                      label: l10n.providerContinueBooking,
                      wrapLabel: true,
                      enabled: canBook,
                      onPressed: canBook
                          ? () => context.push(
                                '/providers/${Uri.encodeComponent(provider.id)}/book',
                                extra: provider,
                              )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppTheme.browseBorder, height: 1),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppTheme.display(
                size: 18,
                color: AppTheme.browseInk,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ProfileValues extends StatelessWidget {
  const _ProfileValues({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.text(color: AppTheme.browseSecondary, height: 1.5);
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final value in values)
          if (value.trim().isNotEmpty) Text(value, style: style),
      ],
    );
  }
}

class _ProviderMessage extends StatelessWidget {
  const _ProviderMessage({required this.message, required this.action});

  final Widget message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SpContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [message, const SizedBox(height: 16), action],
        ),
      ),
    );
  }
}

class _OfferingsSection extends ConsumerWidget {
  const _OfferingsSection({required this.provider});

  final ProviderModel provider;

  void _handleAddToCart(
    BuildContext context,
    WidgetRef ref,
    OfferingModel offering,
  ) {
    final l10n = context.l10n;
    final result = ref
        .read(cartProvider.notifier)
        .addOffering(offering, providerName: provider.displayName);

    if (result.accepted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successDeep,
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.cartAddedSnackbar(offering.title),
                    style: AppTheme.text(size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      return;
    }

    final String message;
    switch (result.rejectionReason) {
      case CartAddRejectionReason.differentProvider:
        final existingName = result.existingProviderName?.trim() ?? '';
        message = existingName.isNotEmpty
            ? l10n.cartErrorDifferentProvider(existingName)
            : l10n.cartErrorDifferentProviderGeneric;
      case CartAddRejectionReason.quoteRequired:
        message = l10n.cartErrorQuoteRequired;
      case CartAddRejectionReason.inactiveOffering:
      case CartAddRejectionReason.invalidPrice:
      case CartAddRejectionReason.notHomeowner:
      case null:
        message = l10n.cartErrorUnavailable;
    }
    showSpError(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offeringsAsync = ref.watch(offeringsByProviderProvider(provider.id));
    final cart = ref.watch(cartProvider);
    final canUseCart = ref.watch(cartOwnerIdProvider) != null;

    return offeringsAsync.when(
      data: (offerings) {
        if (offerings.isEmpty) return const SizedBox.shrink();

        return _ProfileSection(
          title: l10n.providerOfferingsSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cart.isNotEmpty) ...[
                SpNotice(
                  key: const Key('cart_active_provider_notice'),
                  icon: Icons.shopping_cart_outlined,
                  message: l10n.cartActiveProviderNotice(
                    cart.itemCount,
                    cart.providerName ?? '',
                  ),
                  tone: cart.providerId == provider.id
                      ? SpTone.brand
                      : SpTone.neutral,
                ),
                const SizedBox(height: 12),
              ],
              ...offerings.map((offering) {
              final isQuote = offering.isQuoteRequired;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                  border: Border.all(
                    color: isQuote ? AppTheme.accent : AppTheme.browseBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          offering.title,
                          style: AppTheme.display(
                            size: 15,
                            color: AppTheme.browseInk,
                          ),
                        ),
                        if (isQuote)
                          Container(
                            key: Key('badge_quote_${offering.id}'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentSoft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.accent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.request_quote_rounded,
                                  size: 13,
                                  color: AppTheme.accentDeep,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    l10n.offeringBadgeQuoteRequired,
                                    style: AppTheme.text(
                                      size: 11.5,
                                      weight: FontWeight.w700,
                                      color: AppTheme.accentDeep,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            offering.priceDisplay,
                            style: AppTheme.display(
                              size: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offering.description,
                      style: AppTheme.text(
                        size: 13.5,
                        color: AppTheme.browseSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isQuote)
                          Text(
                            'Excluded from direct cart checkout',
                            style: AppTheme.text(
                              size: 12,
                              color: AppTheme.textMuted,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: OutlinedButton(
                            key: Key(isQuote
                                ? 'btn_quote_${offering.id}'
                                : 'btn_book_${offering.id}'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: provider.canAcceptBookings
                                ? () => context.push(
                                      '/providers/${Uri.encodeComponent(provider.id)}/book?serviceTitle=${Uri.encodeComponent(offering.title)}&offeringId=${Uri.encodeComponent(offering.id)}&pricingMode=${Uri.encodeComponent(offering.pricingMode.value)}',
                                      extra: provider,
                                    )
                                : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isQuote
                                      ? Icons.request_quote_rounded
                                      : Icons.calendar_today_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isQuote
                                        ? l10n.offeringCtaRequestQuote
                                        : l10n.offeringCtaBookService,
                                    style: AppTheme.text(
                                      size: 13.5,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isQuote && canUseCart)
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: OutlinedButton(
                              key: Key('btn_add_to_cart_${offering.id}'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(
                                  color: AppTheme.browseControlBorder,
                                ),
                              ),
                              onPressed: provider.canAcceptBookings
                                  ? () => _handleAddToCart(
                                        context,
                                        ref,
                                        offering,
                                      )
                                  : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_shopping_cart_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      l10n.cartAddButton,
                                      style: AppTheme.text(
                                        size: 13.5,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
