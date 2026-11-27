import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';

/// What a homeowner sends to book a time with an approved quote
/// (QUOTE-5 / SCRUM-87). The service, problem details, photos, provider and
/// price all come from the quote; the homeowner adds where and when.
class QuoteBookingRequest {
  const QuoteBookingRequest({
    required this.quoteId,
    required this.customerId,
    required this.address,
    required this.preferredDateTime,
    this.latitude,
    this.longitude,
  });

  final String quoteId;
  final String customerId;
  final String address;
  final DateTime preferredDateTime;
  final double? latitude;
  final double? longitude;

  /// Address and time problems, in form order. Empty when it can be sent.
  List<BookingFieldError> validate({DateTime? now}) => [
        BookingRequestValidator.address(address),
        BookingRequestValidator.preferredDateTime(preferredDateTime, now: now),
      ].whereType<BookingFieldError>().toList();
}

/// Why a quote cannot enter the booking flow.
enum QuoteBookingBlock { notFound, notOwner, notApproved, alreadyBooked }

/// The approval gate for QUOTE-5. Returns null when [quote] can be booked by
/// [customerId]: it exists, belongs to them, is `Approved` with a recorded
/// amount, and has not been booked yet.
QuoteBookingBlock? quoteBookingBlock(
  QuoteRequestModel? quote,
  String customerId,
) {
  if (quote == null) return QuoteBookingBlock.notFound;
  if (!quote.isOwnedByCustomer(customerId)) return QuoteBookingBlock.notOwner;
  if (quote.status != QuoteStatus.approved || quote.approvedPrice == null) {
    return QuoteBookingBlock.notApproved;
  }
  if (quote.isBooked) return QuoteBookingBlock.alreadyBooked;
  return null;
}

/// Builds the Pending booking for an eligible [quote]. It keeps the approved
/// amount and links back to the quote and the chosen provider.
BookingModel bookingFromApprovedQuote({
  required String bookingId,
  required QuoteRequestModel quote,
  required QuoteBookingRequest request,
  required DateTime now,
}) {
  return BookingModel(
    id: bookingId,
    customerId: request.customerId,
    providerId: quote.providerId,
    providerName: quote.providerName,
    serviceCategory:
        quote.categoryName.isNotEmpty ? quote.categoryName : 'General Repair',
    serviceTitle: quote.offeringTitle,
    description: quote.description,
    address: request.address.trim(),
    preferredDateTime: request.preferredDateTime,
    status: BookingStatus.pending,
    totalPrice: quote.approvedPrice!,
    createdAt: now,
    latitude: request.latitude,
    longitude: request.longitude,
    photoUrls: quote.photoUrls,
    quoteId: quote.id,
  );
}
