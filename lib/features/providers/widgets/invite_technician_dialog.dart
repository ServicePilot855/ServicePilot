import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/services/company_profile_service.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Dialog allowing a verified Company administrator to generate a technician
/// activation link (`/activate?token=...&email=...&company=...`).
class InviteTechnicianDialog extends ConsumerStatefulWidget {
  const InviteTechnicianDialog({
    super.key,
    required this.actor,
    required this.companyId,
    required this.companyName,
  });

  final UserModel actor;
  final String companyId;
  final String companyName;

  static Future<void> show(
    BuildContext context, {
    required UserModel actor,
    required String companyId,
    required String companyName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => InviteTechnicianDialog(
        actor: actor,
        companyId: companyId,
        companyName: companyName,
      ),
    );
  }

  @override
  ConsumerState<InviteTechnicianDialog> createState() =>
      _InviteTechnicianDialogState();
}

class _InviteTechnicianDialogState
    extends ConsumerState<InviteTechnicianDialog> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _copied = false;
  String? _errorMessage;
  String? _inviteUrl;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _buildActivationUrl(String token, String email) {
    final query = Uri(
      queryParameters: {
        'token': token,
        'email': email,
        'company': widget.companyName,
      },
    ).query;
    final route = '/activate?$query';
    if (kIsWeb) {
      return '${Uri.base.origin}/#$route';
    }
    return route;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _errorMessage = l10n.companyInviteTechnicianInvalidEmail);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final token = await ref
          .read(companyProfileServiceProvider)
          .createTechnicianInvite(
            actor: widget.actor,
            companyId: widget.companyId,
            email: email,
          );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _inviteUrl = _buildActivationUrl(token, email);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = l10n.companyInviteTechnicianError;
      });
    }
  }

  Future<void> _copyLink() async {
    final url = _inviteUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inviteUrl = _inviteUrl;

    return AlertDialog(
      scrollable: true,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      title: Text(
        l10n.companyInviteTechnicianTitle,
        style: AppTheme.headline(size: 18),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (inviteUrl == null) ...[
              Text(
                l10n.companyInviteTechnicianSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.companyInviteTechnicianEmailLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('company_invite_email_field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: l10n.companyInviteTechnicianEmailHint,
                ),
                onSubmitted: (_) => _isSubmitting ? null : _submit(),
              ),
            ] else ...[
              SpNotice(
                key: const Key('company_invite_created_notice'),
                icon: Icons.check_circle_outline_rounded,
                tone: SpTone.success,
                message: _copied
                    ? l10n.companyInviteTechnicianCopied
                    : l10n.companyInviteTechnicianCreated,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                  border: Border.all(color: AppTheme.border),
                ),
                child: SelectableText(
                  inviteUrl,
                  key: const Key('company_invite_url_text'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              SpNotice(
                key: const Key('company_invite_error_notice'),
                icon: Icons.error_outline_rounded,
                tone: SpTone.danger,
                message: _errorMessage!,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (inviteUrl == null) ...[
          SpSecondaryButton(
            label: MaterialLocalizations.of(context).cancelButtonLabel,
            wrapLabel: true,
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
          SpPrimaryButton(
            key: const Key('company_invite_submit_button'),
            label: l10n.companyInviteTechnicianSubmit,
            isLoading: _isSubmitting,
            wrapLabel: true,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ] else ...[
          SpPrimaryButton(
            key: const Key('company_invite_copy_button'),
            label: l10n.companyInviteTechnicianCopyLink,
            icon: Icons.copy_rounded,
            wrapLabel: true,
            onPressed: _copyLink,
          ),
          const SizedBox(height: 8),
          SpSecondaryButton(
            label: MaterialLocalizations.of(context).closeButtonLabel,
            wrapLabel: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ],
    );
  }
}
