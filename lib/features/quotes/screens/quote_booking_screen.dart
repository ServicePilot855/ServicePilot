import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/models/quote_booking_request.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/widgets/appointment_fields.dart';
import 'package:service_pilot/features/bookings/widgets/problem_photo_controls.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/providers/quote_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Books a time using an approved quote (QUOTE-5 / SCRUM-87).
///
/// Reached from **Book a time** on an approved quote at [path]. The service,
/// problem details, photos, provider and approved price come from the quote;
/// the homeowner adds the address and preferred time, reusing the booking
/// form's controls. The result is a Pending booking linked to the quote, and
/// provider confirmation follows the usual booking flow.
class QuoteBookingScreen extends ConsumerWidget {
  const QuoteBookingScreen({
    super.key,
    required this.quoteId,
    this.initialQuote,
  });

  static String path(String quoteId) => '/quotes/$quoteId/book';

  final String quoteId;
  final QuoteRequestModel? initialQuote;

  static void _leave(BuildContext context, String quoteId) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/quotes/$quoteId');
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

    final block = quoteBookingBlock(quote, ref.watch(activeCustomerIdProvider));
    if (block != null) {
      return _BlockedPage(quoteId: quoteId, block: block, quote: quote);
    }
    return _QuoteBookingForm(quote: quote!);
  }
}

/// The approval gate refused this quote: say why and offer the way back.
class _BlockedPage extends StatelessWidget {
  const _BlockedPage({
    required this.quoteId,
    required this.block,
    required this.quote,
  });

  final String quoteId;
  final QuoteBookingBlock block;
  final QuoteRequestModel? quote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final booked = block == QuoteBookingBlock.alreadyBooked;
    final message = switch (block) {
      QuoteBookingBlock.notApproved => l10n.quoteBookingNotApproved,
      QuoteBookingBlock.alreadyBooked => l10n.quoteBookingAlreadyBooked,
      QuoteBookingBlock.notOwner => l10n.quoteBookingUnavailable,
      QuoteBookingBlock.notFound => l10n.quoteDetailNotFound,
    };

    return SpFlowPage(
      title: l10n.quoteBookingTitle,
      onBack: () => QuoteBookingScreen._leave(context, quoteId),
      bottom: booked && quote?.bookingId != null
          ? SpSecondaryButton(
              key: const Key('quote_booking_view_booking'),
              label: l10n.quoteViewBooking,
              icon: Icons.receipt_long_rounded,
              onPressed: () => context.go('/bookings/${quote!.bookingId}'),
            )
          : SpSecondaryButton(
              label: l10n.bookingSentBackHome,
              onPressed: () => context.go('/home/customer'),
            ),
      children: [
        SpStatusHero(
          key: const Key('quote_booking_blocked'),
          icon: booked
              ? Icons.event_available_rounded
              : Icons.lock_outline_rounded,
          title: l10n.quoteBookingTitle,
          message: message,
          tone: booked ? SpTone.success : SpTone.neutral,
        ),
      ],
    );
  }
}

class _QuoteBookingForm extends ConsumerStatefulWidget {
  const _QuoteBookingForm({required this.quote});

  final QuoteRequestModel quote;

  @override
  ConsumerState<_QuoteBookingForm> createState() => _QuoteBookingFormState();
}

class _QuoteBookingFormState extends ConsumerState<_QuoteBookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  LatLng? _pin;
  bool _attempted = false;
  bool _submitting = false;

  QuoteRequestModel get _quote => widget.quote;

  DateTime? get _preferredDateTime {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String? _check(BookingFieldError? error) =>
      error == null ? null : bookingFieldErrorMessage(context.l10n, error);

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(BookingRequestValidator.maximumAdvance),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    field.didChange(_preferredDateTime);
  }

  Future<void> _pickTime(FormFieldState<DateTime> field) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
    field.didChange(_preferredDateTime);
  }

  Future<void> _pickLocation() async {
    final picked = await context.push<LatLng>(
      '/providers/${_quote.providerId}/book/location',
      extra: _pin,
    );
    if (picked != null && mounted) setState(() => _pin = picked);
  }

  Future<void> _submit() async {
    setState(() => _attempted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      final booking = await ref.read(bookingServiceProvider).createQuoteBooking(
            QuoteBookingRequest(
              quoteId: _quote.id,
              customerId: ref.read(activeCustomerIdProvider),
              address: _addressController.text,
              preferredDateTime: _preferredDateTime!,
              latitude: _pin?.latitude,
              longitude: _pin?.longitude,
            ),
          );
      ref.invalidate(customerBookingsProvider);
      ref.invalidate(customerQuoteRequestsProvider);
      if (!mounted) return;
      // Replace the step so Back cannot send the same booking twice.
      context.go('/bookings/${booking.id}/sent', extra: booking);
    } on InvalidBookingRequestException {
      // The chosen time may have become too soon while the form was open.
      _formKey.currentState?.validate();
    } on QuoteNotBookableException catch (error) {
      if (!mounted) return;
      if (error.bookingId != null) {
        context.go('/bookings/${error.bookingId}');
      } else {
        showSpError(
          context,
          error.reason == QuoteBookingBlock.notApproved
              ? l10n.quoteBookingNotApproved
              : l10n.quoteBookingUnavailable,
        );
      }
    } catch (error, stack) {
      debugPrint('[QuoteBookingScreen] booking request failed: $error');
      debugPrintStack(stackTrace: stack, maxFrames: 8);
      if (mounted) showSpError(context, l10n.bookingErrorSaveFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final price = formatQuoteAmount(_quote.approvedPrice!);

    return Form(
      key: _formKey,
      autovalidateMode: _attempted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: SpFlowPage(
        title: l10n.quoteBookingTitle,
        onBack: () => QuoteBookingScreen._leave(context, _quote.id),
        bottom: SpPrimaryButton(
          key: const Key('quote_booking_submit_button'),
          label: l10n.quoteBookingSubmit,
          icon: Icons.send_rounded,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        children: [
          SpPageHeader(
            title: l10n.quoteBookingHeading,
            subtitle: l10n.quoteBookingSubtitle(
              _quote.offeringTitle,
              _quote.providerName,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.quoteApprovedPriceLabel,
                    style: AppTheme.text(
                      size: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Text(
                  price,
                  key: const Key('quote_booking_approved_price'),
                  style: AppTheme.text(
                    size: 16,
                    weight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 32),
          SpFormSection(
            title: l10n.bookingWhereSection,
            children: [
              SpTextField(
                key: const Key('quote_booking_address_field'),
                label: l10n.bookingAddressLabel,
                hint: l10n.bookingAddressHint,
                helper: l10n.bookingAddressHelper,
                controller: _addressController,
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
                keyboardType: TextInputType.streetAddress,
                autofillHints: const [AutofillHints.fullStreetAddress],
                validator: (value) =>
                    _check(BookingRequestValidator.address(value)),
              ),
              const SizedBox(height: 16),
              BookingLocationPin(
                pin: _pin,
                onPick: _pickLocation,
                onRemove: () => setState(() => _pin = null),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SpFormSection(
            title: l10n.bookingWhenSection,
            children: [
              FormField<DateTime>(
                key: const Key('quote_booking_datetime_field'),
                validator: (_) => _check(
                  BookingRequestValidator.preferredDateTime(_preferredDateTime),
                ),
                builder: (field) => BookingDateTimeRow(
                  date: _date,
                  time: _time,
                  errorText: field.errorText,
                  onPickDate: () => _pickDate(field),
                  onPickTime: () => _pickTime(field),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SpNotice(
            icon: Icons.info_outline_rounded,
            message: l10n.quoteBookingPriceNote(price),
            tone: SpTone.neutral,
          ),
        ],
      ),
    );
  }
}
