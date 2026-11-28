import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/bookings/models/technician_job.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/services/booking_service.dart';
import 'package:service_pilot/features/bookings/widgets/start_job_dialog.dart';
import 'package:service_pilot/features/bookings/widgets/technician_job_list.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

/// One job assigned to the signed-in company technician: the service, its
/// status, when and where to work, and the homeowner's problem description
/// (TECHJOB-1 / SCRUM-100).
///
/// A job that is not this technician's active job shows a neutral
/// "unavailable" notice and nothing from the booking.
class TechnicianJobDetailScreen extends ConsumerStatefulWidget {
  const TechnicianJobDetailScreen({super.key, required this.bookingId});

  static const String path = '/technician/jobs/:bookingId';

  static String location(String bookingId) =>
      '/technician/jobs/${Uri.encodeComponent(bookingId)}';

  final String bookingId;

  @override
  ConsumerState<TechnicianJobDetailScreen> createState() =>
      _TechnicianJobDetailScreenState();
}

class _TechnicianJobDetailScreenState
    extends ConsumerState<TechnicianJobDetailScreen> {
  bool _isStarting = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _startJob(TechnicianJob job, UserModel user) async {
    final l10n = context.l10n;
    final confirmed = await StartJobDialog.show(context);
    if (confirmed != true || !mounted) return;

    setState(() {
      _isStarting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final service = ref.read(bookingServiceProvider);
      await service.startTechnicianJob(
        bookingId: job.id,
        technicianId: user.id,
        companyId: user.companyId ?? '',
      );

      if (!mounted) return;
      ref.invalidate(technicianJobsProvider);
      ref.invalidate(technicianJobProvider(widget.bookingId));
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(liveBookingDetailProvider(widget.bookingId));
      ref.invalidate(providerBookingsProvider(job.companyId));
      ref.invalidate(liveProviderBookingsProvider(job.companyId));
      ref.invalidate(providerActiveBookingsProvider(job.companyId));
      ref.invalidate(liveProviderActiveBookingsProvider(job.companyId));

      setState(() {
        _isStarting = false;
        _successMessage = l10n.technicianJobStartedNotice;
      });
    } on UnauthorizedBookingStartException {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _errorMessage = l10n.providerBookingStartNotAuthorized;
      });
    } on InvalidBookingStartStateException {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _errorMessage = l10n.providerBookingStartIneligible;
      });
    } on QuoteNotApprovedForStartException {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _errorMessage = l10n.providerBookingStartQuotePending;
      });
    } on BookingSubmissionException catch (e) {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
        _errorMessage = l10n.technicianJobsLoadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final jobProvider = technicianJobProvider(widget.bookingId);
    final canActAsTechnician =
        user != null && user.isCompanyTechnician && !user.isSuspended;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: SpBackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(user?.role.homeRoute ?? '/login');
            }
          },
        ),
        title: Text(
          l10n.technicianJobDetailTitle,
          style: AppTheme.display(size: 18),
        ),
      ),
      body: ref.watch(jobProvider).when(
            data: (job) => job == null
                ? const _Unavailable()
                : _JobDetails(
                    job: job,
                    canStart: canActAsTechnician && job.canBeStarted,
                    isStarting: _isStarting,
                    errorMessage: _errorMessage,
                    successMessage: _successMessage,
                    onStart: () => _startJob(job, user!),
                  ),
            loading: () => Center(
              child: CircularProgressIndicator(
                semanticsLabel: l10n.technicianJobsLoading,
              ),
            ),
            error: (error, _) {
              debugPrint('[TechnicianJobDetailScreen] load error: $error');
              return _Centered(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpNotice(
                      key: const Key('technician_job_error'),
                      icon: Icons.error_outline_rounded,
                      message: l10n.technicianJobsLoadError,
                      tone: SpTone.danger,
                    ),
                    const SizedBox(height: 12),
                    SpSecondaryButton(
                      label: l10n.bookingInboxRetry,
                      wrapLabel: true,
                      onPressed: () => ref.invalidate(jobProvider),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

class _JobDetails extends StatelessWidget {
  const _JobDetails({
    required this.job,
    required this.canStart,
    required this.isStarting,
    required this.errorMessage,
    required this.successMessage,
    required this.onStart,
  });

  final TechnicianJob job;
  final bool canStart;
  final bool isStarting;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.gutter),
      child: SpContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpPageHeader(title: job.serviceTitle),
            const SizedBox(height: 12),
            StatusBadge(
              key: const Key('technician_job_detail_status'),
              status: job.status,
            ),
            if (successMessage != null &&
                job.status == BookingStatus.inProgress) ...[
              const SizedBox(height: 16),
              SpNotice(
                key: const Key('technician_job_started_notice'),
                icon: Icons.check_circle_outline_rounded,
                message: successMessage!,
                tone: SpTone.success,
              ),
            ],
            const SizedBox(height: 24),
            Container(
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
                  _InfoRow(
                    key: const Key('technician_job_appointment_row'),
                    icon: job.isAppointmentConfirmed
                        ? Icons.event_available_rounded
                        : Icons.schedule_rounded,
                    label: job.isAppointmentConfirmed
                        ? l10n.technicianJobAppointmentLabel
                        : l10n.technicianJobPreferredTimeLabel,
                    value: formatJobTime(context, job.appointmentAt),
                  ),
                  if (job.address.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoRow(
                      key: const Key('technician_job_address_row'),
                      icon: Icons.location_on_outlined,
                      label: l10n.providerBookingAddressLabel,
                      value: job.address,
                    ),
                  ],
                  if (job.serviceCategory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoRow(
                      key: const Key('technician_job_service_row'),
                      icon: Icons.handyman_outlined,
                      label: l10n.technicianJobServiceLabel,
                      value: job.serviceCategory,
                    ),
                  ],
                  if (job.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoRow(
                      key: const Key('technician_job_description_row'),
                      icon: Icons.description_outlined,
                      label: l10n.providerBookingDescriptionLabel,
                      value: job.description,
                    ),
                  ],
                ],
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              SpNotice(
                key: const Key('technician_job_error_notice'),
                icon: Icons.error_outline_rounded,
                message: errorMessage!,
                tone: SpTone.danger,
              ),
            ],
            if (canStart) ...[
              const SizedBox(height: 24),
              SpPrimaryButton(
                key: const Key('technician_start_job_button'),
                label: l10n.providerBookingStartButton,
                icon: Icons.play_arrow_rounded,
                wrapLabel: true,
                isLoading: isStarting,
                onPressed: isStarting ? null : onStart,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return _Centered(
      child: SpNotice(
        key: const Key('technician_job_unavailable'),
        icon: Icons.lock_outline_rounded,
        tone: SpTone.neutral,
        message: context.l10n.technicianJobUnavailable,
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: SpContentWidth(child: child),
        ),
      );
}

/// Label-over-value row matching the provider booking detail screen.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.text(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.text(
                    size: 15,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
