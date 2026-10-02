# Dawaii (دوائي)

Medication reminders made simple, for older adults, in English and Arabic.

Dawaii reminds you when it is time to take each medication, lets you mark doses as taken, skipped or "remind me later", and shows how well you are keeping up. Everything stays on the phone: there is no account and no server.

## Features

- **Reliable reminders:** they keep coming as long as the medication is active. Optionally they keep ringing until answered, and Take / Later / Skip work right from the notification.
- **Clear daily schedule:** big buttons, LATE and NEXT labels, undo for accidental taps, and read‑aloud.
- **Accessibility:**
  - Text size setting, on top of the phone's own.
  - Simple mode (today only, larger cards).
  - Light, dark, or same‑as‑phone theme.
  - Full Arabic with right‑to‑left layout and correct plurals.
- **Medications:** shape, color and photo; every day, specific days or every N days; ongoing or for a set time; pause/resume.
- **Pill stock:** counts down with each dose, warns before you run out, one‑tap refill.
- **Progress:** perfect‑day streak and adherence. Missed doses are counted, not hidden.
- **Report for the doctor:** a 30‑day PDF to share or print.
- **Backup and restore:** to a file you keep (photos are not included).

## Development

```bash
flutter pub get
flutter test
flutter run
```

Translations live in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb` and are generated automatically. Add each new string to both files.

### Release signing (Android)

Create a keystore once, keep it safe, and never commit it:

```bash
keytool -genkey -v -keystore ~/dawaii-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dawaii
```

Then create `android/key.properties` (already git‑ignored):

```properties
storeFile=C:/Users/<you>/dawaii-release.jks
storePassword=<your store password>
keyAlias=dawaii
keyPassword=<your key password>
```

Without this file, release builds are signed with the debug key, which is fine for testing but not accepted by Google Play.

See `CLAUDE.md` for the architecture.

Created by Adam Maatouk.
