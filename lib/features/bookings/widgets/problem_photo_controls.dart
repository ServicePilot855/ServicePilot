import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/services/photo_source.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Translates shared [BookingFieldError] values into localized form messages.
String bookingFieldErrorMessage(
  AppLocalizations l10n,
  BookingFieldError error,
) {
  const maxPhotoMb = BookingRequestValidator.maxPhotoBytes ~/ (1024 * 1024);
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
      return l10n.bookingErrorPhotoTooLarge(maxPhotoMb);
    case BookingFieldError.cartItemsInvalid:
      return l10n.bookingErrorCartInvalid;
    case BookingFieldError.cartMixedProviders:
      return l10n.bookingErrorCartMixedProviders;
  }
}

/// Opens the camera/gallery picker sheet and returns validated photos under
/// [BookingRequestValidator.maxPhotoBytes].
Future<List<BookingPhoto>> pickProblemPhotos({
  required BuildContext context,
  required WidgetRef ref,
  required int currentCount,
  String keyPrefix = 'booking',
}) async {
  final l10n = context.l10n;
  const maxPhotoMb = BookingRequestValidator.maxPhotoBytes ~/ (1024 * 1024);

  final origin = await showModalBottomSheet<PhotoOrigin>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: Key('${keyPrefix}_photo_camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.bookingPhotosTake),
            onTap: () => Navigator.of(sheetContext).pop(PhotoOrigin.camera),
          ),
          ListTile(
            key: Key('${keyPrefix}_photo_gallery'),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.bookingPhotosChoose),
            onTap: () => Navigator.of(sheetContext).pop(PhotoOrigin.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (origin == null || !context.mounted) return const [];

  final List<BookingPhoto> picked;
  try {
    picked = await ref.read(photoSourceProvider).pick(
          origin,
          limit: BookingRequestValidator.maxPhotos - currentCount,
        );
  } catch (_) {
    if (context.mounted) showSpError(context, l10n.bookingErrorPhotoPick);
    return const [];
  }
  if (!context.mounted || picked.isEmpty) return const [];

  final fitting = picked
      .where((p) => p.sizeInBytes <= BookingRequestValidator.maxPhotoBytes)
      .toList();
  if (fitting.length < picked.length) {
    showSpError(context, l10n.bookingErrorPhotoTooLarge(maxPhotoMb));
  }
  return fitting;
}

/// Shared problem description input with privacy guidance.
class ProblemDescriptionField extends StatelessWidget {
  const ProblemDescriptionField({
    super.key,
    required this.controller,
    this.fieldKey,
    this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final String? hint;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpTextField(
          key: fieldKey,
          label: l10n.bookingProblemLabel,
          hint: hint ?? l10n.bookingProblemHint,
          controller: controller,
          maxLines: 4,
          maxLength: BookingRequestValidator.descriptionMaxLength,
          keyboardType: TextInputType.multiline,
          validator: validator ??
              (value) {
                final err = BookingRequestValidator.description(value);
                return err == null ? null : bookingFieldErrorMessage(l10n, err);
              },
        ),
        Text(
          l10n.bookingProblemPrivacyHelper,
          style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

/// Thumbnails of the attached problem photos with an "Add photo" tile.
class ProblemPhotoStrip extends StatelessWidget {
  const ProblemPhotoStrip({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    this.keyPrefix = 'booking',
  });

  final List<BookingPhoto> photos;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;
  final String keyPrefix;

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
                key: Key('${keyPrefix}_photo_$i'),
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
                          key: Key('${keyPrefix}_photo_remove_$i'),
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
                    key: Key('${keyPrefix}_add_photo'),
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
