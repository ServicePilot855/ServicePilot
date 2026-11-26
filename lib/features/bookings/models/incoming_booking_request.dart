import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';

/// Job and scheduling details a provider can see before accepting a request.
class IncomingBookingRequest {
  const IncomingBookingRequest({
    required this.id,
    required this.serviceTitle,
    required this.description,
    required this.appointmentDate,
  });

  final String id;
  final String serviceTitle;
  final String description;
  final DateTime? appointmentDate;

  factory IncomingBookingRequest.fromBooking(BookingModel booking) {
    return IncomingBookingRequest(
      id: booking.id,
      serviceTitle: booking.serviceTitle,
      description: booking.description,
      appointmentDate: booking.preferredDateTime,
    );
  }

  factory IncomingBookingRequest.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final date = data['appointmentDate'];
    return IncomingBookingRequest(
      id: id,
      serviceTitle: data['serviceTitle'] as String,
      description: data['description'] as String,
      appointmentDate: switch (date) {
        Timestamp() => date.toDate(),
        String() => DateTime.tryParse(date),
        _ => null,
      },
    );
  }

  Map<String, dynamic> toFirestore() => {
        'serviceTitle': serviceTitle,
        'description': description,
        'appointmentDate': appointmentDate == null
            ? null
            : Timestamp.fromDate(appointmentDate!),
      };
}
