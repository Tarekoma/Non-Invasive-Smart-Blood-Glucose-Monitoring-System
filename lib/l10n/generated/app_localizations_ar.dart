// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonSomethingWentWrong => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get routeErrorTitle => 'الصفحة غير موجودة';

  @override
  String get routeErrorMessage => 'الشاشة التي تبحث عنها غير موجودة.';

  @override
  String get routeErrorGoHome => 'العودة';

  @override
  String get glucoseZoneHypoglycemia => 'نقص سكر الدم';

  @override
  String get glucoseZoneNormal => 'طبيعي';

  @override
  String get glucoseZonePreDiabetic => 'ما قبل السكري';

  @override
  String get glucoseZoneHyperglycemia => 'ارتفاع سكر الدم';

  @override
  String get dateToday => 'اليوم';

  @override
  String get dateYesterday => 'أمس';

  @override
  String dateDaysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get bleConnected => 'متصل';

  @override
  String get bleScanning => 'جارٍ البحث…';

  @override
  String get bleConnecting => 'جارٍ الاتصال…';

  @override
  String get bleDisconnected => 'غير متصل';

  @override
  String get placeholderPersonalHome => 'شخصي · الرئيسية';

  @override
  String get placeholderPersonalReadings => 'شخصي · القراءات';

  @override
  String get placeholderPersonalReminders => 'شخصي · التذكيرات';

  @override
  String get placeholderPersonalProfile => 'شخصي · الملف الشخصي';

  @override
  String get placeholderClinicDashboard => 'العيادة · لوحة التحكم';

  @override
  String get placeholderClinicSearch => 'العيادة · البحث';

  @override
  String placeholderClinicMeasure(String patientId) {
    return 'العيادة · القياس (المريض $patientId)';
  }

  @override
  String get placeholderClinicSuccess => 'العيادة · تم بنجاح';

  @override
  String get placeholderClinicPatients => 'العيادة · المرضى';

  @override
  String get modeSelectionAppName => 'GlucoTrack';

  @override
  String get modeSelectionTagline => 'جهاز غير جراحي لمراقبة سكر الدم';

  @override
  String get modeSelectionPersonalTitle => 'الاستخدام الشخصي';

  @override
  String get modeSelectionPersonalSubtitle =>
      'تتبع مستوى السكر لديك ومؤشراتك الحيوية';

  @override
  String get modeSelectionClinicTitle => 'عيادة أو مستشفى';

  @override
  String get modeSelectionClinicSubtitle => 'بإشراف تمريضي لعدة مرضى';

  @override
  String get modeSelectionClinicComingSoon => 'قريبًا';

  @override
  String get clinicNavDashboard => 'لوحة التحكم';

  @override
  String get clinicNavNewPatient => 'مريض جديد';

  @override
  String get clinicNavSearch => 'بحث';

  @override
  String get clinicNavPatients => 'المرضى';

  @override
  String get clinicModeTitle => 'وضع العيادة / المستشفى';

  @override
  String get personalShellNavHome => 'الرئيسية';

  @override
  String get personalShellNavReadings => 'القراءات';

  @override
  String get personalShellNavReminders => 'التذكيرات';

  @override
  String get personalShellNavProfile => 'الملف الشخصي';

  @override
  String get personalShellDeviceConnected => 'الجهاز متصل';

  @override
  String get personalShellDeviceScanning => 'جارٍ البحث...';

  @override
  String get personalShellDeviceConnecting => 'جارٍ الاتصال...';

  @override
  String get personalShellDeviceNotConnected => 'الجهاز غير متصل';

  @override
  String get homeGoodMorning => 'صباح الخير';

  @override
  String get homeGoodAfternoon => 'طاب يومك';

  @override
  String get homeGoodEvening => 'مساء الخير';

  @override
  String get homeGuestName => 'صديقي';

  @override
  String homeGreeting(String greeting, String name) {
    return '$greeting، $name 👋';
  }

  @override
  String get homeRecentReadings => 'القراءات الأخيرة';

  @override
  String get homeViewAll => 'عرض الكل ←';

  @override
  String get homeCouldNotLoadReadings => 'تعذر تحميل القراءات';

  @override
  String get homeNoReadingsYet => 'لا توجد قراءات بعد';

  @override
  String get homeMgDlUnit => 'ملغ/دل';

  @override
  String homeReadingTimestamp(String relative, String time) {
    return '$relative، $time';
  }

  @override
  String get homeTodaysAverage => 'متوسط اليوم';

  @override
  String get homeTimeInRange => 'الوقت ضمن النطاق';

  @override
  String get homeCompleteProfileFirst => 'يرجى إكمال إعداد الملف الشخصي أولاً';

  @override
  String homeScanFailed(String error) {
    return 'فشل المسح: $error';
  }

  @override
  String get homeScanning => 'جارٍ المسح…';

  @override
  String get homeStartNewMeasurement => '▶  بدء قياس جديد';

  @override
  String get homeKeepFingerOnSensor => 'أبقِ إصبعك على المستشعر';

  @override
  String get homeMeasurementSaved => 'تم حفظ القياس ✅';

  @override
  String get homeNotesOptional => 'ملاحظات (اختياري)';

  @override
  String get homeSaveMeasurement => '💾  حفظ القياس';

  @override
  String get homeTakeFirstMeasurement => 'قم بأول قياس لك';

  @override
  String get readingCardLatestReading => 'أحدث قراءة';

  @override
  String get readingCardMgDlUnit => 'ملغ/دل';

  @override
  String readingCardTodayAt(String time) {
    return 'اليوم الساعة $time';
  }

  @override
  String readingCardHeartRate(int bpm) {
    return ' · ❤ $bpm نبضة/د';
  }

  @override
  String readingCardBpValue(int systolic, int diastolic) {
    return 'ضغط الدم: $systolic/$diastolic ملم زئبق';
  }

  @override
  String get readingCardAm => 'ص';

  @override
  String get readingCardPm => 'م';

  @override
  String get readingsTitle => 'قراءات الجلوكوز';

  @override
  String get readingsAllReadings => 'جميع القراءات';

  @override
  String get readingsDaily => 'يومي';

  @override
  String get readingsWeekly => 'أسبوعي';

  @override
  String get readingsMonthly => 'شهري';

  @override
  String get readingsCouldNotLoadChart => 'تعذر تحميل الرسم البياني';

  @override
  String get readingsNoReadingsForPeriod => 'لا توجد قراءات لهذه الفترة';

  @override
  String get readingsAvg => 'المتوسط';

  @override
  String get readingsMin => 'الأدنى';

  @override
  String get readingsMax => 'الأعلى';

  @override
  String get readingsStdDev => 'الانحراف المعياري';

  @override
  String get readingsTir => 'الوقت ضمن النطاق';

  @override
  String get readingsMgdl => 'ملغ/دل';

  @override
  String get readingsTirRange => '70–140 ملغ/دل';

  @override
  String get readingsBpm => 'نبضة/د';

  @override
  String get readingsNewer => 'الأحدث';

  @override
  String get readingsOlder => 'الأقدم';

  @override
  String get readingsEmptyHistory =>
      'لا يوجد سجل قراءات بعد.\nقم بإجراء قياسك الأول!';

  @override
  String get patientRegYourProfileTitle => 'ملفك الشخصي';

  @override
  String get patientRegNewPatientTitle => 'مريض جديد';

  @override
  String get patientRegBasicInformation => 'المعلومات الأساسية';

  @override
  String get patientRegFullNameLabel => 'الاسم الكامل';

  @override
  String get patientRegFullNameHint => 'أدخل الاسم الكامل';

  @override
  String get patientRegNameRequired => 'الاسم مطلوب';

  @override
  String get patientRegPhoneLabel => 'رقم الهاتف';

  @override
  String get patientRegPhoneHint => 'مثال: 0501234567';

  @override
  String get patientRegPhoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get patientRegEmailLabel => 'البريد الإلكتروني';

  @override
  String get patientRegEmailHint => 'optional@example.com';

  @override
  String get patientRegEmailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get patientRegAgeLabel => 'العمر';

  @override
  String get patientRegAgeHint => 'سنة';

  @override
  String get patientRegGenderLabel => 'الجنس';

  @override
  String get patientRegMale => 'ذكر';

  @override
  String get patientRegFemale => 'أنثى';

  @override
  String get patientRegBloodTypeLabel => 'فصيلة الدم';

  @override
  String get patientRegSelectBloodType => 'اختر فصيلة الدم';

  @override
  String get patientRegHealthProfile => 'الملف الصحي';

  @override
  String get patientRegHealthy => 'سليم';

  @override
  String get patientRegHealthySubtitle => 'لا توجد أمراض مزمنة معروفة';

  @override
  String get patientRegHasConditions => 'يعاني من أمراض مزمنة';

  @override
  String get patientRegHasConditionsSubtitle =>
      'يعاني من مرض مزمن واحد أو أكثر';

  @override
  String get patientRegDiabetes => 'داء السكري';

  @override
  String get patientRegHypertension => 'ارتفاع ضغط الدم';

  @override
  String get patientRegHeartDisease => 'أمراض القلب';

  @override
  String get patientRegCkd => 'مرض الكلى المزمن (CKD)';

  @override
  String get patientRegAsthmaCopd => 'الربو / الانسداد الرئوي المزمن';

  @override
  String get patientRegType1 => 'النوع الأول';

  @override
  String get patientRegType2 => 'النوع الثاني';

  @override
  String get patientRegPreDiabetic => 'مقدمات السكري';

  @override
  String get patientRegMedicationsLabel => 'الأدوية';

  @override
  String get patientRegMedicationsHint => 'اذكر الأدوية الحالية (اختياري)';

  @override
  String get patientRegNotesLabel => 'ملاحظات';

  @override
  String get patientRegNotesHint => 'أي ملاحظات إضافية (اختياري)';

  @override
  String get patientRegPersonalSettings => 'الإعدادات الشخصية';

  @override
  String get patientRegDoctorNameLabel => 'اسم الطبيب';

  @override
  String get patientRegDoctorNameHint => 'اسم طبيبك المعالج';

  @override
  String get patientRegDoctorContactLabel => 'بيانات التواصل مع الطبيب';

  @override
  String get patientRegDoctorContactHint => 'رقم الهاتف أو البريد الإلكتروني';

  @override
  String get patientRegEmergencyContactLabel => 'جهة اتصال الطوارئ';

  @override
  String get patientRegEmergencyContactHint => 'الاسم ورقم الهاتف';

  @override
  String get patientRegCalibrationOffsetLabel => 'إزاحة المعايرة (mg/dL)';

  @override
  String get patientRegCalibrationOffsetHint => '0.0';

  @override
  String get patientRegInvalidNumber => 'أدخل رقمًا صحيحًا';

  @override
  String get patientRegSaveContinue => 'حفظ ومتابعة';

  @override
  String get patientRegPhoneAlreadyRegistered =>
      'رقم الهاتف هذا مسجل بالفعل لمريض آخر.';

  @override
  String get profileUnknownName => 'غير معروف';

  @override
  String profileMemberSince(int year) {
    return 'عضو منذ $year';
  }

  @override
  String get profilePersonalInfoTitle => 'المعلومات الشخصية';

  @override
  String get profileNoProfileSetUp => 'لم يتم إعداد الملف الشخصي بعد';

  @override
  String get profileAddNamePrompt => 'أضف اسمك حتى يمكن حفظ القراءات.';

  @override
  String get profileSetUpProfile => 'إعداد الملف الشخصي';

  @override
  String get profileGenderMale => 'ذكر';

  @override
  String get profileGenderFemale => 'أنثى';

  @override
  String get profileEdit => 'تعديل';

  @override
  String get profileTapEditPrompt => 'اضغط على تعديل لإضافة بياناتك.';

  @override
  String profileAgeYears(int age) {
    return '$age سنة';
  }

  @override
  String get profileSetUpYourProfile => 'إعداد ملفك الشخصي';

  @override
  String get profileEditPersonalInfo => 'تعديل المعلومات الشخصية';

  @override
  String get profileNameRequiredSubtitle => 'اسمك مطلوب لحفظ القياسات.';

  @override
  String get profileFullNameLabel => 'الاسم الكامل';

  @override
  String get profileYourNameHint => 'اسمك';

  @override
  String get profileNameRequiredError => 'الاسم مطلوب';

  @override
  String get profileMinTwoCharsError => 'حرفان على الأقل';

  @override
  String get profilePhoneLabel => 'رقم الهاتف';

  @override
  String get profilePhoneHint => '‎+1 555 000 0000';

  @override
  String get profileInvalidPhoneError => 'أدخل رقم هاتف صحيح';

  @override
  String get profileEmailLabel => 'البريد الإلكتروني';

  @override
  String get profileEmailHint => 'name@example.com';

  @override
  String get profileInvalidEmailError => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get profileCreateProfileButton => 'إنشاء الملف الشخصي';

  @override
  String get profileSaveChangesButton => 'حفظ التغييرات';

  @override
  String get profileMedicalConditionsTitle => 'الحالات الطبية';

  @override
  String get profileContactsTitle => 'جهات الاتصال';

  @override
  String get profileDoctorLabel => 'الطبيب';

  @override
  String get profileDoctorPhoneLabel => 'هاتف الطبيب';

  @override
  String get profileEmergencyLabel => 'الطوارئ';

  @override
  String get profileEditContactsTitle => 'تعديل جهات الاتصال';

  @override
  String get profileDoctorNameLabel => 'اسم الطبيب';

  @override
  String get profileDoctorNameHint => 'د. أحمد';

  @override
  String get profileDoctorNameMinLengthError =>
      'يجب أن يتكون الاسم من حرفين على الأقل';

  @override
  String get profileEmergencyContactLabel => 'جهة اتصال الطوارئ';

  @override
  String get profileEmergencyContactHint => 'الاسم · ‎+1 555 000 0001';

  @override
  String get profileEmergencyContactMinLengthError =>
      'أدخل اسمًا أو رقمًا على الأقل';

  @override
  String get profileSaveButton => 'حفظ';

  @override
  String get profileAppSettingsTitle => 'إعدادات التطبيق';

  @override
  String get profileThemeLabel => 'المظهر';

  @override
  String get profileThemeLight => 'فاتح';

  @override
  String get profileThemeAuto => 'تلقائي';

  @override
  String get profileThemeDark => 'داكن';

  @override
  String get profileLanguageLabel => 'اللغة';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get profileSwitchModeDialogTitle => 'تبديل وضع التطبيق؟';

  @override
  String get profileSwitchModeDialogContent =>
      'سيعيدك هذا إلى شاشة اختيار الوضع. تبقى قراءاتك وبياناتك محفوظة على الجهاز.';

  @override
  String get profileCancelButton => 'إلغاء';

  @override
  String get profileSwitchButton => 'تبديل';

  @override
  String get profileAppModeTitle => 'وضع التطبيق';

  @override
  String get profileAppModeDescription =>
      'التبديل إلى وضع مختلف (شخصي أو عيادة). تبقى جميع القراءات والإعدادات محفوظة على هذا الجهاز.';

  @override
  String get profileSwitchModeButton => 'تبديل الوضع';

  @override
  String get profileCouldNotLoadError => 'تعذر تحميل الملف الشخصي';

  @override
  String get remindersWaterReminderTitle => 'تذكير شرب الماء';

  @override
  String get remindersEnableReminders => 'تفعيل التذكيرات';

  @override
  String get remindersInterval => 'الفاصل الزمني';

  @override
  String get remindersInterval1Hr => 'ساعة واحدة';

  @override
  String get remindersInterval2Hrs => 'ساعتان';

  @override
  String get remindersInterval3Hrs => '3 ساعات';

  @override
  String get remindersInterval4Hrs => '4 ساعات';

  @override
  String get remindersWakeTime => 'وقت الاستيقاظ';

  @override
  String get remindersSleepTime => 'وقت النوم';

  @override
  String get remindersTodaysIntake => 'كمية اليوم من الماء';

  @override
  String get remindersGlasses => 'أكواب';

  @override
  String get remindersAm => 'ص';

  @override
  String get remindersPm => 'م';

  @override
  String get remindersGlucoseMeasurement => 'قياس السكر';

  @override
  String get remindersAddReminderTime => 'إضافة وقت تذكير';

  @override
  String get remindersRepeatsDaily => 'يتكرر يوميًا';

  @override
  String get remindersNoReminderTimes => 'لم يتم تعيين أوقات تذكير.';

  @override
  String get remindersMedicationsTitle => 'الأدوية';

  @override
  String get remindersAddMedication => 'إضافة دواء';

  @override
  String get remindersNoMedications => 'لم تتم إضافة أي أدوية.';

  @override
  String get remindersTakenStatus => '✅  تم التناول';

  @override
  String get remindersMissedStatus => '❌  فائت';

  @override
  String get remindersMedicationNameLabel => 'اسم الدواء';

  @override
  String get remindersMedicationNameHint => 'مثال: ميتفورمين';

  @override
  String get remindersDoseLabel => 'الجرعة';

  @override
  String get remindersDoseHint => 'مثال: 500 ملغ';

  @override
  String get remindersFrequencyLabel => 'التكرار';

  @override
  String get remindersFrequencyOnceDaily => 'مرة واحدة يوميًا';

  @override
  String get remindersFrequencyTwiceDaily => 'مرتان يوميًا';

  @override
  String get remindersFrequencyOnceWeekly => 'مرة واحدة أسبوعيًا';

  @override
  String get remindersFrequencyAsNeeded => 'عند الحاجة';

  @override
  String get notifWaterTitle => '💧 حان وقت شرب الماء';

  @override
  String get notifWaterBody => 'اشرب كوبًا من الماء للحفاظ على صحتك!';

  @override
  String get notifWaterChannelName => 'تذكيرات الماء';

  @override
  String get notifGlucoseTitle => '🩸 فحص السكر';

  @override
  String get notifGlucoseBody => 'حان وقت قياس مستوى السكر لديك!';

  @override
  String get notifGlucoseChannelName => 'تذكيرات قياس السكر';

  @override
  String get notifMedTitle => '💊 تذكير بالدواء';

  @override
  String notifMedBody(String medicationName, String dose) {
    return 'تناول $medicationName — $dose';
  }

  @override
  String get notifMedChannelName => 'تذكيرات الأدوية';

  @override
  String get pdfReportTitle => 'تقرير GlucoTrack';

  @override
  String pdfPeriod(String rangeLabel) {
    return 'الفترة: $rangeLabel';
  }

  @override
  String pdfGenerated(String dateTime) {
    return 'تاريخ الإنشاء: $dateTime';
  }

  @override
  String get pdfPatientInformation => 'معلومات المريض';

  @override
  String get pdfName => 'الاسم';

  @override
  String get pdfAge => 'العمر';

  @override
  String get pdfGender => 'الجنس';

  @override
  String get pdfBloodType => 'فصيلة الدم';

  @override
  String pdfConditions(String list) {
    return 'الحالات: $list';
  }

  @override
  String get pdfStatisticalSummary => 'الملخص الإحصائي';

  @override
  String get pdfAverage => 'المتوسط';

  @override
  String get pdfMin => 'الأدنى';

  @override
  String get pdfMax => 'الأعلى';

  @override
  String get pdfStdDev => 'الانحراف المعياري';

  @override
  String get pdfTimeInRange => 'الوقت ضمن النطاق';

  @override
  String pdfGlucoseReadings(int count) {
    return 'قراءات الجلوكوز ($count)';
  }

  @override
  String get pdfDateTime => 'التاريخ والوقت';

  @override
  String get pdfGlucose => 'الجلوكوز';

  @override
  String get pdfZone => 'النطاق';

  @override
  String get pdfBp => 'ضغط الدم';

  @override
  String get pdfHr => 'معدل النبض';
}
