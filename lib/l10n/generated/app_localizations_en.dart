// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonSomethingWentWrong =>
      'Something went wrong. Please try again.';

  @override
  String get routeErrorTitle => 'Page not found';

  @override
  String get routeErrorMessage =>
      'The screen you\'re looking for doesn\'t exist.';

  @override
  String get routeErrorGoHome => 'Go back';

  @override
  String get glucoseZoneHypoglycemia => 'Hypoglycemia';

  @override
  String get glucoseZoneNormal => 'Normal';

  @override
  String get glucoseZonePreDiabetic => 'Pre-Diabetic';

  @override
  String get glucoseZoneHyperglycemia => 'Hyperglycemia';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateDaysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String get bleConnected => 'Connected';

  @override
  String get bleScanning => 'Scanning…';

  @override
  String get bleConnecting => 'Connecting…';

  @override
  String get bleDisconnected => 'Disconnected';

  @override
  String get placeholderPersonalHome => 'Personal · Home';

  @override
  String get placeholderPersonalReadings => 'Personal · Readings';

  @override
  String get placeholderPersonalReminders => 'Personal · Reminders';

  @override
  String get placeholderPersonalProfile => 'Personal · Profile';

  @override
  String get placeholderClinicDashboard => 'Clinic · Dashboard';

  @override
  String get placeholderClinicSearch => 'Clinic · Search';

  @override
  String placeholderClinicMeasure(String patientId) {
    return 'Clinic · Measure (patient $patientId)';
  }

  @override
  String get placeholderClinicSuccess => 'Clinic · Success';

  @override
  String get placeholderClinicPatients => 'Clinic · Patients';

  @override
  String get modeSelectionAppName => 'GlucoTrack';

  @override
  String get modeSelectionTagline => 'Non-Invasive Blood Glucose Monitor';

  @override
  String get modeSelectionPersonalTitle => 'Personal Use';

  @override
  String get modeSelectionPersonalSubtitle =>
      'Track your own glucose and vitals';

  @override
  String get modeSelectionClinicTitle => 'Clinic / Hospital';

  @override
  String get modeSelectionClinicSubtitle => 'Nurse-operated, multiple patients';

  @override
  String get modeSelectionClinicComingSoon => 'Coming soon';

  @override
  String get clinicNavDashboard => 'Dashboard';

  @override
  String get clinicNavNewPatient => 'New Patient';

  @override
  String get clinicNavSearch => 'Search';

  @override
  String get clinicNavPatients => 'Patients';

  @override
  String get clinicModeTitle => 'Clinic / Hospital Mode';

  @override
  String get personalShellNavHome => 'Home';

  @override
  String get personalShellNavReadings => 'Readings';

  @override
  String get personalShellNavReminders => 'Reminders';

  @override
  String get personalShellNavProfile => 'Profile';

  @override
  String get personalShellDeviceConnected => 'Device Connected';

  @override
  String get personalShellDeviceScanning => 'Scanning...';

  @override
  String get personalShellDeviceConnecting => 'Connecting...';

  @override
  String get personalShellDeviceNotConnected => 'Device Not Connected';

  @override
  String get homeGoodMorning => 'Good morning';

  @override
  String get homeGoodAfternoon => 'Good afternoon';

  @override
  String get homeGoodEvening => 'Good evening';

  @override
  String get homeGuestName => 'there';

  @override
  String homeGreeting(String greeting, String name) {
    return '$greeting, $name 👋';
  }

  @override
  String get homeRecentReadings => 'Recent Readings';

  @override
  String get homeViewAll => 'View all →';

  @override
  String get homeCouldNotLoadReadings => 'Could not load readings';

  @override
  String get homeNoReadingsYet => 'No readings yet';

  @override
  String get homeMgDlUnit => 'mg/dL';

  @override
  String homeReadingTimestamp(String relative, String time) {
    return '$relative, $time';
  }

  @override
  String get homeTodaysAverage => 'Today\'s Average';

  @override
  String get homeTimeInRange => 'Time in Range';

  @override
  String get homeCompleteProfileFirst => 'Please complete profile setup first';

  @override
  String homeScanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String get homeScanning => 'Scanning…';

  @override
  String get homeStartNewMeasurement => '▶  Start New Measurement';

  @override
  String get homeKeepFingerOnSensor => 'Keep your finger on the sensor';

  @override
  String get homeMeasurementSaved => 'Measurement saved ✅';

  @override
  String get homeNotesOptional => 'Notes (optional)';

  @override
  String get homeSaveMeasurement => '💾  Save Measurement';

  @override
  String get homeTakeFirstMeasurement => 'Take your first measurement';

  @override
  String get readingCardLatestReading => 'Latest Reading';

  @override
  String get readingCardMgDlUnit => 'mg/dL';

  @override
  String readingCardTodayAt(String time) {
    return 'Today at $time';
  }

  @override
  String readingCardHeartRate(int bpm) {
    return ' · ❤ $bpm bpm';
  }

  @override
  String readingCardBpValue(int systolic, int diastolic) {
    return 'BP: $systolic/$diastolic mmHg';
  }

  @override
  String get readingCardAm => 'AM';

  @override
  String get readingCardPm => 'PM';

  @override
  String get readingsTitle => 'Glucose Readings';

  @override
  String get readingsAllReadings => 'All Readings';

  @override
  String get readingsDaily => 'Daily';

  @override
  String get readingsWeekly => 'Weekly';

  @override
  String get readingsMonthly => 'Monthly';

  @override
  String get readingsCouldNotLoadChart => 'Could not load chart';

  @override
  String get readingsNoReadingsForPeriod => 'No readings for this period';

  @override
  String get readingsAvg => 'Avg';

  @override
  String get readingsMin => 'Min';

  @override
  String get readingsMax => 'Max';

  @override
  String get readingsStdDev => 'Std Dev';

  @override
  String get readingsTir => 'TIR';

  @override
  String get readingsMgdl => 'mg/dL';

  @override
  String get readingsTirRange => '70–140 mg/dL';

  @override
  String get readingsBpm => 'BPM';

  @override
  String get readingsNewer => 'Newer';

  @override
  String get readingsOlder => 'Older';

  @override
  String get readingsEmptyHistory =>
      'No reading history yet.\nTake your first measurement!';

  @override
  String get patientRegYourProfileTitle => 'Your Profile';

  @override
  String get patientRegNewPatientTitle => 'New Patient';

  @override
  String get patientRegBasicInformation => 'Basic Information';

  @override
  String get patientRegFullNameLabel => 'Full Name';

  @override
  String get patientRegFullNameHint => 'Enter full name';

  @override
  String get patientRegNameRequired => 'Name is required';

  @override
  String get patientRegPhoneLabel => 'Phone Number';

  @override
  String get patientRegPhoneHint => 'e.g. 0501234567';

  @override
  String get patientRegPhoneRequired => 'Phone is required';

  @override
  String get patientRegEmailLabel => 'Email';

  @override
  String get patientRegEmailHint => 'optional@example.com';

  @override
  String get patientRegEmailInvalid => 'Enter a valid email';

  @override
  String get patientRegAgeLabel => 'Age';

  @override
  String get patientRegAgeHint => 'Years';

  @override
  String get patientRegGenderLabel => 'Gender';

  @override
  String get patientRegMale => 'Male';

  @override
  String get patientRegFemale => 'Female';

  @override
  String get patientRegBloodTypeLabel => 'Blood Type';

  @override
  String get patientRegSelectBloodType => 'Select blood type';

  @override
  String get patientRegHealthProfile => 'Health Profile';

  @override
  String get patientRegHealthy => 'Healthy';

  @override
  String get patientRegHealthySubtitle => 'No known chronic conditions';

  @override
  String get patientRegHasConditions => 'Has chronic conditions';

  @override
  String get patientRegHasConditionsSubtitle =>
      'Has one or more chronic conditions';

  @override
  String get patientRegDiabetes => 'Diabetes';

  @override
  String get patientRegHypertension => 'Hypertension';

  @override
  String get patientRegHeartDisease => 'Heart Disease';

  @override
  String get patientRegCkd => 'Chronic Kidney Disease (CKD)';

  @override
  String get patientRegAsthmaCopd => 'Asthma / COPD';

  @override
  String get patientRegType1 => 'Type 1';

  @override
  String get patientRegType2 => 'Type 2';

  @override
  String get patientRegPreDiabetic => 'Pre-Diabetic';

  @override
  String get patientRegMedicationsLabel => 'Medications';

  @override
  String get patientRegMedicationsHint => 'List current medications (optional)';

  @override
  String get patientRegNotesLabel => 'Notes';

  @override
  String get patientRegNotesHint => 'Any additional notes (optional)';

  @override
  String get patientRegPersonalSettings => 'Personal Settings';

  @override
  String get patientRegDoctorNameLabel => 'Doctor Name';

  @override
  String get patientRegDoctorNameHint => 'Your physician\'s name';

  @override
  String get patientRegDoctorContactLabel => 'Doctor Contact';

  @override
  String get patientRegDoctorContactHint => 'Phone or email';

  @override
  String get patientRegEmergencyContactLabel => 'Emergency Contact';

  @override
  String get patientRegEmergencyContactHint => 'Name and phone number';

  @override
  String get patientRegCalibrationOffsetLabel => 'Calibration Offset (mg/dL)';

  @override
  String get patientRegCalibrationOffsetHint => '0.0';

  @override
  String get patientRegInvalidNumber => 'Enter a valid number';

  @override
  String get patientRegSaveContinue => 'Save & Continue';

  @override
  String get patientRegPhoneAlreadyRegistered =>
      'This phone number is already registered to another patient.';

  @override
  String get profileUnknownName => 'Unknown';

  @override
  String profileMemberSince(int year) {
    return 'Member since $year';
  }

  @override
  String get profilePersonalInfoTitle => 'Personal info';

  @override
  String get profileNoProfileSetUp => 'No profile set up yet';

  @override
  String get profileAddNamePrompt => 'Add your name so readings can be saved.';

  @override
  String get profileSetUpProfile => 'Set up profile';

  @override
  String get profileGenderMale => 'Male';

  @override
  String get profileGenderFemale => 'Female';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileTapEditPrompt => 'Tap edit to add your details.';

  @override
  String profileAgeYears(int age) {
    return '$age yrs';
  }

  @override
  String get profileSetUpYourProfile => 'Set up your profile';

  @override
  String get profileEditPersonalInfo => 'Edit personal info';

  @override
  String get profileNameRequiredSubtitle =>
      'Your name is required to save measurements.';

  @override
  String get profileFullNameLabel => 'Full name';

  @override
  String get profileYourNameHint => 'Your name';

  @override
  String get profileNameRequiredError => 'Name is required';

  @override
  String get profileMinTwoCharsError => 'At least 2 characters';

  @override
  String get profilePhoneLabel => 'Phone';

  @override
  String get profilePhoneHint => '+1 555 000 0000';

  @override
  String get profileInvalidPhoneError => 'Enter a valid phone number';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileEmailHint => 'name@example.com';

  @override
  String get profileInvalidEmailError => 'Enter a valid email address';

  @override
  String get profileCreateProfileButton => 'Create profile';

  @override
  String get profileSaveChangesButton => 'Save changes';

  @override
  String get profileMedicalConditionsTitle => 'Medical conditions';

  @override
  String get profileContactsTitle => 'Contacts';

  @override
  String get profileDoctorLabel => 'Doctor';

  @override
  String get profileDoctorPhoneLabel => 'Doctor phone';

  @override
  String get profileEmergencyLabel => 'Emergency';

  @override
  String get profileEditContactsTitle => 'Edit contacts';

  @override
  String get profileDoctorNameLabel => 'Doctor name';

  @override
  String get profileDoctorNameHint => 'Dr. Smith';

  @override
  String get profileDoctorNameMinLengthError =>
      'Name must be at least 2 characters';

  @override
  String get profileEmergencyContactLabel => 'Emergency contact';

  @override
  String get profileEmergencyContactHint => 'Name · +1 555 000 0001';

  @override
  String get profileEmergencyContactMinLengthError =>
      'Enter at least a name or number';

  @override
  String get profileSaveButton => 'Save';

  @override
  String get profileAppSettingsTitle => 'App settings';

  @override
  String get profileThemeLabel => 'Theme';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeAuto => 'Auto';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileLanguageLabel => 'Language';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get profileSwitchModeDialogTitle => 'Switch app mode?';

  @override
  String get profileSwitchModeDialogContent =>
      'This will return you to the mode selection screen. Your readings and data remain on the device.';

  @override
  String get profileCancelButton => 'Cancel';

  @override
  String get profileSwitchButton => 'Switch';

  @override
  String get profileAppModeTitle => 'App mode';

  @override
  String get profileAppModeDescription =>
      'Switch to a different mode (Personal or Clinic). All readings and settings remain saved on this device.';

  @override
  String get profileSwitchModeButton => 'Switch mode';

  @override
  String get profileCouldNotLoadError => 'Could not load profile';

  @override
  String get remindersWaterReminderTitle => 'Water Reminder';

  @override
  String get remindersEnableReminders => 'Enable Reminders';

  @override
  String get remindersInterval => 'Interval';

  @override
  String get remindersInterval1Hr => '1 hr';

  @override
  String get remindersInterval2Hrs => '2 hrs';

  @override
  String get remindersInterval3Hrs => '3 hrs';

  @override
  String get remindersInterval4Hrs => '4 hrs';

  @override
  String get remindersWakeTime => 'Wake Time';

  @override
  String get remindersSleepTime => 'Sleep Time';

  @override
  String get remindersTodaysIntake => 'Today\'s Intake';

  @override
  String get remindersGlasses => 'glasses';

  @override
  String get remindersAm => 'AM';

  @override
  String get remindersPm => 'PM';

  @override
  String get remindersGlucoseMeasurement => 'Glucose Measurement';

  @override
  String get remindersAddReminderTime => 'Add Reminder Time';

  @override
  String get remindersRepeatsDaily => 'Repeats daily';

  @override
  String get remindersNoReminderTimes => 'No reminder times set.';

  @override
  String get remindersMedicationsTitle => 'Medications';

  @override
  String get remindersAddMedication => 'Add Medication';

  @override
  String get remindersNoMedications => 'No medications added.';

  @override
  String get remindersTakenStatus => '✅  Taken';

  @override
  String get remindersMissedStatus => '❌  Missed';

  @override
  String get remindersMedicationNameLabel => 'Medication Name';

  @override
  String get remindersMedicationNameHint => 'e.g. Metformin';

  @override
  String get remindersDoseLabel => 'Dose';

  @override
  String get remindersDoseHint => 'e.g. 500 mg';

  @override
  String get remindersFrequencyLabel => 'Frequency';

  @override
  String get remindersFrequencyOnceDaily => 'Once daily';

  @override
  String get remindersFrequencyTwiceDaily => 'Twice daily';

  @override
  String get remindersFrequencyOnceWeekly => 'Once weekly';

  @override
  String get remindersFrequencyAsNeeded => 'As needed';

  @override
  String get notifWaterTitle => '💧 Time to Hydrate';

  @override
  String get notifWaterBody => 'Drink a glass of water to stay healthy!';

  @override
  String get notifWaterChannelName => 'Water Reminders';

  @override
  String get notifGlucoseTitle => '🩸 Glucose Check';

  @override
  String get notifGlucoseBody => 'Time for your glucose measurement!';

  @override
  String get notifGlucoseChannelName => 'Glucose Reminders';

  @override
  String get notifMedTitle => '💊 Medication Reminder';

  @override
  String notifMedBody(String medicationName, String dose) {
    return 'Take $medicationName — $dose';
  }

  @override
  String get notifMedChannelName => 'Medication Reminders';

  @override
  String get pdfReportTitle => 'GlucoTrack Report';

  @override
  String pdfPeriod(String rangeLabel) {
    return 'Period: $rangeLabel';
  }

  @override
  String pdfGenerated(String dateTime) {
    return 'Generated: $dateTime';
  }

  @override
  String get pdfPatientInformation => 'Patient Information';

  @override
  String get pdfName => 'Name';

  @override
  String get pdfAge => 'Age';

  @override
  String get pdfGender => 'Gender';

  @override
  String get pdfBloodType => 'Blood Type';

  @override
  String pdfConditions(String list) {
    return 'Conditions: $list';
  }

  @override
  String get pdfStatisticalSummary => 'Statistical Summary';

  @override
  String get pdfAverage => 'Average';

  @override
  String get pdfMin => 'Min';

  @override
  String get pdfMax => 'Max';

  @override
  String get pdfStdDev => 'Std Dev';

  @override
  String get pdfTimeInRange => 'Time-in-Range';

  @override
  String pdfGlucoseReadings(int count) {
    return 'Glucose Readings ($count)';
  }

  @override
  String get pdfDateTime => 'Date & Time';

  @override
  String get pdfGlucose => 'Glucose';

  @override
  String get pdfZone => 'Zone';

  @override
  String get pdfBp => 'BP';

  @override
  String get pdfHr => 'HR';
}
