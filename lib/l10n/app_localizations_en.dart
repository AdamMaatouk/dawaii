// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Dawaii';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get undo => 'Undo';

  @override
  String get medication => 'Medication';

  @override
  String get yourDose => 'your dose';

  @override
  String get now => 'now';

  @override
  String get settings => 'Settings';

  @override
  String get pausedMedications => 'Paused medications';

  @override
  String get today => 'Today';

  @override
  String get welcomeTitle => 'Welcome to Dawaii';

  @override
  String get welcomeBody =>
      'Add your first medication and Dawaii will remind you when it is time to take it.';

  @override
  String get addFirstMedication => 'Add my first medication';

  @override
  String get nothingTodayTitle => 'Nothing to take today';

  @override
  String get nothingDayTitle => 'Nothing scheduled';

  @override
  String get nothingDayBody => 'No doses are scheduled for this day.';

  @override
  String get allDoneTitle => 'All done for today!';

  @override
  String get allDoneBody =>
      'You have taken care of every dose today. Well done.';

  @override
  String get addMedication => 'Add medication';

  @override
  String get editMedication => 'Edit medication';

  @override
  String get remindersNeedAttention => 'Reminders need attention';

  @override
  String get reminderAttentionDefault =>
      'Your reminder settings need attention.';

  @override
  String get fix => 'Fix';

  @override
  String get unableOpenReminderSettings => 'Unable to open reminder settings.';

  @override
  String get notificationsAndAlarmDisabled =>
      'Notifications and exact alarms are turned off. Reminders may not appear on time.';

  @override
  String get notificationsDisabled =>
      'Notifications are turned off. Reminders cannot appear.';

  @override
  String get exactAlarmDisabled =>
      'Exact alarms are turned off. Reminders may arrive late.';

  @override
  String get soundDisabled =>
      'Reminder sound is off. Reminders will appear silently.';

  @override
  String get confirmDose => 'Confirm dose';

  @override
  String get markTakenQuestion => 'Did you take this dose?';

  @override
  String get yesTaken => 'Yes, I took it';

  @override
  String get skipThisDose => 'Skip this dose?';

  @override
  String get skipWarning =>
      'This dose will be marked as skipped. Only skip it if you really do not want to take it.';

  @override
  String get skipDose => 'Skip dose';

  @override
  String get undoDoseTitle => 'Undo?';

  @override
  String get undoDoseBody => 'Mark this dose as not taken yet?';

  @override
  String snoozeMedication(Object name) {
    return 'Remind me about $name';
  }

  @override
  String get remindAgainIn => 'Remind me again in:';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String pillsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pills',
      one: '1 pill',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String inDuration(Object duration) {
    return 'in $duration';
  }

  @override
  String agoDuration(Object duration) {
    return '$duration ago';
  }

  @override
  String get lessThanMinute => 'in less than a minute';

  @override
  String get justNow => 'just now';

  @override
  String get taken => 'Taken';

  @override
  String takenAt(Object time) {
    return 'Taken at $time';
  }

  @override
  String get skipped => 'Skipped';

  @override
  String get missed => 'Missed';

  @override
  String snoozedUntil(Object time) {
    return 'Snoozed until $time';
  }

  @override
  String get overdue => 'LATE';

  @override
  String get next => 'NEXT';

  @override
  String get take => 'Take';

  @override
  String get snooze => 'Later';

  @override
  String get skip => 'Skip';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get unableTake => 'Unable to save this dose.';

  @override
  String get unableSkip => 'Unable to skip this dose.';

  @override
  String get unableSnooze => 'Unable to snooze this reminder.';

  @override
  String get unableUndo => 'Unable to undo.';

  @override
  String get unableResume => 'Unable to resume medication.';

  @override
  String get unablePause => 'Unable to pause medication.';

  @override
  String get unableDelete => 'Unable to delete medication.';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get editSchedule => 'Edit';

  @override
  String get deleteMedicationQuestion => 'Delete medication?';

  @override
  String deleteMedicationMessage(Object name) {
    return 'Delete \"$name\" and all its history? This cannot be undone.';
  }

  @override
  String deleted(Object name) {
    return '$name deleted.';
  }

  @override
  String get scheduleConfiguration => 'Schedule';

  @override
  String get frequency => 'Frequency';

  @override
  String get everyDay => 'Every day';

  @override
  String get specificDays => 'Specific days';

  @override
  String get interval => 'Every few days';

  @override
  String everyNDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      two: 'Every other day',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String get scheduleEnds => 'Ends';

  @override
  String get ongoing => 'Ongoing';

  @override
  String pillsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pills left',
      one: '1 pill left',
      zero: 'No pills left',
    );
    return '$_temp0';
  }

  @override
  String get lowStockWarning => 'Refill soon';

  @override
  String get refill => 'Refill';

  @override
  String get refillTitle => 'Add pills';

  @override
  String get refillLabel => 'How many pills did you add?';

  @override
  String get refillSaved => 'Stock updated.';

  @override
  String get medicationInfo => 'Medication';

  @override
  String get medicationName => 'Medication name';

  @override
  String get medicationNameHint => 'e.g. Aspirin';

  @override
  String get enterMedicationName => 'Enter the medication name';

  @override
  String get dosage => 'Strength';

  @override
  String get dosageHint => 'e.g. 100mg';

  @override
  String get enterDosage => 'Enter the strength';

  @override
  String get numberOfPills => 'Pills per dose';

  @override
  String get invalidPillCount => 'Enter a number from 1 to 99';

  @override
  String get instructions => 'Instructions';

  @override
  String get stock => 'Pills in stock';

  @override
  String get instructionsOptional => 'Instructions (optional)';

  @override
  String get instructionsHint => 'e.g. Take with food';

  @override
  String get pillAppearance => 'How it looks';

  @override
  String get medicationType => 'Shape';

  @override
  String get capsule => 'Capsule';

  @override
  String get tablet => 'Tablet';

  @override
  String get caplet => 'Caplet';

  @override
  String get softgel => 'Softgel';

  @override
  String get pillColor => 'Color';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorRed => 'Red';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorGray => 'Gray';

  @override
  String get colorWhite => 'White';

  @override
  String get pillPhotoOptional => 'Photo (optional)';

  @override
  String get pillPhotoHelp =>
      'A real photo makes the medication easier to recognize.';

  @override
  String get pillPhotoAdded => 'Photo added';

  @override
  String get shownInsideAppOnly => 'Shown inside Dawaii only.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get cameraError =>
      'Unable to get a photo. Please check the camera permission and try again.';

  @override
  String get notificationPreview => 'Reminder preview';

  @override
  String get repeatEvery => 'Repeat every';

  @override
  String get scheduleEnd => 'How long';

  @override
  String get ongoingOption => 'Ongoing';

  @override
  String get ongoingHelp => 'Keep reminding me until I stop or delete it.';

  @override
  String get fixedDuration => 'For a set time';

  @override
  String get days => 'Days';

  @override
  String get weeks => 'Weeks';

  @override
  String get months => 'Months';

  @override
  String get duration => 'Duration';

  @override
  String enterValueRange(Object max) {
    return 'Enter a number from 1 to $max';
  }

  @override
  String scheduleEndsDate(Object date) {
    return 'Last day: $date';
  }

  @override
  String get doseTimings => 'Reminder times';

  @override
  String get addTime => 'Add time';

  @override
  String get noTimes => 'No times yet. Tap \"Add time\".';

  @override
  String get duplicateDoseTime => 'This time is already added.';

  @override
  String get needDoseTime => 'Please add at least one reminder time.';

  @override
  String get needWeekday => 'Please choose at least one day.';

  @override
  String get saveMedication => 'Save';

  @override
  String saveMedicationError(Object error) {
    return 'Unable to save medication: $error';
  }

  @override
  String get stockSection => 'Pill stock (optional)';

  @override
  String get trackStock => 'Count my pills';

  @override
  String get stockHelp =>
      'Dawaii subtracts pills each time you take a dose and warns you before you run out.';

  @override
  String get pillsInBox => 'Pills I have now';

  @override
  String get refillThreshold => 'Warn me when this many are left';

  @override
  String get enterWholeNumber => 'Enter a whole number';

  @override
  String get mon => 'Monday';

  @override
  String get tue => 'Tuesday';

  @override
  String get wed => 'Wednesday';

  @override
  String get thu => 'Thursday';

  @override
  String get fri => 'Friday';

  @override
  String get sat => 'Saturday';

  @override
  String get sun => 'Sunday';

  @override
  String get monShort => 'Mon';

  @override
  String get tueShort => 'Tue';

  @override
  String get wedShort => 'Wed';

  @override
  String get thuShort => 'Thu';

  @override
  String get friShort => 'Fri';

  @override
  String get satShort => 'Sat';

  @override
  String get sunShort => 'Sun';

  @override
  String get schedule => 'Schedule';

  @override
  String get analytics => 'Progress';

  @override
  String get analyticsHistory => 'Progress';

  @override
  String get timeframe => 'Period';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get thisYear => 'This year';

  @override
  String get allTime => 'All time';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get activeStreak => 'Perfect days in a row';

  @override
  String get adherenceRate => 'Doses taken';

  @override
  String get doseBreakdown => 'Doses';

  @override
  String get totalDue => 'Total';

  @override
  String get perMedication => 'Each medication';

  @override
  String get noSavedMedications => 'No medications yet.';

  @override
  String dosePerDay(String dosage, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times a day',
      two: 'twice a day',
      one: 'once a day',
    );
    return '$dosage • $_temp0';
  }

  @override
  String lastTaken(Object time) {
    return 'Last taken $time';
  }

  @override
  String get noDataYet => 'No data yet';

  @override
  String get adherenceExplanation =>
      'Missed means a dose from a past day that was never marked as taken or skipped.';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get themeSystem => 'Same as phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeExtraLarge => 'Extra large';

  @override
  String get simpleMode => 'Simple mode';

  @override
  String get simpleModeHelp =>
      'Show only today\'s medications with big buttons.';

  @override
  String get remindersSection => 'Reminders';

  @override
  String get persistentAlarm => 'Keep ringing until I answer';

  @override
  String get persistentAlarmHelp =>
      'The reminder sound repeats until you open or answer it.';

  @override
  String get readAloudSetting => 'Read reminders aloud';

  @override
  String get readAloudHelp =>
      'When you open a reminder, Dawaii reads the medication name out loud.';

  @override
  String get notificationSettings => 'Phone notification settings';

  @override
  String get testReminder => 'Send a test reminder';

  @override
  String get testReminderSent =>
      'A test reminder will appear in a few seconds.';

  @override
  String get dataSection => 'Your data';

  @override
  String get exportBackup => 'Save a backup';

  @override
  String get exportBackupHelp =>
      'Save all medications and history to a file (photos not included).';

  @override
  String get importBackup => 'Restore a backup';

  @override
  String get importBackupHelp => 'Replace everything with a backup file.';

  @override
  String get importConfirmTitle => 'Restore backup?';

  @override
  String get importConfirmBody =>
      'This replaces all current medications and history with the backup. This cannot be undone.';

  @override
  String get restore => 'Restore';

  @override
  String importSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restored $count medications.',
      one: 'Restored 1 medication.',
    );
    return '$_temp0';
  }

  @override
  String get importError => 'This file is not a valid Dawaii backup.';

  @override
  String get exportError => 'Unable to create the backup.';

  @override
  String get doctorReport => 'Report for my doctor';

  @override
  String get doctorReportHelp => 'A PDF of the last 30 days to share or print.';

  @override
  String get reportError => 'Unable to create the report.';

  @override
  String get aboutDawaii => 'About Dawaii';

  @override
  String get aboutSubtitle => 'Medication reminders made simple.';

  @override
  String get createdBy => 'Created by Adam Maatouk';

  @override
  String get creatorBio =>
      'Computer Science & Engineering student at the American University of Beirut (AUB). I love building practical technology that makes everyday life a little easier, especially for the people who need it most.';

  @override
  String emailCopied(Object email) {
    return 'Email copied: $email';
  }

  @override
  String get notificationChannelName => 'Medication reminders';

  @override
  String get notificationChannelDescription =>
      'Reminders to take your medications';

  @override
  String get alarmChannelName => 'Medication alarms';

  @override
  String get alarmChannelDescription =>
      'Medication reminders that keep ringing until answered';

  @override
  String get infoChannelName => 'Dawaii notices';

  @override
  String get infoChannelDescription => 'Refill warnings and other notices';

  @override
  String get notificationTake => 'Taken';

  @override
  String get notificationSnooze15 => 'In 15 min';

  @override
  String get notificationSkip => 'Skip';

  @override
  String timeFor(Object name) {
    return 'Time for $name';
  }

  @override
  String takeDoseBody(String pillLabel, String dosage) {
    return 'Take $pillLabel • $dosage';
  }

  @override
  String get keepAliveTitle => 'Please open Dawaii';

  @override
  String get keepAliveBody =>
      'Open the app so your medication reminders keep coming.';

  @override
  String lowStockTitle(Object name) {
    return '$name is running low';
  }

  @override
  String lowStockBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Only $count pills left. Please refill soon.',
      one: 'Only 1 pill left. Please refill soon.',
      zero: 'No pills left. Please refill.',
    );
    return '$_temp0';
  }

  @override
  String get testReminderTitle => 'Test reminder';

  @override
  String get testReminderBody => 'Reminders are working.';

  @override
  String get reportTitle => 'Medication report';

  @override
  String reportPeriod(String from, String to) {
    return 'Period: $from – $to';
  }

  @override
  String reportGenerated(Object date) {
    return 'Created on $date';
  }

  @override
  String get reportMedication => 'Medication';

  @override
  String get reportSchedule => 'Schedule';

  @override
  String get reportTaken => 'Taken';

  @override
  String get reportSkipped => 'Skipped';

  @override
  String get reportMissed => 'Missed';

  @override
  String get reportAdherence => 'Taken %';

  @override
  String get reportOverall => 'Overall';

  @override
  String get reportMissedList => 'Missed doses';

  @override
  String get reportNoMissed => 'No missed doses in this period.';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get may => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get partMorning => 'Morning';

  @override
  String get partAfternoon => 'Afternoon';

  @override
  String get partEvening => 'Evening';

  @override
  String get partNight => 'Night';

  @override
  String sectionProgress(int taken, int total) {
    return '$taken of $total taken';
  }

  @override
  String get tookAll => 'Took all';

  @override
  String get iTookIt => 'I took it';

  @override
  String get iTookThemAll => 'I took them all';

  @override
  String get takeEarly => 'Take it now (early)';

  @override
  String get yesTookAll => 'Yes, I took them all';

  @override
  String get confirmTakeAllTitle => 'Did you take all of these?';

  @override
  String get nowTimeToTake => 'TIME TO TAKE';

  @override
  String get nowNext => 'NEXT';

  @override
  String get laterToday => 'Later today';

  @override
  String get backToToday => 'Today';

  @override
  String get tabToday => 'Today';

  @override
  String get tabMedicines => 'Medicines';

  @override
  String get medicinesTitle => 'My medicines';

  @override
  String get activeMedicines => 'Active';

  @override
  String get medicationPaused =>
      'This medication is paused. No reminders until you resume it.';

  @override
  String get medicationDetails => 'Medicine details';

  @override
  String get onbNameTitle => 'What should we call you?';

  @override
  String get onbNameHelp => 'Optional. Dawaii uses it to greet you.';

  @override
  String get onbNameHint => 'Your first name';

  @override
  String get onbTextTitle => 'Is this text easy to read?';

  @override
  String get onbTextHelp =>
      'Choose the size that feels comfortable. You can change it later in Settings.';

  @override
  String get onbSampleName => 'Aspirin';

  @override
  String get onbRemindersTitle => 'Allow reminders';

  @override
  String get onbRemindersBody =>
      'Dawaii needs your permission to remind you about your medicines, even when the phone is locked.\n\nOn the next screen, please tap \"Allow\".';

  @override
  String get onbAllow => 'Continue';

  @override
  String get onbNotNow => 'Not now';

  @override
  String get nextStep => 'Next';

  @override
  String get back => 'Back';

  @override
  String get ok => 'OK';

  @override
  String get pickTimeTitle => 'Choose a time';

  @override
  String get hourLabel => 'Hour';

  @override
  String get minuteLabel => 'Minute';

  @override
  String get addOtherTime => 'Another time';

  @override
  String get wizNameTitle => 'What is the medicine called?';

  @override
  String get wizLooksTitle => 'What does it look like?';

  @override
  String get wizWhenTitle => 'When do you take it?';

  @override
  String get wizHowLongTitle => 'For how long?';

  @override
  String get wizStockTitle => 'Check and save';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get noStockTracking => 'No, don\'t count';

  @override
  String get yourName => 'Your name';

  @override
  String get yourNameHelp => 'Used to greet you (optional)';

  @override
  String get saved => 'Saved.';

  @override
  String get encouragementGreat => 'Excellent! Keep it up.';

  @override
  String get encouragementGood => 'Good job. Keep going.';

  @override
  String get encouragementLow => 'Every dose counts. You can do it.';

  @override
  String takenOfLast(int taken, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'You took $taken of your last $total doses.',
      one: 'You took $taken of your last dose.',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get legendAllTaken => 'All taken';

  @override
  String get legendSomeMissed => 'Some missed';

  @override
  String get doneTitle => 'Done';

  @override
  String get showDone => 'Show';

  @override
  String get hideDone => 'Hide';

  @override
  String get tookAtOtherTime => 'I took it at another time';

  @override
  String takenSnack(String name) {
    return '$name taken ✓';
  }

  @override
  String takenAllSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses taken ✓',
      one: '1 dose taken ✓',
    );
    return '$_temp0';
  }

  @override
  String snoozedFor(String duration) {
    return 'I\'ll remind you again in $duration.';
  }

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String hoursShort(int count) {
    return '$count h';
  }

  @override
  String todayProgress(int taken, int total) {
    return '$taken of $total taken today';
  }

  @override
  String dosesLeftToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses to go',
      one: '1 dose to go',
    );
    return '$_temp0';
  }

  @override
  String lastsUntil(String date) {
    return 'lasts until $date';
  }

  @override
  String get presetOnce => 'Once a day';

  @override
  String get presetTwice => 'Twice a day';

  @override
  String get presetThree => '3 times a day';

  @override
  String get presetBedtime => 'At bedtime';

  @override
  String get summaryTitle => 'PLEASE CHECK';

  @override
  String get myHealth => 'My health';

  @override
  String get healthTitle => 'Health readings';

  @override
  String get bloodPressure => 'Blood pressure';

  @override
  String get bloodSugar => 'Blood sugar';

  @override
  String get addBloodPressure => 'Add blood pressure';

  @override
  String get addBloodSugar => 'Add blood sugar';

  @override
  String get systolicLabel => 'Top number';

  @override
  String get diastolicLabel => 'Bottom number';

  @override
  String get pulseLabel => 'Pulse (optional)';

  @override
  String get pulse => 'Pulse';

  @override
  String pulseValue(int count) {
    return 'pulse $count';
  }

  @override
  String get sugarLabel => 'Blood sugar';

  @override
  String get unitMmHg => 'mmHg';

  @override
  String get unitMgDl => 'mg/dL';

  @override
  String get whenMeasured => 'When was it measured?';

  @override
  String get sugarFasting => 'Fasting';

  @override
  String get sugarBeforeMeal => 'Before a meal';

  @override
  String get sugarAfterMeal => '2 h after a meal';

  @override
  String get sugarBedtime => 'At bedtime';

  @override
  String get sugarRandom => 'Other time';

  @override
  String measuredAt(String time) {
    return 'Measured at $time';
  }

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteHint => 'e.g. felt dizzy';

  @override
  String enterValueBetween(int min, int max) {
    return 'Enter a number from $min to $max';
  }

  @override
  String get levelLow => 'Low';

  @override
  String get levelNormal => 'Normal';

  @override
  String get levelElevated => 'A bit high';

  @override
  String get levelHigh => 'High';

  @override
  String get levelVeryHigh => 'Very high';

  @override
  String get noReadingsYet => 'No readings yet';

  @override
  String get readingsHelp =>
      'Log your readings here. They are included in the report for your doctor.';

  @override
  String get latestReading => 'Latest';

  @override
  String get readingAdvice =>
      'If readings like this keep happening, or you feel unwell, contact your doctor.';

  @override
  String get average7Days => '7-day average';

  @override
  String get average30Days => '30-day average';

  @override
  String get allReadings => 'All readings';

  @override
  String get deleteReadingQuestion => 'Delete this reading?';

  @override
  String get tapToAdd => 'Tap + to add';

  @override
  String get reportNoReadings => 'No readings in this period.';

  @override
  String reportBpSummary(int count, String average, String pulse) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings',
      one: '1 reading',
    );
    return '$_temp0 • average $average mmHg • average pulse $pulse';
  }

  @override
  String reportSugarSummary(int count, String average, String min, String max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings',
      one: '1 reading',
    );
    return '$_temp0 • average $average mg/dL • lowest $min • highest $max';
  }

  @override
  String get reportDateTime => 'Date & time';

  @override
  String get reportLevel => 'Level';

  @override
  String get reportReadingsNote =>
      'Readings were entered by the patient. Levels follow common guidance (AHA / ADA) and are not a diagnosis.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutStoryTitle => 'Why I built Dawaii';

  @override
  String get aboutStory =>
      'Dawaii started at home. Someone in my family takes several medicines every day, and keeping track of them (which pill, what time, did I already take it?) was a daily worry for all of us.\n\nI wanted something simple enough to use without help, in Arabic or English, with big buttons and no clutter. So I built it, and I hope it brings your family the same peace of mind.';

  @override
  String get aboutPrinciplesTitle => 'Made for older adults';

  @override
  String get principleBig => 'Big and clear';

  @override
  String get principleBigBody =>
      'Large text, big buttons, and one clear thing to do at a time.';

  @override
  String get principleLanguages => 'Arabic and English';

  @override
  String get principleLanguagesBody =>
      'Fully in both languages, written the way people actually speak.';

  @override
  String get principleGentle => 'Gentle, never bossy';

  @override
  String get principleGentleBody =>
      'Missed a dose? No red alarms or scolding. Just a calm reminder and an easy way to catch up.';

  @override
  String get principlePrivate => 'Private by design';

  @override
  String get principlePrivateBody =>
      'No account, no ads, no tracking. Your medicines and readings never leave your phone.';

  @override
  String aboutDosesLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Together, we\'ve logged $count doses. Thank you for trusting Dawaii.',
      one: 'Together, we\'ve logged your first dose. That\'s a great start!',
    );
    return '$_temp0';
  }

  @override
  String get aboutCreatorRole => 'Developer & designer';

  @override
  String get aboutFeedbackTitle => 'Ideas or problems?';

  @override
  String get aboutFeedbackBody => 'I read every message. Tap to copy my email.';

  @override
  String get aboutMadeIn => 'Made with care in Beirut 🇱🇧';

  @override
  String get aboutCredits =>
      'Fonts: Atkinson Hyperlegible Next by the Braille Institute, and IBM Plex Sans Arabic by IBM.';

  @override
  String get openSourceLicenses => 'Open-source licenses';
}
