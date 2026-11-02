import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_pilot/core/theme/app_theme.dart';

/// Reusable text form field matching Figma Form/Field.
///
/// Features:
/// - Label displayed cleanly above or inline
/// - Background fill: `#17181B` (Surface)
/// - Border: `#2A2B31`, active border: `#FF5000` (Primary Orange)
/// - Corner radius: 12.0
/// - Error helper in red `#FF4539`
class SpTextField extends StatelessWidget {
  const SpTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.initialValue,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final String? initialValue;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textBody,
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
          autofillHints: autofillHints,
          maxLines: obscureText ? 1 : maxLines,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? IconTheme(
                    data: const IconThemeData(color: AppTheme.textSecondary, size: 20),
                    child: prefixIcon!,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconTheme(
                    data: const IconThemeData(color: AppTheme.textSecondary, size: 20),
                    child: suffixIcon!,
                  )
                : null,
            fillColor: readOnly ? AppTheme.surfaceElevated : AppTheme.surface,
          ),
        ),
      ],
    );
  }
}
