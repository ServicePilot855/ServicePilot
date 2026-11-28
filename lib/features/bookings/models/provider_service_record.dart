import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/models/incoming_booking_request.dart';

/// Closed service history entry displayed to a provider (`Completed`,
/// `Cancelled`, or `Declined`) in BOOK-5 (SCRUM-90).
class ProviderServiceRecord {
  const ProviderServiceRecord({
    required this.id,
    required this.providerId,
    required this.serviceTitle,
    required this.status,
    this.appointmentDate,
    this.description = '',
    this.assignedTechnicianName,
    this.totalPrice,
    this.booking,
  });

  final String id;
  final String providerId;
  final String serviceTitle;
  final BookingStatus status;
  final DateTime? appointmentDate;
  final String description;
  final String? assignedTechnicianName;
  final double? totalPrice;
  final BookingModel? booking;

  factory ProviderServiceRecord.fromBooking(BookingModel booking) {
    return ProviderServiceRecord(
      id: booking.id,
      providerId: booking.providerId,
      serviceTitle: booking.serviceTitle,
      status: booking.status,
      appointmentDate: booking.confirmedAppointmentAt ?? booking.preferredDateTime,
      description: booking.description,
      assignedTechnicianName: booking.assignedTechnicianName,
      totalPrice: booking.totalPrice,
      booking: booking,
    );
  }

  factory ProviderServiceRecord.fromPreview(
    IncomingBookingRequest preview, {
    required String providerId,
    required BookingStatus status,
  }) {
    return ProviderServiceRecord(
      id: preview.id,
      providerId: providerId,
      serviceTitle: preview.serviceTitle,
      status: status,
      appointmentDate: preview.appointmentDate,
      description: preview.description,
    );
  }
}
