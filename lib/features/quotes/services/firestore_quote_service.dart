import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:service_pilot/features/bookings/services/booking_photo_uploader.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/quotes/models/quote_request_input.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/quotes/services/quote_service.dart';

/// Cloud Firestore implementation of [IQuoteService], backed by the
/// `quoteRequests` collection (QUOTE-1 / SCRUM-83).
class FirestoreQuoteService implements IQuoteService {
  FirestoreQuoteService({
    FirebaseFirestore? firestore,
    IBookingPhotoUploader? photoUploader,
  })  : _injectedFirestore = firestore,
        _injectedUploader = photoUploader;

  final FirebaseFirestore? _injectedFirestore;
  final IBookingPhotoUploader? _injectedUploader;
  final _pendingWrites = <(String, String), Future<QuoteRequestModel>>{};

  static const String collectionName = 'quoteRequests';
  static const Duration writeTimeout = Duration(seconds: 15);
  static const Duration photoUploadTimeout = Duration(seconds: 90);

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  IBookingPhotoUploader get _photoUploader =>
      _injectedUploader ??
      CloudinaryBookingPhotoUploader(baseFolder: 'servicepilot/quotes');

  CollectionReference<Map<String, dynamic>> get _quoteRequests =>
      _firestore.collection(collectionName);

  Query<Map<String, dynamic>> _providerRequests(String providerId) =>
      _quoteRequests.where('providerId', isEqualTo: providerId);

  @override
  String newQuoteRequestId() => _quoteRequests.doc().id;

  @override
  Future<QuoteRequestModel> createQuoteRequest(
    QuoteRequestInput request, {
    bool retry = false,
  }) async {
    final errors = QuoteRequestValidator.validate(request);
    if (errors.isNotEmpty) {
      throw InvalidQuoteRequestException(errors);
    }

    final doc = _quoteRequests.doc(request.submissionId);
    final key = (request.customerId, doc.id);
    final pending = _pendingWrites[key];
    if (pending != null) return _guard(() => pending);

    if (retry) {
      final saved = await _findSavedSubmission(doc.id, request);
      if (saved != null) return saved;
    }

    // Upload photos before persisting so failed uploads never leave an orphan request.
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

    final quote = QuoteRequestModel(
      id: doc.id,
      customerId: request.customerId,
      customerName: request.customerName?.trim(),
      providerId: request.providerId,
      providerName: request.providerName,
      offeringId: request.offering.id,
      offeringTitle: request.offering.title.trim(),
      categoryId: request.offering.categoryId,
      categoryName: request.offering.categoryName,
      description: request.description.trim(),
      photoUrls: photoUrls,
      status: QuoteStatus.requested,
      createdAt: DateTime.now(),
    );

    final existingWrite = _pendingWrites[key];
    if (existingWrite != null) return _guard(() => existingWrite);

    // Keep waiting on the same write if the client stops waiting for its result.
    final write =
        doc.set(quote.toFirestore()).then((_) => quote).whenComplete(() {
      _pendingWrites.remove(key);
    });
    _pendingWrites[key] = write;
    try {
      return await _guard(() => write);
    } on QuoteSubmissionException {
      if (retry && !_pendingWrites.containsKey(key)) {
        final saved = await _findSavedSubmission(doc.id, request);
        if (saved != null) return saved;
      }
      rethrow;
    }
  }

  Future<QuoteRequestModel?> _findSavedSubmission(
    String quoteId,
    QuoteRequestInput request,
  ) async {
    try {
      final saved = await getQuoteRequestById(quoteId).timeout(writeTimeout);
      if (saved != null && !matchesQuoteSubmission(saved, request)) {
        throw const QuoteSubmissionException(
            'Quote request ID is already in use.');
      }
      return saved;
    } on FirebaseException catch (error) {
      throw QuoteSubmissionException(
        error.message ?? 'Could not check quote request status.',
      );
    } on TimeoutException {
      throw const QuoteSubmissionException(
          'Could not check quote request status.');
    }
  }

  @override
  Future<List<QuoteRequestModel>> getCustomerQuoteRequests(
    String customerId,
  ) async {
    final snapshot =
        await _quoteRequests.where('customerId', isEqualTo: customerId).get();
    final quotes = snapshot.docs
        .map((d) => QuoteRequestModel.fromFirestore(d.id, d.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(quotes);
  }

  @override
  Future<List<QuoteRequestModel>> getProviderQuoteRequests(
    String providerId,
  ) async {
    final snapshot = await _providerRequests(providerId)
        .get(const GetOptions(source: Source.server));
    final quotes = snapshot.docs
        .map((d) => QuoteRequestModel.fromFirestore(d.id, d.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(quotes);
  }

  @override
  Future<QuoteRequestPage> getCustomerQuotePage(
      String customerId, int size) async {
    final snapshot = await _quoteRequests
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(size + 1)
        .get();
    return QuoteRequestPage(_decodeQuotes(snapshot), size);
  }

  @override
  Stream<QuoteRequestPage> watchProviderQuotePage(String providerId, int size) {
    // Creation covers requests without an update. The update feed keeps old
    // requests with recent decisions in the same bounded window.
    final queries = {
      'createdAt': _providerRequests(providerId),
      'updatedAt':
          _providerRequests(providerId).where('updatedAt', isNull: false),
    };
    return Stream.multi((controller) {
      final feeds = <String, List<QuoteRequestModel>>{};
      final subscriptions = [
        for (final entry in queries.entries)
          _watchAuthorized(entry.value
                  .orderBy(entry.key, descending: true)
                  .limit(size + 1))
              .map(_decodeQuotes)
              .listen((quotes) {
            feeds[entry.key] = quotes;
            final created = feeds['createdAt'];
            final updated = feeds['updatedAt'];
            if (created == null || updated == null) return;

            final byId = {for (final quote in created) quote.id: quote};
            for (final quote in updated) {
              final previous = byId[quote.id];
              final previousUpdate = previous?.updatedAt;
              final update = quote.updatedAt;
              if (previous == null ||
                  previousUpdate == null ||
                  (update != null && !update.isBefore(previousUpdate))) {
                byId[quote.id] = quote;
              }
            }
            final ordered = byId.values.toList()..sort(compareQuoteActivity);
            controller.add(QuoteRequestPage(ordered, size));
          }, onError: (Object error, StackTrace stack) {
            // A missing index or a rules refusal lands here; the message
            // names which (and links to create a missing index).
            debugPrint(
                '[FirestoreQuoteService] provider quotes by ${entry.key} failed: $error');
            feeds.remove(entry.key);
            controller.addError(error, stack);
          }),
      ];
      controller.onCancel = () async {
        await Future.wait(
            subscriptions.map((subscription) => subscription.cancel()));
      };
    });
  }

  List<QuoteRequestModel> _decodeQuotes(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => QuoteRequestModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Stream<List<QuoteRequestModel>> watchProviderQuoteRequests(
    String providerId,
  ) {
    return _watchAuthorized(_providerRequests(providerId)).map((snapshot) {
      final quotes = snapshot.docs
          .map((d) => QuoteRequestModel.fromFirestore(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(quotes);
    });
  }

  @override
  Stream<QuoteRequestModel?> watchProviderQuoteRequest(
    String providerId,
    String quoteId,
  ) {
    final query = _providerRequests(providerId)
        .where(FieldPath.documentId, isEqualTo: quoteId);
    return _watchAuthorized(query).map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.single;
      return QuoteRequestModel.fromFirestore(doc.id, doc.data());
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchAuthorized(
    Query<Map<String, dynamic>> query,
  ) {
    // A cached snapshot may predate the current account's authorization.
    return query
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache);
  }

  @override
  Future<QuoteRequestModel?> getQuoteRequestById(String quoteId) async {
    try {
      final doc = await _quoteRequests.doc(quoteId).get(
            const GetOptions(source: Source.server),
          );
      final data = doc.data();
      if (data == null || doc.metadata.hasPendingWrites) return null;
      return QuoteRequestModel.fromFirestore(doc.id, data);
    } on FirebaseException catch (error) {
      // The quote read rules also deny reads of documents that do not exist.
      if (error.code == 'permission-denied') return null;
      rethrow;
    }
  }

  @override
  Stream<QuoteRequestModel?> watchQuoteRequestById(String quoteId) {
    return _quoteRequests.doc(quoteId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return QuoteRequestModel.fromFirestore(doc.id, data);
    });
  }

  @override
  Future<QuoteRequestModel> submitQuotePrice({
    required String quoteId,
    required String providerId,
    required double price,
  }) async {
    // Check the price before any network round trip.
    final priceError = QuotePriceValidator.validate(price);
    if (priceError != null) throw InvalidQuotePriceException(priceError);

    return _transition(
      quoteId,
      (current) => applyQuotePrice(
        current,
        quoteId: quoteId,
        providerId: providerId,
        price: price,
        now: DateTime.now(),
      ),
      (updated) => {
        'status': QuoteStatus.quoted.value,
        'quotedPrice': updated.quotedPrice,
        'quotedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  @override
  Future<QuoteRequestModel> approveQuote({
    required String quoteId,
    required String customerId,
  }) {
    return _transition(
      quoteId,
      (current) => applyQuoteApproval(
        current,
        quoteId: quoteId,
        customerId: customerId,
        now: DateTime.now(),
      ),
      (updated) => {
        'status': QuoteStatus.approved.value,
        // The rules require this to equal the stored quotedPrice.
        'approvedPrice': updated.approvedPrice,
        'approvedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  /// Reads the quote, applies [change] and writes [fields] in one
  /// transaction, so two devices cannot both move the same request.
  /// [change] throws to abort without writing.
  Future<QuoteRequestModel> _transition(
    String quoteId,
    QuoteRequestModel Function(QuoteRequestModel? current) change,
    Map<String, Object?> Function(QuoteRequestModel updated) fields,
  ) {
    final ref = _quoteRequests.doc(quoteId);
    return _guard(() => _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          final data = snapshot.data();
          final current = snapshot.exists && data != null
              ? QuoteRequestModel.fromFirestore(snapshot.id, data)
              : null;
          final updated = change(current);
          transaction.update(ref, {
            ...fields(updated),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return updated;
        }));
  }

  Future<T> _guard<T>(
    Future<T> Function() run, {
    Duration timeout = writeTimeout,
  }) async {
    try {
      return await run().timeout(timeout);
    } on QuoteSubmissionException {
      rethrow;
    } on BookingSubmissionException catch (e) {
      throw QuoteSubmissionException(e.message);
    } on TimeoutException {
      throw const QuoteSubmissionException(
        'Request timed out. Check your connection and try again.',
      );
    } on FirebaseException catch (e) {
      debugPrint(
          '[FirestoreQuoteService] FirebaseException ${e.code}: ${e.message}');
      if (e.code == 'permission-denied') {
        // The rules refused the change: wrong account or a stale status.
        throw const QuoteSubmissionException(
          'You are not allowed to change this quote request.',
        );
      }
      throw QuoteSubmissionException(
        e.message ?? 'Could not save quote request. Please try again.',
      );
    }
  }
}
