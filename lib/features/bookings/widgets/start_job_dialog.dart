import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';

/// Confirmation before a provider marks a job In Progress (WORK-1 / SCRUM-91).
///
/// Returns `true` when the provider confirms, `null` when they keep waiting.
class StartJobDialog extends StatelessWidget {
  const StartJobDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const StartJobDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      key: const Key('start_job_dialog'),
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppTheme.onPrimarySoft,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.providerBookingStartDialogTitle,
              style: AppTheme.display(size: 18),
            ),
          ),
        ],
      ),
      content: Text(
        l10n.providerBookingStartDialogBody,
        style: AppTheme.text(
          size: 14.5,
          color: AppTheme.textBody,
          height: 1.5,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpPrimaryButton(
              key: const Key('start_job_confirm_button'),
              label: l10n.providerBookingStartConfirm,
              icon: Icons.play_arrow_rounded,
              wrapLabel: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            SpSecondaryButton(
              key: const Key('start_job_keep_button'),
              label: l10n.providerBookingStartKeep,
              wrapLabel: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}
