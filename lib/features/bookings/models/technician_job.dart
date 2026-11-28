import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';

/// What a company technician may see about a job assigned to them
/// (TECHJOB-1 / SCRUM-100): when and where to work, what the job is and its
/// current status.
///
/// The homeowner's identity and contact details, the price and the photos stay
/// on the booking and are not copied here.
class TechnicianJob {
  const TechnicianJob({
    required this.id,
    required this.companyId,
    required this.serviceTitle,
    required this.serviceCategory,
    required this.status,
    required this.appointmentAt,
    required this.isAppointmentConfirmed,
    required this.address,
    required this.description,
  });

  final String id;

  /// The company that owns the booking and employs the technician.
  final String companyId;
  final String serviceTitle;
  final String serviceCategory;
  final BookingStatus status;

  /// The confirmed appointment, or the homeowner's preferred time when the
  /// booking carries no confirmed time.
  final DateTime appointmentAt;
  final bool isAppointmentConfirmed;
  final String address;
  final String description;

  /// Whether this assigned job can be marked `In Progress` now
  /// (TECHJOB-2 / SCRUM-101).
  bool get canBeStarted =>
      status == BookingStatus.confirmed || status == BookingStatus.assigned;

  /// Whether this assigned job can be marked `Completed` now
  /// (TECHJOB-3 / SCRUM-102).
  bool get canBeCompleted => status == BookingStatus.inProgress;

  TechnicianJob copyWith({BookingStatus? status}) {
    return TechnicianJob(
      id: id,
      companyId: companyId,
      serviceTitle: serviceTitle,
      serviceCategory: serviceCategory,
      status: status ?? this.status,
      appointmentAt: appointmentAt,
      isAppointmentConfirmed: isAppointmentConfirmed,
      address: address,
      description: description,
    );
  }

  factory TechnicianJob.fromBooking(BookingModel booking) {
    final confirmed = booking.confirmedAppointmentAt;
    return TechnicianJob(
      id: booking.id,
      companyId: booking.providerId,
      serviceTitle: booking.serviceTitle,
      serviceCategory: booking.serviceCategory,
      status: booking.status,
      appointmentAt: confirmed ?? booking.preferredDateTime,
      isAppointmentConfirmed: confirmed != null,
      address: booking.address,
      description: booking.description,
    );
  }

  /// Whether [booking] is an active job of [technicianId] at [companyId].
  ///
  /// Mirrors the `isAssignedBookingTechnician` read rule in `firestore.rules`.
  static bool isAssignedTo(
    BookingModel booking, {
    required String technicianId,
    required String companyId,
  }) {
    return technicianId.isNotEmpty &&
        companyId.isNotEmpty &&
        booking.assignedTechnicianId == technicianId &&
        booking.providerId == companyId &&
        booking.status.isTechnicianJob;
  }

  /// Soonest appointment first.
  static List<TechnicianJob> sorted(Iterable<TechnicianJob> jobs) =>
      List.unmodifiable(
        jobs.toList()
          ..sort((a, b) => a.appointmentAt.compareTo(b.appointmentAt)),
      );
}
