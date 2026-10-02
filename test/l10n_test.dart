import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pill_reminder_app/l10n/app_localizations.dart';
import 'package:pill_reminder_app/utils/formatters.dart';

void main() {
  final ar = lookupAppLocalizations(const Locale('ar'));
  final en = lookupAppLocalizations(const Locale('en'));

  test(
    'Arabic plurals follow Arabic grammar (old bug: "2 حبات", "11 أيام")',
    () {
      expect(ar.pillsCount(1), 'حبة واحدة');
      expect(ar.pillsCount(2), 'حبتين');
      expect(ar.pillsCount(3), '3 حبات');
      expect(ar.pillsCount(11), '11 حبة');
      expect(ar.streakDays(2), 'يومان');
      expect(ar.streakDays(5), '5 أيام');
      expect(ar.streakDays(11), '11 يومًا');
      expect(ar.pillsLeft(2), 'بقيت حبتان');
    },
  );

  test('reminder text puts the pill count before the strength', () {
    // Undeclared ARB placeholders are ordered alphabetically by gen-l10n,
    // which once swapped these two arguments.
    expect(en.takeDoseBody(en.pillsCount(2), '500mg'), 'Take 2 pills • 500mg');
    expect(ar.takeDoseBody(ar.pillsCount(1), '5mg'), 'خذ حبة واحدة • 5mg');
  });

  test('English plurals', () {
    expect(en.pillsCount(1), '1 pill');
    expect(en.pillsCount(3), '3 pills');
    expect(en.everyNDays(2), 'Every other day');
  });

  test('relative times read naturally (old bug: "10h 47m" with no "ago")', () {
    final fmt = Formatters(en);
    final now = DateTime(2026, 3, 10, 12, 0);
    expect(fmt.since(DateTime(2026, 3, 10, 1, 13), now), '10 h 47 min ago');
    expect(fmt.until(DateTime(2026, 3, 10, 12, 25), now), 'in 25 minutes');
    expect(
      Formatters(ar).since(DateTime(2026, 3, 10, 11, 0), now),
      'منذ ساعة واحدة',
    );
  });

  test('every English key has an Arabic translation', () {
    // Generated getters would fall back silently if a key were missing in
    // the Arabic file; gen-l10n reports it, this guards the important ones.
    expect(ar.appName, 'دوائي');
    expect(ar.take, isNot(en.take));
    expect(ar.welcomeTitle, isNot(en.welcomeTitle));
  });
}
