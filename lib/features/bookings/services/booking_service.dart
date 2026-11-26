import 'dart:async';

import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/models/incoming_booking_request.dart';

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

/// Thrown when a provider attempts to confirm a booking addressed to another
/// provider.
///
/// Enforces BOOK-2 (SCRUM-104) AC:
/// "A cancelled booking or another provider's booking cannot be confirmed."
class UnauthorizedBookingConfirmationException implements Exception {
  final String bookingId;
  final String providerId;
  final String message;

  const UnauthorizedBookingConfirmationException({
    required this.bookingId,
    required this.providerId,
    this.message = 'Only the assigned service provider can confirm this booking.',
  });

  @override
  String toString() =>
      'UnauthorizedBookingConfirmationException(bookingId: $bookingId, providerId: $providerId): $message';
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

/// Thrown when a booking request breaks the US-12 field rules.
class InvalidBookingRequestException implements Exception {
  final List<BookingFieldError> errors;

  const InvalidBookingRequestException(this.errors);

  @override
  String toString() =>
      'InvalidBookingRequestException(${errors.map((e) => e.name).join(', ')})';
}

/// Thrown when a booking could not be saved (offline, refused by the server).
class BookingSubmissionException implements Exception {
  final String message;

  const BookingSubmissionException(this.message);

  @override
  String toString() => 'BookingSubmissionException: $message';
}

/// Contract for repair booking creation, retrieval, cancellation, and status
/// transitions.
///
/// Corresponds to US-12 (SCRUM-43), US-13 (SCRUM-44), US-14 (SCRUM-45), and
/// US-15 (SCRUM-46).
abstract class IBookingService {
  /// Saves [request] as a new `Pending` booking for its customer and provider.
  ///
  /// Throws:
  /// - [InvalidBookingRequestException] if a field breaks the US-12 rules.
  /// - [BookingSubmissionException] if the booking could not be saved.
  Future<BookingModel> createBooking(BookingRequest request);

  /// Returns all bookings belonging to [customerId].
  Future<List<BookingModel>> getCustomerBookings(String customerId);

  /// Returns accepted bookings addressed to [providerId].
  Future<List<BookingModel>> getProviderBookings(String providerId);

  /// Emits real-time updates for accepted bookings addressed to [providerId].
  Stream<List<BookingModel>> watchProviderBookings(String providerId);

  Future<List<IncomingBookingRequest>> getIncomingRequests(String providerId);

  Future<IncomingBookingRequest?> getIncomingRequest(
    String providerId,
    String bookingId,
  );

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

  /// Provider confirms (`Confirmed`) an eligible pending/assigned booking and
  /// records the agreed appointment time.
  ///
  /// Throws:
  /// - [BookingNotFoundException] if [bookingId] does not exist.
  /// - [UnauthorizedBookingConfirmationException] if [providerId] does not own the booking.
  /// - [InvalidBookingTransitionException] if the booking was cancelled
  ///   or cannot transition to [BookingStatus.confirmed].
  Future<BookingModel> acceptBooking({
    required String bookingId,
    required String providerId,
    DateTime? confirmedAppointmentAt,
    String? confirmedBy,
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

  /// Emits real-time updates for a single booking identified by [bookingId].
  ///
  /// Corresponds to US-13 (SCRUM-44) AC #3 and DoD #2:
  /// "Status changes made by authorized service providers or technicians are
  /// reflected in the customer's booking view."
  Stream<BookingModel?> watchBookingById(String bookingId);
}

/// Production and testable implementation of [IBookingService].
class BookingService implements IBookingService {
  static const String defaultCustomerId = 'customer-1';

  final List<BookingModel> _bookings;

  @override
  Future<List<IncomingBookingRequest>> getIncomingRequests(
    String providerId,
  ) async {
    return _bookings
        .where((booking) =>
            booking.providerId == providerId &&
            booking.status == BookingStatus.pending)
        .map(IncomingBookingRequest.fromBooking)
        .toList();
  }

  @override
  Future<IncomingBookingRequest?> getIncomingRequest(
    String providerId,
    String bookingId,
  ) async {
    final booking = await getBookingById(bookingId);
    if (booking == null ||
        booking.providerId != providerId ||
        booking.status != BookingStatus.pending) {
      return null;
    }
    return IncomingBookingRequest.fromBooking(booking);
  }
  final StreamController<List<BookingModel>> _updatesController =
      StreamController<List<BookingModel>>.broadcast();

  void _notifyListeners() {
    if (!_updatesController.isClosed) {
      _updatesController.add(List.unmodifiable(_bookings));
    }
  }

  void dispose() {
    _updatesController.close();
  }

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
      // Owned Pending fixtures for demo technician and company accounts (BOOK-2)
      BookingModel(
        id: 'bk-virak-pending-01',
        customerId: 'demo-homeowner-2',
        providerId: 'prov-virak-ac',
        providerName: 'Virak Chan',
        serviceCategory: 'Air Conditioner Repair & Care',
        serviceTitle: 'Split AC Chemical Wash & Diagnostic',
        description:
            'Living room AC leaks water from indoor blower after 20 minutes.',
        address: 'St. 360, Boeung Keng Kang 3, Chamkarmon, Phnom Penh',
        preferredDateTime: now.add(const Duration(days: 1, hours: 3)),
        status: BookingStatus.pending,
        totalPrice: 25.0,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      BookingModel(
        id: 'bk-fixco-pending-01',
        customerId: 'demo-homeowner-2',
        providerId: 'prov-fixco-company',
        providerName: 'Phnom Penh Fix Co.',
        serviceCategory: 'Plumbing & Drainage',
        serviceTitle: 'Water Pump Pressure & Valve Service',
        description:
            'Booster pump cycles on and off continuously even with taps closed.',
        address: 'St. 516, Boeung Kak 1, Toul Kork, Phnom Penh',
        preferredDateTime: now.add(const Duration(days: 2, hours: 2)),
        status: BookingStatus.pending,
        totalPrice: 35.0,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  @override
  Future<BookingModel> createBooking(BookingRequest request) async {
    final errors = BookingRequestValidator.validate(request);
    if (errors.isNotEmpty) {
      throw InvalidBookingRequestException(errors);
    }

    final now = DateTime.now();
    final booking = BookingModel(
      id: 'bk-${now.microsecondsSinceEpoch}',
      customerId: request.customerId,
      providerId: request.providerId,
      providerName: request.providerName,
      serviceCategory: request.serviceCategory,
      serviceTitle: request.serviceTitle.trim(),
      description: request.description.trim(),
      address: request.address.trim(),
      preferredDateTime: request.preferredDateTime,
      status: BookingStatus.pending,
      totalPrice: request.estimatedPrice,
      createdAt: now,
      latitude: request.latitude,
      longitude: request.longitude,
      // Nothing is uploaded in memory; keep a recognisable placeholder link.
      photoUrls: [
        for (final photo in request.photos)
          'memory://bk-${now.microsecondsSinceEpoch}/${photo.name}',
      ],
    );
    _bookings.add(booking);
    _notifyListeners();
    return booking;
  }

  @override
  Future<List<BookingModel>> getCustomerBookings(String customerId) async {
    return List.unmodifiable(
      _bookings.where((booking) => booking.customerId == customerId),
    );
  }

  @override
  Future<List<BookingModel>> getProviderBookings(String providerId) async {
    return List.unmodifiable(
      _bookings.where((booking) => _isAcceptedBy(booking, providerId)),
    );
  }

  @override
  Stream<List<BookingModel>> watchProviderBookings(String providerId) async* {
    List<BookingModel> filter() => List.unmodifiable(
          _bookings.where((booking) => _isAcceptedBy(booking, providerId)),
        );

    yield filter();
    yield* _updatesController.stream.map(
      (list) => List.unmodifiable(
        list.where((booking) => _isAcceptedBy(booking, providerId)),
      ),
    );
  }

  bool _isAcceptedBy(BookingModel booking, String providerId) {
    return booking.providerId == providerId &&
        booking.status.exposesAcceptedDetails;
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
    _notifyListeners();
    return updatedBooking;
  }

  @override
  Future<BookingModel> acceptBooking({
    required String bookingId,
    required String providerId,
    DateTime? confirmedAppointmentAt,
    String? confirmedBy,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) {
      throw BookingNotFoundException(bookingId);
    }

    final booking = _bookings[index];
    if (!booking.isOwnedByProvider(providerId)) {
      throw UnauthorizedBookingConfirmationException(
        bookingId: bookingId,
        providerId: providerId,
      );
    }

    if (!booking.status.canTransitionTo(BookingStatus.confirmed)) {
      throw InvalidBookingTransitionException(
        bookingId: bookingId,
        currentStatus: booking.status,
        targetStatus: BookingStatus.confirmed,
        message: booking.status == BookingStatus.cancelled
            ? 'Cancelled bookings cannot be accepted, assigned, or started afterward.'
            : null,
      );
    }

    final now = DateTime.now();
    final updated = booking.copyWith(
      status: BookingStatus.confirmed,
      clearAssignment: true,
      confirmedAppointmentAt:
          confirmedAppointmentAt ?? booking.preferredDateTime,
      confirmedAt: now,
      confirmedBy: confirmedBy ?? providerId,
      updatedAt: now,
    );
    _bookings[index] = updated;
    _notifyListeners();
    return updated;
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
    _notifyListeners();
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
      clearAssignment: newStatus == BookingStatus.confirmed,
      updatedAt: DateTime.now(),
    );
    _bookings[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Stream<BookingModel?> watchBookingById(String bookingId) async* {
    BookingModel? findCurrent() {
      for (final booking in _bookings) {
        if (booking.id == bookingId) {
          return booking;
        }
      }
      return null;
    }

    yield findCurrent();
    yield* _updatesController.stream.map((list) {
      for (final b in list) {
        if (b.id == bookingId) return b;
      }
      return null;
    });
  }
}
