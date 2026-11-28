import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/technician_job.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/features/bookings/screens/technician_job_detail_screen.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

/// The signed-in company technician's active jobs, soonest first, each
/// opening its details (TECHJOB-1 / SCRUM-100).
///
/// Follows the BOOK-4 provider list: one card per job with the service, the
/// status, the appointment time and the address.
class TechnicianJobList extends ConsumerWidget {
  const TechnicianJobList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.technicianJobsTitle,
            style: AppTheme.display(size: 20, color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(height: 12),
        ref.watch(technicianJobsProvider).when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return SpNotice(
                    key: const Key('technician_jobs_empty'),
                    icon: Icons.event_note_rounded,
                    message: l10n.technicianJobsEmpty,
                    tone: SpTone.neutral,
                  );
                }
                return Column(
                  children: [
                    for (final job in jobs) ...[
                      TechnicianJobCard(job: job),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    semanticsLabel: l10n.technicianJobsLoading,
                  ),
                ),
              ),
              error: (error, _) {
                debugPrint('[TechnicianJobList] load error: $error');
                return Column(
                  children: [
                    SpNotice(
                      key: const Key('technician_jobs_error'),
                      icon: Icons.error_outline_rounded,
                      message: l10n.technicianJobsLoadError,
                      tone: SpTone.danger,
                    ),
                    const SizedBox(height: 12),
                    SpSecondaryButton(
                      label: l10n.bookingInboxRetry,
                      wrapLabel: true,
                      onPressed: () => ref.invalidate(technicianJobsProvider),
                    ),
                  ],
                );
              },
            ),
      ],
    );
  }
}

/// Formats a job's appointment in the reader's locale.
String formatJobTime(BuildContext context, DateTime time) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .add_jm()
        .format(time.toLocal());

class TechnicianJobCard extends StatelessWidget {
  const TechnicianJobCard({super.key, required this.job});

  final TechnicianJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = formatJobTime(context, job.appointmentAt);

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        key: Key('technician_job_card_${job.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: () => context.push(TechnicianJobDetailScreen.location(job.id)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    job.serviceTitle,
                    style: AppTheme.display(
                      size: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  StatusBadge(
                    key: Key('technician_job_status_${job.id}'),
                    status: job.status,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CardLine(
                icon: job.isAppointmentConfirmed
                    ? Icons.event_available_rounded
                    : Icons.schedule_rounded,
                text: job.isAppointmentConfirmed
                    ? l10n.technicianJobAppointmentValue(time)
                    : l10n.technicianJobPreferredTimeValue(time),
                emphasised: true,
              ),
              if (job.address.isNotEmpty) ...[
                const SizedBox(height: 6),
                _CardLine(
                  icon: Icons.location_on_outlined,
                  text: job.address,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardLine extends StatelessWidget {
  const _CardLine({
    required this.icon,
    required this.text,
    this.emphasised = false,
  });

  final IconData icon;
  final String text;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTheme.text(
              size: 13.5,
              weight: emphasised ? FontWeight.w600 : FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
