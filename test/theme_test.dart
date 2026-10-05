import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/screens/medication_form/form_sections.dart';
import 'package:pill_reminder_app/theme/app_theme.dart';

/// Widgets like dropdowns REPLACE the inherited text style with their own
/// `style`, so every style handed to them must still name the app fonts.
/// Without them Latin text falls back to Roboto and Arabic shows boxes.
void main() {
  for (final arabic in [false, true]) {
    testWidgets('form input style keeps the app fonts (arabic: $arabic)', (
      tester,
    ) async {
      TextStyle? style;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(arabic: arabic),
          home: Builder(
            builder: (context) {
              style = formInputStyle(context);
              return const SizedBox();
            },
          ),
        ),
      );
      final primary = arabic ? AppTheme.arabicFont : AppTheme.latinFont;
      final fallback = arabic ? AppTheme.latinFont : AppTheme.arabicFont;
      expect(style!.fontFamily, primary);
      expect(style!.fontFamilyFallback, contains(fallback));
    });
  }

  test('every theme text style names the app fonts', () {
    for (final arabic in [false, true]) {
      final theme = AppTheme.light(arabic: arabic);
      final styles = <TextStyle?>[
        theme.textTheme.headlineSmall,
        theme.textTheme.titleLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
        theme.appBarTheme.titleTextStyle,
        theme.dialogTheme.titleTextStyle,
        theme.dialogTheme.contentTextStyle,
        theme.listTileTheme.titleTextStyle,
        theme.listTileTheme.subtitleTextStyle,
        theme.snackBarTheme.contentTextStyle,
      ];
      for (final style in styles) {
        expect(style?.fontFamily, isNotNull);
        expect(style!.fontFamilyFallback, isNotEmpty);
      }
    }
  });
}
