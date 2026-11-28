import 'dart:async';

import 'package:service_pilot/features/quotes/models/quote_request_input.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/models/quote_status.dart';

/// Thrown when a quote request violates field or offering rules.
class InvalidQuoteRequestException implements Exception {
  InvalidQuoteRequestException(this.errors) : assert(errors.isNotEmpty);

  final List<QuoteFieldError> errors;

  @override
  String toString() =>
      'InvalidQuoteRequestException(${errors.map((e) => e.name).join(', ')})';
}

/// Thrown when saving a quote request or uploading its photos fails.
class QuoteSubmissionException implements Exception {
  const QuoteSubmissionException(this.message);

  final String message;

  @override
  String toString() => 'QuoteSubmissionException: $message';
}

/// Thrown when a quote request does not exist (or is not readable).
class QuoteNotFoundException implements Exception {
  const QuoteNotFoundException(this.quoteId);

  final String quoteId;

  @override
  String toString() => 'QuoteNotFoundException($quoteId)';
}

/// Thrown when the signed-in account may not act on a quote request:
/// another provider pricing it (QUOTE-3) or another homeowner approving it
/// (QUOTE-4). The record is left unchanged.
class UnauthorizedQuoteActionException implements Exception {
  const UnauthorizedQuoteActionException(this.quoteId);

  final String quoteId;

  @override
  String toString() => 'UnauthorizedQuoteActionException($quoteId)';
}

/// Thrown when a quote request is not in the status an action needs, for
/// example pricing a request that is already Quoted, or approving one that
/// has no price yet. The record is left unchanged.
class InvalidQuoteStateException implements Exception {
  const InvalidQuoteStateException(this.quoteId, this.status);

  final String quoteId;
  final QuoteStatus status;

  @override
  String toString() =>
      'InvalidQuoteStateException($quoteId, status: ${status.value})';
}

/// Thrown when a provider's price breaks [QuotePriceValidator].
class InvalidQuotePriceException implements Exception {
  const InvalidQuotePriceException(this.error);

  final QuotePriceError error;

  @override
  String toString() => 'InvalidQuotePriceException(${error.name})';
}

const quotePageSize = 20;

class QuoteRequestPage {
  const QuoteRequestPage.empty()
      : quotes = const [],
        hasMore = false;

  QuoteRequestPage(List<QuoteRequestModel> candidates, int size)
      : quotes = List.unmodifiable(candidates.take(size)),
        hasMore = candidates.length > size;

  final List<QuoteRequestModel> quotes;
  final bool hasMore;
}

int compareQuoteActivity(QuoteRequestModel a, QuoteRequestModel b) {
  final byDate = _quoteActivityAt(b).compareTo(_quoteActivityAt(a));
  return byDate == 0 ? b.id.compareTo(a.id) : byDate;
}

DateTime _quoteActivityAt(QuoteRequestModel quote) {
  final updated = quote.updatedAt;
  return updated != null && updated.isAfter(quote.createdAt)
      ? updated
      : quote.createdAt;
}

/// Contract for submitting and reading separate quote requests (QUOTE-1).
abstract class IQuoteService {
  String newQuoteRequestId();
  Future<QuoteRequestModel> createQuoteRequest(
    QuoteRequestInput request, {
    bool retry = false,
  });

  Future<List<QuoteRequestModel>> getCustomerQuoteRequests(String customerId);

  Future<List<QuoteRequestModel>> getProviderQuoteRequests(String providerId);
  Future<QuoteRequestPage> getCustomerQuotePage(String customerId, int size);
  Stream<QuoteRequestPage> watchProviderQuotePage(String providerId, int size);

  Stream<List<QuoteRequestModel>> watchProviderQuoteRequests(String providerId);
  Stream<QuoteRequestModel?> watchProviderQuoteRequest(
    String providerId,
    String quoteId,
  );

  Future<QuoteRequestModel?> getQuoteRequestById(String quoteId);

  Stream<QuoteRequestModel?> watchQuoteRequestById(String quoteId);

  /// QUOTE-3 (SCRUM-85): the addressed provider saves [price] on a
  /// `Requested` record and moves it to `Quoted`.
  ///
  /// Throws [InvalidQuotePriceException], [QuoteNotFoundException],
  /// [UnauthorizedQuoteActionException] or [InvalidQuoteStateException];
  /// in each case nothing is saved.
  Future<QuoteRequestModel> submitQuotePrice({
    required String quoteId,
    required String providerId,
    required double price,
  });

  /// QUOTE-4 (SCRUM-86): the requesting homeowner approves the quoted price.
  /// The agreed amount ([QuoteRequestModel.approvedPrice]) and `Approved`
  /// status are recorded together.
  ///
  /// Throws [QuoteNotFoundException], [UnauthorizedQuoteActionException] or
  /// [InvalidQuoteStateException]; in each case nothing is saved.
  Future<QuoteRequestModel> approveQuote({
    required String quoteId,
    required String customerId,
  });
}

/// Applies the QUOTE-3 checks to [quote]. Shared by both implementations so
/// in-memory tests and Firestore enforce the same rules.
QuoteRequestModel applyQuotePrice(
  QuoteRequestModel? quote, {
  required String quoteId,
  required String providerId,
  required double price,
  required DateTime now,
}) {
  final priceError = QuotePriceValidator.validate(price);
  if (priceError != null) throw InvalidQuotePriceException(priceError);
  if (quote == null) throw QuoteNotFoundException(quoteId);
  if (!quote.isAddressedToProvider(providerId)) {
    throw UnauthorizedQuoteActionException(quoteId);
  }
  if (!quote.canBeQuotedBy(providerId)) {
    throw InvalidQuoteStateException(quoteId, quote.status);
  }
  return quote.copyWith(
    status: QuoteStatus.quoted,
    quotedPrice: price,
    quotedAt: now,
    updatedAt: now,
  );
}

/// Applies the QUOTE-4 checks to [quote].
QuoteRequestModel applyQuoteApproval(
  QuoteRequestModel? quote, {
  required String quoteId,
  required String customerId,
  required DateTime now,
}) {
  if (quote == null) throw QuoteNotFoundException(quoteId);
  if (!quote.isOwnedByCustomer(customerId)) {
    throw UnauthorizedQuoteActionException(quoteId);
  }
  if (!quote.canBeApprovedBy(customerId)) {
    throw InvalidQuoteStateException(quoteId, quote.status);
  }
  return quote.copyWith(
    status: QuoteStatus.approved,
    approvedPrice: quote.quotedPrice,
    approvedAt: now,
    updatedAt: now,
  );
}

/// In-memory quote request store used in standalone widget and unit tests.
class InMemoryQuoteService implements IQuoteService {
  InMemoryQuoteService({List<QuoteRequestModel>? initialQuotes})
      : _quotes = List<QuoteRequestModel>.from(initialQuotes ?? const []);

  final List<QuoteRequestModel> _quotes;
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  @override
  String newQuoteRequestId() => 'qr-${_nextId++}';

  @override
  Future<QuoteRequestModel> createQuoteRequest(
    QuoteRequestInput request, {
    bool retry = false,
  }) async {
    final errors = QuoteRequestValidator.validate(request);
    if (errors.isNotEmpty) {
      throw InvalidQuoteRequestException(errors);
    }

    final id = request.submissionId ?? newQuoteRequestId();
    for (final existing in _quotes.where((quote) => quote.id == id)) {
      if (retry && matchesQuoteSubmission(existing, request)) return existing;
      throw const QuoteSubmissionException(
          'Quote request ID is already in use.');
    }
    final quote = QuoteRequestModel(
      id: id,
      customerId: request.customerId,
      customerName: request.customerName?.trim(),
      providerId: request.providerId,
      providerName: request.providerName,
      offeringId: request.offering.id,
      offeringTitle: request.offering.title.trim(),
      categoryId: request.offering.categoryId,
      categoryName: request.offering.categoryName,
      description: request.description.trim(),
      photoUrls: [
        for (var i = 0; i < request.photos.length; i++)
          'memory://quote/$id/${i + 1}_${request.photos[i].name}',
      ],
      status: QuoteStatus.requested,
      createdAt: DateTime.now(),
    );

    _quotes.insert(0, quote);
    _changes.add(null);
    return quote;
  }

  @override
  Future<List<QuoteRequestModel>> getCustomerQuoteRequests(
    String customerId,
  ) async {
    return List.unmodifiable(
      _quotes.where((q) => q.isOwnedByCustomer(customerId)),
    );
  }

  @override
  Future<List<QuoteRequestModel>> getProviderQuoteRequests(
    String providerId,
  ) async {
    return List.unmodifiable(
      _quotes.where((q) => q.isAddressedToProvider(providerId)),
    );
  }

  @override
  Future<QuoteRequestPage> getCustomerQuotePage(
      String customerId, int size) async {
    final quotes =
        _quotes.where((q) => q.isOwnedByCustomer(customerId)).toList()
          ..sort((a, b) {
            final byDate = b.createdAt.compareTo(a.createdAt);
            return byDate == 0 ? b.id.compareTo(a.id) : byDate;
          });
    return QuoteRequestPage(quotes, size);
  }

  @override
  Stream<QuoteRequestPage> watchProviderQuotePage(String providerId, int size) {
    return watchProviderQuoteRequests(providerId).map((quotes) {
      final ordered = quotes.toList()..sort(compareQuoteActivity);
      return QuoteRequestPage(ordered, size);
    });
  }

  @override
  Stream<List<QuoteRequestModel>> watchProviderQuoteRequests(
    String providerId,
  ) async* {
    yield await getProviderQuoteRequests(providerId);
    await for (final _ in _changes.stream) {
      yield await getProviderQuoteRequests(providerId);
    }
  }

  @override
  Stream<QuoteRequestModel?> watchProviderQuoteRequest(
    String providerId,
    String quoteId,
  ) {
    return watchQuoteRequestById(quoteId).map((quote) {
      return quote?.isAddressedToProvider(providerId) == true ? quote : null;
    });
  }

  @override
  Future<QuoteRequestModel?> getQuoteRequestById(String quoteId) async {
    for (final quote in _quotes) {
      if (quote.id == quoteId) return quote;
    }
    return null;
  }

  @override
  Stream<QuoteRequestModel?> watchQuoteRequestById(String quoteId) async* {
    yield await getQuoteRequestById(quoteId);
    await for (final _ in _changes.stream) {
      yield await getQuoteRequestById(quoteId);
    }
  }

  @override
  Future<QuoteRequestModel> submitQuotePrice({
    required String quoteId,
    required String providerId,
    required double price,
  }) async {
    final updated = applyQuotePrice(
      await getQuoteRequestById(quoteId),
      quoteId: quoteId,
      providerId: providerId,
      price: price,
      now: DateTime.now(),
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<QuoteRequestModel> approveQuote({
    required String quoteId,
    required String customerId,
  }) async {
    final updated = applyQuoteApproval(
      await getQuoteRequestById(quoteId),
      quoteId: quoteId,
      customerId: customerId,
      now: DateTime.now(),
    );
    _replace(updated);
    return updated;
  }

  /// Records that [bookingId] was created from [quoteId] (QUOTE-5). The
  /// Firestore service writes the link in the booking transaction; tests that
  /// pair this store with the in-memory booking service call it directly.
  void linkBooking(String quoteId, String bookingId) {
    final index = _quotes.indexWhere((quote) => quote.id == quoteId);
    if (index == -1) return;
    _replace(_quotes[index].copyWith(
      bookingId: bookingId,
      updatedAt: DateTime.now(),
    ));
  }

  void _replace(QuoteRequestModel quote) {
    final index = _quotes.indexWhere((existing) => existing.id == quote.id);
    if (index == -1) return;
    _quotes[index] = quote;
    _changes.add(null);
  }
}

bool matchesQuoteSubmission(QuoteRequestModel quote, QuoteRequestInput input) =>
    quote.isOwnedByCustomer(input.customerId) &&
    quote.providerId == input.providerId &&
    quote.offeringId == input.offering.id &&
    quote.description == input.description.trim();
