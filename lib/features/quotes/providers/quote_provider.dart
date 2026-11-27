import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
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
    FutureProvider.autoDispose.family<QuoteRequestPage, int>((ref, size) async {
  final service = ref.watch(quoteServiceProvider);
  final customerId = ref.watch(activeCustomerIdProvider);
  return service.getCustomerQuotePage(customerId, size);
});

String? _quoteInboxProviderId(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.canViewBookingInbox != true) return null;
  final providerId = ref.watch(currentProviderIdProvider);
  return providerId.isEmpty ? null : providerId;
}

/// Watches incoming requests for the signed-in provider's inbox.
final liveProviderQuoteRequestsProvider =
    StreamProvider.autoDispose.family<QuoteRequestPage, int>((ref, size) {
  final providerId = _quoteInboxProviderId(ref);
  if (providerId == null) return Stream.value(const QuoteRequestPage.empty());
  final service = ref.watch(quoteServiceProvider);
  return service.watchProviderQuotePage(providerId, size);
});

/// Watches one incoming request in the signed-in provider's inbox.
final liveProviderQuoteDetailProvider =
    StreamProvider.autoDispose.family<QuoteRequestModel?, String>(
  (ref, quoteId) {
    final providerId = _quoteInboxProviderId(ref);
    if (providerId == null || quoteId.isEmpty) return Stream.value(null);
    final service = ref.watch(quoteServiceProvider);
    return service.watchProviderQuoteRequest(providerId, quoteId);
  },
);

/// Confirms a saved quote request belongs to the active customer.
final quoteDetailProvider =
    FutureProvider.autoDispose.family<QuoteRequestModel?, String>(
  (ref, quoteId) async {
    final service = ref.watch(quoteServiceProvider);
    final customerId = ref.watch(activeCustomerIdProvider);
    final quote = await service.getQuoteRequestById(quoteId);
    return quote?.isOwnedByCustomer(customerId) == true ? quote : null;
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
