import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/photo_source.dart';
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

  String _message(BookingFieldError error) {
    final l10n = context.l10n;
    switch (error) {
      case BookingFieldError.serviceRequired:
        return l10n.bookingErrorServiceRequired;
      case BookingFieldError.descriptionRequired:
        return l10n.bookingErrorDescriptionRequired;
      case BookingFieldError.descriptionTooShort:
        return l10n.bookingErrorDescriptionTooShort(
          BookingRequestValidator.descriptionMinLength,
        );
      case BookingFieldError.descriptionTooLong:
        return l10n.bookingErrorDescriptionTooLong(
          BookingRequestValidator.descriptionMaxLength,
        );
      case BookingFieldError.addressRequired:
        return l10n.bookingErrorAddressRequired;
      case BookingFieldError.addressTooShort:
        return l10n.bookingErrorAddressTooShort;
      case BookingFieldError.addressTooLong:
        return l10n.bookingErrorAddressTooLong(
          BookingRequestValidator.addressMaxLength,
        );
      case BookingFieldError.dateTimeRequired:
        return l10n.bookingErrorDateTimeRequired;
      case BookingFieldError.dateTimeTooSoon:
        return l10n.bookingErrorDateTimeTooSoon(
          BookingRequestValidator.minimumNotice.inHours,
        );
      case BookingFieldError.dateTimeTooFar:
        return l10n.bookingErrorDateTimeTooFar(
          BookingRequestValidator.maximumAdvance.inDays,
        );
      case BookingFieldError.tooManyPhotos:
        return l10n.bookingErrorTooManyPhotos(BookingRequestValidator.maxPhotos);
      case BookingFieldError.photoTooLarge:
        return l10n.bookingErrorPhotoTooLarge(_maxPhotoMb);
    }
  }

  static const int _maxPhotoMb =
      BookingRequestValidator.maxPhotoBytes ~/ (1024 * 1024);

  String? _check(BookingFieldError? error) =>
      error == null ? null : _message(error);

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
    final l10n = context.l10n;
    final origin = await showModalBottomSheet<PhotoOrigin>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('booking_photo_camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.bookingPhotosTake),
              onTap: () => Navigator.of(sheetContext).pop(PhotoOrigin.camera),
            ),
            ListTile(
              key: const Key('booking_photo_gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.bookingPhotosChoose),
              onTap: () => Navigator.of(sheetContext).pop(PhotoOrigin.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (origin == null || !mounted) return;

    final List<BookingPhoto> picked;
    try {
      picked = await ref.read(photoSourceProvider).pick(
            origin,
            limit: BookingRequestValidator.maxPhotos - _photos.length,
          );
    } catch (_) {
      if (mounted) showSpError(context, l10n.bookingErrorPhotoPick);
      return;
    }
    if (!mounted || picked.isEmpty) return;

    final fitting = picked
        .where((p) => p.sizeInBytes <= BookingRequestValidator.maxPhotoBytes)
        .toList();
    setState(() => _photos.addAll(fitting));
    if (fitting.length < picked.length) {
      showSpError(context, l10n.bookingErrorPhotoTooLarge(_maxPhotoMb));
    }
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
              SpTextField(
                key: const Key('booking_description_field'),
                label: l10n.bookingProblemLabel,
                hint: l10n.bookingProblemHint,
                controller: _descriptionController,
                maxLines: 4,
                maxLength: BookingRequestValidator.descriptionMaxLength,
                keyboardType: TextInputType.multiline,
                validator: (value) =>
                    _check(BookingRequestValidator.description(value)),
              ),
              const SizedBox(height: 16),
              _PhotoStrip(
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
              _LocationPin(
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
                builder: (field) => _DateTimeRow(
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
                if (field.hasError) _FieldError(field.errorText!),
              ],
            );
          },
        );
}

/// Date and time side by side, each opening the platform picker.
class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.date,
    required this.time,
    required this.errorText,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime? date;
  final TimeOfDay? time;
  final String? errorText;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _PickerField(
                key: const Key('booking_date_picker'),
                label: l10n.bookingDateLabel,
                icon: Icons.calendar_today_rounded,
                value: date == null ? null : material.formatMediumDate(date!),
                placeholder: l10n.bookingDatePlaceholder,
                hasError: hasError,
                onTap: onPickDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _PickerField(
                key: const Key('booking_time_picker'),
                label: l10n.bookingTimeLabel,
                icon: Icons.schedule_rounded,
                value: time == null ? null : material.formatTimeOfDay(time!),
                placeholder: l10n.bookingTimePlaceholder,
                hasError: hasError,
                onTap: onPickTime,
              ),
            ),
          ],
        ),
        if (hasError) _FieldError(errorText!),
      ],
    );
  }
}

/// Looks like a text field, opens a picker when tapped.
class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.hasError,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? value;
  final String placeholder;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppTheme.error : AppTheme.fieldBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.text(
            size: 14,
            weight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: '$label, ${value ?? placeholder}',
          excludeSemantics: true,
          child: Material(
            color: AppTheme.inputFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: AppTheme.controlHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          value ?? placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.text(
                            size: 16,
                            color: value == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: AppTheme.text(size: 13, color: AppTheme.error),
        ),
      ),
    );
  }
}

/// Thumbnails of the attached problem photos with an "Add photo" tile.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<BookingPhoto> photos;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;

  static const double _tile = 88;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canAdd = photos.length < BookingRequestValidator.maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bookingPhotosLabel,
          style: AppTheme.text(
            size: 14,
            weight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < photos.length; i++)
              SizedBox.square(
                key: Key('booking_photo_$i'),
                dimension: _tile,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusControl),
                        child: Image.memory(
                          photos[i].bytes,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: AppTheme.surfaceElevated,
                            child: Icon(
                              Icons.image_outlined,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Semantics(
                        button: true,
                        label: l10n.bookingPhotoRemove(i + 1),
                        excludeSemantics: true,
                        child: InkResponse(
                          key: Key('booking_photo_remove_$i'),
                          onTap: () => onRemove(i),
                          radius: 24,
                          child: SizedBox.square(
                            dimension: 48,
                            child: Center(
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xCC0E1726),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (canAdd)
              SizedBox.square(
                dimension: _tile,
                child: Material(
                  color: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                    side: const BorderSide(color: AppTheme.fieldBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('booking_add_photo'),
                    onTap: onAdd,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.bookingPhotosAdd,
                          textAlign: TextAlign.center,
                          style: AppTheme.text(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.bookingPhotosHelper(
            BookingRequestValidator.maxPhotos,
            BookingRequestValidator.maxPhotoBytes ~/ (1024 * 1024),
          ),
          style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

/// Optional map pin for the address: a button before pinning, a status row
/// with change and remove actions after.
class _LocationPin extends StatelessWidget {
  const _LocationPin({
    required this.pin,
    required this.onPick,
    required this.onRemove,
  });

  final LatLng? pin;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final point = pin;

    if (point == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSecondaryButton(
            key: const Key('booking_pin_location'),
            label: l10n.bookingLocationAdd,
            icon: Icons.map_outlined,
            onPressed: onPick,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bookingLocationAddHelper,
            style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    return Container(
      key: const Key('booking_location_pinned'),
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppTheme.successSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.where_to_vote_rounded,
            size: 22,
            color: AppTheme.successDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bookingLocationPinned,
                  style: AppTheme.text(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${point.latitude.toStringAsFixed(5)}, '
                  '${point.longitude.toStringAsFixed(5)}',
                  style: AppTheme.text(
                    size: 12.5,
                    color: AppTheme.textSecondary,
                  ).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          SpTextButton(label: l10n.bookingLocationChange, onPressed: onPick),
          IconButton(
            key: const Key('booking_remove_pin'),
            tooltip: l10n.bookingLocationRemove,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppTheme.textSecondary,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
