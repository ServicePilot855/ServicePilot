import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';

/// Thrown when a requested booking ID does not exist.
class BookingNotFoundException implements Exception {
  final String bookingId;
  final String message;

  const BookingNotFoundException(
    this.bookingId, [
    this.message = 'The requested repair booking could not be found.',
  ]);

  @override
  String toString() => 'BookingNotFoundException($bookingId): $message';
}

/// Thrown when a user attempts to cancel a booking they did not create.
///
/// Enforces US-14 (SCRUM-45) AC:
/// "Only the customer who created the booking can cancel it."
class UnauthorizedBookingCancellationException implements Exception {
  final String bookingId;
  final String userId;
  final String message;

  const UnauthorizedBookingCancellationException({
    required this.bookingId,
    required this.userId,
    this.message = 'Only the customer who created this booking can cancel it.',
  });

  @override
  String toString() =>
      'UnauthorizedBookingCancellationException(bookingId: $bookingId, userId: $userId): $message';
}

/// Thrown when a customer attempts to cancel a booking whose status is
/// `In Progress`, `Completed`, `Cancelled`, or `Declined`.
///
/// Enforces US-14 (SCRUM-45) AC:
/// - "Customers can cancel bookings with Pending, Assigned, or Confirmed status."
/// - "Customers cannot cancel bookings that are In Progress, Completed, Cancelled, or Declined."
class CannotCancelBookingException implements Exception {
  final String bookingId;
  final BookingStatus currentStatus;
  final String message;

  CannotCancelBookingException({
    required this.bookingId,
    required this.currentStatus,
    String? message,
  }) : message =
           message ??
           'Cannot cancel a booking that is already ${currentStatus.label}. '
               'Only Pending, Assigned, or Confirmed bookings can be cancelled.';

  @override
  String toString() =>
      'CannotCancelBookingException(bookingId: $bookingId, status: ${currentStatus.value}): $message';
}

/// Thrown when an invalid status transition is attempted on a booking
/// (e.g., accepting, assigning, or starting a `Cancelled` booking).
///
/// Enforces US-14 (SCRUM-45) AC:
/// "Cancelled bookings cannot be accepted, assigned, or started afterward."
class InvalidBookingTransitionException implements Exception {
  final String bookingId;
  final BookingStatus currentStatus;
  final BookingStatus targetStatus;
  final String message;

  InvalidBookingTransitionException({
    required this.bookingId,
    required this.currentStatus,
    required this.targetStatus,
    String? message,
  }) : message =
           message ??
           'Cannot change booking status from ${currentStatus.label} to ${targetStatus.label}.';

  @override
  String toString() =>
      'InvalidBookingTransitionException(bookingId: $bookingId, from: ${currentStatus.value}, to: ${targetStatus.value}): $message';
}

/// Contract for repair booking retrieval, cancellation, and status transitions.
///
/// Corresponds to US-13 (SCRUM-44), US-14 (SCRUM-45), and US-15 (SCRUM-46).
abstract class IBookingService {
  /// Returns all bookings belonging to [customerId].
  Future<List<BookingModel>> getCustomerBookings(String customerId);

  /// Fetches a single booking by its [bookingId].
  Future<BookingModel?> getBookingById(String bookingId);

  /// Cancels a booking on behalf of [customerId].
  ///
  /// Throws:
  /// - [BookingNotFoundException] if [bookingId] does not exist.
  /// - [UnauthorizedBookingCancellationException] if [customerId] is not the creator.
  /// - [CannotCancelBookingException] if the booking status is `In Progress`,
  ///   `Completed`, `Cancelled`, or `Declined`.
  Future<BookingModel> cancelBooking({
    required String bookingId,
    required String customerId,
    String? reason,
  });

  /// Provider accepts (`Confirmed`) a pending booking.
  ///
  /// Throws [InvalidBookingTransitionException] if the booking was cancelled
  /// or cannot transition to [BookingStatus.confirmed].
  Future<BookingModel> acceptBooking({
    required String bookingId,
    required String providerId,
  });

  /// Company/provider assigns a technician (`Assigned`) to a booking.
  ///
  /// Throws [InvalidBookingTransitionException] if the booking was cancelled
  /// or cannot transition to [BookingStatus.assigned].
  Future<BookingModel> assignBooking({
    required String bookingId,
    required String technicianId,
    required String technicianName,
  });

  /// Technician/provider starts work (`In Progress`) on a booking.
  ///
  /// Throws [InvalidBookingTransitionException] if the booking was cancelled
  /// or cannot transition to [BookingStatus.inProgress].
  Future<BookingModel> startBooking({
    required String bookingId,
  });

  /// Updates a booking to [newStatus] if the lifecycle transition is valid.
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  });
}

/// Production and testable implementation of [IBookingService].
class BookingService implements IBookingService {
  static const String defaultCustomerId = 'customer-1';

  final List<BookingModel> _bookings;

  BookingService({
    List<BookingModel>? initialBookings,
    String customerId = defaultCustomerId,
  }) : _bookings = List<BookingModel>.from(
         initialBookings ?? buildDefaultBookings(customerId: customerId),
       );

  /// Default Phnom Penh repair bookings covering each lifecycle status for US-14.
  static List<BookingModel> buildDefaultBookings({
    String customerId = defaultCustomerId,
  }) {
    final now = DateTime(2026, 11, 20, 10, 0);
    return [
      BookingModel(
        id: 'bk-pending-01',
        customerId: customerId,
        providerId: 'prov-ac-01',
        providerName: 'Phnom Penh CoolAir Engineering',
        serviceCategory: 'Air Conditioner Repair & Care',
        serviceTitle: 'AC Deep Chemical Wash & Gas Check',
        description:
            'Master bedroom split AC unit is blowing warm air and dripping water indoors.',
        address: 'St. 310, Boeung Keng Kang 1, Chamkarmon, Phnom Penh',
        preferredDateTime: now.add(const Duration(days: 2, hours: 4)),
        status: BookingStatus.pending,
        totalPrice: 25.0,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      BookingModel(
        id: 'bk-assigned-02',
        customerId: customerId,
        providerId: 'prov-plumb-01',
        providerName: 'Mekong Pipe & Drainage Solutions',
        serviceCategory: 'Plumbing & Drainage',
        serviceTitle: 'Kitchen Pipe Leak & Pressure Pump Check',
        description:
            'Under-sink PVC joint is leaking steadily when the water pump turns on.',
        address: 'St. 592, Boeung Kak 2, Toul Kork, Phnom Penh',
        preferredDateTime: now.add(const Duration(days: 1, hours: 5)),
        status: BookingStatus.assigned,
        totalPrice: 18.0,
        assignedTechnicianId: 'tech-sokha-01',
        assignedTechnicianName: 'Sokha Vann',
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
      BookingModel(
        id: 'bk-confirmed-03',
        customerId: customerId,
        providerId: 'prov-elec-01',
        providerName: 'Dara Smart Electrical Services',
        serviceCategory: 'Electrical & Wiring',
        serviceTitle: 'Main Breaker Replacement & Circuit Inspection',
        description:
            'Living room circuit breaker trips whenever the oven and AC run together.',
        address: 'Borey Peng Huoth Boeung Snor, Chbar Ampov, Phnom Penh',
        preferredDateTime: now.add(const Duration(days: 3, hours: 1)),
        status: BookingStatus.confirmed,
        totalPrice: 30.0,
        assignedTechnicianId: 'tech-dara-02',
        assignedTechnicianName: 'Dara Meas',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      BookingModel(
        id: 'bk-inprogress-04',
        customerId: customerId,
        providerId: 'prov-app-01',
        providerName: 'Khmer Home Appliance Masters',
        serviceCategory: 'Appliance Repair',
        serviceTitle: 'Front-Load Washing Machine Drum Bearing Repair',
        description:
            'Washing machine makes loud grinding noise during spin cycle.',
        address: 'St. 1986, Phnom Penh Thmey, Sen Sok, Phnom Penh',
        preferredDateTime: now,
        status: BookingStatus.inProgress,
        totalPrice: 40.0,
        assignedTechnicianId: 'tech-piseth-03',
        assignedTechnicianName: 'Piseth Chan',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      BookingModel(
        id: 'bk-completed-05',
        customerId: customerId,
        providerId: 'prov-clean-01',
        providerName: 'CleanNest Phnom Penh Co.',
        serviceCategory: 'Home & Room Cleaning',
        serviceTitle: 'Full Condo Deep Sanitization',
        description: '2-bedroom condo deep cleaning including sofa steam wash.',
        address: 'Diamond Island (Koh Pich), Tonle Bassac, Phnom Penh',
        preferredDateTime: now.subtract(const Duration(days: 5)),
        status: BookingStatus.completed,
        totalPrice: 55.0,
        assignedTechnicianId: 'tech-sreyneang-04',
        assignedTechnicianName: 'Sreyneang Keo',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      BookingModel(
        id: 'bk-declined-06',
        customerId: customerId,
        providerId: 'prov-elec-02',
        providerName: 'Angkor Power & Lighting',
        serviceCategory: 'Electrical & Wiring',
        serviceTitle: 'Ceiling Fan & Chandelier Installation',
        description: 'Install two ceiling fans in guest bedrooms.',
        address: 'St. 2004, Tuek Thla, Sen Sok, Phnom Penh',
        preferredDateTime: now.subtract(const Duration(days: 3)),
        status: BookingStatus.declined,
        totalPrice: 22.0,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      // Booking belonging to another customer for ownership guard verification
      BookingModel(
        id: 'bk-other-customer-99',
        customerId: 'other-customer-999',
        providerId: 'prov-ac-01',
        providerName: 'Phnom Penh CoolAir Engineering',
        serviceCategory: 'Air Conditioner Repair & Care',
        serviceTitle: 'AC Gas Refill',
        description: 'Refill R32 refrigerant.',
        address: 'St. 271, Toul Tompoung, Chamkarmon, Phnom Penh',
        preferredDateTime: now.add(const Duration(days: 1)),
        status: BookingStatus.pending,
        totalPrice: 20.0,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  @override
  Future<List<BookingModel>> getCustomerBookings(String customerId) async {
    return List.unmodifiable(
      _bookings.where((booking) => booking.customerId == customerId),
    );
  }

  @override
  Future<BookingModel?> getBookingById(String bookingId) async {
    for (final booking in _bookings) {
      if (booking.id == bookingId) {
        return booking;
      }
    }
    return null;
  }

  @override
  Future<BookingModel> cancelBooking({
    required String bookingId,
    required String customerId,
    String? reason,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) {
      throw BookingNotFoundException(bookingId);
    }

    final booking = _bookings[index];

    // US-14 AC #6: Only the customer who created the booking can cancel it.
    if (!booking.isOwnedBy(customerId)) {
      throw UnauthorizedBookingCancellationException(
        bookingId: bookingId,
        userId: customerId,
      );
    }

    // US-14 AC #1 & #4:
    // Customers can cancel bookings with Pending, Assigned, or Confirmed status.
    // Customers cannot cancel bookings that are In Progress, Completed, Cancelled, or Declined.
    if (!booking.canBeCancelled) {
      throw CannotCancelBookingException(
        bookingId: bookingId,
        currentStatus: booking.status,
      );
    }

    final now = DateTime.now();
    final trimmedReason = reason?.trim();
    final updatedBooking = booking.copyWith(
      status: BookingStatus.cancelled,
      updatedAt: now,
      cancelledAt: now,
      cancelledBy: customerId,
      cancellationReason: (trimmedReason != null && trimmedReason.isNotEmpty)
          ? trimmedReason
          : booking.cancellationReason,
    );

    _bookings[index] = updatedBooking;
    return updatedBooking;
  }

  @override
  Future<BookingModel> acceptBooking({
    required String bookingId,
    required String providerId,
  }) async {
    return updateBookingStatus(
      bookingId: bookingId,
      newStatus: BookingStatus.confirmed,
    );
  }

  @override
  Future<BookingModel> assignBooking({
    required String bookingId,
    required String technicianId,
    required String technicianName,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) {
      throw BookingNotFoundException(bookingId);
    }

    final booking = _bookings[index];
    if (!booking.status.canTransitionTo(BookingStatus.assigned)) {
      throw InvalidBookingTransitionException(
        bookingId: bookingId,
        currentStatus: booking.status,
        targetStatus: BookingStatus.assigned,
        message: booking.status == BookingStatus.cancelled
            ? 'Cancelled bookings cannot be accepted, assigned, or started afterward.'
            : null,
      );
    }

    final updated = booking.copyWith(
      status: BookingStatus.assigned,
      assignedTechnicianId: technicianId,
      assignedTechnicianName: technicianName,
      updatedAt: DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<BookingModel> startBooking({
    required String bookingId,
  }) async {
    return updateBookingStatus(
      bookingId: bookingId,
      newStatus: BookingStatus.inProgress,
    );
  }

  @override
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) {
      throw BookingNotFoundException(bookingId);
    }

    final booking = _bookings[index];
    if (!booking.status.canTransitionTo(newStatus)) {
      throw InvalidBookingTransitionException(
        bookingId: bookingId,
        currentStatus: booking.status,
        targetStatus: newStatus,
        message: booking.status == BookingStatus.cancelled
            ? 'Cancelled bookings cannot be accepted, assigned, or started afterward.'
            : null,
      );
    }

    final updated = booking.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    _bookings[index] = updated;
    return updated;
  }
}
