import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/provider_service_record.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

/// Displays completed, cancelled, and declined service records owned by the
/// signed-in independent provider or company administrator (BOOK-5 / SCRUM-90).
class ProviderServiceHistoryScreen extends ConsumerWidget {
  const ProviderServiceHistoryScreen({super.key});

  static const path = '/provider/bookings/history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recordsAsync = ref.watch(providerServiceRecordsProvider);

    return SpFlowPage(
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          final user = ref.read(currentUserProvider);
          context.go(user?.role.homeRoute ?? '/login');
        }
      },
      children: [
        SpPageHeader(
          title: l10n.providerHistoryTitle,
          subtitle: l10n.providerHistorySubtitle,
        ),
        const SizedBox(height: 24),
        recordsAsync.when(
          skipLoadingOnRefresh: false,
          data: (records) {
            if (records.isEmpty) {
              return SpNotice(
                key: const Key('provider_history_empty_notice'),
                icon: Icons.history_rounded,
                tone: SpTone.neutral,
                message: l10n.providerHistoryEmpty,
              );
            }

            return Column(
              children: [
                for (final record in records)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ServiceRecordCard(record: record),
                  ),
              ],
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                semanticsLabel: l10n.providerHistoryTitle,
              ),
            ),
          ),
          error: (_, __) => Column(
            children: [
              SpNotice(
                icon: Icons.error_outline_rounded,
                tone: SpTone.danger,
                message: l10n.providerHistoryLoadError,
              ),
              const SizedBox(height: 12),
              SpSecondaryButton(
                label: l10n.bookingInboxRetry,
                wrapLabel: true,
                onPressed: () => ref.invalidate(providerServiceRecordsProvider),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceRecordCard extends StatelessWidget {
  const _ServiceRecordCard({required this.record});

  final ProviderServiceRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = record.appointmentDate;
    final locale = Localizations.localeOf(context).toString();
    final formattedDate = date == null
        ? l10n.bookingInboxDateUnavailable
        : DateFormat.yMMMd(locale).add_jm().format(date.toLocal());
    final canOpenDetail = record.status == BookingStatus.completed ||
        record.status == BookingStatus.declined;
    final technician = record.assignedTechnicianName?.trim() ?? '';

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        key: Key('provider_history_card_${record.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: canOpenDetail
            ? () => context.push(
                  '/provider/bookings/${Uri.encodeComponent(record.id)}',
                )
            : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      record.serviceTitle.isEmpty
                          ? l10n.bookingInboxDetailTitle
                          : record.serviceTitle,
                      style: AppTheme.display(
                        size: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    key: Key('provider_history_status_${record.id}'),
                    status: record.status,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.event_note_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: AppTheme.text(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (technician.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person_pin_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        technician,
                        style: AppTheme.text(
                          size: 13.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (record.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  record.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(
                    size: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
