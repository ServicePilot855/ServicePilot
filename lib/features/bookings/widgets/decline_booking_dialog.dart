import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';

/// Maximum length of a decline reason, matching `firestore.rules`.
const int declineReasonMaxLength = 300;

/// Confirmation dialog before a provider declines a pending request
/// (BOOK-3 / SCRUM-105).
///
/// Returns the trimmed reason when the provider confirms the decline, or
/// `null` when they keep the request.
class DeclineBookingDialog extends StatefulWidget {
  const DeclineBookingDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const DeclineBookingDialog(),
    );
  }

  @override
  State<DeclineBookingDialog> createState() => _DeclineBookingDialogState();
}

class _DeclineBookingDialogState extends State<DeclineBookingDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String? _validationMessage(AppLocalizations l10n) {
    final text = _reasonController.text.trim();
    if (text.isEmpty) return null;
    if (text.length > declineReasonMaxLength) {
      return l10n.providerBookingDeclineReasonTooLong;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = _reasonController.text.trim();
    final error = _validationMessage(l10n);
    final canConfirm = text.isNotEmpty && error == null;

    return AlertDialog(
      key: const Key('decline_booking_dialog'),
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      title: Text(
        l10n.providerBookingDeclineDialogTitle,
        style: AppTheme.display(size: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.providerBookingDeclineDialogBody,
              style: AppTheme.text(
                size: 14.5,
                color: AppTheme.textBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.providerBookingDeclineReasonLabel,
              style: AppTheme.text(
                size: 13.5,
                weight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('decline_reason_field'),
              controller: _reasonController,
              maxLines: 3,
              maxLength: declineReasonMaxLength,
              style: AppTheme.text(size: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.providerBookingDeclineReasonHint,
                hintStyle: AppTheme.text(
                  size: 13.5,
                  color: AppTheme.textSecondary,
                ),
                errorText: error,
                errorMaxLines: 3,
                counterText: '',
              ),
            ),
            if (text.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.providerBookingDeclineReasonRequired,
                key: const Key('decline_reason_required_hint'),
                style: AppTheme.text(
                  size: 13,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpSecondaryButton(
              key: const Key('decline_dialog_confirm_button'),
              label: l10n.providerBookingDeclineConfirm,
              icon: Icons.block_rounded,
              foregroundColor: AppTheme.errorDeep,
              wrapLabel: true,
              onPressed: canConfirm
                  ? () => Navigator.of(context).pop(text)
                  : null,
            ),
            const SizedBox(height: 10),
            SpPrimaryButton(
              key: const Key('decline_dialog_keep_button'),
              label: l10n.providerBookingDeclineKeep,
              wrapLabel: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}
