import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';

/// Resolves the active customer ID from authentication state, falling back
/// to [BookingService.defaultCustomerId] in standalone widget tests.
final activeCustomerIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id ?? BookingService.defaultCustomerId;
});

/// Provides the active [IBookingService] instance.
final bookingServiceProvider = Provider<IBookingService>((ref) {
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
