import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/models/incoming_booking_request.dart';
import 'package:service_pilot/features/bookings/models/provider_service_record.dart';
import 'package:service_pilot/features/bookings/models/quote_booking_request.dart';
import 'package:service_pilot/features/bookings/models/technician_job.dart';
import 'package:service_pilot/features/bookings/services/booking_photo_uploader.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';

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
      _injectedUploader ?? CloudinaryBookingPhotoUploader();

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

  CollectionReference<Map<String, dynamic>> _providerRequests(
    String providerId,
    String collection,
  ) =>
      _firestore.collection('providers').doc(providerId).collection(collection);

  CollectionReference<Map<String, dynamic>> _inbox(String providerId) =>
      _providerRequests(providerId, 'incomingBookingRequests');

  CollectionReference<Map<String, dynamic>> _declinedRequests(
          String providerId) =>
      _providerRequests(providerId, 'declinedBookingRequests');

  CollectionReference<Map<String, dynamic>> _cancelledRequests(
          String providerId) =>
      _providerRequests(providerId, 'cancelledBookingRequests');

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
      totalPrice: request.totalPrice,
      createdAt: DateTime.now(),
      latitude: request.latitude,
      longitude: request.longitude,
      photoUrls: photoUrls,
      items: request.items,
    );

    await _guard(() {
      final batch = _firestore.batch();
      batch.set(doc, booking.toFirestore());
      batch.set(
        _inbox(booking.providerId).doc(doc.id),
        IncomingBookingRequest.fromBooking(booking).toFirestore(),
      );
      return batch.commit();
    });
    return booking;
  }

  @override
  Future<BookingModel> createQuoteBooking(
    QuoteBookingRequest request,
  ) async {
    final errors = request.validate();
    if (errors.isNotEmpty) {
      throw InvalidBookingRequestException(errors);
    }

    final quoteRef =
        _firestore.collection('quoteRequests').doc(request.quoteId);
    final doc = _bookings.doc();

    // One transaction re-reads the quote, so it cannot be booked twice or
    // after it stops being Approved. The rules check the same link.
    return _guard(() => _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(quoteRef);
          final data = snapshot.data();
          final quote = snapshot.exists && data != null
              ? QuoteRequestModel.fromFirestore(snapshot.id, data)
              : null;
          final block = quoteBookingBlock(quote, request.customerId);
          if (block != null) {
            throw QuoteNotBookableException(
              request.quoteId,
              block,
              bookingId: quote?.bookingId,
            );
          }

          final booking = bookingFromApprovedQuote(
            bookingId: doc.id,
            quote: quote!,
            request: request,
            now: DateTime.now(),
          );
          transaction.set(doc, booking.toFirestore());
          transaction.set(
            _inbox(booking.providerId).doc(doc.id),
            IncomingBookingRequest.fromBooking(booking).toFirestore(),
          );
          transaction.update(quoteRef, {
            'bookingId': doc.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return booking;
        }));
  }

  @override
  Future<List<IncomingBookingRequest>> getIncomingRequests(
    String providerId,
  ) =>
      _getRequestPreviews(_inbox(providerId));

  @override
  Future<List<IncomingBookingRequest>> getDeclinedRequests(
    String providerId,
  ) =>
      _getRequestPreviews(_declinedRequests(providerId));

  @override
  Future<List<ProviderServiceRecord>> getProviderServiceRecords(
    String providerId,
  ) async {
    final completedFuture = _bookings
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: BookingStatus.completed.value)
        .get(const GetOptions(source: Source.server));
    final cancelledFuture = _getRequestPreviews(_cancelledRequests(providerId));
    final declinedFuture = _getRequestPreviews(_declinedRequests(providerId));

    final completedSnap = await completedFuture;
    final cancelled = await cancelledFuture;
    final declined = await declinedFuture;

    final byId = <String, ProviderServiceRecord>{};
    for (final doc in completedSnap.docs) {
      final booking = BookingModel.fromFirestore(doc.id, doc.data());
      byId[booking.id] = ProviderServiceRecord.fromBooking(booking);
    }
    for (final preview in cancelled) {
      byId.putIfAbsent(
        preview.id,
        () => ProviderServiceRecord.fromPreview(
          preview,
          providerId: providerId,
          status: BookingStatus.cancelled,
        ),
      );
    }
    for (final preview in declined) {
      byId.putIfAbsent(
        preview.id,
        () => ProviderServiceRecord.fromPreview(
          preview,
          providerId: providerId,
          status: BookingStatus.declined,
        ),
      );
    }

    final records = byId.values.toList()
      ..sort((a, b) {
        final dateA = a.appointmentDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.appointmentDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
    return List.unmodifiable(records);
  }

  Future<List<IncomingBookingRequest>> _getRequestPreviews(
    CollectionReference<Map<String, dynamic>> requests,
  ) async {
    final result = await requests.get(const GetOptions(source: Source.server));
    return result.docs
        .map((doc) => IncomingBookingRequest.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<IncomingBookingRequest?> getIncomingRequest(
    String providerId,
    String bookingId,
  ) =>
      _getRequestPreview(_inbox(providerId).doc(bookingId));

  @override
  Future<IncomingBookingRequest?> getDeclinedRequest(
    String providerId,
    String bookingId,
  ) =>
      _getRequestPreview(_declinedRequests(providerId).doc(bookingId));

  Future<IncomingBookingRequest?> _getRequestPreview(
    DocumentReference<Map<String, dynamic>> request,
  ) async {
    final result = await request.get(const GetOptions(source: Source.server));
    final data = result.data();
    return data == null
        ? null
        : IncomingBookingRequest.fromFirestore(result.id, data);
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
    final snapshot = await _acceptedBookings(providerId).get(
      const GetOptions(source: Source.server),
    );
    return List.unmodifiable(
      snapshot.docs.map((d) => BookingModel.fromFirestore(d.id, d.data())),
    );
  }

  @override
  Stream<List<BookingModel>> watchProviderBookings(String providerId) {
    return _acceptedBookings(providerId)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs.map(
              (d) => BookingModel.fromFirestore(d.id, d.data()),
            ),
          ),
        );
  }

  Query<Map<String, dynamic>> _acceptedBookings(String providerId) =>
      _bookings.where('providerId', isEqualTo: providerId).where(
            'status',
            whereIn: BookingStatusExtension.acceptedStatuses
                .map((status) => status.value)
                .toList(),
          );

  @override
  Future<List<BookingModel>> getProviderActiveBookings(
    String providerId,
  ) async {
    final snapshot = await _activeProviderBookings(providerId).get(
      const GetOptions(source: Source.server),
    );
    return List.unmodifiable(
      snapshot.docs.map((d) => BookingModel.fromFirestore(d.id, d.data())),
    );
  }

  @override
  Stream<List<BookingModel>> watchProviderActiveBookings(String providerId) {
    return _activeProviderBookings(providerId)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs.map(
              (d) => BookingModel.fromFirestore(d.id, d.data()),
            ),
          ),
        );
  }

  Query<Map<String, dynamic>> _activeProviderBookings(String providerId) =>
      _bookings.where('providerId', isEqualTo: providerId).where(
            'status',
            whereIn: BookingStatusExtension.activeProviderStatuses
                .map((status) => status.value)
                .toList(),
          );

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

  /// TECHJOB-1 (SCRUM-100): the rules let a technician list bookings only
  /// when the query itself pins the company, the technician and the active
  /// statuses, so every filter here is required.
  @override
  Stream<List<TechnicianJob>> watchTechnicianJobs({
    required String technicianId,
    required String companyId,
  }) {
    if (technicianId.isEmpty || companyId.isEmpty) {
      return Stream.value(const []);
    }
    return _bookings
        .where('providerId', isEqualTo: companyId)
        .where('technicianId', isEqualTo: technicianId)
        .where(
          'status',
          whereIn: BookingStatusExtension.technicianJobStatuses
              .map((status) => status.value)
              .toList(),
        )
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map(
          (snapshot) => TechnicianJob.sorted(
            snapshot.docs
                .map((d) => BookingModel.fromFirestore(d.id, d.data()))
                .where((booking) => TechnicianJob.isAssignedTo(
                      booking,
                      technicianId: technicianId,
                      companyId: companyId,
                    ))
                .map(TechnicianJob.fromBooking),
          ),
        );
  }

  @override
  Stream<TechnicianJob?> watchTechnicianJob({
    required String technicianId,
    required String companyId,
    required String bookingId,
  }) {
    return _bookings.doc(bookingId).snapshots().map<TechnicianJob?>((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final booking = BookingModel.fromFirestore(doc.id, data);
      return TechnicianJob.isAssignedTo(
        booking,
        technicianId: technicianId,
        companyId: companyId,
      )
          ? TechnicianJob.fromBooking(booking)
          : null;
    }).transform(
      // The rules refuse the read once the job is not this technician's
      // active job (unassigned, reassigned, cancelled or completed).
      StreamTransformer.fromHandlers(
        handleError: (error, stack, sink) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            sink.add(null);
          } else {
            sink.addError(error, stack);
          }
        },
      ),
    );
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
  Future<void> acceptBooking({
    required String bookingId,
    required String providerId,
    DateTime? confirmedAppointmentAt,
  }) {
    final ref = _bookings.doc(bookingId);
    final previewRef = _inbox(providerId).doc(bookingId);
    return _guard(() async {
      await _firestore.runTransaction((transaction) async {
        final preview = (await transaction.get(previewRef)).data();
        Object? appointment = preview?['appointmentDate'];
        if (preview == null) {
          // An assigned booking already permits the provider's private read.
          final data = (await transaction.get(ref)).data();
          if (data == null) throw BookingNotFoundException(bookingId);
          final booking = BookingModel.fromFirestore(bookingId, data);
          if (!booking.isOwnedByProvider(providerId)) {
            throw UnauthorizedBookingConfirmationException(
              bookingId: bookingId,
              providerId: providerId,
            );
          }
          _checkTransition(booking, BookingStatus.confirmed);
          appointment = data['appointmentDate'];
        }
        final preferred = switch (appointment) {
          Timestamp() => appointment.toDate(),
          String() => DateTime.tryParse(appointment),
          _ => null,
        };
        if (preferred == null ||
            (confirmedAppointmentAt != null &&
                !confirmedAppointmentAt.isAtSameMomentAs(preferred))) {
          throw const BookingSubmissionException(
            'The preferred appointment is unavailable or has changed.',
          );
        }
        transaction.update(ref, {
          'status': BookingStatus.confirmed.value,
          'updatedAt': FieldValue.serverTimestamp(),
          ..._confirmationFields(appointment!, providerId),
        });
        if (preview != null) transaction.delete(previewRef);
      });
    });
  }

  Map<String, Object?> _confirmationFields(
          Object appointment, String providerId) =>
      {
        'confirmedAppointmentAt': appointment,
        'confirmedAt': FieldValue.serverTimestamp(),
        'confirmedBy': providerId,
        'technicianId': FieldValue.delete(),
        'technicianName': FieldValue.delete(),
      };

  @override
  Future<void> declineBooking({
    required String bookingId,
    required String providerId,
    String? reason,
  }) {
    final pending = _inbox(providerId).doc(bookingId);
    final archived = _declinedRequests(providerId).doc(bookingId);
    final trimmedReason = reason?.trim();
    return _guard(() => _firestore.runTransaction<void>((transaction) async {
          final preview = (await transaction.get(pending)).data();
          if (preview == null) {
            if ((await transaction.get(archived)).exists) {
              throw InvalidBookingDeclineStateException(
                bookingId: bookingId,
                currentStatus: BookingStatus.declined,
              );
            }
            throw BookingNotFoundException(bookingId);
          }
          transaction.update(_bookings.doc(bookingId), {
            'status': BookingStatus.declined.value,
            'updatedAt': FieldValue.serverTimestamp(),
            'declinedReason': trimmedReason != null && trimmedReason.isNotEmpty
                ? trimmedReason
                : FieldValue.delete(),
          });
          transaction.set(archived, preview);
          transaction.delete(pending);
        }));
  }

  @override
  Future<Map<String, String>> getAssignableTechnicians(String companyId) async {
    final roster = await _providerRequests(companyId, 'technicians')
        .orderBy('fullName')
        .get(const GetOptions(source: Source.server));
    return {
      for (final doc in roster.docs)
        if (doc.data()['fullName'] case final String name when name.isNotEmpty)
          doc.id: name,
    };
  }

  @override
  Future<BookingModel> assignBooking({
    required String bookingId,
    required String companyId,
    required String technicianId,
  }) {
    final bookingRef = _bookings.doc(bookingId);
    final technicianRef =
        _providerRequests(companyId, 'technicians').doc(technicianId);
    return _guard(() => _firestore.runTransaction((transaction) async {
          final data = (await transaction.get(bookingRef)).data();
          if (data == null) throw BookingNotFoundException(bookingId);
          final booking = BookingModel.fromFirestore(bookingId, data);
          if (!booking.isOwnedByProvider(companyId)) {
            throw const BookingSubmissionException('This company does not own the booking.');
          }
          if (!booking.canBeAssigned) {
            throw InvalidBookingTransitionException(
              bookingId: bookingId,
              currentStatus: booking.status,
              targetStatus: BookingStatus.assigned,
            );
          }
          final name = (await transaction.get(technicianRef)).data()?['fullName'];
          if (name is! String || name.isEmpty) {
            throw const BookingSubmissionException('The technician is unavailable.');
          }
          transaction.update(bookingRef, {
            'status': BookingStatus.assigned.value,
            'technicianId': technicianId,
            'technicianName': name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return booking.copyWith(
            status: BookingStatus.assigned,
            assignedTechnicianId: technicianId,
            assignedTechnicianName: name,
            updatedAt: DateTime.now(),
          );
        }));
  }

  /// WORK-1 (SCRUM-91): starts an owned confirmed/assigned job. A booking that
  /// came from a quote also needs that quote to be approved, read in the same
  /// transaction so a missing approval can never slip through.
  @override
  Future<BookingModel> startBooking({
    required String bookingId,
    required String providerId,
  }) {
    final ref = _bookings.doc(bookingId);
    return _guard(
      () => _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (!snapshot.exists || data == null) {
          throw BookingNotFoundException(bookingId);
        }

        final booking = BookingModel.fromFirestore(ref.id, data);
        if (!booking.isOwnedByProvider(providerId)) {
          throw UnauthorizedBookingStartException(
            bookingId: bookingId,
            providerId: providerId,
          );
        }
        if (!booking.canBeStarted) {
          throw InvalidBookingStartStateException(
            bookingId: bookingId,
            currentStatus: booking.status,
          );
        }

        final quoteId = booking.quoteId;
        if (booking.isFromQuote) {
          final quoteData = (await transaction.get(
            _firestore.collection('quoteRequests').doc(quoteId),
          ))
              .data();
          final approved = quoteData != null &&
              quoteData['status'] == 'approved' &&
              (() {
                final linked = quoteData['bookingId'];
                return linked == null ||
                    (linked is String && linked.isEmpty) ||
                    linked == bookingId;
              })();
          if (!approved) {
            throw QuoteNotApprovedForStartException(
              bookingId: bookingId,
              quoteId: quoteId,
            );
          }
        }

        final now = DateTime.now();
        transaction.update(ref, {
          'status': BookingStatus.inProgress.value,
          'updatedAt': Timestamp.fromDate(now),
        });
        return booking.copyWith(
          status: BookingStatus.inProgress,
          updatedAt: now,
        );
      }),
    );
  }

  @override
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) {
    return _update(bookingId, (booking) {
      _checkTransition(booking, newStatus);
      final now = DateTime.now();
      final confirming = newStatus == BookingStatus.confirmed;
      return booking.copyWith(
        status: newStatus,
        clearAssignment: confirming,
        confirmedAppointmentAt: confirming ? booking.preferredDateTime : null,
        confirmedAt: confirming ? now : null,
        confirmedBy: confirming ? booking.providerId : null,
        updatedAt: now,
      );
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
        final current = BookingModel.fromFirestore(ref.id, data);
        final updated = change(current);
        final appointment = data['appointmentDate'];
        if (updated.status == BookingStatus.confirmed && appointment == null) {
          throw const BookingSubmissionException(
            'The preferred appointment is unavailable or has changed.',
          );
        }
        tx.update(ref, {
          'status': updated.status.value,
          'updatedAt': Timestamp.fromDate(updated.updatedAt!),
          if (updated.status == BookingStatus.confirmed)
            ..._confirmationFields(appointment!, current.providerId),
          if (updated.status == BookingStatus.assigned) ...{
            if (updated.assignedTechnicianId != null)
              'technicianId': updated.assignedTechnicianId,
            if (updated.assignedTechnicianName != null)
              'technicianName': updated.assignedTechnicianName,
          },
          if (updated.status == BookingStatus.cancelled &&
              updated.cancelledAt != null) ...{
            'cancelledAt': Timestamp.fromDate(updated.cancelledAt!),
            'cancelledBy': updated.cancelledBy,
            if (updated.cancellationReason != null)
              'cancellationReason': updated.cancellationReason,
          },
        });
        if (current.status == BookingStatus.pending &&
            updated.status != BookingStatus.pending) {
          tx.delete(_inbox(current.providerId).doc(bookingId));
        }
        if (updated.status == BookingStatus.cancelled) {
          tx.set(
            _cancelledRequests(current.providerId).doc(bookingId),
            IncomingBookingRequest.fromBooking(updated).toFirestore(),
          );
        }
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
