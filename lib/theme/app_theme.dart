import 'package:flutter/material.dart';

/// All app colors, for light and dark mode, in one place.
/// Read it with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color page;
  final Color surface;
  final Color innerSurface;
  final Color textPrimary;
  final Color textBody;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color cardBorder;
  final Color pillTray;
  final Color pillTrayBorder;
  final Color accent;
  final Color accentStrong;
  final Color softAccent;
  final Color success;
  final Color successText;
  final Color softSuccess;
  final Color danger;
  final Color dangerText;
  final Color softDanger;
  final Color warning;
  final Color warningText;
  final Color softWarning;
  final Color warningBorder;

  const AppPalette({
    required this.page,
    required this.surface,
    required this.innerSurface,
    required this.textPrimary,
    required this.textBody,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.cardBorder,
    required this.pillTray,
    required this.pillTrayBorder,
    required this.accent,
    required this.accentStrong,
    required this.softAccent,
    required this.success,
    required this.successText,
    required this.softSuccess,
    required this.danger,
    required this.dangerText,
    required this.softDanger,
    required this.warning,
    required this.warningText,
    required this.softWarning,
    required this.warningBorder,
  });

  // "Soft slate": clear blue accent on cool, quiet greys. Text is dark
  // slate grey instead of black (and soft off-white instead of pure white
  // in dark mode), still above WCAG AA contrast everywhere. Status colors
  // (green = taken, amber = later / refill, red = late) stay distinct.
  static const light = AppPalette(
    page: Color(0xFFF1F3F6),
    surface: Color(0xFFFFFFFF),
    innerSurface: Color(0xFFF6F7F9),
    textPrimary: Color(0xFF2B323B),
    textBody: Color(0xFF3D4550),
    textSecondary: Color(0xFF555E6A),
    textMuted: Color(0xFF646E7B),
    border: Color(0xFFDFE3E8),
    cardBorder: Color(0xFFE4E7EC),
    pillTray: Color(0xFFEDF0F3),
    pillTrayBorder: Color(0xFFD5DAE0),
    accent: Color(0xFF2563EB),
    accentStrong: Color(0xFF2563EB),
    softAccent: Color(0xFFE8F0FD),
    success: Color(0xFF059669),
    successText: Color(0xFF15803D),
    softSuccess: Color(0xFFDCFCE7),
    danger: Color(0xFFDC2626),
    dangerText: Color(0xFFB91C1C),
    softDanger: Color(0xFFFEF2F2),
    warning: Color(0xFFB45309),
    warningText: Color(0xFF92400E),
    softWarning: Color(0xFFFFFBEB),
    warningBorder: Color(0xFFFDE68A),
  );

  static const dark = AppPalette(
    page: Color(0xFF14171C),
    surface: Color(0xFF1D2128),
    innerSurface: Color(0xFF181B21),
    textPrimary: Color(0xFFE3E6EA),
    textBody: Color(0xFFC5CAD1),
    textSecondary: Color(0xFFAEB4BC),
    textMuted: Color(0xFF949BA5),
    border: Color(0xFF2D323A),
    cardBorder: Color(0xFF2B3038),
    pillTray: Color(0xFF252A31),
    pillTrayBorder: Color(0xFF3B414A),
    accent: Color(0xFF60A5FA),
    accentStrong: Color(0xFF2563EB),
    softAccent: Color(0xFF1C2C46),
    success: Color(0xFF10B981),
    successText: Color(0xFF6EE7B7),
    softSuccess: Color(0xFF15352A),
    danger: Color(0xFFF87171),
    dangerText: Color(0xFFFCA5A5),
    softDanger: Color(0xFF3A1E1E),
    warning: Color(0xFFFBBF24),
    warningText: Color(0xFFFDE68A),
    softWarning: Color(0xFF3A2A12),
    warningBorder: Color(0xFF6B4A16),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      t < 0.5 || other is! AppPalette ? this : other;
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class AppTheme {
  static const String latinFont = 'Atkinson';
  static const String arabicFont = 'PlexArabic';

  static ThemeData light({bool arabic = false}) =>
      _build(AppPalette.light, Brightness.light, arabic);
  static ThemeData dark({bool arabic = false}) =>
      _build(AppPalette.dark, Brightness.dark, arabic);

  static ThemeData _build(AppPalette p, Brightness brightness, bool arabic) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: brightness,
      primary: p.accentStrong,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
    );

    // Generous sizes throughout: the app is designed for older adults.
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    // Every explicit TextStyle in the theme must name the font: buttons,
    // dialogs and inputs do not inherit ThemeData.fontFamily, and the
    // default font has no Arabic letters (shows empty boxes).
    final family = arabic ? arabicFont : latinFont;
    final fallback = arabic ? const [latinFont] : const [arabicFont];
    final buttonText = TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    const minButton = Size(64, 52);

    return ThemeData(
      useMaterial3: true,
      // Atkinson Hyperlegible Next was designed for low-vision readers; IBM Plex
      // Sans Arabic covers Arabic (also as a fallback for Arabic medication
      // names typed while the app is in English).
      fontFamily: arabic ? arabicFont : latinFont,
      fontFamilyFallback: arabic ? const [latinFont] : const [arabicFont],
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [p],
      scaffoldBackgroundColor: p.page,
      canvasColor: p.page,
      cardColor: p.surface,
      dividerColor: p.border,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: p.page,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textBody,
          fontSize: 17,
        ),
        bodyMedium: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textBody,
          fontSize: 15,
        ),
        bodySmall: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textMuted,
          fontSize: 13,
        ),
        labelLarge: buttonText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.innerSurface,
        labelStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textSecondary,
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textMuted,
        ),
        helperStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textMuted,
          fontSize: 13,
        ),
        prefixIconColor: p.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.danger, width: 2),
        ),
        errorStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.dangerText,
          fontSize: 13,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textPrimary,
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textBody,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        showDragHandle: true,
        dragHandleColor: p.border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: p.surface,
        indicatorColor: p.softAccent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: family,
            fontFamilyFallback: fallback,
            fontSize: 14,
            color: states.contains(WidgetState.selected)
                ? p.accent
                : p.textMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 28,
            color: states.contains(WidgetState.selected)
                ? p.accent
                : p.textMuted,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accentStrong,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accentStrong,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: minButton,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minButton,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.accent,
          minimumSize: minButton,
          textStyle: buttonText,
          side: BorderSide(color: p.border, width: 1.5),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          minimumSize: const Size(48, 48),
          textStyle: buttonText,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.accentStrong,
          selectedForegroundColor: Colors.white,
          foregroundColor: p.textSecondary,
          backgroundColor: p.innerSurface,
          side: BorderSide(color: p.border),
          minimumSize: const Size(48, 52),
          textStyle: TextStyle(
            fontFamily: family,
            fontFamilyFallback: fallback,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(p.border),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textPrimary,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFFE3E6EA)
            : const Color(0xFF2B323B),
        contentTextStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: brightness == Brightness.dark
              ? const Color(0xFF2B323B)
              : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.accent,
        textColor: p.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          color: p.textMuted,
          fontSize: 14,
        ),
        minVerticalPadding: 12,
      ),
    );
  }
}
