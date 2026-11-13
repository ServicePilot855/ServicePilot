import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ServicePilot design system ("Blue Pipe").
///
/// Light, daylight-readable, and plain:
/// - **Pipe Blue** is the brand and every primary action.
/// - **Tape Yellow** marks one thing only: something is waiting.
/// - Cool neutrals keep ink, hairlines and fills in one family.
///
/// All Latin text is Figtree; Khmer falls back to Kantumruy Pro. See DESIGN.md
/// for the rules behind the tokens.
class AppTheme {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1463D8);
  static const Color primaryDeep = Color(0xFF0B2E6B);
  static const Color primarySoft = Color(0xFFE6EEFB);

  /// Text and icons on [primarySoft].
  static const Color onPrimarySoft = Color(0xFF0B3A8A);

  /// Tape Yellow: a fill or a mark for "waiting". Never text.
  static const Color accent = Color(0xFFFFC42E);
  static const Color accentSoft = Color(0xFFFFF4D1);

  /// Text and icons on [accent].
  static const Color onAccent = Color(0xFF3A2A00);

  /// Text and icons on [accentSoft] or on white.
  static const Color accentDeep = Color(0xFF6B4E00);

  // ── Neutrals ──────────────────────────────────────────────────────────────
  /// Page background on browse and home screens.
  static const Color background = Color(0xFFF4F6FA);

  /// Cards, sheets, and the whole page on form screens.
  static const Color surface = Color(0xFFFFFFFF);

  /// Neutral fills: read-only fields, skeletons, unselected segments.
  static const Color surfaceElevated = Color(0xFFEEF1F6);

  /// 1px dividers and card edges. Decorative; too faint to mark a control.
  static const Color border = Color(0xFFE1E6EE);

  /// Edge of inputs and other controls (3:1 on white).
  static const Color fieldBorder = Color(0xFF8793A8);

  static const Color textPrimary = Color(0xFF0E1726);
  static const Color textBody = Color(0xFF2A3547);
  static const Color textSecondary = Color(0xFF55627A);

  /// Disabled text and decorative marks only; too faint to carry information.
  static const Color textMuted = Color(0xFF8E99AD);
  static const Color inputFill = Color(0xFFFFFFFF);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFC7352B);
  static const Color errorSoft = Color(0xFFFCEAE8);
  static const Color errorDeep = Color(0xFF9B271F);
  static const Color success = Color(0xFF18794E);
  static const Color successSoft = Color(0xFFE3F5EC);
  static const Color successDeep = Color(0xFF125C3B);

  // ── Shape and space ───────────────────────────────────────────────────────
  static const double radiusChip = 8.0;
  static const double radiusControl = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusSheet = 24.0;

  /// Horizontal page gutter on form and flow screens.
  static const double gutter = 20.0;

  /// Height of buttons and single-line inputs.
  static const double controlHeight = 52.0;

  /// Content never grows wider than this (tablets, web).
  static const double maxContentWidth = 480.0;

  /// Shadow for things that float over scrolling content, and nothing else.
  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: primaryDeep.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ── Type ──────────────────────────────────────────────────────────────────
  //
  // One family, Figtree, for every Latin string: headings differ from body by
  // weight and size only. Figtree is compact, so labels and prices fit on one
  // line more often. It has no Khmer glyphs, so each style falls back to
  // Kantumruy Pro, whose rounded geometric shapes sit well beside it.

  static List<String> get _khmerFallback =>
      [GoogleFonts.kantumruyPro().fontFamily!];

  /// Headings: Figtree, heavy, slightly tightened at large sizes.
  static TextStyle display({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = textPrimary,
    double height = 1.2,
  }) {
    return GoogleFonts.figtree(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size >= 24 ? size * -0.015 : 0,
    ).copyWith(fontFamilyFallback: _khmerFallback);
  }

  /// Body and UI text: Figtree at normal tracking.
  static TextStyle text({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = textBody,
    double? height,
  }) {
    return GoogleFonts.figtree(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    ).copyWith(fontFamilyFallback: _khmerFallback);
  }

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primarySoft,
      onPrimaryContainer: onPrimarySoft,
      secondary: accent,
      onSecondary: onAccent,
      secondaryContainer: accentSoft,
      onSecondaryContainer: accentDeep,
      error: error,
      onError: Colors.white,
      errorContainer: errorSoft,
      onErrorContainer: errorDeep,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: fieldBorder,
      outlineVariant: border,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),

      textTheme: TextTheme(
        displayLarge: display(size: 32),
        displayMedium: display(size: 28),
        headlineLarge: display(size: 24),
        headlineMedium: display(size: 20),
        headlineSmall: display(size: 18),
        titleLarge: text(size: 17, weight: FontWeight.w600, color: textPrimary),
        titleMedium:
            text(size: 15, weight: FontWeight.w600, color: textPrimary),
        bodyLarge: text(size: 16, height: 1.5),
        bodyMedium: text(size: 14, height: 1.5),
        bodySmall: text(size: 12.5, color: textSecondary, height: 1.45),
        labelLarge: text(size: 15, weight: FontWeight.w600, color: textPrimary),
        labelMedium:
            text(size: 13, weight: FontWeight.w600, color: textPrimary),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: display(size: 20),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: text(size: 15.5, color: textSecondary),
        errorStyle: text(size: 13, color: error, weight: FontWeight.w500),
        errorMaxLines: 3,
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) return error;
          if (states.contains(WidgetState.focused)) return primary;
          return textSecondary;
        }),
        suffixIconColor: textSecondary,
        border: inputBorder(fieldBorder),
        enabledBorder: inputBorder(fieldBorder),
        disabledBorder: inputBorder(border),
        focusedBorder: inputBorder(primary, 2),
        errorBorder: inputBorder(error),
        focusedErrorBorder: inputBorder(error, 2),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: fieldBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: text(size: 15, weight: FontWeight.w600),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: text(size: 14, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
        ),
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: primary),

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
