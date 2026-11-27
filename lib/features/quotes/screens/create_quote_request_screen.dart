import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/widgets/problem_photo_controls.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/quotes/models/quote_request_input.dart';
import 'package:service_pilot/features/quotes/providers/quote_provider.dart';
import 'package:service_pilot/features/quotes/services/quote_service.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Optional route payload passed when launching [CreateQuoteRequestScreen] from
/// a provider profile so the form renders without extra round-trips.
class QuoteRequestRouteArgs {
  const QuoteRequestRouteArgs({
    this.provider,
    this.offering,
  });

  final ProviderModel? provider;
  final OfferingModel? offering;
}

/// Separate intake form for a quote-required service offering (QUOTE-1 / SCRUM-83).
///
/// Reuses the shared problem description and photo controls without modifying
/// the homeowner's fixed-price cart.
class CreateQuoteRequestScreen extends ConsumerWidget {
  const CreateQuoteRequestScreen({
    super.key,
    required this.providerId,
    required this.offeringId,
    this.initialProvider,
    this.initialOffering,
  });

  final String providerId;
  final String offeringId;
  final ProviderModel? initialProvider;
  final OfferingModel? initialOffering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    void back() => _leave(context);

    final providerAsync = initialProvider != null
        ? AsyncValue.data(initialProvider)
        : ref.watch(providerDetailsProvider(providerId));
    final offeringAsync = initialOffering != null
        ? AsyncValue.data(initialOffering)
        : ref.watch(offeringDetailProvider(offeringId));

    if (providerAsync.isLoading || offeringAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (providerAsync.hasError || offeringAsync.hasError) {
      return SpFlowPage(
        title: l10n.quoteFormTitle,
        onBack: back,
        children: [
          SpNotice(
            icon: Icons.error_outline_rounded,
            message: providerAsync.hasError
                ? l10n.bookingProviderNotFound
                : l10n.quoteOfferingNotFound,
            tone: SpTone.danger,
          ),
        ],
      );
    }

    final provider = providerAsync.valueOrNull;
    if (provider == null) {
      return SpFlowPage(
        title: l10n.quoteFormTitle,
        onBack: back,
        children: [
          SpNotice(
            icon: Icons.person_search_rounded,
            message: l10n.bookingProviderNotFound,
            tone: SpTone.neutral,
          ),
        ],
      );
    }

    if (!provider.canAcceptBookings) {
      return SpFlowPage(
        title: l10n.quoteFormTitle,
        onBack: back,
        children: [
          SpStatusHero(
            key: const Key('quote_provider_unavailable'),
            icon: Icons.event_busy_rounded,
            title: l10n.bookingProviderUnavailable(provider.displayName),
            message: provider.unavailableReason ?? '',
            tone: SpTone.neutral,
          ),
        ],
      );
    }

    final offering = offeringAsync.valueOrNull;
    if (offering == null) {
      return SpFlowPage(
        title: l10n.quoteFormTitle,
        onBack: back,
        children: [
          SpNotice(
            key: const Key('quote_offering_not_found'),
            icon: Icons.search_off_rounded,
            message: l10n.quoteOfferingNotFound,
            tone: SpTone.neutral,
          ),
        ],
      );
    }

    final isEligibleOffering = offering.isActive &&
        offering.isQuoteRequired &&
        offering.providerId == provider.id;
    if (!isEligibleOffering) {
      return SpFlowPage(
        title: l10n.quoteFormTitle,
        onBack: back,
        children: [
          SpNotice(
            key: const Key('quote_offering_ineligible'),
            icon: Icons.block_rounded,
            message: l10n.quoteOfferingUnavailable,
            tone: SpTone.danger,
          ),
        ],
      );
    }

    return _QuoteRequestForm(
      provider: provider,
      offering: offering,
    );
  }

  static void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/customer');
    }
  }
}

class _QuoteRequestForm extends ConsumerStatefulWidget {
  const _QuoteRequestForm({
    required this.provider,
    required this.offering,
  });

  final ProviderModel provider;
  final OfferingModel offering;

  @override
  ConsumerState<_QuoteRequestForm> createState() => _QuoteRequestFormState();
}

class _QuoteRequestFormState extends ConsumerState<_QuoteRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final List<BookingPhoto> _photos = [];
  bool _attempted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final fitting = await pickProblemPhotos(
      context: context,
      ref: ref,
      currentCount: _photos.length,
      keyPrefix: 'quote',
    );
    if (!mounted || fitting.isEmpty) return;
    setState(() => _photos.addAll(fitting));
  }

  Future<void> _submit() async {
    setState(() => _attempted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      final user = ref.read(currentUserProvider);
      final input = QuoteRequestInput(
        customerId: ref.read(activeCustomerIdProvider),
        customerName: user?.fullName,
        providerId: widget.provider.id,
        providerName: widget.provider.displayName,
        offering: widget.offering,
        description: _descriptionController.text,
        photos: List.unmodifiable(_photos),
      );
      final quote =
          await ref.read(quoteServiceProvider).createQuoteRequest(input);
      ref.invalidate(customerQuoteRequestsProvider);
      if (!mounted) return;
      context.go('/quotes/${Uri.encodeComponent(quote.id)}/sent', extra: quote);
    } on InvalidQuoteRequestException {
      _formKey.currentState?.validate();
    } catch (error, stack) {
      debugPrint('[CreateQuoteRequestScreen] quote submission failed: $error');
      debugPrintStack(stackTrace: stack, maxFrames: 8);
      if (mounted) showSpError(context, l10n.quoteErrorSaveFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      autovalidateMode: _attempted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: SpFlowPage(
        title: l10n.quoteFormTitle,
        onBack: () => CreateQuoteRequestScreen._leave(context),
        bottom: SpPrimaryButton(
          key: const Key('quote_submit_button'),
          label: l10n.quoteSubmit,
          icon: Icons.send_rounded,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        children: [
          SpPageHeader(
            title: l10n.quoteFormHeading,
            subtitle: l10n.quoteFormSubtitle(widget.provider.displayName),
          ),
          const SizedBox(height: 16),
          SpNotice(
            icon: Icons.request_quote_rounded,
            message: l10n.offeringNoticeQuoteRequiredBooking,
            tone: SpTone.waiting,
          ),
          const SizedBox(height: 24),
          _SelectedOfferingCard(offering: widget.offering),
          const SizedBox(height: 32),
          SpFormSection(
            title: l10n.bookingProblemSection,
            children: [
              ProblemDescriptionField(
                fieldKey: const Key('quote_description_field'),
                controller: _descriptionController,
                hint: l10n.quoteDescriptionHint,
              ),
              const SizedBox(height: 16),
              ProblemPhotoStrip(
                photos: _photos,
                keyPrefix: 'quote',
                onAdd: _submitting ? null : _addPhotos,
                onRemove: (index) => setState(() => _photos.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SpNotice(
            icon: Icons.info_outline_rounded,
            message: l10n.quoteRequestFooterNote,
            tone: SpTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _SelectedOfferingCard extends StatelessWidget {
  const _SelectedOfferingCard({required this.offering});

  final OfferingModel offering;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      key: Key('quote_selected_offering_${offering.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                l10n.quoteSelectedOfferingLabel,
                style: AppTheme.text(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  l10n.offeringBadgeQuoteRequired,
                  style: AppTheme.text(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppTheme.accentDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            offering.title,
            style: AppTheme.text(
              size: 16,
              weight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (offering.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              offering.description,
              style: AppTheme.text(
                size: 13.5,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
