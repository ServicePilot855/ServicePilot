import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';

/// Progress milestone status representing where the booking is in its lifecycle.
enum _MilestoneState {
  completed,
  current,
  upcoming,
  cancelled,
  declined,
}

/// A milestone entry within the booking status timeline.
class _MilestoneItem {
  final String title;
  final String subtitle;
  final _MilestoneState state;
  final IconData? icon;

  const _MilestoneItem({
    required this.title,
    required this.subtitle,
    required this.state,
    this.icon,
  });
}

/// Visual progress timeline and stepper representing the repair booking lifecycle.
///
/// Implements US-13 (SCRUM-44) DoD #1:
/// "Booking status tracking interface is implemented with a timeline/stepper UI."
///
/// Follows ServicePilot's **Blue Pipe** design system in DESIGN.md:
/// - Reached collar joints and pipe connections: Pipe Blue (`AppTheme.primary`).
/// - Current active waiting joint: Tape Yellow dot (`AppTheme.accent`).
/// - Upcoming joints: Surface with Field Border (`AppTheme.fieldBorder`).
/// - Terminal negative states (Cancelled / Declined): Danger tone (`AppTheme.error`).
class BookingStatusStepper extends StatelessWidget {
  final BookingModel booking;

  const BookingStatusStepper({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildMilestones(booking);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Service Progress',
                style: AppTheme.display(size: 16.5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < items.length; i++) ...[
            _MilestoneRow(
              item: items[i],
              isLast: i == items.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  List<_MilestoneItem> _buildMilestones(BookingModel booking) {
    final status = booking.status;

    // Terminal branch: Cancelled
    if (status == BookingStatus.cancelled) {
      return [
        const _MilestoneItem(
          title: 'Request Submitted',
          subtitle: 'Booking request was received',
          state: _MilestoneState.completed,
        ),
        const _MilestoneItem(
          title: 'Booking Cancelled',
          subtitle: 'The repair booking was cancelled.',
          state: _MilestoneState.cancelled,
          icon: Icons.cancel_outlined,
        ),
      ];
    }

    // Terminal branch: Declined
    if (status == BookingStatus.declined) {
      return [
        const _MilestoneItem(
          title: 'Request Submitted',
          subtitle: 'Booking request was received',
          state: _MilestoneState.completed,
        ),
        const _MilestoneItem(
          title: 'Request Declined',
          subtitle: 'Service provider could not accept this request',
          state: _MilestoneState.declined,
          icon: Icons.do_not_disturb_on_outlined,
        ),
      ];
    }

    // Happy Path Lifecycle:
    // 1. Pending -> 2. Confirmed -> 3. Assigned -> 4. In Progress -> 5. Completed
    final stepIndex = _happyPathIndex(status);

    final technicianSubtitle = booking.assignedTechnicianName != null
        ? 'Assigned to ${booking.assignedTechnicianName}'
        : 'Specialist assigned to your job';

    return [
      _MilestoneItem(
        title: 'Request Submitted',
        subtitle: 'Provider will review your request',
        state: _stateForIndex(0, stepIndex),
      ),
      _MilestoneItem(
        title: 'Booking Confirmed',
        subtitle: 'Provider confirmed appointment',
        state: _stateForIndex(1, stepIndex),
      ),
      _MilestoneItem(
        title: 'Technician Assigned',
        subtitle: technicianSubtitle,
        state: _stateForIndex(2, stepIndex),
      ),
      _MilestoneItem(
        title: 'Repair In Progress',
        subtitle: 'Technician is performing the repair',
        state: _stateForIndex(3, stepIndex),
      ),
      _MilestoneItem(
        title: 'Repair Completed',
        subtitle: 'Service finished successfully',
        state: _stateForIndex(4, stepIndex),
      ),
    ];
  }

  int _happyPathIndex(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 0;
      case BookingStatus.confirmed:
        return 1;
      case BookingStatus.assigned:
        return 2;
      case BookingStatus.inProgress:
        return 3;
      case BookingStatus.completed:
        return 4;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return 0;
    }
  }

  _MilestoneState _stateForIndex(int index, int activeIndex) {
    if (index < activeIndex) return _MilestoneState.completed;
    if (index == activeIndex) return _MilestoneState.current;
    return _MilestoneState.upcoming;
  }
}

class _MilestoneRow extends StatelessWidget {
  final _MilestoneItem item;
  final bool isLast;

  const _MilestoneRow({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Joint & Connecting Pipe
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _buildJoint(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 4,
                      color: _pipeColor(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Milestone Title & Subtitle
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTheme.text(
                      size: 14.5,
                      weight: item.state == _MilestoneState.current ||
                              item.state == _MilestoneState.completed
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: _titleColor(),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: AppTheme.text(
                      size: 12.5,
                      color: item.state == _MilestoneState.upcoming
                          ? AppTheme.textMuted
                          : AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoint() {
    switch (item.state) {
      case _MilestoneState.completed:
        return Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary,
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              size: 11,
              color: AppTheme.surface,
            ),
          ),
        );
      case _MilestoneState.current:
        // The Waiting Rule: Current step has Pipe Blue collar with Tape Yellow dot
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.primary, width: 2.5),
          ),
          child: const Center(
            child: SizedBox.square(
              dimension: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      case _MilestoneState.upcoming:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.fieldBorder, width: 2),
          ),
        );
      case _MilestoneState.cancelled:
      case _MilestoneState.declined:
        return Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.error,
          ),
          child: const Center(
            child: Icon(
              Icons.close_rounded,
              size: 11,
              color: AppTheme.surface,
            ),
          ),
        );
    }
  }

  Color _pipeColor() {
    switch (item.state) {
      case _MilestoneState.completed:
        return AppTheme.primary;
      case _MilestoneState.current:
      case _MilestoneState.upcoming:
        return AppTheme.border;
      case _MilestoneState.cancelled:
      case _MilestoneState.declined:
        return AppTheme.errorSoft;
    }
  }

  Color _titleColor() {
    switch (item.state) {
      case _MilestoneState.completed:
        return AppTheme.textPrimary;
      case _MilestoneState.current:
        return AppTheme.primary;
      case _MilestoneState.upcoming:
        return AppTheme.textSecondary;
      case _MilestoneState.cancelled:
      case _MilestoneState.declined:
        return AppTheme.errorDeep;
    }
  }
}
