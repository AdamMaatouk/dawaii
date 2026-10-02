import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Dawaii'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @medication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medication;

  /// No description provided for @yourDose.
  ///
  /// In en, this message translates to:
  /// **'your dose'**
  String get yourDose;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get now;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get mainMenu;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @pausedMedications.
  ///
  /// In en, this message translates to:
  /// **'Paused medications'**
  String get pausedMedications;

  /// No description provided for @pausedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None paused} =1{1 medication paused} other{{count} medications paused}}'**
  String pausedCount(int count);

  /// No description provided for @showingPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused medications'**
  String get showingPaused;

  /// No description provided for @backToSchedule.
  ///
  /// In en, this message translates to:
  /// **'Back to schedule'**
  String get backToSchedule;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Dawaii'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first medication and Dawaii will remind you when it is time to take it.'**
  String get welcomeBody;

  /// No description provided for @addFirstMedication.
  ///
  /// In en, this message translates to:
  /// **'Add my first medication'**
  String get addFirstMedication;

  /// No description provided for @nothingTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to take today'**
  String get nothingTodayTitle;

  /// No description provided for @nothingDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get nothingDayTitle;

  /// No description provided for @nothingDayBody.
  ///
  /// In en, this message translates to:
  /// **'No doses are scheduled for this day.'**
  String get nothingDayBody;

  /// No description provided for @allDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'All done for today!'**
  String get allDoneTitle;

  /// No description provided for @allDoneBody.
  ///
  /// In en, this message translates to:
  /// **'You have taken care of every dose today. Well done.'**
  String get allDoneBody;

  /// No description provided for @noPaused.
  ///
  /// In en, this message translates to:
  /// **'No paused medications'**
  String get noPaused;

  /// No description provided for @pausedEmpty.
  ///
  /// In en, this message translates to:
  /// **'When you pause a medication, it will appear here.'**
  String get pausedEmpty;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get addMedication;

  /// No description provided for @editMedication.
  ///
  /// In en, this message translates to:
  /// **'Edit medication'**
  String get editMedication;

  /// No description provided for @remindersNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'Reminders need attention'**
  String get remindersNeedAttention;

  /// No description provided for @reminderAttentionDefault.
  ///
  /// In en, this message translates to:
  /// **'Your reminder settings need attention.'**
  String get reminderAttentionDefault;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @unableOpenReminderSettings.
  ///
  /// In en, this message translates to:
  /// **'Unable to open reminder settings.'**
  String get unableOpenReminderSettings;

  /// No description provided for @notificationsAndAlarmDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications and exact alarms are turned off. Reminders may not appear on time.'**
  String get notificationsAndAlarmDisabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off. Reminders cannot appear.'**
  String get notificationsDisabled;

  /// No description provided for @exactAlarmDisabled.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are turned off. Reminders may arrive late.'**
  String get exactAlarmDisabled;

  /// No description provided for @soundDisabled.
  ///
  /// In en, this message translates to:
  /// **'Reminder sound is off. Reminders will appear silently.'**
  String get soundDisabled;

  /// No description provided for @confirmDose.
  ///
  /// In en, this message translates to:
  /// **'Confirm dose'**
  String get confirmDose;

  /// No description provided for @markTakenQuestion.
  ///
  /// In en, this message translates to:
  /// **'Did you take this dose?'**
  String get markTakenQuestion;

  /// No description provided for @yesTaken.
  ///
  /// In en, this message translates to:
  /// **'Yes, I took it'**
  String get yesTaken;

  /// No description provided for @skipThisDose.
  ///
  /// In en, this message translates to:
  /// **'Skip this dose?'**
  String get skipThisDose;

  /// No description provided for @skipWarning.
  ///
  /// In en, this message translates to:
  /// **'This dose will be marked as skipped. Only skip it if you really do not want to take it.'**
  String get skipWarning;

  /// No description provided for @skipDose.
  ///
  /// In en, this message translates to:
  /// **'Skip dose'**
  String get skipDose;

  /// No description provided for @undoDoseTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo?'**
  String get undoDoseTitle;

  /// No description provided for @undoDoseBody.
  ///
  /// In en, this message translates to:
  /// **'Mark this dose as not taken yet?'**
  String get undoDoseBody;

  /// No description provided for @snoozeMedication.
  ///
  /// In en, this message translates to:
  /// **'Remind me about {name}'**
  String snoozeMedication(Object name);

  /// No description provided for @remindAgainIn.
  ///
  /// In en, this message translates to:
  /// **'Remind me again in:'**
  String get remindAgainIn;

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String minutesCount(int count);

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hoursCount(int count);

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @weeksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String weeksCount(int count);

  /// No description provided for @monthsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String monthsCount(int count);

  /// No description provided for @pillsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pill} other{{count} pills}}'**
  String pillsCount(int count);

  /// No description provided for @dosesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 dose} other{{count} doses}}'**
  String dosesCount(int count);

  /// No description provided for @hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String hoursMinutes(String hours, String minutes);

  /// No description provided for @inDuration.
  ///
  /// In en, this message translates to:
  /// **'in {duration}'**
  String inDuration(Object duration);

  /// No description provided for @agoDuration.
  ///
  /// In en, this message translates to:
  /// **'{duration} ago'**
  String agoDuration(Object duration);

  /// No description provided for @lessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'in less than a minute'**
  String get lessThanMinute;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @doseLine.
  ///
  /// In en, this message translates to:
  /// **'Dose: {summary}'**
  String doseLine(Object summary);

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @takenAt.
  ///
  /// In en, this message translates to:
  /// **'Taken at {time}'**
  String takenAt(Object time);

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @snoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {time}'**
  String snoozedUntil(Object time);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'LATE'**
  String get overdue;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get next;

  /// No description provided for @take.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get take;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get snooze;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @unableTake.
  ///
  /// In en, this message translates to:
  /// **'Unable to save this dose.'**
  String get unableTake;

  /// No description provided for @unableSkip.
  ///
  /// In en, this message translates to:
  /// **'Unable to skip this dose.'**
  String get unableSkip;

  /// No description provided for @unableSnooze.
  ///
  /// In en, this message translates to:
  /// **'Unable to snooze this reminder.'**
  String get unableSnooze;

  /// No description provided for @unableUndo.
  ///
  /// In en, this message translates to:
  /// **'Unable to undo.'**
  String get unableUndo;

  /// No description provided for @unableResume.
  ///
  /// In en, this message translates to:
  /// **'Unable to resume medication.'**
  String get unableResume;

  /// No description provided for @unablePause.
  ///
  /// In en, this message translates to:
  /// **'Unable to pause medication.'**
  String get unablePause;

  /// No description provided for @unableDelete.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete medication.'**
  String get unableDelete;

  /// No description provided for @unableLoadMedications.
  ///
  /// In en, this message translates to:
  /// **'Unable to load medications.'**
  String get unableLoadMedications;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editSchedule;

  /// No description provided for @deleteMedicationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete medication?'**
  String get deleteMedicationQuestion;

  /// No description provided for @deleteMedicationMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its history? This cannot be undone.'**
  String deleteMedicationMessage(Object name);

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted.'**
  String deleted(Object name);

  /// No description provided for @scheduleConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleConfiguration;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @specificDays.
  ///
  /// In en, this message translates to:
  /// **'Specific days'**
  String get specificDays;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Every few days'**
  String get interval;

  /// No description provided for @everyNDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} =2{Every other day} other{Every {count} days}}'**
  String everyNDays(int count);

  /// No description provided for @timesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Times a day'**
  String get timesPerDay;

  /// No description provided for @scheduleEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get scheduleEnds;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @pillsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No pills left} =1{1 pill left} other{{count} pills left}}'**
  String pillsLeft(int count);

  /// No description provided for @lowStockWarning.
  ///
  /// In en, this message translates to:
  /// **'Refill soon'**
  String get lowStockWarning;

  /// No description provided for @refill.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get refill;

  /// No description provided for @refillTitle.
  ///
  /// In en, this message translates to:
  /// **'Add pills'**
  String get refillTitle;

  /// No description provided for @refillLabel.
  ///
  /// In en, this message translates to:
  /// **'How many pills did you add?'**
  String get refillLabel;

  /// No description provided for @refillSaved.
  ///
  /// In en, this message translates to:
  /// **'Stock updated.'**
  String get refillSaved;

  /// No description provided for @medicationInfo.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medicationInfo;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication name'**
  String get medicationName;

  /// No description provided for @medicationNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Aspirin'**
  String get medicationNameHint;

  /// No description provided for @enterMedicationName.
  ///
  /// In en, this message translates to:
  /// **'Enter the medication name'**
  String get enterMedicationName;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get dosage;

  /// No description provided for @dosageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100mg'**
  String get dosageHint;

  /// No description provided for @enterDosage.
  ///
  /// In en, this message translates to:
  /// **'Enter the strength'**
  String get enterDosage;

  /// No description provided for @numberOfPills.
  ///
  /// In en, this message translates to:
  /// **'Pills per dose'**
  String get numberOfPills;

  /// No description provided for @pillCountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 or 2'**
  String get pillCountHint;

  /// No description provided for @invalidPillCount.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 99'**
  String get invalidPillCount;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Pills in stock'**
  String get stock;

  /// No description provided for @instructionsOptional.
  ///
  /// In en, this message translates to:
  /// **'Instructions (optional)'**
  String get instructionsOptional;

  /// No description provided for @instructionsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Take with food'**
  String get instructionsHint;

  /// No description provided for @pillAppearance.
  ///
  /// In en, this message translates to:
  /// **'How it looks'**
  String get pillAppearance;

  /// No description provided for @medicationType.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get medicationType;

  /// No description provided for @capsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get capsule;

  /// No description provided for @tablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get tablet;

  /// No description provided for @caplet.
  ///
  /// In en, this message translates to:
  /// **'Caplet'**
  String get caplet;

  /// No description provided for @softgel.
  ///
  /// In en, this message translates to:
  /// **'Softgel'**
  String get softgel;

  /// No description provided for @pillColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get pillColor;

  /// No description provided for @colorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @pillPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo (optional)'**
  String get pillPhotoOptional;

  /// No description provided for @pillPhotoHelp.
  ///
  /// In en, this message translates to:
  /// **'A real photo makes the medication easier to recognize.'**
  String get pillPhotoHelp;

  /// No description provided for @pillPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get pillPhotoAdded;

  /// No description provided for @shownInsideAppOnly.
  ///
  /// In en, this message translates to:
  /// **'Shown inside Dawaii only.'**
  String get shownInsideAppOnly;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Unable to get a photo. Please check the camera permission and try again.'**
  String get cameraError;

  /// No description provided for @notificationPreview.
  ///
  /// In en, this message translates to:
  /// **'Reminder preview'**
  String get notificationPreview;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get repeatEvery;

  /// No description provided for @scheduleEnd.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get scheduleEnd;

  /// No description provided for @ongoingOption.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoingOption;

  /// No description provided for @ongoingHelp.
  ///
  /// In en, this message translates to:
  /// **'Keep reminding me until I stop or delete it.'**
  String get ongoingHelp;

  /// No description provided for @fixedDuration.
  ///
  /// In en, this message translates to:
  /// **'For a set time'**
  String get fixedDuration;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @enterValueRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to {max}'**
  String enterValueRange(Object max);

  /// No description provided for @scheduleEndsDate.
  ///
  /// In en, this message translates to:
  /// **'Last day: {date}'**
  String scheduleEndsDate(Object date);

  /// No description provided for @doseTimings.
  ///
  /// In en, this message translates to:
  /// **'Reminder times'**
  String get doseTimings;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get addTime;

  /// No description provided for @noTimes.
  ///
  /// In en, this message translates to:
  /// **'No times yet. Tap \"Add time\".'**
  String get noTimes;

  /// No description provided for @duplicateDoseTime.
  ///
  /// In en, this message translates to:
  /// **'This time is already added.'**
  String get duplicateDoseTime;

  /// No description provided for @needDoseTime.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one reminder time.'**
  String get needDoseTime;

  /// No description provided for @needWeekday.
  ///
  /// In en, this message translates to:
  /// **'Please choose at least one day.'**
  String get needWeekday;

  /// No description provided for @saveMedication.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveMedication;

  /// No description provided for @saveMedicationError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save medication: {error}'**
  String saveMedicationError(Object error);

  /// No description provided for @stockSection.
  ///
  /// In en, this message translates to:
  /// **'Pill stock (optional)'**
  String get stockSection;

  /// No description provided for @trackStock.
  ///
  /// In en, this message translates to:
  /// **'Count my pills'**
  String get trackStock;

  /// No description provided for @stockHelp.
  ///
  /// In en, this message translates to:
  /// **'Dawaii subtracts pills each time you take a dose and warns you before you run out.'**
  String get stockHelp;

  /// No description provided for @pillsInBox.
  ///
  /// In en, this message translates to:
  /// **'Pills I have now'**
  String get pillsInBox;

  /// No description provided for @refillThreshold.
  ///
  /// In en, this message translates to:
  /// **'Warn me when this many are left'**
  String get refillThreshold;

  /// No description provided for @enterWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get enterWholeNumber;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sun;

  /// No description provided for @monShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monShort;

  /// No description provided for @tueShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tueShort;

  /// No description provided for @wedShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wedShort;

  /// No description provided for @thuShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thuShort;

  /// No description provided for @friShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friShort;

  /// No description provided for @satShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get satShort;

  /// No description provided for @sunShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunShort;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get analytics;

  /// No description provided for @analyticsHistory.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get analyticsHistory;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @timeframe.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get timeframe;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String streakDays(int count);

  /// No description provided for @activeStreak.
  ///
  /// In en, this message translates to:
  /// **'Perfect days in a row'**
  String get activeStreak;

  /// No description provided for @adherenceRate.
  ///
  /// In en, this message translates to:
  /// **'Doses taken'**
  String get adherenceRate;

  /// No description provided for @doseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Doses'**
  String get doseBreakdown;

  /// No description provided for @totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalDue;

  /// No description provided for @perMedication.
  ///
  /// In en, this message translates to:
  /// **'Each medication'**
  String get perMedication;

  /// No description provided for @noSavedMedications.
  ///
  /// In en, this message translates to:
  /// **'No medications yet.'**
  String get noSavedMedications;

  /// No description provided for @dosePerDay.
  ///
  /// In en, this message translates to:
  /// **'{dosage} • {count, plural, =1{once a day} =2{twice a day} other{{count} times a day}}'**
  String dosePerDay(String dosage, int count);

  /// No description provided for @lastTaken.
  ///
  /// In en, this message translates to:
  /// **'Last taken {time}'**
  String lastTaken(Object time);

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @adherenceExplanation.
  ///
  /// In en, this message translates to:
  /// **'Missed means a dose from a past day that was never marked as taken or skipped.'**
  String get adherenceExplanation;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textSizeExtraLarge;

  /// No description provided for @simpleMode.
  ///
  /// In en, this message translates to:
  /// **'Simple mode'**
  String get simpleMode;

  /// No description provided for @simpleModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Show only today\'s medications with big buttons.'**
  String get simpleModeHelp;

  /// No description provided for @remindersSection.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersSection;

  /// No description provided for @persistentAlarm.
  ///
  /// In en, this message translates to:
  /// **'Keep ringing until I answer'**
  String get persistentAlarm;

  /// No description provided for @persistentAlarmHelp.
  ///
  /// In en, this message translates to:
  /// **'The reminder sound repeats until you open or answer it.'**
  String get persistentAlarmHelp;

  /// No description provided for @readAloudSetting.
  ///
  /// In en, this message translates to:
  /// **'Read reminders aloud'**
  String get readAloudSetting;

  /// No description provided for @readAloudHelp.
  ///
  /// In en, this message translates to:
  /// **'When you open a reminder, Dawaii reads the medication name out loud.'**
  String get readAloudHelp;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Phone notification settings'**
  String get notificationSettings;

  /// No description provided for @testReminder.
  ///
  /// In en, this message translates to:
  /// **'Send a test reminder'**
  String get testReminder;

  /// No description provided for @testReminderSent.
  ///
  /// In en, this message translates to:
  /// **'A test reminder will appear in a few seconds.'**
  String get testReminderSent;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get dataSection;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Save a backup'**
  String get exportBackup;

  /// No description provided for @exportBackupHelp.
  ///
  /// In en, this message translates to:
  /// **'Save all medications and history to a file (photos not included).'**
  String get exportBackupHelp;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get importBackup;

  /// No description provided for @importBackupHelp.
  ///
  /// In en, this message translates to:
  /// **'Replace everything with a backup file.'**
  String get importBackupHelp;

  /// No description provided for @importConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This replaces all current medications and history with the backup. This cannot be undone.'**
  String get importConfirmBody;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restored 1 medication.} other{Restored {count} medications.}}'**
  String importSuccess(int count);

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'This file is not a valid Dawaii backup.'**
  String get importError;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the backup.'**
  String get exportError;

  /// No description provided for @doctorReport.
  ///
  /// In en, this message translates to:
  /// **'Report for my doctor'**
  String get doctorReport;

  /// No description provided for @doctorReportHelp.
  ///
  /// In en, this message translates to:
  /// **'A PDF of the last 30 days to share or print.'**
  String get doctorReportHelp;

  /// No description provided for @reportError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the report.'**
  String get reportError;

  /// No description provided for @aboutDawaii.
  ///
  /// In en, this message translates to:
  /// **'About Dawaii'**
  String get aboutDawaii;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Medication reminders made simple.'**
  String get aboutSubtitle;

  /// No description provided for @aboutParagraph1.
  ///
  /// In en, this message translates to:
  /// **'Dawaii was created to solve a real everyday problem: forgetting medication, missing doses, and struggling to keep track of different schedules.'**
  String get aboutParagraph1;

  /// No description provided for @aboutParagraph2.
  ///
  /// In en, this message translates to:
  /// **'The app focuses on making medication management simple, clear, and accessible through reminders, dose tracking, scheduling, and an easy-to-use interface.'**
  String get aboutParagraph2;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by Adam Maatouk'**
  String get createdBy;

  /// No description provided for @creatorBio.
  ///
  /// In en, this message translates to:
  /// **'Computer Science & Engineering student at the American University of Beirut (AUB), interested in solving real-world problems through practical, user-centered technology.'**
  String get creatorBio;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @emailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email copied: {email}'**
  String emailCopied(Object email);

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Medication reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders to take your medications'**
  String get notificationChannelDescription;

  /// No description provided for @alarmChannelName.
  ///
  /// In en, this message translates to:
  /// **'Medication alarms'**
  String get alarmChannelName;

  /// No description provided for @alarmChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Medication reminders that keep ringing until answered'**
  String get alarmChannelDescription;

  /// No description provided for @infoChannelName.
  ///
  /// In en, this message translates to:
  /// **'Dawaii notices'**
  String get infoChannelName;

  /// No description provided for @infoChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Refill warnings and other notices'**
  String get infoChannelDescription;

  /// No description provided for @notificationTake.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get notificationTake;

  /// No description provided for @notificationSnooze15.
  ///
  /// In en, this message translates to:
  /// **'In 15 min'**
  String get notificationSnooze15;

  /// No description provided for @notificationSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get notificationSkip;

  /// No description provided for @timeFor.
  ///
  /// In en, this message translates to:
  /// **'Time for {name}'**
  String timeFor(Object name);

  /// No description provided for @takeDoseBody.
  ///
  /// In en, this message translates to:
  /// **'Take {pillLabel} • {dosage}'**
  String takeDoseBody(String pillLabel, String dosage);

  /// No description provided for @keepAliveTitle.
  ///
  /// In en, this message translates to:
  /// **'Please open Dawaii'**
  String get keepAliveTitle;

  /// No description provided for @keepAliveBody.
  ///
  /// In en, this message translates to:
  /// **'Open the app so your medication reminders keep coming.'**
  String get keepAliveBody;

  /// No description provided for @lowStockTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is running low'**
  String lowStockTitle(Object name);

  /// No description provided for @lowStockBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No pills left. Please refill.} =1{Only 1 pill left. Please refill soon.} other{Only {count} pills left. Please refill soon.}}'**
  String lowStockBody(int count);

  /// No description provided for @testReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Test reminder'**
  String get testReminderTitle;

  /// No description provided for @testReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders are working.'**
  String get testReminderBody;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication report'**
  String get reportTitle;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period: {from} – {to}'**
  String reportPeriod(String from, String to);

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String reportGenerated(Object date);

  /// No description provided for @reportMedication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get reportMedication;

  /// No description provided for @reportSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get reportSchedule;

  /// No description provided for @reportTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get reportTaken;

  /// No description provided for @reportSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get reportSkipped;

  /// No description provided for @reportMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get reportMissed;

  /// No description provided for @reportAdherence.
  ///
  /// In en, this message translates to:
  /// **'Taken %'**
  String get reportAdherence;

  /// No description provided for @reportOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get reportOverall;

  /// No description provided for @reportMissedList.
  ///
  /// In en, this message translates to:
  /// **'Missed doses'**
  String get reportMissedList;

  /// No description provided for @reportNoMissed.
  ///
  /// In en, this message translates to:
  /// **'No missed doses in this period.'**
  String get reportNoMissed;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
