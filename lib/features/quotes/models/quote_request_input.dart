import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';

/// Input submitted by a homeowner to request a custom price quote for a
/// quote-required service offering (QUOTE-1 / SCRUM-83).
class QuoteRequestInput {
  const QuoteRequestInput({
    required this.customerId,
    this.customerName,
    required this.providerId,
    required this.providerName,
    required this.offering,
    required this.description,
    this.photos = const [],
  });

  final String customerId;
  final String? customerName;
  final String providerId;
  final String providerName;
  final OfferingModel offering;
  final String description;
  final List<BookingPhoto> photos;
}

/// Validation failure reasons for [QuoteRequestInput].
enum QuoteFieldError {
  customerRequired,
  providerRequired,
  offeringNotQuoteRequired,
  offeringInactive,
  offeringProviderMismatch,
  descriptionRequired,
  descriptionTooShort,
  descriptionTooLong,
  tooManyPhotos,
  photoTooLarge,
}

/// Validates quote requests on both the form and service boundary.
///
/// Reuses the shared problem description and photo constraints from
/// [BookingRequestValidator] so booking and quote intake follow identical limits.
class QuoteRequestValidator {
  QuoteRequestValidator._();

  static QuoteFieldError? description(String? value) {
    final error = BookingRequestValidator.description(value);
    switch (error) {
      case BookingFieldError.descriptionRequired:
        return QuoteFieldError.descriptionRequired;
      case BookingFieldError.descriptionTooShort:
        return QuoteFieldError.descriptionTooShort;
      case BookingFieldError.descriptionTooLong:
        return QuoteFieldError.descriptionTooLong;
      default:
        return null;
    }
  }

  static QuoteFieldError? photos(List<BookingPhoto> photos) {
    final error = BookingRequestValidator.photos(photos);
    switch (error) {
      case BookingFieldError.tooManyPhotos:
        return QuoteFieldError.tooManyPhotos;
      case BookingFieldError.photoTooLarge:
        return QuoteFieldError.photoTooLarge;
      default:
        return null;
    }
  }

  static List<QuoteFieldError> validate(QuoteRequestInput input) {
    final errors = <QuoteFieldError>[];
    if (input.customerId.trim().isEmpty) {
      errors.add(QuoteFieldError.customerRequired);
    }
    if (input.providerId.trim().isEmpty) {
      errors.add(QuoteFieldError.providerRequired);
    }
    if (!input.offering.isQuoteRequired) {
      errors.add(QuoteFieldError.offeringNotQuoteRequired);
    }
    if (!input.offering.isActive) {
      errors.add(QuoteFieldError.offeringInactive);
    }
    if (input.offering.providerId != input.providerId) {
      errors.add(QuoteFieldError.offeringProviderMismatch);
    }

    final descError = description(input.description);
    if (descError != null) errors.add(descError);

    final photoError = photos(input.photos);
    if (photoError != null) errors.add(photoError);

    return errors;
  }
}
