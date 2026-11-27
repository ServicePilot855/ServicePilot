import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/services/booking_photo_uploader.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/cart/providers/cart_provider.dart';
import 'package:service_pilot/features/quotes/models/quote_request_input.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/quotes/services/firestore_quote_service.dart';
import 'package:service_pilot/features/quotes/services/quote_service.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';

class _FakePhotoUploader implements IBookingPhotoUploader {
  _FakePhotoUploader({this.fail = false});

  final bool fail;
  final uploads = <String>[];

  @override
  Future<List<String>> upload({
    required String customerId,
    required String bookingId,
    required List<BookingPhoto> photos,
  }) async {
    if (fail) {
      throw const BookingSubmissionException('Upload failed');
    }
    return [
      for (final photo in photos)
        (uploads..add('quotes/$customerId/$bookingId/${photo.name}')).last,
    ]
        .map((path) => 'https://res.cloudinary.com/demo/image/upload/$path')
        .toList();
  }
}

class _DelayedQuoteFirestore extends FakeFirebaseFirestore {
  final release = Completer<void>();
  int writes = 0;

  @override
  Future<void> maybeThrowSecurityException(String path, Object method) async {
    if (method is Enum && method.name == 'write') {
      writes++;
      await release.future;
    }
  }
}

OfferingModel _quoteOffering({
  String id = 'off-quote-1',
  String providerId = 'prov-dara-ac',
  OfferingPricingMode pricingMode = OfferingPricingMode.quoteRequired,
  bool isActive = true,
}) {
  return OfferingModel(
    id: id,
    providerId: providerId,
    providerName: 'Dara Chhum',
    categoryId: 'cat-ac',
    categoryName: 'Air Conditioner Repair & Care',
    title: 'Central Inverter PCB Diagnosis',
    description: 'Micro-soldering diagnostics requiring custom quote.',
    pricingMode: pricingMode,
    price: pricingMode == OfferingPricingMode.fixed ? 25.0 : null,
    isActive: isActive,
  );
}

OfferingModel _fixedOffering() => const OfferingModel(
      id: 'off-fixed-1',
      providerId: 'prov-dara-ac',
      providerName: 'Dara Chhum',
      categoryId: 'cat-ac',
      categoryName: 'Air Conditioner Repair & Care',
      title: 'Split AC Wash',
      description: 'Standard coil and filter wash.',
      pricingMode: OfferingPricingMode.fixed,
      price: 25.0,
      isActive: true,
    );

BookingPhoto _photo(String name) => BookingPhoto(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      name: name,
    );

QuoteRequestInput _input({
  String? submissionId,
  String customerId = 'customer-1',
  String? customerName = 'Sophea Meas',
  String providerId = 'prov-dara-ac',
  OfferingModel? offering,
  String description = '  Inverter board clicks repeatedly and blinks E5.  ',
  List<BookingPhoto> photos = const [],
}) {
  return QuoteRequestInput(
    submissionId: submissionId,
    customerId: customerId,
    customerName: customerName,
    providerId: providerId,
    providerName: 'Dara Chhum',
    offering: offering ?? _quoteOffering(providerId: providerId),
    description: description,
    photos: photos,
  );
}

void main() {
  group('SCRUM-83 / SCRUM-135: InMemoryQuoteService', () {
    test('stores quote request with Requested status for offering and provider',
        () async {
      final service = InMemoryQuoteService();
      final quote = await service.createQuoteRequest(
        _input(photos: [_photo('board.jpg')]),
      );

      expect(quote.status, QuoteStatus.requested);
      expect(quote.customerId, 'customer-1');
      expect(quote.providerId, 'prov-dara-ac');
      expect(quote.offeringId, 'off-quote-1');
      expect(quote.offeringTitle, 'Central Inverter PCB Diagnosis');
      expect(quote.description, 'Inverter board clicks repeatedly and blinks E5.');
      expect(quote.quotedPrice, isNull);
      expect(quote.photoUrls, hasLength(1));

      expect(await service.getQuoteRequestById(quote.id), isNotNull);
      expect(await service.getCustomerQuoteRequests('customer-1'), hasLength(1));
      expect(await service.getCustomerQuoteRequests('other-customer'), isEmpty);
      expect(await service.getProviderQuoteRequests('prov-dara-ac'), hasLength(1));
      expect(await service.getProviderQuoteRequests('other-provider'), isEmpty);
    });

    test('rejects invalid requests without saving', () async {
      final service = InMemoryQuoteService();
      await expectLater(
        service.createQuoteRequest(
          _input(
            offering: _fixedOffering(),
            description: 'too short',
          ),
        ),
        throwsA(isA<InvalidQuoteRequestException>()),
      );
      expect(await service.getCustomerQuoteRequests('customer-1'), isEmpty);
    });

    test('submitting a quote request leaves the fixed-price cart unchanged',
        () async {
      final cart = CartNotifier();
      cart.addOffering(_fixedOffering());
      expect(cart.state.itemCount, 1);
      expect(cart.state.totalPrice, 25.0);

      final service = InMemoryQuoteService();
      await service.createQuoteRequest(_input());

      expect(cart.state.itemCount, 1);
      expect(cart.state.totalPrice, 25.0);
      expect(cart.state.items.single.offering.id, 'off-fixed-1');
    });
  });

  group('SCRUM-83 / SCRUM-135: FirestoreQuoteService', () {
    late FakeFirebaseFirestore firestore;
    late _FakePhotoUploader uploader;
    late FirestoreQuoteService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      uploader = _FakePhotoUploader();
      service = FirestoreQuoteService(
        firestore: firestore,
        photoUploader: uploader,
      );
    });

    test(
        'retry returns the saved submission without writing or uploading again',
        () async {
      final input = _input(
        submissionId: service.newQuoteRequestId(),
        photos: [_photo('pcb.jpg')],
      );
      final saved = await service.createQuoteRequest(input);
      final retryService = FirestoreQuoteService(
        firestore: firestore,
        photoUploader: _FakePhotoUploader(fail: true),
      );

      final retried = await retryService.createQuoteRequest(input, retry: true);

      expect(retried.id, saved.id);
      expect(retried.photoUrls, saved.photoUrls);
      expect((await firestore.collection('quoteRequests').get()).docs,
          hasLength(1));
    });

    testWidgets('retry after a timeout joins the original pending write', (
      tester,
    ) async {
      final delayed = _DelayedQuoteFirestore();
      final service =
          FirestoreQuoteService(firestore: delayed, photoUploader: uploader);
      final input = _input(
        submissionId: service.newQuoteRequestId(),
        photos: [_photo('pcb.jpg')],
      );
      final timeout = expectLater(
        service.createQuoteRequest(input),
        throwsA(isA<QuoteSubmissionException>()),
      );
      await tester.pump();
      expect(delayed.writes, 1);
      await tester.pump(FirestoreQuoteService.writeTimeout);
      await timeout;

      final retried = service.createQuoteRequest(input, retry: true);
      await tester.pump();
      expect(delayed.writes, 1);
      expect(uploader.uploads, hasLength(1));
      delayed.release.complete();
      await tester.pump();

      expect((await retried).id, input.submissionId);
      expect(
          (await delayed.collection('quoteRequests').get()).docs, hasLength(1));
    });

    test('limits dashboard results and includes recent activity on old quotes',
        () async {
      final quotes = firestore.collection('quoteRequests');
      for (var i = 0; i < 6; i++) {
        final id = 'q$i';
        await quotes.doc(id).set({
          'customerId': 'customer-1',
          'providerId': i == 5 ? 'another-provider' : 'prov-dara-ac',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, i + 1)),
          if (i == 0) 'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 2)),
        });
      }

      final customer = await service.getCustomerQuotePage('customer-1', 2);
      expect(customer.quotes.map((q) => q.id), ['q5', 'q4']);
      expect(customer.hasMore, isTrue);
      final provider =
          await service.watchProviderQuotePage('prov-dara-ac', 2).first;
      expect(provider.quotes.map((q) => q.id), ['q0', 'q4']);
      expect(provider.hasMore, isTrue);
      final expanded =
          await service.watchProviderQuotePage('prov-dara-ac', 5).first;
      expect(expanded.quotes.map((q) => q.id), ['q0', 'q4', 'q3', 'q2', 'q1']);
      expect(expanded.hasMore, isFalse);
    });

    test('uploads photos first and persists quoteRequest in Requested status',
        () async {
      final quote = await service.createQuoteRequest(
        _input(photos: [_photo('pcb.jpg'), _photo('label.png')]),
      );

      expect(uploader.uploads, [
        'quotes/customer-1/${quote.id}/pcb.jpg',
        'quotes/customer-1/${quote.id}/label.png',
      ]);

      final doc =
          await firestore.collection('quoteRequests').doc(quote.id).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['id'], quote.id);
      expect(data['customerId'], 'customer-1');
      expect(data['providerId'], 'prov-dara-ac');
      expect(data['offeringId'], 'off-quote-1');
      expect(data['offeringTitle'], 'Central Inverter PCB Diagnosis');
      expect(data['status'], 'requested');
      expect(data.containsKey('quotedPrice'), isFalse);
      expect(data['photos'], quote.photoUrls);

      final forProvider =
          await service.getProviderQuoteRequests('prov-dara-ac');
      expect(forProvider.map((q) => q.id), [quote.id]);
      expect(await service.getProviderQuoteRequests('other-prov'), isEmpty);
    });

    test('writes no quoteRequest document when photo upload fails', () async {
      final failing = FirestoreQuoteService(
        firestore: firestore,
        photoUploader: _FakePhotoUploader(fail: true),
      );

      await expectLater(
        failing.createQuoteRequest(_input(photos: [_photo('pcb.jpg')])),
        throwsA(isA<QuoteSubmissionException>()),
      );

      final docs = (await firestore.collection('quoteRequests').get()).docs;
      expect(docs, isEmpty);
    });

    test('rejects non-quote offerings before uploading or writing', () async {
      await expectLater(
        service.createQuoteRequest(
          _input(offering: _fixedOffering(), photos: [_photo('pcb.jpg')]),
        ),
        throwsA(isA<InvalidQuoteRequestException>()),
      );

      expect(uploader.uploads, isEmpty);
      expect((await firestore.collection('quoteRequests').get()).docs, isEmpty);
    });

    test('streams owned quote decisions and prices only for the target provider',
        () async {
      await firestore.collection('quoteRequests').doc('q-approved').set({
        'id': 'q-approved',
        'customerId': 'customer-1',
        'customerName': 'Sophea Meas',
        'providerId': 'prov-dara-ac',
        'providerName': 'Dara Chhum',
        'offeringId': 'off-quote-1',
        'offeringTitle': 'Central Inverter PCB Diagnosis',
        'description': 'Inverter board clicks repeatedly and blinks E5.',
        'status': 'approved',
        'quotedPrice': 85.0,
        'createdAt': DateTime(2026, 11, 27, 9, 0).toIso8601String(),
      });
      await firestore.collection('quoteRequests').doc('q-other').set({
        'id': 'q-other',
        'customerId': 'customer-2',
        'providerId': 'other-provider',
        'providerName': 'Other Provider',
        'offeringId': 'off-quote-2',
        'offeringTitle': 'Other AC Service',
        'description': 'Other provider quote request description.',
        'status': 'rejected',
        'quotedPrice': 120.0,
        'createdAt': DateTime(2026, 11, 27, 10, 0).toIso8601String(),
      });

      final owned = await service.watchProviderQuoteRequests('prov-dara-ac').first;
      expect(owned, hasLength(1));
      expect(owned.single.id, 'q-approved');
      expect(owned.single.status, QuoteStatus.approved);
      expect(owned.single.quotedPrice, 85.0);

      final other =
          await service.watchProviderQuoteRequests('other-provider').first;
      expect(other, hasLength(1));
      expect(other.single.id, 'q-other');
      expect(other.single.status, QuoteStatus.rejected);
      expect(other.single.quotedPrice, 120.0);

      final detail = await service
          .watchProviderQuoteRequest('prov-dara-ac', 'q-approved')
          .first;
      expect(detail?.id, 'q-approved');
      expect(
        await service
            .watchProviderQuoteRequest('prov-dara-ac', 'q-other')
            .first,
        isNull,
      );
    });
  });
}
