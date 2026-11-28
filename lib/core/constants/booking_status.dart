import 'package:flutter/material.dart';
import 'package:service_pilot/l10n/app_localizations.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Repair booking lifecycle status values in ServicePilot.
///
/// Corresponds to US-13 (SCRUM-44) and US-14 (SCRUM-45).
enum BookingStatus {
  pending,
  assigned,
  confirmed,
  inProgress,
  completed,
  cancelled,
  declined,
}

extension BookingStatusExtension on BookingStatus {
  static const acceptedStatuses = {
    BookingStatus.confirmed,
    BookingStatus.assigned,
    BookingStatus.inProgress,
    BookingStatus.completed,
  };

  /// Active provider jobs displayed in BOOK-4 (SCRUM-89).
  static const activeProviderStatuses = {
    BookingStatus.confirmed,
    BookingStatus.assigned,
    BookingStatus.inProgress,
  };

  /// Terminal service record statuses displayed in BOOK-5 (SCRUM-90).
  static const closedRecordStatuses = {
    BookingStatus.completed,
    BookingStatus.cancelled,
    BookingStatus.declined,
  };

  bool get exposesAcceptedDetails => acceptedStatuses.contains(this);

  bool get isActiveProviderWork => activeProviderStatuses.contains(this);

  bool get isClosedRecord => closedRecordStatuses.contains(this);

  /// Serialized database string value.
  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.assigned:
        return 'assigned';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.declined:
        return 'declined';
    }
  }

  /// Human-readable display label.
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.assigned:
        return 'Assigned';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.declined:
        return 'Declined';
    }
  }

  /// Localized display label for UI badges and summaries.
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case BookingStatus.pending:
        return l10n.bookingStatusPending;
      case BookingStatus.assigned:
        return l10n.bookingStatusAssigned;
      case BookingStatus.confirmed:
        return l10n.bookingStatusConfirmed;
      case BookingStatus.inProgress:
        return l10n.bookingStatusInProgress;
      case BookingStatus.completed:
        return l10n.bookingStatusCompleted;
      case BookingStatus.cancelled:
        return l10n.bookingStatusCancelled;
      case BookingStatus.declined:
        return l10n.bookingStatusDeclined;
    }
  }

  /// Short description explaining what the current status means for the customer.
  String get description {
    switch (this) {
      case BookingStatus.pending:
        return 'Waiting for the service provider to review and confirm your request.';
      case BookingStatus.assigned:
        return 'A technician has been assigned to handle your repair.';
      case BookingStatus.confirmed:
        return 'Your repair appointment is confirmed and scheduled.';
      case BookingStatus.inProgress:
        return 'The technician is currently performing the repair service.';
      case BookingStatus.completed:
        return 'The repair service has been completed.';
      case BookingStatus.cancelled:
        return 'This booking was cancelled by the customer.';
      case BookingStatus.declined:
        return 'The service provider was unavailable and declined this request.';
    }
  }

  /// US-14 (SCRUM-45) AC:
  /// Customers can cancel bookings with Pending, Assigned, or Confirmed status.
  /// Customers cannot cancel bookings that are In Progress, Completed, Cancelled, or Declined.
  bool get canBeCancelled {
    switch (this) {
      case BookingStatus.pending:
      case BookingStatus.assigned:
      case BookingStatus.confirmed:
        return true;
      case BookingStatus.inProgress:
      case BookingStatus.completed:
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return false;
    }
  }

  /// Whether the booking is in an active (upcoming/ongoing) state.
  bool get isActive {
    switch (this) {
      case BookingStatus.pending:
      case BookingStatus.assigned:
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
        return true;
      case BookingStatus.completed:
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return false;
    }
  }

  /// Whether the booking has reached a final terminal state.
  bool get isTerminal => !isActive;

  /// US-14 (SCRUM-45) AC:
  /// Cancelled bookings cannot be accepted, assigned, or started afterward.
  bool canTransitionTo(BookingStatus target) {
    if (this == target) return false;
    switch (this) {
      case BookingStatus.pending:
        return target == BookingStatus.confirmed ||
            target == BookingStatus.assigned ||
            target == BookingStatus.cancelled ||
            target == BookingStatus.declined;
      case BookingStatus.confirmed:
        return target == BookingStatus.assigned ||
            target == BookingStatus.inProgress ||
            target == BookingStatus.cancelled;
      case BookingStatus.assigned:
        return target == BookingStatus.confirmed ||
            target == BookingStatus.inProgress ||
            target == BookingStatus.cancelled;
      case BookingStatus.inProgress:
        return target == BookingStatus.completed;
      case BookingStatus.completed:
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return false;
    }
  }

  /// Design system tone for badges and notices (follows "The Waiting Rule" in DESIGN.md).
  SpTone get tone {
    switch (this) {
      case BookingStatus.pending:
        return SpTone.waiting;
      case BookingStatus.assigned:
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
        return SpTone.brand;
      case BookingStatus.completed:
        return SpTone.success;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return SpTone.danger;
    }
  }

  /// Icon paired with the status label ("The Not Colour Alone Rule" in DESIGN.md).
  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.schedule_rounded;
      case BookingStatus.assigned:
        return Icons.person_pin_rounded;
      case BookingStatus.confirmed:
        return Icons.event_available_rounded;
      case BookingStatus.inProgress:
        return Icons.handyman_rounded;
      case BookingStatus.completed:
        return Icons.check_circle_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
      case BookingStatus.declined:
        return Icons.block_rounded;
    }
  }

  /// Parses a string status value (case-insensitive) into a [BookingStatus].
  static BookingStatus fromValue(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'assigned':
        return BookingStatus.assigned;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
      case 'inprogress':
      case 'in progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
      case 'canceled':
        return BookingStatus.cancelled;
      case 'declined':
      case 'rejected':
        return BookingStatus.declined;
      default:
        return BookingStatus.pending;
    }
  }
}
