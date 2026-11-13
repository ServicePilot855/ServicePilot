import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';

/// Labelled form field. The label sits above the input so it stays visible
/// while typing and when an error is shown.
class SpTextField extends StatelessWidget {
  const SpTextField({
    super.key,
    required this.label,
    this.hint,
    this.helper,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.autofillHints,
    this.initialValue,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
  });

  final String label;
  final String? hint;

  /// Guidance shown under the field while there is no error.
  final String? helper;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final Iterable<String>? autofillHints;
  final String? initialValue;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.text(
            size: 14,
            weight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          autofillHints: autofillHints,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          cursorColor: AppTheme.primary,
          style: AppTheme.text(
            size: 16,
            color: readOnly ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperMaxLines: 2,
            helperStyle: AppTheme.text(size: 13, color: AppTheme.textSecondary),
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            suffixIcon: suffixIcon,
            fillColor: readOnly ? AppTheme.surfaceElevated : AppTheme.inputFill,
          ),
        ),
      ],
    );
  }
}

/// Password field with a built-in show / hide control.
class SpPasswordField extends StatefulWidget {
  const SpPasswordField({
    super.key,
    required this.label,
    this.hint,
    this.helper,
    this.controller,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.autofillHints,
  });

  final String label;
  final String? hint;
  final String? helper;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final Iterable<String>? autofillHints;

  @override
  State<SpPasswordField> createState() => _SpPasswordFieldState();
}

class _SpPasswordFieldState extends State<SpPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return SpTextField(
      label: widget.label,
      hint: widget.hint,
      helper: widget.helper,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: !_visible,
      prefixIcon: Icons.lock_outline_rounded,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      autofillHints: widget.autofillHints,
      suffixIcon: IconButton(
        tooltip: _visible
            ? context.l10n.commonHidePassword
            : context.l10n.commonShowPassword,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: Icon(
          _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 22,
        ),
        onPressed: () => setState(() => _visible = !_visible),
      ),
    );
  }
}
