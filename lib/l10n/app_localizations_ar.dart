// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'دوائي';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get remove => 'إزالة';

  @override
  String get undo => 'تراجع';

  @override
  String get medication => 'الدواء';

  @override
  String get yourDose => 'جرعتك';

  @override
  String get now => 'الآن';

  @override
  String get settings => 'الإعدادات';

  @override
  String get pausedMedications => 'الأدوية المتوقفة';

  @override
  String get today => 'اليوم';

  @override
  String get welcomeTitle => 'أهلًا بك في دوائي';

  @override
  String get welcomeBody =>
      'أضف دواءك الأول وسيذكّرك دوائي عندما يحين موعد أخذه.';

  @override
  String get addFirstMedication => 'أضف دوائي الأول';

  @override
  String get nothingTodayTitle => 'لا يوجد دواء اليوم';

  @override
  String get nothingDayTitle => 'لا توجد جرعات';

  @override
  String get nothingDayBody => 'لا توجد جرعات مجدولة في هذا اليوم.';

  @override
  String get allDoneTitle => 'انتهيت من جرعات اليوم!';

  @override
  String get allDoneBody => 'أخذت جميع جرعات اليوم. أحسنت.';

  @override
  String get addMedication => 'إضافة دواء';

  @override
  String get editMedication => 'تعديل الدواء';

  @override
  String get remindersNeedAttention => 'التذكيرات تحتاج إلى انتباه';

  @override
  String get reminderAttentionDefault => 'تحتاج إعدادات التذكير إلى مراجعة.';

  @override
  String get fix => 'إصلاح';

  @override
  String get unableOpenReminderSettings => 'تعذر فتح إعدادات التذكير.';

  @override
  String get notificationsAndAlarmDisabled =>
      'الإشعارات والمنبهات الدقيقة متوقفة. قد لا تصل التذكيرات في وقتها.';

  @override
  String get notificationsDisabled => 'الإشعارات متوقفة. لن تظهر التذكيرات.';

  @override
  String get exactAlarmDisabled =>
      'المنبهات الدقيقة متوقفة. قد تتأخر التذكيرات.';

  @override
  String get soundDisabled => 'صوت التذكير متوقف. ستظهر التذكيرات بلا صوت.';

  @override
  String get confirmDose => 'تأكيد الجرعة';

  @override
  String get markTakenQuestion => 'هل أخذت هذه الجرعة؟';

  @override
  String get yesTaken => 'نعم، أخذتها';

  @override
  String get skipThisDose => 'تخطي هذه الجرعة؟';

  @override
  String get skipWarning =>
      'سيتم تسجيل هذه الجرعة كمتخطاة. لا تتخطَّها إلا إذا كنت لا تريد أخذها فعلًا.';

  @override
  String get skipDose => 'تخطي الجرعة';

  @override
  String get undoDoseTitle => 'تراجع؟';

  @override
  String get undoDoseBody => 'هل تريد إلغاء تسجيل هذه الجرعة؟';

  @override
  String snoozeMedication(Object name) {
    return 'ذكّرني بـ $name';
  }

  @override
  String get remindAgainIn => 'ذكّرني مجددًا بعد:';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة',
      many: '$count دقيقة',
      few: '$count دقائق',
      two: 'دقيقتين',
      one: 'دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة',
      many: '$count ساعة',
      few: '$count ساعات',
      two: 'ساعتين',
      one: 'ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String pillsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حبة',
      many: '$count حبة',
      few: '$count حبات',
      two: 'حبتين',
      one: 'حبة واحدة',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutes(String hours, String minutes) {
    return '$hours س و$minutes د';
  }

  @override
  String inDuration(Object duration) {
    return 'بعد $duration';
  }

  @override
  String agoDuration(Object duration) {
    return 'منذ $duration';
  }

  @override
  String get lessThanMinute => 'بعد أقل من دقيقة';

  @override
  String get justNow => 'الآن';

  @override
  String get taken => 'تم أخذها';

  @override
  String takenAt(Object time) {
    return 'أُخذت الساعة $time';
  }

  @override
  String get skipped => 'تم تخطيها';

  @override
  String get missed => 'فائتة';

  @override
  String snoozedUntil(Object time) {
    return 'مؤجلة حتى $time';
  }

  @override
  String get overdue => 'متأخرة';

  @override
  String get next => 'التالية';

  @override
  String get take => 'أخذتها';

  @override
  String get snooze => 'لاحقًا';

  @override
  String get skip => 'تخطي';

  @override
  String get readAloud => 'اقرأ بصوت عالٍ';

  @override
  String get unableTake => 'تعذر حفظ هذه الجرعة.';

  @override
  String get unableSkip => 'تعذر تخطي هذه الجرعة.';

  @override
  String get unableSnooze => 'تعذر تأجيل هذا التذكير.';

  @override
  String get unableUndo => 'تعذر التراجع.';

  @override
  String get unableResume => 'تعذر استئناف الدواء.';

  @override
  String get unablePause => 'تعذر إيقاف الدواء.';

  @override
  String get unableDelete => 'تعذر حذف الدواء.';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get resume => 'استئناف';

  @override
  String get editSchedule => 'تعديل';

  @override
  String get deleteMedicationQuestion => 'حذف الدواء؟';

  @override
  String deleteMedicationMessage(Object name) {
    return 'حذف \"$name\" وكل سجله؟ لا يمكن التراجع عن ذلك.';
  }

  @override
  String deleted(Object name) {
    return 'تم حذف $name.';
  }

  @override
  String get scheduleConfiguration => 'الجدول';

  @override
  String get frequency => 'التكرار';

  @override
  String get everyDay => 'كل يوم';

  @override
  String get specificDays => 'أيام محددة';

  @override
  String get interval => 'كل بضعة أيام';

  @override
  String everyNDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'كل $count يوم',
      many: 'كل $count يومًا',
      few: 'كل $count أيام',
      two: 'يومًا بعد يوم',
      one: 'كل يوم',
    );
    return '$_temp0';
  }

  @override
  String get scheduleEnds => 'ينتهي';

  @override
  String get ongoing => 'مستمر';

  @override
  String pillsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count حبة',
      many: 'بقيت $count حبة',
      few: 'بقيت $count حبات',
      two: 'بقيت حبتان',
      one: 'بقيت حبة واحدة',
      zero: 'لم تبقَ حبات',
    );
    return '$_temp0';
  }

  @override
  String get lowStockWarning => 'أعد التعبئة قريبًا';

  @override
  String get refill => 'إعادة تعبئة';

  @override
  String get refillTitle => 'إضافة حبات';

  @override
  String get refillLabel => 'كم حبة أضفت؟';

  @override
  String get refillSaved => 'تم تحديث المخزون.';

  @override
  String get medicationInfo => 'الدواء';

  @override
  String get medicationName => 'اسم الدواء';

  @override
  String get medicationNameHint => 'مثال: بانادول';

  @override
  String get enterMedicationName => 'أدخل اسم الدواء';

  @override
  String get dosage => 'التركيز';

  @override
  String get dosageHint => 'مثال: 100mg';

  @override
  String get enterDosage => 'أدخل التركيز';

  @override
  String get numberOfPills => 'عدد الحبات في الجرعة';

  @override
  String get invalidPillCount => 'أدخل رقمًا من 1 إلى 99';

  @override
  String get instructions => 'التعليمات';

  @override
  String get stock => 'المخزون';

  @override
  String get instructionsOptional => 'تعليمات (اختياري)';

  @override
  String get instructionsHint => 'مثال: مع الطعام';

  @override
  String get pillAppearance => 'شكل الدواء';

  @override
  String get medicationType => 'الشكل';

  @override
  String get capsule => 'كبسولة';

  @override
  String get tablet => 'قرص';

  @override
  String get caplet => 'قرص ممدود';

  @override
  String get softgel => 'كبسولة هلامية';

  @override
  String get pillColor => 'اللون';

  @override
  String get colorIndigo => 'نيلي';

  @override
  String get colorGreen => 'أخضر';

  @override
  String get colorYellow => 'أصفر';

  @override
  String get colorOrange => 'برتقالي';

  @override
  String get colorRed => 'أحمر';

  @override
  String get colorPink => 'زهري';

  @override
  String get colorBlue => 'أزرق';

  @override
  String get colorBrown => 'بني';

  @override
  String get colorGray => 'رمادي';

  @override
  String get colorWhite => 'أبيض';

  @override
  String get pillPhotoOptional => 'صورة (اختياري)';

  @override
  String get pillPhotoHelp => 'الصورة الحقيقية تسهّل التعرف على الدواء.';

  @override
  String get pillPhotoAdded => 'تمت إضافة الصورة';

  @override
  String get shownInsideAppOnly => 'تظهر داخل دوائي فقط.';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get chooseFromGallery => 'اختر من الصور';

  @override
  String get cameraError =>
      'تعذر الحصول على صورة. تحقق من إذن الكاميرا وحاول مرة أخرى.';

  @override
  String get notificationPreview => 'معاينة التذكير';

  @override
  String get repeatEvery => 'التكرار كل';

  @override
  String get scheduleEnd => 'المدة';

  @override
  String get ongoingOption => 'مستمر';

  @override
  String get ongoingHelp => 'استمر في تذكيري حتى أوقفه أو أحذفه.';

  @override
  String get fixedDuration => 'لمدة محددة';

  @override
  String get days => 'أيام';

  @override
  String get weeks => 'أسابيع';

  @override
  String get months => 'أشهر';

  @override
  String get duration => 'المدة';

  @override
  String enterValueRange(Object max) {
    return 'أدخل رقمًا من 1 إلى $max';
  }

  @override
  String scheduleEndsDate(Object date) {
    return 'آخر يوم: $date';
  }

  @override
  String get doseTimings => 'أوقات التذكير';

  @override
  String get addTime => 'إضافة وقت';

  @override
  String get noTimes => 'لا توجد أوقات بعد. اضغط \"إضافة وقت\".';

  @override
  String get duplicateDoseTime => 'هذا الوقت مضاف مسبقًا.';

  @override
  String get needDoseTime => 'يرجى إضافة وقت تذكير واحد على الأقل.';

  @override
  String get needWeekday => 'يرجى اختيار يوم واحد على الأقل.';

  @override
  String get saveMedication => 'حفظ';

  @override
  String saveMedicationError(Object error) {
    return 'تعذر حفظ الدواء: $error';
  }

  @override
  String get stockSection => 'مخزون الحبات (اختياري)';

  @override
  String get trackStock => 'عُدّ حباتي';

  @override
  String get stockHelp =>
      'يطرح دوائي الحبات كلما أخذت جرعة وينبهك قبل أن تنفد.';

  @override
  String get pillsInBox => 'عدد الحبات لدي الآن';

  @override
  String get refillThreshold => 'نبّهني عندما يتبقى هذا العدد';

  @override
  String get enterWholeNumber => 'أدخل رقمًا صحيحًا';

  @override
  String get mon => 'الإثنين';

  @override
  String get tue => 'الثلاثاء';

  @override
  String get wed => 'الأربعاء';

  @override
  String get thu => 'الخميس';

  @override
  String get fri => 'الجمعة';

  @override
  String get sat => 'السبت';

  @override
  String get sun => 'الأحد';

  @override
  String get monShort => 'إثنين';

  @override
  String get tueShort => 'ثلاثاء';

  @override
  String get wedShort => 'أربعاء';

  @override
  String get thuShort => 'خميس';

  @override
  String get friShort => 'جمعة';

  @override
  String get satShort => 'سبت';

  @override
  String get sunShort => 'أحد';

  @override
  String get schedule => 'الجدول';

  @override
  String get analytics => 'التقدم';

  @override
  String get analyticsHistory => 'التقدم';

  @override
  String get timeframe => 'الفترة';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get last30Days => 'آخر 30 يومًا';

  @override
  String get thisYear => 'هذه السنة';

  @override
  String get allTime => 'كل الوقت';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get activeStreak => 'أيام كاملة متتالية';

  @override
  String get adherenceRate => 'الجرعات المأخوذة';

  @override
  String get doseBreakdown => 'الجرعات';

  @override
  String get totalDue => 'المجموع';

  @override
  String get perMedication => 'كل دواء';

  @override
  String get noSavedMedications => 'لا توجد أدوية بعد.';

  @override
  String dosePerDay(String dosage, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرة يوميًا',
      many: '$count مرة يوميًا',
      few: '$count مرات يوميًا',
      two: 'مرتين يوميًا',
      one: 'مرة يوميًا',
    );
    return '$dosage • $_temp0';
  }

  @override
  String lastTaken(Object time) {
    return 'آخر جرعة $time';
  }

  @override
  String get noDataYet => 'لا توجد بيانات بعد';

  @override
  String get adherenceExplanation =>
      'الجرعة الفائتة هي جرعة من يوم سابق لم تُسجَّل كمأخوذة أو متخطاة.';

  @override
  String get appearance => 'المظهر';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get themeSystem => 'مثل الهاتف';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get textSize => 'حجم الخط';

  @override
  String get textSizeNormal => 'عادي';

  @override
  String get textSizeLarge => 'كبير';

  @override
  String get textSizeExtraLarge => 'كبير جدًا';

  @override
  String get simpleMode => 'الوضع المبسّط';

  @override
  String get simpleModeHelp => 'اعرض أدوية اليوم فقط مع أزرار كبيرة.';

  @override
  String get remindersSection => 'التذكيرات';

  @override
  String get persistentAlarm => 'استمر بالرنين حتى أرد';

  @override
  String get persistentAlarmHelp => 'يتكرر صوت التذكير حتى تفتحه أو ترد عليه.';

  @override
  String get readAloudSetting => 'قراءة التذكيرات بصوت عالٍ';

  @override
  String get readAloudHelp =>
      'عند فتح التذكير، يقرأ دوائي اسم الدواء بصوت عالٍ.';

  @override
  String get notificationSettings => 'إعدادات الإشعارات في الهاتف';

  @override
  String get testReminder => 'إرسال تذكير تجريبي';

  @override
  String get testReminderSent => 'سيظهر تذكير تجريبي خلال ثوانٍ.';

  @override
  String get dataSection => 'بياناتك';

  @override
  String get exportBackup => 'حفظ نسخة احتياطية';

  @override
  String get exportBackupHelp => 'احفظ كل الأدوية والسجل في ملف (بدون الصور).';

  @override
  String get importBackup => 'استعادة نسخة احتياطية';

  @override
  String get importBackupHelp => 'استبدل كل شيء بملف نسخة احتياطية.';

  @override
  String get importConfirmTitle => 'استعادة النسخة الاحتياطية؟';

  @override
  String get importConfirmBody =>
      'سيتم استبدال كل الأدوية والسجل الحالي بالنسخة الاحتياطية. لا يمكن التراجع عن ذلك.';

  @override
  String get restore => 'استعادة';

  @override
  String importSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت استعادة $count دواء.',
      many: 'تمت استعادة $count دواءً.',
      few: 'تمت استعادة $count أدوية.',
      two: 'تمت استعادة دواءين.',
      one: 'تمت استعادة دواء واحد.',
    );
    return '$_temp0';
  }

  @override
  String get importError => 'هذا الملف ليس نسخة احتياطية صالحة من دوائي.';

  @override
  String get exportError => 'تعذر إنشاء النسخة الاحتياطية.';

  @override
  String get doctorReport => 'تقرير للطبيب';

  @override
  String get doctorReportHelp => 'ملف PDF لآخر 30 يومًا للمشاركة أو الطباعة.';

  @override
  String get reportError => 'تعذر إنشاء التقرير.';

  @override
  String get aboutDawaii => 'حول دوائي';

  @override
  String get aboutSubtitle => 'تذكيرات الدواء بشكل أبسط.';

  @override
  String get aboutParagraph1 =>
      'تم إنشاء دوائي لحل مشكلة يومية حقيقية: نسيان الدواء، تفويت الجرعات، وصعوبة متابعة المواعيد المختلفة.';

  @override
  String get aboutParagraph2 =>
      'يركّز التطبيق على جعل إدارة الأدوية بسيطة وواضحة وسهلة من خلال التذكيرات، وتتبع الجرعات، وتنظيم المواعيد، وواجهة سهلة الاستخدام.';

  @override
  String get createdBy => 'أنشأه آدم معتوق';

  @override
  String get creatorBio =>
      'طالب هندسة علوم الحاسوب في الجامعة الأميركية في بيروت (AUB)، مهتم بحل المشكلات الواقعية من خلال تقنيات عملية تتمحور حول المستخدم.';

  @override
  String get contact => 'التواصل';

  @override
  String emailCopied(Object email) {
    return 'تم نسخ البريد الإلكتروني: $email';
  }

  @override
  String get notificationChannelName => 'تذكيرات الدواء';

  @override
  String get notificationChannelDescription => 'تذكيرات بأخذ أدويتك';

  @override
  String get alarmChannelName => 'منبهات الدواء';

  @override
  String get alarmChannelDescription =>
      'تذكيرات دواء تستمر بالرنين حتى الرد عليها';

  @override
  String get infoChannelName => 'تنبيهات دوائي';

  @override
  String get infoChannelDescription => 'تنبيهات إعادة التعبئة وغيرها';

  @override
  String get notificationTake => 'أخذتها';

  @override
  String get notificationSnooze15 => 'بعد 15 د';

  @override
  String get notificationSkip => 'تخطي';

  @override
  String timeFor(Object name) {
    return 'حان موعد $name';
  }

  @override
  String takeDoseBody(String pillLabel, String dosage) {
    return 'خذ $pillLabel • $dosage';
  }

  @override
  String get keepAliveTitle => 'يرجى فتح دوائي';

  @override
  String get keepAliveBody => 'افتح التطبيق لتستمر تذكيرات أدويتك.';

  @override
  String lowStockTitle(Object name) {
    return '$name على وشك النفاد';
  }

  @override
  String lowStockBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count حبة فقط. يرجى إعادة التعبئة قريبًا.',
      many: 'بقيت $count حبة فقط. يرجى إعادة التعبئة قريبًا.',
      few: 'بقيت $count حبات فقط. يرجى إعادة التعبئة قريبًا.',
      two: 'بقيت حبتان فقط. يرجى إعادة التعبئة قريبًا.',
      one: 'بقيت حبة واحدة فقط. يرجى إعادة التعبئة قريبًا.',
      zero: 'لم تبقَ حبات. يرجى إعادة التعبئة.',
    );
    return '$_temp0';
  }

  @override
  String get testReminderTitle => 'تذكير تجريبي';

  @override
  String get testReminderBody => 'التذكيرات تعمل.';

  @override
  String get reportTitle => 'تقرير الأدوية';

  @override
  String reportPeriod(String from, String to) {
    return 'الفترة: $from – $to';
  }

  @override
  String reportGenerated(Object date) {
    return 'أُنشئ في $date';
  }

  @override
  String get reportMedication => 'الدواء';

  @override
  String get reportSchedule => 'الجدول';

  @override
  String get reportTaken => 'مأخوذة';

  @override
  String get reportSkipped => 'متخطاة';

  @override
  String get reportMissed => 'فائتة';

  @override
  String get reportAdherence => 'نسبة الأخذ';

  @override
  String get reportOverall => 'الإجمالي';

  @override
  String get reportMissedList => 'الجرعات الفائتة';

  @override
  String get reportNoMissed => 'لا توجد جرعات فائتة في هذه الفترة.';

  @override
  String get am => 'ص';

  @override
  String get pm => 'م';

  @override
  String get jan => 'كانون الثاني';

  @override
  String get feb => 'شباط';

  @override
  String get mar => 'آذار';

  @override
  String get apr => 'نيسان';

  @override
  String get may => 'أيار';

  @override
  String get jun => 'حزيران';

  @override
  String get jul => 'تموز';

  @override
  String get aug => 'آب';

  @override
  String get sep => 'أيلول';

  @override
  String get oct => 'تشرين الأول';

  @override
  String get nov => 'تشرين الثاني';

  @override
  String get dec => 'كانون الأول';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'نهارك سعيد';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting يا $name';
  }

  @override
  String get partMorning => 'الصباح';

  @override
  String get partAfternoon => 'بعد الظهر';

  @override
  String get partEvening => 'المساء';

  @override
  String get partNight => 'الليل';

  @override
  String sectionProgress(int taken, int total) {
    return 'أُخذ $taken من $total';
  }

  @override
  String get tookAll => 'أخذتها كلها';

  @override
  String get iTookIt => 'أخذته';

  @override
  String get iTookThemAll => 'أخذتها كلها';

  @override
  String get takeEarly => 'خذه الآن (مبكرًا)';

  @override
  String get yesTookAll => 'نعم، أخذتها كلها';

  @override
  String get confirmTakeAllTitle => 'هل أخذت كل هذه الأدوية؟';

  @override
  String get nowTimeToTake => 'حان الموعد';

  @override
  String get nowNext => 'التالي';

  @override
  String get laterToday => 'لاحقًا اليوم';

  @override
  String get backToToday => 'اليوم';

  @override
  String get add => 'إضافة';

  @override
  String get tabToday => 'اليوم';

  @override
  String get tabMedicines => 'أدويتي';

  @override
  String get medicinesTitle => 'أدويتي';

  @override
  String get activeMedicines => 'الأدوية الحالية';

  @override
  String get medicationPaused =>
      'هذا الدواء متوقف مؤقتًا. لن تصل تذكيرات حتى تستأنفه.';

  @override
  String get medicationDetails => 'تفاصيل الدواء';

  @override
  String get onbNameTitle => 'بماذا نناديك؟';

  @override
  String get onbNameHelp => 'اختياري. يستخدمه دوائي للترحيب بك.';

  @override
  String get onbNameHint => 'اسمك الأول';

  @override
  String get onbTextTitle => 'هل هذا النص سهل القراءة؟';

  @override
  String get onbTextHelp =>
      'اختر الحجم المريح لك. يمكنك تغييره لاحقًا من الإعدادات.';

  @override
  String get onbSampleName => 'أسبرين';

  @override
  String get onbRemindersTitle => 'السماح بالتذكيرات';

  @override
  String get onbRemindersBody =>
      'يحتاج دوائي إلى إذنك ليذكّرك بأدويتك، حتى عندما يكون الهاتف مقفلًا.\n\nفي الشاشة التالية، يرجى الضغط على \"السماح\".';

  @override
  String get onbAllow => 'متابعة';

  @override
  String get onbNotNow => 'ليس الآن';

  @override
  String get nextStep => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get ok => 'تم';

  @override
  String get pickTimeTitle => 'اختر الوقت';

  @override
  String get hourLabel => 'الساعة';

  @override
  String get minuteLabel => 'الدقيقة';

  @override
  String get addOtherTime => 'وقت آخر';

  @override
  String get wizNameTitle => 'ما اسم الدواء؟';

  @override
  String get wizLooksTitle => 'كيف يبدو؟';

  @override
  String get wizWhenTitle => 'متى تأخذه؟';

  @override
  String get wizHowLongTitle => 'لأي مدة؟';

  @override
  String get wizStockTitle => 'راجع واحفظ';

  @override
  String stepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get noStockTracking => 'لا، بدون عدّ';

  @override
  String get yourName => 'اسمك';

  @override
  String get yourNameHelp => 'للترحيب بك (اختياري)';

  @override
  String get saved => 'تم الحفظ.';

  @override
  String get encouragementGreat => 'ممتاز! استمر على هذا.';

  @override
  String get encouragementGood => 'عمل جيد. واصل.';

  @override
  String get encouragementLow => 'كل جرعة مهمة. أنت قادر على ذلك.';

  @override
  String takenOfLast(int taken, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'أخذت $taken من آخر $total جرعة.',
      many: 'أخذت $taken من آخر $total جرعة.',
      few: 'أخذت $taken من آخر $total جرعات.',
      two: 'أخذت $taken من آخر جرعتين.',
      one: 'أخذت $taken من آخر جرعة.',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get legendAllTaken => 'أُخذت كلها';

  @override
  String get legendSomeMissed => 'فاتت بعضها';

  @override
  String get doneTitle => 'تمّ';

  @override
  String get showDone => 'إظهار';

  @override
  String get hideDone => 'إخفاء';

  @override
  String get tookAtOtherTime => 'أخذته في وقت آخر';

  @override
  String takenSnack(String name) {
    return 'تم أخذ $name ✓';
  }

  @override
  String takenAllSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم أخذ $count جرعة ✓',
      many: 'تم أخذ $count جرعة ✓',
      few: 'تم أخذ $count جرعات ✓',
      two: 'تم أخذ جرعتين ✓',
      one: 'تم أخذ جرعة واحدة ✓',
    );
    return '$_temp0';
  }

  @override
  String snoozedFor(String duration) {
    return 'سأذكّرك مجددًا بعد $duration.';
  }

  @override
  String minutesShort(int count) {
    return '$count د';
  }

  @override
  String hoursShort(int count) {
    return '$count س';
  }

  @override
  String todayProgress(int taken, int total) {
    return 'أُخذ $taken من $total اليوم';
  }

  @override
  String dosesLeftToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count جرعة',
      many: 'بقيت $count جرعة',
      few: 'بقيت $count جرعات',
      two: 'بقيت جرعتان',
      one: 'بقيت جرعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String lastsUntil(String date) {
    return 'تكفي حتى $date';
  }

  @override
  String get presetOnce => 'مرة يوميًا';

  @override
  String get presetTwice => 'مرتين يوميًا';

  @override
  String get presetThree => '3 مرات يوميًا';

  @override
  String get presetBedtime => 'قبل النوم';

  @override
  String get summaryTitle => 'يرجى المراجعة';

  @override
  String get myHealth => 'صحتي';

  @override
  String get healthTitle => 'قياساتي الصحية';

  @override
  String get bloodPressure => 'ضغط الدم';

  @override
  String get bloodSugar => 'السكر في الدم';

  @override
  String get addBloodPressure => 'إضافة قياس الضغط';

  @override
  String get addBloodSugar => 'إضافة قياس السكر';

  @override
  String get systolicLabel => 'الرقم الأعلى';

  @override
  String get diastolicLabel => 'الرقم الأدنى';

  @override
  String get pulseLabel => 'النبض (اختياري)';

  @override
  String get pulse => 'النبض';

  @override
  String pulseValue(int count) {
    return 'النبض $count';
  }

  @override
  String get sugarLabel => 'السكر';

  @override
  String get unitMmHg => 'ملم زئبق';

  @override
  String get unitMgDl => 'ملغ/دل';

  @override
  String get whenMeasured => 'متى تم القياس؟';

  @override
  String get sugarFasting => 'صائم';

  @override
  String get sugarBeforeMeal => 'قبل الأكل';

  @override
  String get sugarAfterMeal => 'بعد الأكل بساعتين';

  @override
  String get sugarBedtime => 'قبل النوم';

  @override
  String get sugarRandom => 'وقت آخر';

  @override
  String measuredAt(String time) {
    return 'تم القياس الساعة $time';
  }

  @override
  String get noteOptional => 'ملاحظة (اختياري)';

  @override
  String get noteHint => 'مثال: شعرت بدوخة';

  @override
  String enterValueBetween(int min, int max) {
    return 'أدخل رقمًا من $min إلى $max';
  }

  @override
  String get levelLow => 'منخفض';

  @override
  String get levelNormal => 'طبيعي';

  @override
  String get levelElevated => 'مرتفع قليلًا';

  @override
  String get levelHigh => 'مرتفع';

  @override
  String get levelVeryHigh => 'مرتفع جدًا';

  @override
  String get noReadingsYet => 'لا توجد قياسات بعد';

  @override
  String get readingsHelp =>
      'سجّل قياساتك هنا. ستُضاف إلى التقرير الخاص بطبيبك.';

  @override
  String get latestReading => 'آخر قياس';

  @override
  String get readingAdvice =>
      'إذا تكررت قياسات كهذه أو شعرت بتوعك، تواصل مع طبيبك.';

  @override
  String get average7Days => 'متوسط 7 أيام';

  @override
  String get average30Days => 'متوسط 30 يومًا';

  @override
  String get allReadings => 'كل القياسات';

  @override
  String get deleteReadingQuestion => 'حذف هذا القياس؟';

  @override
  String get tapToAdd => 'اضغط + للإضافة';

  @override
  String get reportNoReadings => 'لا توجد قياسات في هذه الفترة.';

  @override
  String reportBpSummary(int count, String average, String pulse) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قياس',
      many: '$count قياسًا',
      few: '$count قياسات',
      two: 'قياسان',
      one: 'قياس واحد',
    );
    return '$_temp0 • المتوسط $average ملم زئبق • متوسط النبض $pulse';
  }

  @override
  String reportSugarSummary(int count, String average, String min, String max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قياس',
      many: '$count قياسًا',
      few: '$count قياسات',
      two: 'قياسان',
      one: 'قياس واحد',
    );
    return '$_temp0 • المتوسط $average ملغ/دل • الأدنى $min • الأعلى $max';
  }

  @override
  String get reportDateTime => 'التاريخ والوقت';

  @override
  String get reportLevel => 'المستوى';

  @override
  String get reportReadingsNote =>
      'أدخل المريض هذه القياسات. تتبع المستويات الإرشادات الشائعة (AHA / ADA) وليست تشخيصًا.';
}
