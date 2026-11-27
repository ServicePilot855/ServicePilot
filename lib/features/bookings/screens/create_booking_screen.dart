import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/widgets/appointment_fields.dart';
import 'package:service_pilot/features/bookings/widgets/problem_photo_controls.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// One-page booking request form: service, problem, address, date and time.
///
/// US-12 (SCRUM-43). Reached from the provider page's Book button at
/// `/providers/:providerId/book`. On success the booking is saved as Pending
/// and the customer lands on the "Request sent" page.
class CreateBookingScreen extends ConsumerWidget {
  const CreateBookingScreen({
    super.key,
    required this.providerId,
    this.initialProvider,
    this.initialServiceTitle,
    this.initialOfferingId,
    this.isQuoteRequired = false,
  });

  final String providerId;

  /// Passed by the provider page so the form opens without a second fetch.
  final ProviderModel? initialProvider;

  /// Preselected service offering title when launched from an offering card.
  final String? initialServiceTitle;

  /// Preselected offering ID.
  final String? initialOfferingId;

  /// Whether this intake requires a custom price quote.
  final bool isQuoteRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    void back() => _leave(context);

    if (initialProvider != null) {
      return _bodyFor(context, initialProvider!);
    }

    return ref.watch(providerDetailsProvider(providerId)).when(
          data: (provider) => provider == null
              ? SpFlowPage(
                  title: l10n.bookingFormTitle,
                  onBack: back,
                  children: [
                    SpNotice(
                      icon: Icons.person_search_rounded,
                      message: l10n.bookingProviderNotFound,
                      tone: SpTone.neutral,
                    ),
                  ],
                )
              : _bodyFor(context, provider),
          loading: () => const Scaffold(
            backgroundColor: AppTheme.surface,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
          error: (_, __) => SpFlowPage(
            title: l10n.bookingFormTitle,
            onBack: back,
            children: [
              SpNotice(
                icon: Icons.error_outline_rounded,
                message: l10n.bookingProviderNotFound,
                tone: SpTone.danger,
              ),
            ],
          ),
        );
  }

  Widget _bodyFor(BuildContext context, ProviderModel provider) {
    if (!provider.canAcceptBookings) {
      final l10n = context.l10n;
      return SpFlowPage(
        title: l10n.bookingFormTitle,
        onBack: () => _leave(context),
        children: [
          SpStatusHero(
            key: const Key('booking_provider_unavailable'),
            icon: Icons.event_busy_rounded,
            title: l10n.bookingProviderUnavailable(provider.displayName),
            message: provider.unavailableReason ?? '',
            tone: SpTone.neutral,
          ),
        ],
      );
    }
    return _BookingForm(
      provider: provider,
      initialServiceTitle: initialServiceTitle,
      initialOfferingId: initialOfferingId,
      isQuoteRequired: isQuoteRequired,
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

class _BookingForm extends ConsumerStatefulWidget {
  const _BookingForm({
    required this.provider,
    this.initialServiceTitle,
    this.initialOfferingId,
    this.isQuoteRequired = false,
  });

  final ProviderModel provider;
  final String? initialServiceTitle;
  final String? initialOfferingId;
  final bool isQuoteRequired;

  @override
  ConsumerState<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends ConsumerState<_BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  String? _service;
  DateTime? _date;
  TimeOfDay? _time;
  LatLng? _pin;
  final List<BookingPhoto> _photos = [];
  bool _attempted = false;
  bool _submitting = false;

  ProviderModel get _provider => widget.provider;

  @override
  void initState() {
    super.initState();
    if (widget.initialServiceTitle != null &&
        widget.initialServiceTitle!.trim().isNotEmpty) {
      _service = widget.initialServiceTitle!.trim();
    }
  }

  /// The services offered on the provider page. A provider without a listed
  /// specialty still gets one choice so the form can be sent.
  List<String> _serviceOptions(AppLocalizations l10n) {
    final list = _provider.specialties.isNotEmpty
        ? List<String>.from(_provider.specialties)
        : <String>[l10n.bookingServiceGeneral];
    if (_service != null && !list.contains(_service)) {
      list.insert(0, _service!);
    }
    return list;
  }

  DateTime? get _preferredDateTime {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // With only one service on offer, choose it for the customer.
    final options = _serviceOptions(context.l10n);
    if (_service == null && options.length == 1) {
      _service = options.single;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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

  Future<void> _addPhotos() async {
    final fitting = await pickProblemPhotos(
      context: context,
      ref: ref,
      currentCount: _photos.length,
    );
    if (!mounted || fitting.isEmpty) return;
    setState(() => _photos.addAll(fitting));
  }

  Future<void> _pickLocation() async {
    final picked = await context.push<LatLng>(
      '/providers/${_provider.id}/book/location',
      extra: _pin,
    );
    if (picked != null && mounted) setState(() => _pin = picked);
  }

  Future<String> _categoryName() async {
    if (_provider.categoryIds.isEmpty) return 'General Repair';
    try {
      final category = await ref
          .read(categoryServiceProvider)
          .getCategoryById(_provider.categoryIds.first);
      return category?.name ?? 'General Repair';
    } catch (_) {
      return 'General Repair';
    }
  }

  Future<void> _submit() async {
    setState(() => _attempted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      final request = BookingRequest(
        customerId: ref.read(activeCustomerIdProvider),
        providerId: _provider.id,
        providerName: _provider.displayName,
        serviceCategory: await _categoryName(),
        serviceTitle: _service!,
        description: _descriptionController.text,
        address: _addressController.text,
        preferredDateTime: _preferredDateTime!,
        estimatedPrice: _provider.startingPrice ?? 0,
        latitude: _pin?.latitude,
        longitude: _pin?.longitude,
        photos: List.unmodifiable(_photos),
      );
      final booking =
          await ref.read(bookingServiceProvider).createBooking(request);
      ref.invalidate(customerBookingsProvider);
      if (!mounted) return;
      // Replace the form so Back cannot send the same request twice.
      context.go('/bookings/${booking.id}/sent', extra: booking);
    } on InvalidBookingRequestException {
      // The chosen time may have become too soon while the form was open.
      _formKey.currentState?.validate();
    } catch (error, stack) {
      // The customer sees a plain message; the cause goes to the debug console.
      debugPrint('[CreateBookingScreen] booking request failed: $error');
      debugPrintStack(stackTrace: stack, maxFrames: 8);
      if (mounted) showSpError(context, l10n.bookingErrorSaveFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final price = _provider.startingPrice ?? 0;

    return Form(
      key: _formKey,
      autovalidateMode: _attempted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: SpFlowPage(
        title: l10n.bookingFormTitle,
        onBack: () => CreateBookingScreen._leave(context),
        bottom: SpPrimaryButton(
          key: const Key('booking_submit_button'),
          label: l10n.bookingSubmit,
          icon: Icons.send_rounded,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        children: [
          SpPageHeader(
            title: l10n.bookingFormHeading,
            subtitle: l10n.bookingFormSubtitle(_provider.displayName),
          ),
          if (widget.isQuoteRequired) ...[
            const SizedBox(height: 16),
            SpNotice(
              icon: Icons.request_quote_rounded,
              message: l10n.offeringNoticeQuoteRequiredBooking,
              tone: SpTone.waiting,
            ),
          ],
          const SizedBox(height: 32),
          SpFormSection(
            title: l10n.bookingServiceSection,
            children: [
              _ServicePicker(
                options: _serviceOptions(l10n),
                initialValue: _service,
                validator: (value) =>
                    _check(BookingRequestValidator.service(value)),
                onChanged: (value) => setState(() => _service = value),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SpFormSection(
            title: l10n.bookingProblemSection,
            children: [
              ProblemDescriptionField(
                fieldKey: const Key('booking_description_field'),
                controller: _descriptionController,
              ),
              const SizedBox(height: 16),
              ProblemPhotoStrip(
                photos: _photos,
                onAdd: _submitting ? null : _addPhotos,
                onRemove: (index) => setState(() => _photos.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SpFormSection(
            title: l10n.bookingWhereSection,
            children: [
              SpTextField(
                key: const Key('booking_address_field'),
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
                key: const Key('booking_datetime_field'),
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
          if (price > 0) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.bookingEstimateLabel,
                    style: AppTheme.text(
                      size: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Text(
                  l10n.bookingEstimateValue('\$${price.toStringAsFixed(2)}'),
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
          ],
          const SizedBox(height: 16),
          SpNotice(
            icon: Icons.info_outline_rounded,
            message: l10n.bookingPaymentNote,
            tone: SpTone.neutral,
          ),
        ],
      ),
    );
  }
}

/// Single-choice chips for the provider's services, with the error under them.
class _ServicePicker extends FormField<String> {
  _ServicePicker({
    required List<String> options,
    required ValueChanged<String> onChanged,
    super.initialValue,
    super.validator,
  }) : super(
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in options)
                      ChoiceChip(
                        key: Key('booking_service_$option'),
                        label: Text(option),
                        selected: field.value == option,
                        showCheckmark: true,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        selectedColor: AppTheme.primarySoft,
                        checkmarkColor: AppTheme.onPrimarySoft,
                        backgroundColor: AppTheme.surface,
                        side: BorderSide(
                          color: field.value == option
                              ? AppTheme.primary
                              : AppTheme.fieldBorder,
                        ),
                        labelStyle: AppTheme.text(
                          size: 14,
                          weight: FontWeight.w600,
                          color: field.value == option
                              ? AppTheme.onPrimarySoft
                              : AppTheme.textPrimary,
                        ),
                        onSelected: (_) {
                          field.didChange(option);
                          onChanged(option);
                        },
                      ),
                  ],
                ),
                if (field.hasError) BookingFieldErrorText(field.errorText!),
              ],
            );
          },
        );
}
