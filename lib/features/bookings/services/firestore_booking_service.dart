import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/services/booking_photo_uploader.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';

/// Cloud Firestore implementation of [IBookingService], backed by the
/// `bookings` collection.
///
/// Status changes run in transactions so two people changing the same booking
/// at once cannot both win (Sprint 2 risk: concurrent cancellations).
/// `firestore.rules` enforces the same ownership and status rules on the server.
class FirestoreBookingService implements IBookingService {
  FirestoreBookingService({
    FirebaseFirestore? firestore,
    IBookingPhotoUploader? photoUploader,
  })  : _injectedFirestore = firestore,
        _injectedUploader = photoUploader;

  final FirebaseFirestore? _injectedFirestore;
  final IBookingPhotoUploader? _injectedUploader;

  IBookingPhotoUploader get _photoUploader =>
      _injectedUploader ?? FirebaseBookingPhotoUploader();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'bookings';

  /// How long to wait for the server before telling the customer to retry.
  /// Without it an offline write would leave the form spinning indefinitely.
  static const Duration writeTimeout = Duration(seconds: 15);

  /// Up to five photos on a slow mobile connection need longer.
  static const Duration photoUploadTimeout = Duration(seconds: 90);

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(collectionName);

  @override
  Future<BookingModel> createBooking(BookingRequest request) async {
    final errors = BookingRequestValidator.validate(request);
    if (errors.isNotEmpty) {
      throw InvalidBookingRequestException(errors);
    }

    final doc = _bookings.doc();

    // Photos go up first so the booking is only written once they are safe.
    final photoUrls = request.photos.isEmpty
        ? const <String>[]
        : await _guard(
            () => _photoUploader.upload(
              customerId: request.customerId,
              bookingId: doc.id,
              photos: request.photos,
            ),
            timeout: photoUploadTimeout,
          );

    final booking = BookingModel(
      id: doc.id,
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
      createdAt: DateTime.now(),
      latitude: request.latitude,
      longitude: request.longitude,
      photoUrls: photoUrls,
    );

    await _guard(() => doc.set(booking.toFirestore()));
    return booking;
  }

  @override
  Future<List<BookingModel>> getCustomerBookings(String customerId) async {
    final snapshot =
        await _bookings.where('customerId', isEqualTo: customerId).get();
    return List.unmodifiable(
      snapshot.docs.map((d) => BookingModel.fromFirestore(d.id, d.data())),
    );
  }

  @override
  Future<List<BookingModel>> getProviderBookings(String providerId) async {
    final snapshot =
        await _bookings.where('providerId', isEqualTo: providerId).get();
    return List.unmodifiable(
      snapshot.docs.map((d) => BookingModel.fromFirestore(d.id, d.data())),
    );
  }

  @override
  Stream<List<BookingModel>> watchProviderBookings(String providerId) {
    return _bookings
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs.map(
              (d) => BookingModel.fromFirestore(d.id, d.data()),
            ),
          ),
        );
  }

  @override
  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc = await _bookings.doc(bookingId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return BookingModel.fromFirestore(doc.id, data);
  }

  @override
  Stream<BookingModel?> watchBookingById(String bookingId) {
    return _bookings.doc(bookingId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return BookingModel.fromFirestore(doc.id, data);
    });
  }

  @override
  Future<BookingModel> cancelBooking({
    required String bookingId,
    required String customerId,
    String? reason,
  }) {
    return _update(bookingId, (booking) {
      if (!booking.isOwnedBy(customerId)) {
        throw UnauthorizedBookingCancellationException(
          bookingId: bookingId,
          userId: customerId,
        );
      }
      if (!booking.canBeCancelled) {
        throw CannotCancelBookingException(
          bookingId: bookingId,
          currentStatus: booking.status,
        );
      }
      final now = DateTime.now();
      final trimmedReason = reason?.trim();
      return booking.copyWith(
        status: BookingStatus.cancelled,
        updatedAt: now,
        cancelledAt: now,
        cancelledBy: customerId,
        cancellationReason: (trimmedReason != null && trimmedReason.isNotEmpty)
            ? trimmedReason
            : booking.cancellationReason,
      );
    });
  }

  @override
  Future<BookingModel> acceptBooking({
    required String bookingId,
    required String providerId,
    DateTime? confirmedAppointmentAt,
    String? confirmedBy,
  }) {
    return _update(bookingId, (booking) {
      if (!booking.isOwnedByProvider(providerId)) {
        throw UnauthorizedBookingConfirmationException(
          bookingId: bookingId,
          providerId: providerId,
        );
      }
      _checkTransition(booking, BookingStatus.confirmed);
      final now = DateTime.now();
      return booking.copyWith(
        status: BookingStatus.confirmed,
        confirmedAppointmentAt:
            confirmedAppointmentAt ?? booking.preferredDateTime,
        confirmedAt: now,
        confirmedBy: confirmedBy ?? providerId,
        updatedAt: now,
      );
    });
  }

  @override
  Future<BookingModel> assignBooking({
    required String bookingId,
    required String technicianId,
    required String technicianName,
  }) {
    return _update(bookingId, (booking) {
      _checkTransition(booking, BookingStatus.assigned);
      return booking.copyWith(
        status: BookingStatus.assigned,
        assignedTechnicianId: technicianId,
        assignedTechnicianName: technicianName,
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<BookingModel> startBooking({required String bookingId}) {
    return updateBookingStatus(
      bookingId: bookingId,
      newStatus: BookingStatus.inProgress,
    );
  }

  @override
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) {
    return _update(bookingId, (booking) {
      _checkTransition(booking, newStatus);
      return booking.copyWith(status: newStatus, updatedAt: DateTime.now());
    });
  }

  /// Reads the booking, applies [change] and writes the result in one
  /// transaction. [change] throws to abort.
  Future<BookingModel> _update(
    String bookingId,
    BookingModel Function(BookingModel current) change,
  ) {
    final ref = _bookings.doc(bookingId);
    return _guard(
      () => _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(ref);
        final data = snapshot.data();
        if (!snapshot.exists || data == null) {
          throw BookingNotFoundException(bookingId);
        }
        final updated = change(BookingModel.fromFirestore(ref.id, data));
        // Leave the fields the rules treat as immutable untouched, so a
        // createdAt stored in another format is not rewritten.
        final fields = updated.toFirestore()
          ..remove('id')
          ..remove('customerId')
          ..remove('providerId')
          ..remove('createdAt');
        tx.update(ref, fields);
        return updated;
      }),
    );
  }

  void _checkTransition(BookingModel booking, BookingStatus target) {
    if (!booking.status.canTransitionTo(target)) {
      throw InvalidBookingTransitionException(
        bookingId: booking.id,
        currentStatus: booking.status,
        targetStatus: target,
        message: booking.status == BookingStatus.cancelled
            ? 'Cancelled bookings cannot be accepted, assigned, or started afterward.'
            : null,
      );
    }
  }

  /// Turns timeouts and server refusals into [BookingSubmissionException].
  /// The booking exceptions thrown by our own checks pass through unchanged.
  Future<T> _guard<T>(
    Future<T> Function() action, {
    Duration timeout = writeTimeout,
  }) async {
    try {
      return await action().timeout(timeout);
    } on TimeoutException {
      throw const BookingSubmissionException(
        'Could not reach the server. Check your connection and try again.',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '[FirestoreBookingService] ${e.plugin} ${e.code}: ${e.message}',
      );
      throw BookingSubmissionException(
        e.code == 'permission-denied'
            ? 'You are not allowed to change this booking.'
            : 'The booking could not be saved (${e.code}). Please try again.',
      );
    }
  }
}
