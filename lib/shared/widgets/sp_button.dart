import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';

/// The one filled action on a screen.
class SpPrimaryButton extends StatelessWidget {
  const SpPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Shows a spinner and ignores taps; the button keeps its size.
  final bool isLoading;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading && onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: AppTheme.controlHeight,
      child: ElevatedButton(
        // While loading the button stays blue and ignores taps.
        onPressed: enabled ? (active ? onPressed : () {}) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.surfaceElevated,
          disabledForegroundColor: AppTheme.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          ),
        ),
        child: isLoading
            ? Semantics(
                label: context.l10n.commonLoading(label),
                child: const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              )
            : _Content(
                label: label,
                icon: icon,
                color: enabled ? Colors.white : AppTheme.textMuted,
              ),
      ),
    );
  }
}

/// Outlined alternative that sits beside or below a primary action.
class SpSecondaryButton extends StatelessWidget {
  const SpSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.foregroundColor = AppTheme.textPrimary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Custom leading widget (for example a brand glyph) instead of [icon].
  final Widget? leading;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled ? foregroundColor : AppTheme.textMuted;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: AppTheme.controlHeight,
        child: Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            side: BorderSide(
              color: enabled ? AppTheme.fieldBorder : AppTheme.border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: _Content(
                label: label,
                icon: icon,
                leading: leading,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Continue with Google" style button with the multicolour G.
class SpGoogleButton extends StatelessWidget {
  const SpGoogleButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SpSecondaryButton(
      label: label,
      onPressed: onPressed,
      leading: Text(
        'G',
        style: AppTheme.text(
          size: 18,
          weight: FontWeight.w700,
          color: const Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}

/// Inline text action in Pipe Blue with a full-size tap target.
class SpTextButton extends StatelessWidget {
  const SpTextButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primary,
        disabledForegroundColor: AppTheme.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: AppTheme.text(size: 15, weight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// Back arrow at the top of pushed screens.
class SpBackButton extends StatelessWidget {
  const SpBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: context.l10n.commonBack,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: const Icon(Icons.arrow_back_rounded, size: 24),
      color: AppTheme.textPrimary,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    required this.color,
    this.icon,
    this.leading,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final lead = leading ?? (icon == null ? null : Icon(icon, size: 20, color: color));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lead != null) ...[lead, const SizedBox(width: 10)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(
                size: 16,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
