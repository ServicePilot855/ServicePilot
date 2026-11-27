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

  @override
  Future<QuoteRequestModel> createQuoteRequest(
    QuoteRequestInput request,
  ) async {
    final errors = QuoteRequestValidator.validate(request);
    if (errors.isNotEmpty) {
      throw InvalidQuoteRequestException(errors);
    }

    final doc = _quoteRequests.doc();

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

    await _guard(() => doc.set(quote.toFirestore()));
    return quote;
  }

  @override
  Future<List<QuoteRequestModel>> getCustomerQuoteRequests(
    String customerId,
  ) async {
    final snapshot = await _quoteRequests
        .where('customerId', isEqualTo: customerId)
        .get();
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
    final snapshot = await _quoteRequests
        .where('providerId', isEqualTo: providerId)
        .get(const GetOptions(source: Source.server));
    final quotes = snapshot.docs
        .map((d) => QuoteRequestModel.fromFirestore(d.id, d.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(quotes);
  }

  @override
  Stream<List<QuoteRequestModel>> watchProviderQuoteRequests(
    String providerId,
  ) {
    return _quoteRequests
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      final quotes = snapshot.docs
          .map((d) => QuoteRequestModel.fromFirestore(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(quotes);
    });
  }

  @override
  Future<QuoteRequestModel?> getQuoteRequestById(String quoteId) async {
    final doc = await _quoteRequests.doc(quoteId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return QuoteRequestModel.fromFirestore(doc.id, data);
  }

  @override
  Stream<QuoteRequestModel?> watchQuoteRequestById(String quoteId) {
    return _quoteRequests.doc(quoteId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return QuoteRequestModel.fromFirestore(doc.id, data);
    });
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
      debugPrint('[FirestoreQuoteService] FirebaseException ${e.code}: ${e.message}');
      throw QuoteSubmissionException(
        e.message ?? 'Could not save quote request. Please try again.',
      );
    }
  }
}
