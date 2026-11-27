import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_request.dart';
import 'package:service_pilot/features/bookings/models/quote_booking_request.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';
import 'package:service_pilot/features/quotes/services/firestore_quote_service.dart';
import 'package:service_pilot/features/quotes/services/quote_service.dart';

const _customer = 'customer-1';
const _provider = 'prov-ind-1';

QuoteRequestModel _quote({
  String id = 'q-1',
  QuoteStatus status = QuoteStatus.requested,
  double? quotedPrice,
  double? approvedPrice,
  String? bookingId,
  String customerId = _customer,
  String providerId = _provider,
}) {
  return QuoteRequestModel(
    id: id,
    customerId: customerId,
    customerName: 'Sophea Meas',
    providerId: providerId,
    providerName: 'Dara Chhum',
    offeringId: 'off-quote-1',
    offeringTitle: 'Central Inverter PCB Diagnosis',
    categoryName: 'Air Conditioning',
    description: 'Inverter board clicks repeatedly and blinks E5.',
    photoUrls: const ['https://res.cloudinary.com/demo/image/upload/pcb.jpg'],
    status: status,
    quotedPrice: quotedPrice,
    approvedPrice: approvedPrice,
    bookingId: bookingId,
    createdAt: DateTime(2026, 11, 27, 9),
  );
}

QuoteRequestModel _approved({String id = 'q-1', String? bookingId}) => _quote(
      id: id,
      status: QuoteStatus.approved,
      quotedPrice: 85,
      approvedPrice: 85,
      bookingId: bookingId,
    );

QuoteBookingRequest _bookingRequest({
  String quoteId = 'q-1',
  String customerId = _customer,
  String address = 'House 12, Street 271, Toul Kork, Phnom Penh',
  DateTime? when,
}) {
  return QuoteBookingRequest(
    quoteId: quoteId,
    customerId: customerId,
    address: address,
    preferredDateTime:
        when ?? DateTime.now().add(const Duration(days: 2, hours: 3)),
  );
}

void main() {
  group('QUOTE-3 / SCRUM-85: price input rules', () {
    test('accepts a positive USD amount with up to two decimals', () {
      expect(QuotePriceValidator.validateInput('85'), isNull);
      expect(QuotePriceValidator.validateInput(r'$45.50'), isNull);
      expect(QuotePriceValidator.parse(' 45.50 '), 45.5);
    });

    test('refuses empty, zero, negative and over-precise amounts', () {
      expect(QuotePriceValidator.validateInput(''), QuotePriceError.required);
      expect(
          QuotePriceValidator.validateInput('abc'), QuotePriceError.required);
      expect(QuotePriceValidator.validateInput('0'), QuotePriceError.invalid);
      expect(QuotePriceValidator.validateInput('-5'), QuotePriceError.invalid);
      expect(
          QuotePriceValidator.validateInput('12.345'), QuotePriceError.invalid);
    });

    test('formats every quote amount the same way', () {
      expect(formatQuoteAmount(85), r'$85.00');
      expect(formatQuoteAmount(45.5), r'$45.50');
    });
  });

  group('QUOTE-3 / QUOTE-4: InMemoryQuoteService transitions', () {
    test('the addressed provider moves a Requested record to Quoted', () async {
      final service = InMemoryQuoteService(initialQuotes: [_quote()]);

      final quoted = await service.submitQuotePrice(
        quoteId: 'q-1',
        providerId: _provider,
        price: 85,
      );

      expect(quoted.status, QuoteStatus.quoted);
      expect(quoted.quotedPrice, 85);
      expect(quoted.quotedAt, isNotNull);
      final stored = await service.getQuoteRequestById('q-1');
      expect(stored!.status, QuoteStatus.quoted);
    });

    test('another provider, a bad price or a priced record changes nothing',
        () async {
      final service = InMemoryQuoteService(initialQuotes: [
        _quote(),
        _quote(id: 'q-2', status: QuoteStatus.quoted, quotedPrice: 40),
      ]);

      await expectLater(
        service.submitQuotePrice(
            quoteId: 'q-1', providerId: 'prov-other', price: 85),
        throwsA(isA<UnauthorizedQuoteActionException>()),
      );
      await expectLater(
        service.submitQuotePrice(
            quoteId: 'q-1', providerId: _provider, price: 0),
        throwsA(isA<InvalidQuotePriceException>()),
      );
      await expectLater(
        service.submitQuotePrice(
            quoteId: 'q-2', providerId: _provider, price: 99),
        throwsA(isA<InvalidQuoteStateException>()),
      );
      await expectLater(
        service.submitQuotePrice(
            quoteId: 'missing', providerId: _provider, price: 85),
        throwsA(isA<QuoteNotFoundException>()),
      );

      expect((await service.getQuoteRequestById('q-1'))!.status,
          QuoteStatus.requested);
      expect((await service.getQuoteRequestById('q-2'))!.quotedPrice, 40);
    });

    test('the homeowner approval records the agreed amount', () async {
      final service = InMemoryQuoteService(initialQuotes: [
        _quote(status: QuoteStatus.quoted, quotedPrice: 85),
      ]);

      final approved =
          await service.approveQuote(quoteId: 'q-1', customerId: _customer);

      expect(approved.status, QuoteStatus.approved);
      expect(approved.approvedPrice, 85);
      expect(approved.approvedAt, isNotNull);
    });

    test('other accounts and unpriced requests cannot be approved', () async {
      final service = InMemoryQuoteService(initialQuotes: [
        _quote(status: QuoteStatus.quoted, quotedPrice: 85),
        _quote(id: 'q-2'),
      ]);

      await expectLater(
        service.approveQuote(quoteId: 'q-1', customerId: 'customer-2'),
        throwsA(isA<UnauthorizedQuoteActionException>()),
      );
      await expectLater(
        service.approveQuote(quoteId: 'q-2', customerId: _customer),
        throwsA(isA<InvalidQuoteStateException>()),
      );
      expect((await service.getQuoteRequestById('q-1'))!.status,
          QuoteStatus.quoted);
      expect((await service.getQuoteRequestById('q-1'))!.approvedPrice, isNull);
    });
  });

  group('QUOTE-3 / QUOTE-4: FirestoreQuoteService transitions', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreQuoteService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreQuoteService(firestore: firestore);
    });

    Future<Map<String, dynamic>> stored(String id) async =>
        (await firestore.collection('quoteRequests').doc(id).get()).data()!;

    test('price then approval are saved on the same record', () async {
      await firestore
          .collection('quoteRequests')
          .doc('q-1')
          .set(_quote().toFirestore());

      await service.submitQuotePrice(
          quoteId: 'q-1', providerId: _provider, price: 85);
      var data = await stored('q-1');
      expect(data['status'], 'quoted');
      expect(data['quotedPrice'], 85);
      expect(data['quotedAt'], isNotNull);

      await service.approveQuote(quoteId: 'q-1', customerId: _customer);
      data = await stored('q-1');
      expect(data['status'], 'approved');
      expect(data['approvedPrice'], 85);
      expect(data['approvedAt'], isNotNull);
    });

    test('refused transitions leave the stored record as it was', () async {
      await firestore
          .collection('quoteRequests')
          .doc('q-1')
          .set(_quote().toFirestore());

      await expectLater(
        service.submitQuotePrice(
            quoteId: 'q-1', providerId: 'prov-other', price: 85),
        throwsA(isA<UnauthorizedQuoteActionException>()),
      );
      await expectLater(
        service.submitQuotePrice(
            quoteId: 'q-1', providerId: _provider, price: -1),
        throwsA(isA<InvalidQuotePriceException>()),
      );
      await expectLater(
        service.approveQuote(quoteId: 'q-1', customerId: _customer),
        throwsA(isA<InvalidQuoteStateException>()),
      );

      final data = await stored('q-1');
      expect(data['status'], 'requested');
      expect(data.containsKey('quotedPrice'), isFalse);
      expect(data.containsKey('approvedPrice'), isFalse);
    });
  });

  group('QUOTE-5 / SCRUM-87: approval gate', () {
    test('only an owned, approved, unbooked quote can be booked', () {
      expect(quoteBookingBlock(_approved(), _customer), isNull);
      expect(quoteBookingBlock(null, _customer), QuoteBookingBlock.notFound);
      expect(quoteBookingBlock(_approved(), 'customer-2'),
          QuoteBookingBlock.notOwner);
      expect(
        quoteBookingBlock(
            _quote(status: QuoteStatus.quoted, quotedPrice: 85), _customer),
        QuoteBookingBlock.notApproved,
      );
      expect(quoteBookingBlock(_quote(), _customer),
          QuoteBookingBlock.notApproved);
      expect(
        quoteBookingBlock(
            _quote(status: QuoteStatus.rejected, quotedPrice: 85), _customer),
        QuoteBookingBlock.notApproved,
      );
      expect(quoteBookingBlock(_approved(bookingId: 'bk-1'), _customer),
          QuoteBookingBlock.alreadyBooked);
    });

    test('address and time are checked like the booking form', () {
      expect(_bookingRequest().validate(), isEmpty);
      expect(
        _bookingRequest(address: '', when: DateTime(2020)).validate(),
        hasLength(2),
      );
    });
  });

  group('QUOTE-5 / SCRUM-87: BookingService.createQuoteBooking', () {
    late InMemoryQuoteService quotes;
    late BookingService bookings;

    setUp(() {
      quotes = InMemoryQuoteService(initialQuotes: [
        _approved(),
        _quote(id: 'q-quoted', status: QuoteStatus.quoted, quotedPrice: 60),
      ]);
      bookings = BookingService(
        initialBookings: const [],
        customerId: _customer,
        findQuote: quotes.getQuoteRequestById,
        onQuoteBooked: quotes.linkBooking,
      );
    });

    tearDown(() => bookings.dispose());

    test('creates a Pending booking with the approved price and links',
        () async {
      final booking = await bookings.createQuoteBooking(_bookingRequest());

      expect(booking.status, BookingStatus.pending);
      expect(booking.totalPrice, 85);
      expect(booking.quoteId, 'q-1');
      expect(booking.isFromQuote, isTrue);
      expect(booking.providerId, _provider);
      expect(booking.providerName, 'Dara Chhum');
      expect(booking.customerId, _customer);
      expect(booking.serviceTitle, 'Central Inverter PCB Diagnosis');
      expect(booking.photoUrls, hasLength(1));
      expect((await quotes.getQuoteRequestById('q-1'))!.bookingId, booking.id);
    });

    test('an unapproved quote cannot enter the booking flow', () async {
      await expectLater(
        bookings.createQuoteBooking(_bookingRequest(quoteId: 'q-quoted')),
        throwsA(isA<QuoteNotBookableException>()
            .having((e) => e.reason, 'reason', QuoteBookingBlock.notApproved)),
      );
      expect(await bookings.getCustomerBookings(_customer), isEmpty);
    });

    test('another homeowner cannot book the quote', () async {
      await expectLater(
        bookings.createQuoteBooking(_bookingRequest(customerId: 'customer-2')),
        throwsA(isA<QuoteNotBookableException>()
            .having((e) => e.reason, 'reason', QuoteBookingBlock.notOwner)),
      );
    });

    test('a quote is booked once and points to the existing booking', () async {
      final first = await bookings.createQuoteBooking(_bookingRequest());

      await expectLater(
        bookings.createQuoteBooking(_bookingRequest()),
        throwsA(isA<QuoteNotBookableException>()
            .having((e) => e.reason, 'reason', QuoteBookingBlock.alreadyBooked)
            .having((e) => e.bookingId, 'bookingId', first.id)),
      );
      expect(await bookings.getCustomerBookings(_customer), hasLength(1));
    });

    test('invalid address or time saves nothing', () async {
      await expectLater(
        bookings.createQuoteBooking(_bookingRequest(address: ' ')),
        throwsA(isA<InvalidBookingRequestException>().having(
          (e) => e.errors,
          'errors',
          contains(BookingFieldError.addressRequired),
        )),
      );
      expect(await bookings.getCustomerBookings(_customer), isEmpty);
    });
  });

  group('QUOTE-5 / SCRUM-87: FirestoreBookingService.createQuoteBooking', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreBookingService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreBookingService(firestore: firestore);
    });

    Future<void> seed(QuoteRequestModel quote) => firestore
        .collection('quoteRequests')
        .doc(quote.id)
        .set(quote.toFirestore());

    test('writes the booking, the provider preview and the quote link together',
        () async {
      await seed(_approved());

      final booking = await service.createQuoteBooking(_bookingRequest());

      final saved =
          (await firestore.collection('bookings').doc(booking.id).get())
              .data()!;
      expect(saved['status'], 'pending');
      expect(saved['totalPrice'], 85);
      expect(saved['quoteId'], 'q-1');
      expect(saved['providerId'], _provider);
      expect(saved['customerId'], _customer);

      final preview = await firestore
          .collection('providers')
          .doc(_provider)
          .collection('incomingBookingRequests')
          .doc(booking.id)
          .get();
      expect(preview.exists, isTrue);

      final quote =
          (await firestore.collection('quoteRequests').doc('q-1').get())
              .data()!;
      expect(quote['bookingId'], booking.id);
      expect(quote['status'], 'approved');
    });

    test('refuses unapproved, foreign and already booked quotes', () async {
      await seed(
          _quote(id: 'q-quoted', status: QuoteStatus.quoted, quotedPrice: 60));
      await seed(_approved(id: 'q-booked', bookingId: 'bk-existing'));
      await seed(_approved(id: 'q-1'));

      await expectLater(
        service.createQuoteBooking(_bookingRequest(quoteId: 'q-quoted')),
        throwsA(isA<QuoteNotBookableException>()
            .having((e) => e.reason, 'reason', QuoteBookingBlock.notApproved)),
      );
      await expectLater(
        service.createQuoteBooking(_bookingRequest(quoteId: 'q-booked')),
        throwsA(isA<QuoteNotBookableException>()
            .having((e) => e.reason, 'reason', QuoteBookingBlock.alreadyBooked)
            .having((e) => e.bookingId, 'bookingId', 'bk-existing')),
      );
      await expectLater(
        service.createQuoteBooking(_bookingRequest(customerId: 'customer-2')),
        throwsA(isA<QuoteNotBookableException>()
            .having((e) => e.reason, 'reason', QuoteBookingBlock.notOwner)),
      );
      await expectLater(
        service.createQuoteBooking(_bookingRequest(quoteId: 'missing')),
        throwsA(isA<QuoteNotBookableException>()
            .having((e) => e.reason, 'reason', QuoteBookingBlock.notFound)),
      );

      expect((await firestore.collection('bookings').get()).docs, isEmpty);
    });
  });
}
