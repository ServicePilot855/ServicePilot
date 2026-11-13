import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';

/// Colour pairing for notices and status illustrations.
///
/// [waiting] is the only place Tape Yellow appears: something is pending.
enum SpTone { brand, waiting, success, danger, neutral }

extension SpToneColors on SpTone {
  /// Icon and emphasis colour, readable on [background].
  Color get foreground {
    switch (this) {
      case SpTone.brand:
        return AppTheme.onPrimarySoft;
      case SpTone.waiting:
        return AppTheme.accentDeep;
      case SpTone.success:
        return AppTheme.successDeep;
      case SpTone.danger:
        return AppTheme.errorDeep;
      case SpTone.neutral:
        return AppTheme.textSecondary;
    }
  }

  Color get background {
    switch (this) {
      case SpTone.brand:
        return AppTheme.primarySoft;
      case SpTone.waiting:
        return AppTheme.accentSoft;
      case SpTone.success:
        return AppTheme.successSoft;
      case SpTone.danger:
        return AppTheme.errorSoft;
      case SpTone.neutral:
        return AppTheme.surfaceElevated;
    }
  }
}

/// Centres content and caps its width on tablets and web.
class SpContentWidth extends StatelessWidget {
  const SpContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// White task page: back arrow and optional step run on top, scrolling
/// content, and the primary action pinned at the bottom above the keyboard.
class SpFlowPage extends StatelessWidget {
  const SpFlowPage({
    super.key,
    required this.children,
    this.title,
    this.onBack,
    this.step,
    this.totalSteps,
    this.bottom,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;

  /// Short name of the flow, shown small in the top bar beside the back arrow.
  final String? title;
  final VoidCallback? onBack;

  /// 1-based position in a multi-screen flow, drawn as a jointed pipe run.
  final int? step;
  final int? totalSteps;

  /// Pinned action area (usually one primary button).
  final Widget? bottom;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final hasSteps = step != null && totalSteps != null;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            if (onBack != null || hasSteps || title != null)
              SpContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, AppTheme.gutter, 0),
                  child: Row(
                    children: [
                      if (onBack != null)
                        SpBackButton(onPressed: onBack!)
                      else
                        const SizedBox(width: 12, height: 48),
                      Expanded(
                        child: title == null
                            ? const SizedBox.shrink()
                            : Text(
                                title!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.text(
                                  size: 15,
                                  weight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                      ),
                      if (hasSteps)
                        SpJointSteps(step: step!, total: totalSteps!),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.gutter,
                  12,
                  AppTheme.gutter,
                  32,
                ),
                child: SpContentWidth(
                  child: Column(
                    crossAxisAlignment: crossAxisAlignment,
                    children: children,
                  ),
                ),
              ),
            ),
            if (bottom != null)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    12,
                    AppTheme.gutter,
                    12,
                  ),
                  child: SpContentWidth(child: bottom!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Step indicator drawn as a run of pipe with a collar joint at each step.
/// Reached joints and the pipe between them are Pipe Blue.
class SpJointSteps extends StatelessWidget {
  const SpJointSteps({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.commonStepOf(step, total),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 5,
                color: i <= step ? AppTheme.primary : AppTheme.border,
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= step ? AppTheme.primary : AppTheme.surface,
                border: Border.all(
                  color: i <= step ? AppTheme.primary : AppTheme.fieldBorder,
                  width: 2,
                ),
              ),
              child: i == step
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
          const SizedBox(width: 8),
          Text(
            context.l10n.commonStepCount(step, total),
            style: AppTheme.text(
              size: 13,
              weight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen heading: title with an optional supporting line.
class SpPageHeader extends StatelessWidget {
  const SpPageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTheme.display(size: 30)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: AppTheme.text(
              size: 15.5,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Flat group of fields under a short heading. No box around it.
class SpFormSection extends StatelessWidget {
  const SpFormSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTheme.display(size: 20)),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

/// Inline message with an icon. Never a floating toast.
class SpNotice extends StatelessWidget {
  const SpNotice({
    super.key,
    required this.icon,
    required this.message,
    this.tone = SpTone.brand,
  });

  final IconData icon;
  final String message;
  final SpTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 20, color: tone.foreground),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.text(
                size: 14,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon, title and message for a result, empty or dead-end state.
class SpStatusHero extends StatelessWidget {
  const SpStatusHero({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = SpTone.brand,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String message;
  final SpTone tone;

  /// Optional emphasised line under [message] (for example an email).
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: tone.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Icon(icon, size: 28, color: tone.foreground),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(title, style: AppTheme.display(size: 28)),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: AppTheme.text(
            size: 15.5,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 6),
          Text(
            detail!,
            style: AppTheme.text(
              size: 15.5,
              weight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

/// "or" between two ways of doing the same thing.
class SpOrDivider extends StatelessWidget {
  const SpOrDivider({super.key, this.label});

  /// Defaults to the localised word "or".
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label ?? context.l10n.commonOr,
            style: AppTheme.text(size: 13.5, color: AppTheme.textSecondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// A question followed by a text action: "New here? Create an account".
class SpFooterLink extends StatelessWidget {
  const SpFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: AppTheme.text(size: 15, color: AppTheme.textSecondary),
        ),
        SpTextButton(label: action, onPressed: onTap),
      ],
    );
  }
}

/// Selectable row for a single choice from a short list (for example a role).
class SpChoiceRow extends StatelessWidget {
  const SpChoiceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppTheme.primarySoft : AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: BorderSide(
            color: selected ? AppTheme.primary : AppTheme.fieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            // Keeps the content still when the border thickens on selection.
            padding: EdgeInsets.all(selected ? 15 : 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.text(
                          size: 16.5,
                          weight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTheme.text(
                          size: 14,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 24,
                  color: selected ? AppTheme.primary : AppTheme.fieldBorder,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Drag handle at the top of bottom sheets.
class SpSheetHandle extends StatelessWidget {
  const SpSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.fieldBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Shows a failure as a floating snackbar with an icon and the message.
void showSpError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.errorDeep,
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTheme.text(size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Shows a one-action result sheet and completes when it closes.
Future<void> showSpResultSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String actionLabel,
  SpTone tone = SpTone.success,
  Key? actionKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(AppTheme.gutter, 12, AppTheme.gutter, 16),
        child: SpContentWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SpSheetHandle(),
              const SizedBox(height: 24),
              SpStatusHero(icon: icon, tone: tone, title: title, message: message),
              const SizedBox(height: 28),
              SpPrimaryButton(
                key: actionKey,
                label: actionLabel,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
