import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/services/firestore_booking_service.dart';

/// Resolves the active customer ID from authentication state, falling back
/// to [BookingService.defaultCustomerId] in standalone widget tests.
final activeCustomerIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id ?? BookingService.defaultCustomerId;
});

/// Provides the active [IBookingService] instance.
///
/// The running app saves bookings in Firestore (US-12 Definition of Done).
/// When Firebase is not initialised, as in widget tests, it falls back to the
/// in-memory [BookingService] and its sample bookings.
final bookingServiceProvider = Provider<IBookingService>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreBookingService();
  }
  final customerId = ref.watch(activeCustomerIdProvider);
  return BookingService(customerId: customerId);
});

/// Fetches all repair bookings belonging to the active customer.
final customerBookingsProvider =
    FutureProvider.autoDispose<List<BookingModel>>((ref) async {
      final service = ref.watch(bookingServiceProvider);
      final customerId = ref.watch(activeCustomerIdProvider);
      return service.getCustomerBookings(customerId);
    });

/// Fetches a single booking by its unique ID.
final bookingDetailProvider =
    FutureProvider.autoDispose.family<BookingModel?, String>((
      ref,
      bookingId,
    ) async {
      final service = ref.watch(bookingServiceProvider);
      return service.getBookingById(bookingId);
    });

/// Emits live updates whenever the booking status changes in Firestore or in-memory.
///
/// Implements US-13 (SCRUM-44) AC #3 and DoD #2.
final liveBookingDetailProvider =
    StreamProvider.autoDispose.family<BookingModel?, String>((
      ref,
      bookingId,
    ) {
      final service = ref.watch(bookingServiceProvider);
      return service.watchBookingById(bookingId);
    });

/// Fetches all repair bookings addressed to [providerId] (BOOK-2 / SCRUM-104).
final providerBookingsProvider =
    FutureProvider.autoDispose.family<List<BookingModel>, String>((
      ref,
      providerId,
    ) async {
      final service = ref.watch(bookingServiceProvider);
      return service.getProviderBookings(providerId);
    });

/// Emits live updates for all bookings addressed to [providerId].
final liveProviderBookingsProvider =
    StreamProvider.autoDispose.family<List<BookingModel>, String>((
      ref,
      providerId,
    ) {
      final service = ref.watch(bookingServiceProvider);
      return service.watchProviderBookings(providerId);
    });
