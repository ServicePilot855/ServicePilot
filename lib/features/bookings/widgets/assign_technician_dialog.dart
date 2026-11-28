import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

class AssignTechnicianDialog extends StatefulWidget {
  const AssignTechnicianDialog({super.key, required this.loadTechnicians});

  final Future<Map<String, String>> Function() loadTechnicians;

  static Future<String?> show(
    BuildContext context, {
    required Future<Map<String, String>> Function() loadTechnicians,
  }) =>
      showDialog<String>(
        context: context,
        builder: (_) =>
            AssignTechnicianDialog(loadTechnicians: loadTechnicians),
      );

  @override
  State<AssignTechnicianDialog> createState() => _AssignTechnicianDialogState();
}

class _AssignTechnicianDialogState extends State<AssignTechnicianDialog> {
  late Future<Map<String, String>> _technicians = widget.loadTechnicians();
  String? _selectedId;

  Widget _content(
    BuildContext context,
    AsyncSnapshot<Map<String, String>> snapshot,
    Map<String, String> technicians,
  ) {
    final l10n = context.l10n;
    if (snapshot.connectionState != ConnectionState.done) {
      return Center(
        child: CircularProgressIndicator(
          semanticsLabel: l10n.commonLoading(l10n.providerAssignmentTitle),
        ),
      );
    }
    if (snapshot.hasError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpNotice(
            icon: Icons.error_outline_rounded,
            tone: SpTone.danger,
            message: l10n.providerAssignmentLoadError,
          ),
          const SizedBox(height: 12),
          SpSecondaryButton(
            label: l10n.bookingInboxRetry,
            wrapLabel: true,
            onPressed: () => setState(() {
              _technicians = widget.loadTechnicians();
            }),
          ),
        ],
      );
    }
    if (technicians.isEmpty) {
      return SpNotice(
        key: const Key('provider_assignment_empty'),
        icon: Icons.people_outline_rounded,
        tone: SpTone.neutral,
        message: l10n.providerAssignmentEmpty,
      );
    }
    return RadioGroup<String>(
      groupValue: _selectedId,
      onChanged: (id) => setState(() => _selectedId = id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final technician in technicians.entries)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: technician.key,
              title: Text(technician.value),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<Map<String, String>>(
      future: _technicians,
      builder: (context, snapshot) {
        final technicians = snapshot.data ?? const <String, String>{};
        return AlertDialog(
          scrollable: true,
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          title: Text(
            l10n.providerAssignmentTitle,
            style: AppTheme.display(size: 18),
          ),
          content: _content(context, snapshot, technicians),
          actions: [
            if (snapshot.connectionState == ConnectionState.done &&
                technicians.isNotEmpty)
              SpPrimaryButton(
                key: const Key('provider_save_assignment_button'),
                label: l10n.providerAssignmentSave,
                enabled: _selectedId != null,
                wrapLabel: true,
                onPressed: () => Navigator.of(context).pop(_selectedId),
              ),
            SpSecondaryButton(
              label: MaterialLocalizations.of(context).cancelButtonLabel,
              wrapLabel: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
