import 'dart:typed_data';

import 'package:service_pilot/features/bookings/models/booking_item.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';

/// A problem photo picked by the customer, held in memory until upload.
class BookingPhoto {
  final Uint8List bytes;
  final String name;

  /// For example `image/jpeg`. Storage rules only accept `image/*`.
  final String contentType;

  const BookingPhoto({
    required this.bytes,
    required this.name,
    this.contentType = 'image/jpeg',
  });

  int get sizeInBytes => bytes.lengthInBytes;
}

/// What a customer sends when they ask a provider for a repair.
///
/// US-12 (SCRUM-43). [BookingRequestValidator] checks it in the form and again
/// in the booking service, so a request that skips the form is still rejected.
class BookingRequest {
  final String customerId;
  final String providerId;
  final String providerName;

  /// Category the provider works in, for example "Plumbing".
  final String serviceCategory;

  /// The service the customer picked from the provider's list.
  final String serviceTitle;
  final String description;
  final String address;
  final DateTime preferredDateTime;

  /// The provider's starting price, shown to the customer as an estimate.
  final double estimatedPrice;

  /// Optional map pin for [address].
  final double? latitude;
  final double? longitude;

  /// Optional problem photos (PLAN.md: up to 5, 5 MB each).
  final List<BookingPhoto> photos;

  /// Fixed-price services from the reviewed cart (CART-3 / SCRUM-82). Empty
  /// for a single-service request from the provider page.
  final List<BookingItem> items;

  const BookingRequest({
    required this.customerId,
    required this.providerId,
    required this.providerName,
    required this.serviceCategory,
    required this.serviceTitle,
    required this.description,
    required this.address,
    required this.preferredDateTime,
    this.estimatedPrice = 0.0,
    this.latitude,
    this.longitude,
    this.photos = const [],
    this.items = const [],
  });

  /// Whether this request was sent from the cart.
  bool get isFromCart => items.isNotEmpty;

  /// Price saved on the booking: the item total for a cart, otherwise the
  /// provider's starting price.
  double get totalPrice =>
      isFromCart ? BookingItem.totalOf(items) : estimatedPrice;

  /// Longest service title Firestore accepts (`serviceType` in the rules).
  static const int serviceTitleMaxLength = 100;

  /// One-line service title for a cart booking, for lists that show a single
  /// title: the item names joined with commas, shortened to fit.
  static String cartServiceTitle(List<BookingItem> items) {
    final joined = items.map((item) => item.title.trim()).join(', ');
    if (joined.length <= serviceTitleMaxLength) return joined;
    return '${joined.substring(0, serviceTitleMaxLength - 1).trimRight()}…';
  }
}

/// Why a booking request field was rejected. The form turns each value into a
/// translated message; the service reports them in [InvalidBookingRequestException].
enum BookingFieldError {
  serviceRequired,
  descriptionRequired,
  descriptionTooShort,
  descriptionTooLong,
  addressRequired,
  addressTooShort,
  addressTooLong,
  dateTimeRequired,
  dateTimeTooSoon,
  dateTimeTooFar,
  tooManyPhotos,
  photoTooLarge,

  /// A cart item is missing its offering, has no valid fixed price or
  /// quantity, or the cart holds too many lines (CART-3 / SCRUM-82).
  cartItemsInvalid,

  /// A cart item belongs to a provider other than the booking's provider.
  cartMixedProviders,
}

/// Field rules for US-12 booking requests.
class BookingRequestValidator {
  BookingRequestValidator._();

  static const int descriptionMinLength = 15;
  static const int descriptionMaxLength = 1000;
  static const int addressMinLength = 10;
  static const int addressMaxLength = 300;

  /// A provider needs some notice: the appointment must be at least this far ahead.
  static const Duration minimumNotice = Duration(hours: 1);

  /// Requests further ahead than this are refused.
  static const Duration maximumAdvance = Duration(days: 60);

  static const int maxPhotos = 5;
  static const int maxPhotoBytes = 5 * 1024 * 1024;

  /// Matches the `services` list limit in `firestore.rules`.
  static const int maxCartItems = 20;

  static BookingFieldError? service(String? value) {
    if (value == null || value.trim().isEmpty) {
      return BookingFieldError.serviceRequired;
    }
    return null;
  }

  static BookingFieldError? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return BookingFieldError.descriptionRequired;
    if (text.length < descriptionMinLength) {
      return BookingFieldError.descriptionTooShort;
    }
    if (text.length > descriptionMaxLength) {
      return BookingFieldError.descriptionTooLong;
    }
    return null;
  }

  static BookingFieldError? address(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return BookingFieldError.addressRequired;
    if (text.length < addressMinLength) {
      return BookingFieldError.addressTooShort;
    }
    if (text.length > addressMaxLength) return BookingFieldError.addressTooLong;
    return null;
  }

  static BookingFieldError? preferredDateTime(DateTime? value,
      {DateTime? now}) {
    if (value == null) return BookingFieldError.dateTimeRequired;
    final reference = now ?? DateTime.now();
    if (value.isBefore(reference.add(minimumNotice))) {
      return BookingFieldError.dateTimeTooSoon;
    }
    if (value.isAfter(reference.add(maximumAdvance))) {
      return BookingFieldError.dateTimeTooFar;
    }
    return null;
  }

  static BookingFieldError? photos(List<BookingPhoto> photos) {
    if (photos.length > maxPhotos) return BookingFieldError.tooManyPhotos;
    if (photos.any((p) => p.sizeInBytes > maxPhotoBytes)) {
      return BookingFieldError.photoTooLarge;
    }
    return null;
  }

  /// Cart lines must all come from [providerId], each with an offering, a
  /// title, a valid fixed price and a positive quantity. No items is valid:
  /// that is a single-service request.
  static BookingFieldError? cartItems(
    List<BookingItem> items, {
    required String providerId,
  }) {
    if (items.isEmpty) return null;
    if (items.any((item) => item.providerId != providerId)) {
      return BookingFieldError.cartMixedProviders;
    }
    final offeringIds = <String>{};
    final invalid = items.length > maxCartItems ||
        items.any((item) =>
            item.offeringId.trim().isEmpty ||
            !offeringIds.add(item.offeringId) ||
            item.title.trim().isEmpty ||
            item.quantity < 1 ||
            !OfferingModel.isValidFixedPrice(item.unitPrice));
    return invalid ? BookingFieldError.cartItemsInvalid : null;
  }

  /// Every problem with [request], in form order. Empty when it can be sent.
  static List<BookingFieldError> validate(
    BookingRequest request, {
    DateTime? now,
  }) {
    return [
      cartItems(request.items, providerId: request.providerId),
      service(request.serviceTitle),
      description(request.description),
      photos(request.photos),
      address(request.address),
      preferredDateTime(request.preferredDateTime, now: now),
    ].whereType<BookingFieldError>().toList();
  }
}
