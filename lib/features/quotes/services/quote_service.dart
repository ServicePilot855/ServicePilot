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

/// Contract for submitting and reading separate quote requests (QUOTE-1).
abstract class IQuoteService {
  Future<QuoteRequestModel> createQuoteRequest(QuoteRequestInput request);

  Future<List<QuoteRequestModel>> getCustomerQuoteRequests(String customerId);

  Future<List<QuoteRequestModel>> getProviderQuoteRequests(String providerId);

  Future<QuoteRequestModel?> getQuoteRequestById(String quoteId);

  Stream<QuoteRequestModel?> watchQuoteRequestById(String quoteId);
}

/// In-memory quote request store used in standalone widget and unit tests.
class InMemoryQuoteService implements IQuoteService {
  InMemoryQuoteService({List<QuoteRequestModel>? initialQuotes})
      : _quotes = List<QuoteRequestModel>.from(initialQuotes ?? const []);

  final List<QuoteRequestModel> _quotes;
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  @override
  Future<QuoteRequestModel> createQuoteRequest(QuoteRequestInput request) async {
    final errors = QuoteRequestValidator.validate(request);
    if (errors.isNotEmpty) {
      throw InvalidQuoteRequestException(errors);
    }

    final id = 'qr-${_nextId++}';
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
}
