import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/widgets/provider_rating_summary.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.browseBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: SpBackButton(onPressed: () => _goBack(context)),
        title: Text(
          l10n.providerProfileTitle,
          style: AppTheme.display(size: 18, color: AppTheme.browseInk),
        ),
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

class _ProviderProfile extends StatelessWidget {
  const _ProviderProfile({required this.provider});

  final ProviderModel provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canBook = provider.canAcceptBookings;
    final unavailableReason = provider.unavailableReason?.trim();
    final about = provider.bio.trim();
    final description = provider.description.trim();
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
                    Text(l10n.providerBookingPreviewNotice, style: bodyStyle),
                    const SizedBox(height: 8),
                    SpPrimaryButton(
                      label: l10n.providerContinueBooking,
                      wrapLabel: true,
                      enabled: canBook,
                      onPressed: canBook
                          ? () => context.push(
                                '/providers/${Uri.encodeComponent(provider.id)}/book',
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
