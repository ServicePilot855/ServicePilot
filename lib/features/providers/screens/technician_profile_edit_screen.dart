import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/features/auth/models/user_model.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/providers/services/independent_profile_service.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

class TechnicianProfileEditScreen extends ConsumerWidget {
  const TechnicianProfileEditScreen({super.key});

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/technician');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actor = ref.watch(currentUserProvider);
    final request =
        actor != null && actor.isIndependentTechnician && !actor.isSuspended
            ? editableIndependentProfileProvider(actor)
            : null;
    final profile = request == null ? null : ref.watch(request);
    final technician = profile?.valueOrNull;

    if (actor != null && technician != null) {
      return _TechnicianProfileForm(
        key: ValueKey(technician.id),
        actor: actor,
        profile: technician,
      );
    }

    return SpFlowPage(
      onBack: () => goBack(context),
      children: [
        SpPageHeader(title: l10n.technicianProfileEdit),
        const SizedBox(height: 24),
        if (profile?.isLoading == true)
          Center(
            child: CircularProgressIndicator(
              semanticsLabel: l10n.technicianProfileLoading,
            ),
          )
        else if (profile?.hasError == true) ...[
          SpNotice(
            icon: Icons.error_outline_rounded,
            message: l10n.technicianProfileLoadError,
            tone: SpTone.danger,
          ),
          const SizedBox(height: 16),
          SpSecondaryButton(
            label: l10n.providerDirectoryRetry,
            wrapLabel: true,
            onPressed: () => ref.invalidate(request!),
          ),
        ] else
          SpNotice(
            icon: Icons.person_outline_rounded,
            message: l10n.technicianProfileUnavailable,
            tone: SpTone.neutral,
          ),
      ],
    );
  }
}

class _TechnicianProfileForm extends ConsumerStatefulWidget {
  const _TechnicianProfileForm({
    super.key,
    required this.actor,
    required this.profile,
  });

  final UserModel actor;
  final ProviderModel profile;

  @override
  ConsumerState<_TechnicianProfileForm> createState() =>
      _TechnicianProfileFormState();
}

class _TechnicianProfileFormState
    extends ConsumerState<_TechnicianProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _description = TextEditingController(
    text: widget.profile.description.trim().isNotEmpty
        ? widget.profile.description
        : widget.profile.bio,
  );
  late final _area =
      TextEditingController(text: widget.profile.formattedCoverageAreas);
  late final _telegram =
      TextEditingController(text: widget.profile.telegramUrl);
  late final _messenger =
      TextEditingController(text: widget.profile.messengerUrl);
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _area.dispose();
    _telegram.dispose();
    _messenger.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(invalid.first.context);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _saved = false;
    });

    try {
      await ref.read(independentProfileServiceProvider).save(
            actor: widget.actor,
            providerId: widget.profile.id,
            fullName: _name.text,
            description: _description.text,
            serviceArea: _area.text,
            telegramUrl: _telegram.text,
            messengerUrl: _messenger.text,
          );
      if (!mounted) return;
      ref.invalidate(editableIndependentProfileProvider(widget.actor));
      ref.invalidate(providerDetailsProvider(widget.profile.id));
      ref.invalidate(categoryProvidersProvider);
      setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        showSpError(context, context.l10n.technicianProfileSaveError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateLength(String? raw, int limit, {String? requiredError}) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return requiredError;
    return value.length > limit
        ? context.l10n.technicianProfileLengthError(limit)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final telegramExample = l10n.technicianProfileTelegramExample;
    final messengerExample = l10n.technicianProfileMessengerExample;

    return PopScope(
      canPop: !_saving,
      child: SpFlowPage(
        onBack: () {
          if (!_saving) TechnicianProfileEditScreen.goBack(context);
        },
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_saved) ...[
              Semantics(
                liveRegion: true,
                child: SpNotice(
                  icon: Icons.check_circle_outline_rounded,
                  message: l10n.technicianProfileSaved,
                  tone: SpTone.success,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SpPrimaryButton(
              label: l10n.technicianProfileSave,
              wrapLabel: true,
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
        children: [
          SpPageHeader(title: l10n.technicianProfileEdit),
          const SizedBox(height: 24),
          Form(
            key: _form,
            onChanged: () {
              if (_saved) setState(() => _saved = false);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SpTextField(
                  label: l10n.technicianProfileName,
                  hint: l10n.technicianProfileNameHint,
                  controller: _name,
                  readOnly: _saving,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validateLength(
                    value,
                    100,
                    requiredError: l10n.technicianProfileNameRequired,
                  ),
                ),
                const SizedBox(height: 16),
                SpTextField(
                  label: l10n.technicianProfileDescription,
                  hint: l10n.technicianProfileDescriptionHint,
                  controller: _description,
                  readOnly: _saving,
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 3,
                  validator: (value) => _validateLength(value, 2000),
                ),
                const SizedBox(height: 16),
                SpTextField(
                  label: l10n.providerAreas,
                  hint: l10n.technicianProfileAreaHint,
                  controller: _area,
                  readOnly: _saving,
                  prefixIcon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validateLength(
                    value,
                    300,
                    requiredError: l10n.technicianProfileAreaRequired,
                  ),
                ),
                const SizedBox(height: 32),
                SpFormSection(
                  title: l10n.technicianProfileOptionalContacts,
                  children: [
                    SpTextField(
                      label: l10n.technicianProfileTelegram,
                      hint: telegramExample,
                      controller: _telegram,
                      readOnly: _saving,
                      prefixIcon: Icons.link_rounded,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          IndependentProfileService.isValidContactLink(
                        value ?? '',
                        't.me',
                      )
                              ? null
                              : l10n.technicianProfileInvalidLink(
                                  telegramExample,
                                ),
                    ),
                    const SizedBox(height: 16),
                    SpTextField(
                      label: l10n.technicianProfileMessenger,
                      hint: messengerExample,
                      controller: _messenger,
                      readOnly: _saving,
                      prefixIcon: Icons.link_rounded,
                      keyboardType: TextInputType.url,
                      validator: (value) =>
                          IndependentProfileService.isValidContactLink(
                        value ?? '',
                        'm.me',
                      )
                              ? null
                              : l10n.technicianProfileInvalidLink(
                                  messengerExample,
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
