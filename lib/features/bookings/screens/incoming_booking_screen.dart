import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/incoming_booking_request.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

class IncomingBookingScreen extends ConsumerWidget {
  const IncomingBookingScreen({super.key});

  static const path = '/booking-requests';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = _content(
      context,
      ref.watch(incomingBookingRequestsProvider),
      onRetry: () => ref.invalidate(incomingBookingRequestsProvider),
      data: (requests) => requests.isEmpty
          ? SpNotice(
              icon: Icons.inbox_outlined,
              tone: SpTone.neutral,
              message: l10n.bookingInboxEmpty,
            )
          : Column(
              children: [
                for (final request in requests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: AppTheme.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCard),
                        side: const BorderSide(color: AppTheme.fieldBorder),
                      ),
                      child: ListTile(
                        title: Text(_title(context, request)),
                        subtitle: Text(_date(context, request)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        focusColor: AppTheme.primarySoft,
                        onTap: () async {
                          final encodedId = Uri.encodeComponent(request.id);
                          await context.push('$path/$encodedId');
                          if (context.mounted) {
                            ref.invalidate(incomingBookingRequestsProvider);
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );

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
        SpPageHeader(title: l10n.bookingInboxTitle),
        const SizedBox(height: 24),
        content,
      ],
    );
  }

  String _title(BuildContext context, IncomingBookingRequest request) =>
      request.serviceTitle.isEmpty
          ? context.l10n.bookingInboxDetailTitle
          : request.serviceTitle;

  String _date(BuildContext context, IncomingBookingRequest request) {
    final date = request.appointmentDate;
    final locale = Localizations.localeOf(context).toString();
    return date == null
        ? context.l10n.bookingInboxDateUnavailable
        : DateFormat.yMMMd(locale).add_jm().format(date.toLocal());
  }

  Widget _content<T>(
    BuildContext context,
    AsyncValue<T> value, {
    required Widget Function(T) data,
    required VoidCallback onRetry,
  }) {
    final l10n = context.l10n;
    return value.when(
      skipLoadingOnRefresh: false,
      data: data,
      loading: () => Center(
        child:
            CircularProgressIndicator(semanticsLabel: l10n.bookingInboxLoading),
      ),
      error: (_, __) => Column(
        children: [
          SpNotice(
            icon: Icons.error_outline_rounded,
            tone: SpTone.danger,
            message: l10n.bookingInboxError,
          ),
          const SizedBox(height: 12),
          SpSecondaryButton(
              label: l10n.bookingInboxRetry,
              onPressed: onRetry,
              wrapLabel: true),
        ],
      ),
    );
  }
}
