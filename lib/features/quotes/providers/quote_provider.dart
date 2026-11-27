import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/quotes/models/quote_request_model.dart';
import 'package:service_pilot/features/quotes/services/firestore_quote_service.dart';
import 'package:service_pilot/features/quotes/services/quote_service.dart';

/// Provides the active [IQuoteService] instance.
///
/// Uses [FirestoreQuoteService] when Firebase is initialized and falls back
/// to [InMemoryQuoteService] in standalone widget tests.
final quoteServiceProvider = Provider<IQuoteService>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreQuoteService();
  }
  return InMemoryQuoteService();
});

/// Fetches quote requests created by the active customer.
final customerQuoteRequestsProvider =
    FutureProvider.autoDispose<List<QuoteRequestModel>>((ref) async {
  final service = ref.watch(quoteServiceProvider);
  final customerId = ref.watch(activeCustomerIdProvider);
  return service.getCustomerQuoteRequests(customerId);
});

/// Fetches quote requests addressed to [providerId].
final providerQuoteRequestsProvider =
    FutureProvider.autoDispose.family<List<QuoteRequestModel>, String>(
  (ref, providerId) async {
    final service = ref.watch(quoteServiceProvider);
    return service.getProviderQuoteRequests(providerId);
  },
);

/// Watches live quote requests addressed to [providerId].
final liveProviderQuoteRequestsProvider =
    StreamProvider.autoDispose.family<List<QuoteRequestModel>, String>(
  (ref, providerId) {
    final service = ref.watch(quoteServiceProvider);
    return service.watchProviderQuoteRequests(providerId);
  },
);

/// Fetches a single quote request by ID.
final quoteDetailProvider =
    FutureProvider.autoDispose.family<QuoteRequestModel?, String>(
  (ref, quoteId) async {
    final service = ref.watch(quoteServiceProvider);
    return service.getQuoteRequestById(quoteId);
  },
);

/// Watches live updates for a single quote request by ID.
final liveQuoteDetailProvider =
    StreamProvider.autoDispose.family<QuoteRequestModel?, String>(
  (ref, quoteId) {
    final service = ref.watch(quoteServiceProvider);
    return service.watchQuoteRequestById(quoteId);
  },
);
