import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance =
      LanguageService._internal();

  factory LanguageService() => _instance;

  LanguageService._internal();

  static const String _languageKey =
      'app_language_code';

  String _languageCode = 'en';

  String get languageCode => _languageCode;

  Locale get locale => Locale(_languageCode);

  bool get isArabic => _languageCode == 'ar';

  Future<void> loadLanguage() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getString(_languageKey);

    _languageCode =
        saved == 'ar' ? 'ar' : 'en';
  }

  Future<void> setLanguageCode(
    String languageCode,
  ) async {
    final normalized =
        languageCode == 'ar' ? 'ar' : 'en';

    if (_languageCode == normalized) {
      return;
    }

    _languageCode = normalized;
    notifyListeners();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _languageKey,
      normalized,
    );
  }

  Future<void> toggleLanguage() async {
    await setLanguageCode(
      isArabic ? 'en' : 'ar',
    );
  }

  String tr(
    String key, {
    Map<String, Object?> params =
        const <String, Object?>{},
  }) {
    final table =
        isArabic ? _ar : _en;

    String value =
        table[key] ?? _en[key] ?? key;

    params.forEach((name, replacement) {
      value = value.replaceAll(
        '{$name}',
        replacement?.toString() ?? '',
      );
    });

    return value;
  }

  static const Map<String, String> _en = {
    'appName': 'Dawaii',
    'mainMenu': 'MAIN MENU',
    'pausedMedications': 'Paused Medications',
    'oneMedicationPaused': '1 medication paused',
    'medicationsPaused': '{count} medications paused',
    'darkMode': 'Dark Mode',
    'on': 'On',
    'off': 'Off',
    'language': 'Language',
    'english': 'English',
    'arabic': 'العربية',
    'aboutDawaii': 'About Dawaii',
    'aboutSubtitle': 'Medication reminders made simpler.',
    'aboutParagraph1':
        'Dawaii was created to solve a real everyday problem: forgetting medication, missing doses, and struggling to keep track of different schedules.',
    'aboutParagraph2':
        'The app focuses on making medication management simple, clear, and accessible through reminders, dose tracking, scheduling, and an easy-to-use interface.',
    'createdBy': 'Created by Adam Maatouk',
    'creatorBio':
        'Computer Science & Engineering student at the American University of Beirut (AUB), interested in solving real-world problems through practical, user-centered technology.',
    'contact': 'Contact',
    'emailCopied': 'Email copied: {email}',
    'showingPaused': 'Showing Paused Medications',
    'noPaused': 'No Paused Medications',
    'allClearToday': 'All Clear for Today!',
    'pausedEmpty':
        'When you temporarily pause a medication schedule, it will appear here.',
    'scheduleEmpty':
        'No medication doses are scheduled for this day. Tap below to create a schedule.',
    'addSchedule': 'Add Schedule',
    'addMedication': 'Add Medication',
    'editMedication': 'Edit Medication',
    'medicationInfo': 'Medication Info',
    'medicationName': 'Medication Name',
    'medicationNameHint': 'e.g. Aspirin',
    'enterMedicationName': 'Enter medication name',
    'dosage': 'Dosage',
    'dosageHint': 'e.g. 200mg or 1 pill',
    'enterDosage': 'Enter dosage',
    'numberOfPills': 'Number of Pills',
    'pillCountHint': 'e.g. 1 or 2',
    'invalidPillCount': 'Enter a valid number of pills',
    'max99Pills': 'Enter 99 pills or fewer',
    'instructionsOptional': 'Instructions (Optional)',
    'instructionsHint': 'e.g. Take with a meal',
    'pillAppearance': 'Pill Appearance',
    'medicationType': 'Medication Type',
    'pillColor': 'Pill Color',
    'selectPillColor': 'Select pill color',
    'notificationPreview': 'Notification Preview',
    'frequency': 'Frequency',
    'everyDay': 'Every Day',
    'specificDays': 'Specific Days',
    'interval': 'Interval',
    'repeatEvery': 'Repeat every',
    'valueDays': '{value} days',
    'scheduleEnd': 'Schedule End',
    'treatmentDuration': 'Treatment Duration',
    'durationHelp':
        'Choose how long this medication schedule should stay active.',
    'days': 'Days',
    'weeks': 'Weeks',
    'months': 'Months',
    'duration': 'Duration',
    'enterDurationRange': 'Enter 1–{max}',
    'maximumDuration': 'Maximum: {max} {unit}',
    'enterValueRange': 'Enter a value from 1 to {max}',
    'maximumIs': 'Maximum is {max} {unit}',
    'scheduleEndsDate': 'Schedule ends {date}',
    'doseTimings': 'Dose Timings',
    'scheduledTimes': 'Scheduled Times',
    'addTime': 'Add Time',
    'noTimes':
        'No times added yet. Tap "Add Time".',
    'updateSchedule': 'Update Schedule',
    'saveMedicationSchedule':
        'Save Medication Schedule',
    'pillPhotoOptional': 'Pill Photo (Optional)',
    'pillPhotoHelp':
        'Add a real photo to make this medication easier to recognize in the app.',
    'pillPhotoAdded': 'Pill photo added',
    'shownInsideAppOnly': 'Shown inside Dawaii only.',
    'retake': 'Retake',
    'remove': 'Remove',
    'addPillPhoto': 'Add Pill Photo',
    'cameraError':
        'Unable to take a pill photo. Please check camera permission and try again.',
    'duplicateDoseTime':
        'This dose time has already been added.',
    'needDoseTime':
        'Please add at least one scheduled dose time.',
    'needWeekday':
        'Please select at least one day of the week.',
    'saveMedicationError':
        'Unable to save medication: {error}',
    'medication': 'Medication',
    'yourDose': 'your dose',
    'onePill': '1 pill',
    'pillsCount': '{count} pills',
    'timeFor': 'Time for {name}',
    'takeDoseBody': 'Take {pillLabel} • {dosage}',
    'now': 'now',
    'capsule': 'Capsule',
    'tablet': 'Tablet',
    'caplet': 'Caplet',
    'softgel': 'Softgel',
    'mon': 'Mon',
    'tue': 'Tue',
    'wed': 'Wed',
    'thu': 'Thu',
    'fri': 'Fri',
    'sat': 'Sat',
    'sun': 'Sun',
    'monShort': 'MON',
    'tueShort': 'TUE',
    'wedShort': 'WED',
    'thuShort': 'THU',
    'friShort': 'FRI',
    'satShort': 'SAT',
    'sunShort': 'SUN',
    'am': 'AM',
    'pm': 'PM',
    'dayUnit': 'days',
    'weekUnit': 'weeks',
    'monthUnit': 'months',
    'jan': 'Jan',
    'feb': 'Feb',
    'mar': 'Mar',
    'apr': 'Apr',
    'may': 'May',
    'jun': 'Jun',
    'jul': 'Jul',
    'aug': 'Aug',
    'sep': 'Sep',
    'oct': 'Oct',
    'nov': 'Nov',
    'dec': 'Dec',
    'unableLoadMedications':
        'Unable to load medications.',
    'unableOpenReminderSettings':
        'Unable to open reminder settings.',
    'reminderAttentionDefault':
        'Your reminder settings need attention.',
    'remindersNeedAttention':
        'Reminders need attention',
    'fix': 'Fix',
    'unableTake':
        'Unable to mark dose as taken.',
    'confirmDose': 'Confirm dose',
    'markTakenQuestion':
        'Mark this dose as taken?',
    'cancel': 'Cancel',
    'yesTaken': 'Yes, Taken',
    'unableSkip': 'Unable to skip this dose.',
    'skipThisDose': 'Skip this dose?',
    'skipWarning':
        'This dose will be marked as skipped. Make sure you really want to skip it.',
    'skipDose': 'Skip Dose',
    'unableSnooze':
        'Unable to snooze this reminder.',
    'snoozeMedication': 'Snooze {name}',
    'remindAgainIn': 'Remind me again in:',
    'fifteenMinutes': '15 minutes',
    'quickReminder': 'Quick reminder',
    'thirtyMinutes': '30 minutes',
    'remindLittleLater':
        'Remind me a little later',
    'oneHour': '1 hour',
    'remindOneHour': 'Remind me in one hour',
    'twoHours': '2 hours',
    'remindTwoHours': 'Remind me in two hours',
    'unableResume':
        'Unable to resume medication.',
    'unablePause':
        'Unable to pause medication.',
    'deleteMedicationQuestion':
        'Delete Medication?',
    'deleteMedicationMessage':
        'Delete "{name}" and its schedule? This action cannot be undone.',
    'delete': 'Delete',
    'deleted': '{name} deleted.',
    'unableDelete':
        'Unable to delete medication.',
    'dose': 'Dose: {summary}',
    'scheduleConfiguration':
        'Schedule Configuration',
    'timesPerDay': 'Times / Day',
    'dosesCount': '{count} Doses',
    'scheduleEnds': 'Schedule Ends',
    'pause': 'Pause',
    'resume': 'Resume',
    'editSchedule': 'Edit Schedule',
    'edit': 'Edit',
    'snoozedSuffix': '(Snoozed)',
    'takenAt': 'Taken at {time}',
    'taken': 'Taken',
    'skipped': 'Skipped',
    'take': 'Take',
    'snooze': 'Snooze',
    'skip': 'Skip',
    'next': 'NEXT',
    'overdue': 'OVERDUE',
    'schedule': 'Schedule',
    'analytics': 'Analytics',
    'analyticsHistory': 'Analytics & History',
    'syncData': 'Sync Data',
    'timeframe': 'Timeframe',
    'last7Days': 'Last 7 Days',
    'last30Days': 'Last 30 Days',
    'thisYear': 'This Year',
    'allTime': 'All Time',
    'streakDays': '{count} Days',
    'activeStreak': 'Active Streak',
    'adherenceRate': 'Adherence Rate',
    'doseBreakdown': 'Dose Breakdown',
    'totalLogged': 'Total Logged',
    'medicationsAdherence':
        'Medications Adherence',
    'noSavedMedications':
        'No saved medications yet.',
    'dosePerDay':
        '{dosage} • {count} dose/day',
    'lastTaken': 'Last taken {time}',
    'nowRelative': 'Now',
    'lessThanMinute':
        'In less than 1 min',
    'inMinutes': 'In {count} {unit}',
    'minute': 'min',
    'minutes': 'mins',
    'inHours': 'In {count} {unit}',
    'hour': 'hour',
    'hours': 'hours',
    'inHoursMinutes': 'In {hours}h {minutes}m',
    'justNow': 'just now',
    'agoMinutes': '{count} {unit}',
    'agoHours': '{count} {unit}',
    'agoHoursMinutes': '{hours}h {minutes}m',
    'agoDays': '{count} {unit}',
    'day': 'day',
    'daysLower': 'days',
    'notificationChannelName': 'Pill Reminders',
    'notificationChannelDescription':
        'Notifications for pill schedules',
    'notificationTake': 'Take',
    'notificationSnooze15': 'Snooze 15m',
    'notificationSkip': 'Skip',
    'notificationsAndAlarmDisabled':
        'Notifications and exact alarm access are disabled. Medication reminders may not appear on time.',
    'notificationsDisabled':
        'Notifications are disabled. Medication reminders cannot appear.',
    'exactAlarmDisabled':
        'Exact alarm access is disabled. Medication reminders may not arrive exactly on time.',
    'soundDisabled':
        'Reminder sound is disabled. Notifications can still appear silently.',
    'snoozedReminder':
        'Snoozed Pill Reminder',
    'dontForget':
        "Don't forget to take your medication!",
  };

  static const Map<String, String> _ar = {
    'appName': 'دوائي',
    'mainMenu': 'القائمة الرئيسية',
    'pausedMedications': 'الأدوية المتوقفة مؤقتًا',
    'oneMedicationPaused': 'دواء واحد متوقف مؤقتًا',
    'medicationsPaused': '{count} أدوية متوقفة مؤقتًا',
    'darkMode': 'الوضع الداكن',
    'on': 'مفعّل',
    'off': 'غير مفعّل',
    'language': 'اللغة',
    'english': 'English',
    'arabic': 'العربية',
    'aboutDawaii': 'حول دوائي',
    'aboutSubtitle': 'تذكيرات الدواء بشكل أبسط.',
    'aboutParagraph1':
        'تم إنشاء دوائي لحل مشكلة يومية حقيقية: نسيان الدواء، تفويت الجرعات، وصعوبة متابعة المواعيد المختلفة.',
    'aboutParagraph2':
        'يركّز التطبيق على جعل إدارة الأدوية بسيطة وواضحة وسهلة من خلال التذكيرات، وتتبع الجرعات، وتنظيم المواعيد، وواجهة سهلة الاستخدام.',
    'createdBy': 'أنشأه آدم معتوق',
    'creatorBio':
        'طالب هندسة علوم الحاسوب في الجامعة الأميركية في بيروت (AUB)، مهتم بحل المشكلات الواقعية من خلال تقنيات عملية تتمحور حول المستخدم.',
    'contact': 'التواصل',
    'emailCopied': 'تم نسخ البريد الإلكتروني: {email}',
    'showingPaused': 'عرض الأدوية المتوقفة مؤقتًا',
    'noPaused': 'لا توجد أدوية متوقفة مؤقتًا',
    'allClearToday': 'لا توجد جرعات متبقية اليوم!',
    'pausedEmpty':
        'عند إيقاف جدول دواء مؤقتًا، سيظهر هنا.',
    'scheduleEmpty':
        'لا توجد جرعات دواء مجدولة لهذا اليوم. اضغط أدناه لإضافة جدول.',
    'addSchedule': 'إضافة جدول',
    'addMedication': 'إضافة دواء',
    'editMedication': 'تعديل الدواء',
    'medicationInfo': 'معلومات الدواء',
    'medicationName': 'اسم الدواء',
    'medicationNameHint': 'مثال: بانادول',
    'enterMedicationName': 'أدخل اسم الدواء',
    'dosage': 'الجرعة',
    'dosageHint': 'مثال: 200mg أو حبة واحدة',
    'enterDosage': 'أدخل الجرعة',
    'numberOfPills': 'عدد الحبات',
    'pillCountHint': 'مثال: 1 أو 2',
    'invalidPillCount': 'أدخل عددًا صحيحًا من الحبات',
    'max99Pills': 'الحد الأقصى 99 حبة',
    'instructionsOptional': 'تعليمات (اختياري)',
    'instructionsHint': 'مثال: يؤخذ مع الطعام',
    'pillAppearance': 'شكل الدواء',
    'medicationType': 'نوع الدواء',
    'pillColor': 'لون الدواء',
    'selectPillColor': 'اختر لون الدواء',
    'notificationPreview': 'معاينة الإشعار',
    'frequency': 'التكرار',
    'everyDay': 'كل يوم',
    'specificDays': 'أيام محددة',
    'interval': 'كل عدة أيام',
    'repeatEvery': 'التكرار كل',
    'valueDays': '{value} أيام',
    'scheduleEnd': 'نهاية الجدول',
    'treatmentDuration': 'مدة العلاج',
    'durationHelp':
        'اختر المدة التي تريد أن يبقى فيها جدول هذا الدواء فعالًا.',
    'days': 'أيام',
    'weeks': 'أسابيع',
    'months': 'أشهر',
    'duration': 'المدة',
    'enterDurationRange': 'أدخل قيمة من 1 إلى {max}',
    'maximumDuration': 'الحد الأقصى: {max} {unit}',
    'enterValueRange': 'أدخل قيمة من 1 إلى {max}',
    'maximumIs': 'الحد الأقصى هو {max} {unit}',
    'scheduleEndsDate': 'ينتهي الجدول في {date}',
    'doseTimings': 'مواعيد الجرعات',
    'scheduledTimes': 'الأوقات المجدولة',
    'addTime': 'إضافة وقت',
    'noTimes': 'لم تتم إضافة أوقات بعد. اضغط "إضافة وقت".',
    'updateSchedule': 'تحديث الجدول',
    'saveMedicationSchedule': 'حفظ جدول الدواء',
    'pillPhotoOptional': 'صورة الدواء (اختياري)',
    'pillPhotoHelp':
        'أضف صورة حقيقية لتسهيل التعرف على هذا الدواء داخل التطبيق.',
    'pillPhotoAdded': 'تمت إضافة صورة الدواء',
    'shownInsideAppOnly': 'تظهر داخل دوائي فقط.',
    'retake': 'إعادة التصوير',
    'remove': 'إزالة',
    'addPillPhoto': 'إضافة صورة للدواء',
    'cameraError':
        'تعذر التقاط صورة للدواء. تحقق من إذن الكاميرا وحاول مرة أخرى.',
    'duplicateDoseTime':
        'تمت إضافة هذا الوقت مسبقًا.',
    'needDoseTime':
        'يرجى إضافة موعد جرعة واحد على الأقل.',
    'needWeekday':
        'يرجى اختيار يوم واحد على الأقل من الأسبوع.',
    'saveMedicationError':
        'تعذر حفظ الدواء: {error}',
    'medication': 'الدواء',
    'yourDose': 'جرعتك',
    'onePill': 'حبة واحدة',
    'pillsCount': '{count} حبات',
    'timeFor': 'حان موعد {name}',
    'takeDoseBody': 'خذ {pillLabel} • {dosage}',
    'now': 'الآن',
    'capsule': 'كبسولة',
    'tablet': 'قرص',
    'caplet': 'قرص ممدود',
    'softgel': 'كبسولة هلامية',
    'mon': 'الإثنين',
    'tue': 'الثلاثاء',
    'wed': 'الأربعاء',
    'thu': 'الخميس',
    'fri': 'الجمعة',
    'sat': 'السبت',
    'sun': 'الأحد',
    'monShort': 'إثن',
    'tueShort': 'ثلا',
    'wedShort': 'أرب',
    'thuShort': 'خمي',
    'friShort': 'جمع',
    'satShort': 'سبت',
    'sunShort': 'أحد',
    'am': 'ص',
    'pm': 'م',
    'dayUnit': 'يومًا',
    'weekUnit': 'أسبوعًا',
    'monthUnit': 'شهرًا',
    'jan': 'ينا',
    'feb': 'فبر',
    'mar': 'مار',
    'apr': 'أبر',
    'may': 'ماي',
    'jun': 'يون',
    'jul': 'يول',
    'aug': 'أغس',
    'sep': 'سبت',
    'oct': 'أكت',
    'nov': 'نوف',
    'dec': 'ديس',
    'unableLoadMedications': 'تعذر تحميل الأدوية.',
    'unableOpenReminderSettings':
        'تعذر فتح إعدادات التذكيرات.',
    'reminderAttentionDefault':
        'تحتاج إعدادات التذكير إلى مراجعة.',
    'remindersNeedAttention':
        'التذكيرات تحتاج إلى مراجعة',
    'fix': 'إصلاح',
    'unableTake':
        'تعذر تسجيل الجرعة كمأخوذة.',
    'confirmDose': 'تأكيد الجرعة',
    'markTakenQuestion':
        'هل تريد تسجيل هذه الجرعة كمأخوذة؟',
    'cancel': 'إلغاء',
    'yesTaken': 'نعم، تم أخذها',
    'unableSkip': 'تعذر تخطي هذه الجرعة.',
    'skipThisDose': 'تخطي هذه الجرعة؟',
    'skipWarning':
        'سيتم تسجيل هذه الجرعة كمتخطاة. تأكد من أنك تريد تخطيها.',
    'skipDose': 'تخطي الجرعة',
    'unableSnooze':
        'تعذر تأجيل هذا التذكير.',
    'snoozeMedication': 'تأجيل تذكير {name}',
    'remindAgainIn': 'ذكّرني مجددًا بعد:',
    'fifteenMinutes': '15 دقيقة',
    'quickReminder': 'تذكير سريع',
    'thirtyMinutes': '30 دقيقة',
    'remindLittleLater': 'ذكّرني بعد قليل',
    'oneHour': 'ساعة واحدة',
    'remindOneHour': 'ذكّرني بعد ساعة',
    'twoHours': 'ساعتان',
    'remindTwoHours': 'ذكّرني بعد ساعتين',
    'unableResume':
        'تعذر استئناف الدواء.',
    'unablePause':
        'تعذر إيقاف الدواء مؤقتًا.',
    'deleteMedicationQuestion':
        'حذف الدواء؟',
    'deleteMedicationMessage':
        'حذف "{name}" وجدوله؟ لا يمكن التراجع عن هذا الإجراء.',
    'delete': 'حذف',
    'deleted': 'تم حذف {name}.',
    'unableDelete': 'تعذر حذف الدواء.',
    'dose': 'الجرعة: {summary}',
    'scheduleConfiguration': 'إعدادات الجدول',
    'timesPerDay': 'مرات يوميًا',
    'dosesCount': '{count} جرعات',
    'scheduleEnds': 'ينتهي الجدول',
    'pause': 'إيقاف مؤقت',
    'resume': 'استئناف',
    'editSchedule': 'تعديل الجدول',
    'edit': 'تعديل',
    'snoozedSuffix': '(مؤجّل)',
    'takenAt': 'تم أخذها عند {time}',
    'taken': 'تم أخذها',
    'skipped': 'تم تخطيها',
    'take': 'أخذت الدواء',
    'snooze': 'ذكّرني لاحقًا',
    'skip': 'تخطي',
    'next': 'التالي',
    'overdue': 'متأخر',
    'schedule': 'الجدول',
    'analytics': 'الإحصائيات',
    'analyticsHistory': 'الإحصائيات والسجل',
    'syncData': 'تحديث البيانات',
    'timeframe': 'الفترة',
    'last7Days': 'آخر 7 أيام',
    'last30Days': 'آخر 30 يومًا',
    'thisYear': 'هذه السنة',
    'allTime': 'كل الوقت',
    'streakDays': '{count} أيام',
    'activeStreak': 'سلسلة الالتزام',
    'adherenceRate': 'نسبة الالتزام',
    'doseBreakdown': 'تفاصيل الجرعات',
    'totalLogged': 'إجمالي المسجل',
    'medicationsAdherence': 'الالتزام بالأدوية',
    'noSavedMedications': 'لا توجد أدوية محفوظة بعد.',
    'dosePerDay': '{dosage} • {count} جرعة/يوم',
    'lastTaken': 'آخر جرعة أُخذت {time}',
    'nowRelative': 'الآن',
    'lessThanMinute': 'خلال أقل من دقيقة',
    'inMinutes': 'خلال {count} {unit}',
    'minute': 'دقيقة',
    'minutes': 'دقائق',
    'inHours': 'خلال {count} {unit}',
    'hour': 'ساعة',
    'hours': 'ساعات',
    'inHoursMinutes': 'خلال {hours} س و{minutes} د',
    'justNow': 'الآن',
    'agoMinutes': 'منذ {count} {unit}',
    'agoHours': 'منذ {count} {unit}',
    'agoHoursMinutes': 'منذ {hours} س و{minutes} د',
    'agoDays': 'منذ {count} {unit}',
    'day': 'يوم',
    'daysLower': 'أيام',
    'notificationChannelName': 'تذكيرات الدواء',
    'notificationChannelDescription': 'إشعارات مواعيد الأدوية',
    'notificationTake': 'أخذت الدواء',
    'notificationSnooze15': 'ذكّرني بعد 15 د',
    'notificationSkip': 'تخطي',
    'notificationsAndAlarmDisabled':
        'الإشعارات وإذن المنبّه الدقيق غير مفعّلين. قد لا تصل تذكيرات الدواء في وقتها.',
    'notificationsDisabled':
        'الإشعارات غير مفعّلة. لن تظهر تذكيرات الدواء.',
    'exactAlarmDisabled':
        'إذن المنبّه الدقيق غير مفعّل. قد لا تصل التذكيرات في وقتها تمامًا.',
    'soundDisabled':
        'صوت التذكير غير مفعّل. قد تظهر الإشعارات من دون صوت.',
    'snoozedReminder': 'تذكير دواء مؤجّل',
    'dontForget': 'لا تنسَ أخذ دوائك!',
  };
}
