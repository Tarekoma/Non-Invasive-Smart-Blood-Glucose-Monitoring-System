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
/// import 'generated/app_localizations.dart';
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

  /// No description provided for @glucoseZoneHypoglycemia.
  ///
  /// In en, this message translates to:
  /// **'Hypoglycemia'**
  String get glucoseZoneHypoglycemia;

  /// No description provided for @glucoseZoneNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get glucoseZoneNormal;

  /// No description provided for @glucoseZonePreDiabetic.
  ///
  /// In en, this message translates to:
  /// **'Pre-Diabetic'**
  String get glucoseZonePreDiabetic;

  /// No description provided for @glucoseZoneHyperglycemia.
  ///
  /// In en, this message translates to:
  /// **'Hyperglycemia'**
  String get glucoseZoneHyperglycemia;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day ago} other{{count} days ago}}'**
  String dateDaysAgo(num count);

  /// No description provided for @bleConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get bleConnected;

  /// No description provided for @bleScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get bleScanning;

  /// No description provided for @bleConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get bleConnecting;

  /// No description provided for @bleDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get bleDisconnected;

  /// No description provided for @placeholderPersonalHome.
  ///
  /// In en, this message translates to:
  /// **'Personal · Home'**
  String get placeholderPersonalHome;

  /// No description provided for @placeholderPersonalReadings.
  ///
  /// In en, this message translates to:
  /// **'Personal · Readings'**
  String get placeholderPersonalReadings;

  /// No description provided for @placeholderPersonalReminders.
  ///
  /// In en, this message translates to:
  /// **'Personal · Reminders'**
  String get placeholderPersonalReminders;

  /// No description provided for @placeholderPersonalProfile.
  ///
  /// In en, this message translates to:
  /// **'Personal · Profile'**
  String get placeholderPersonalProfile;

  /// No description provided for @placeholderClinicDashboard.
  ///
  /// In en, this message translates to:
  /// **'Clinic · Dashboard'**
  String get placeholderClinicDashboard;

  /// No description provided for @placeholderClinicSearch.
  ///
  /// In en, this message translates to:
  /// **'Clinic · Search'**
  String get placeholderClinicSearch;

  /// No description provided for @placeholderClinicMeasure.
  ///
  /// In en, this message translates to:
  /// **'Clinic · Measure (patient {patientId})'**
  String placeholderClinicMeasure(String patientId);

  /// No description provided for @placeholderClinicSuccess.
  ///
  /// In en, this message translates to:
  /// **'Clinic · Success'**
  String get placeholderClinicSuccess;

  /// No description provided for @placeholderClinicPatients.
  ///
  /// In en, this message translates to:
  /// **'Clinic · Patients'**
  String get placeholderClinicPatients;

  /// No description provided for @modeSelectionAppName.
  ///
  /// In en, this message translates to:
  /// **'GlucoTrack'**
  String get modeSelectionAppName;

  /// No description provided for @modeSelectionTagline.
  ///
  /// In en, this message translates to:
  /// **'Non-Invasive Blood Glucose Monitor'**
  String get modeSelectionTagline;

  /// No description provided for @modeSelectionPersonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Use'**
  String get modeSelectionPersonalTitle;

  /// No description provided for @modeSelectionPersonalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your own glucose and vitals'**
  String get modeSelectionPersonalSubtitle;

  /// No description provided for @modeSelectionClinicTitle.
  ///
  /// In en, this message translates to:
  /// **'Clinic / Hospital'**
  String get modeSelectionClinicTitle;

  /// No description provided for @modeSelectionClinicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nurse-operated, multiple patients'**
  String get modeSelectionClinicSubtitle;

  /// No description provided for @clinicNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get clinicNavDashboard;

  /// No description provided for @clinicNavNewPatient.
  ///
  /// In en, this message translates to:
  /// **'New Patient'**
  String get clinicNavNewPatient;

  /// No description provided for @clinicNavSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get clinicNavSearch;

  /// No description provided for @clinicNavPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get clinicNavPatients;

  /// No description provided for @clinicModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Clinic / Hospital Mode'**
  String get clinicModeTitle;

  /// No description provided for @personalShellNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get personalShellNavHome;

  /// No description provided for @personalShellNavReadings.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get personalShellNavReadings;

  /// No description provided for @personalShellNavReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get personalShellNavReminders;

  /// No description provided for @personalShellNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get personalShellNavProfile;

  /// No description provided for @personalShellDeviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Device Connected'**
  String get personalShellDeviceConnected;

  /// No description provided for @personalShellDeviceScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get personalShellDeviceScanning;

  /// No description provided for @personalShellDeviceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get personalShellDeviceConnecting;

  /// No description provided for @personalShellDeviceNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Device Not Connected'**
  String get personalShellDeviceNotConnected;

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// No description provided for @homeGuestName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get homeGuestName;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name} 👋'**
  String homeGreeting(String greeting, String name);

  /// No description provided for @homeRecentReadings.
  ///
  /// In en, this message translates to:
  /// **'Recent Readings'**
  String get homeRecentReadings;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all →'**
  String get homeViewAll;

  /// No description provided for @homeCouldNotLoadReadings.
  ///
  /// In en, this message translates to:
  /// **'Could not load readings'**
  String get homeCouldNotLoadReadings;

  /// No description provided for @homeNoReadingsYet.
  ///
  /// In en, this message translates to:
  /// **'No readings yet'**
  String get homeNoReadingsYet;

  /// No description provided for @homeMgDlUnit.
  ///
  /// In en, this message translates to:
  /// **'mg/dL'**
  String get homeMgDlUnit;

  /// No description provided for @homeReadingTimestamp.
  ///
  /// In en, this message translates to:
  /// **'{relative}, {time}'**
  String homeReadingTimestamp(String relative, String time);

  /// No description provided for @homeTodaysAverage.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Average'**
  String get homeTodaysAverage;

  /// No description provided for @homeTimeInRange.
  ///
  /// In en, this message translates to:
  /// **'Time in Range'**
  String get homeTimeInRange;

  /// No description provided for @homeCompleteProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please complete profile setup first'**
  String get homeCompleteProfileFirst;

  /// No description provided for @homeScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String homeScanFailed(String error);

  /// No description provided for @homeScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get homeScanning;

  /// No description provided for @homeStartNewMeasurement.
  ///
  /// In en, this message translates to:
  /// **'▶  Start New Measurement'**
  String get homeStartNewMeasurement;

  /// No description provided for @homeKeepFingerOnSensor.
  ///
  /// In en, this message translates to:
  /// **'Keep your finger on the sensor'**
  String get homeKeepFingerOnSensor;

  /// No description provided for @homeMeasurementSaved.
  ///
  /// In en, this message translates to:
  /// **'Measurement saved ✅'**
  String get homeMeasurementSaved;

  /// No description provided for @homeNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get homeNotesOptional;

  /// No description provided for @homeSaveMeasurement.
  ///
  /// In en, this message translates to:
  /// **'💾  Save Measurement'**
  String get homeSaveMeasurement;

  /// No description provided for @homeTakeFirstMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Take your first measurement'**
  String get homeTakeFirstMeasurement;

  /// No description provided for @readingCardLatestReading.
  ///
  /// In en, this message translates to:
  /// **'Latest Reading'**
  String get readingCardLatestReading;

  /// No description provided for @readingCardMgDlUnit.
  ///
  /// In en, this message translates to:
  /// **'mg/dL'**
  String get readingCardMgDlUnit;

  /// No description provided for @readingCardTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String readingCardTodayAt(String time);

  /// No description provided for @readingCardHeartRate.
  ///
  /// In en, this message translates to:
  /// **' · ❤ {bpm} bpm'**
  String readingCardHeartRate(int bpm);

  /// No description provided for @readingCardBpValue.
  ///
  /// In en, this message translates to:
  /// **'BP: {systolic}/{diastolic} mmHg'**
  String readingCardBpValue(int systolic, int diastolic);

  /// No description provided for @readingCardAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get readingCardAm;

  /// No description provided for @readingCardPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get readingCardPm;

  /// No description provided for @readingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Glucose Readings'**
  String get readingsTitle;

  /// No description provided for @readingsAllReadings.
  ///
  /// In en, this message translates to:
  /// **'All Readings'**
  String get readingsAllReadings;

  /// No description provided for @readingsDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get readingsDaily;

  /// No description provided for @readingsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get readingsWeekly;

  /// No description provided for @readingsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get readingsMonthly;

  /// No description provided for @readingsCouldNotLoadChart.
  ///
  /// In en, this message translates to:
  /// **'Could not load chart'**
  String get readingsCouldNotLoadChart;

  /// No description provided for @readingsNoReadingsForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No readings for this period'**
  String get readingsNoReadingsForPeriod;

  /// No description provided for @readingsAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get readingsAvg;

  /// No description provided for @readingsMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get readingsMin;

  /// No description provided for @readingsMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get readingsMax;

  /// No description provided for @readingsStdDev.
  ///
  /// In en, this message translates to:
  /// **'Std Dev'**
  String get readingsStdDev;

  /// No description provided for @readingsTir.
  ///
  /// In en, this message translates to:
  /// **'TIR'**
  String get readingsTir;

  /// No description provided for @readingsMgdl.
  ///
  /// In en, this message translates to:
  /// **'mg/dL'**
  String get readingsMgdl;

  /// No description provided for @readingsTirRange.
  ///
  /// In en, this message translates to:
  /// **'70–140 mg/dL'**
  String get readingsTirRange;

  /// No description provided for @readingsBpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get readingsBpm;

  /// No description provided for @readingsNewer.
  ///
  /// In en, this message translates to:
  /// **'Newer'**
  String get readingsNewer;

  /// No description provided for @readingsOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get readingsOlder;

  /// No description provided for @readingsEmptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No reading history yet.\nTake your first measurement!'**
  String get readingsEmptyHistory;

  /// No description provided for @patientRegYourProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get patientRegYourProfileTitle;

  /// No description provided for @patientRegNewPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'New Patient'**
  String get patientRegNewPatientTitle;

  /// No description provided for @patientRegBasicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get patientRegBasicInformation;

  /// No description provided for @patientRegFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get patientRegFullNameLabel;

  /// No description provided for @patientRegFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get patientRegFullNameHint;

  /// No description provided for @patientRegNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get patientRegNameRequired;

  /// No description provided for @patientRegPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get patientRegPhoneLabel;

  /// No description provided for @patientRegPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 0501234567'**
  String get patientRegPhoneHint;

  /// No description provided for @patientRegPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get patientRegPhoneRequired;

  /// No description provided for @patientRegEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get patientRegEmailLabel;

  /// No description provided for @patientRegEmailHint.
  ///
  /// In en, this message translates to:
  /// **'optional@example.com'**
  String get patientRegEmailHint;

  /// No description provided for @patientRegEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get patientRegEmailInvalid;

  /// No description provided for @patientRegAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get patientRegAgeLabel;

  /// No description provided for @patientRegAgeHint.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get patientRegAgeHint;

  /// No description provided for @patientRegGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get patientRegGenderLabel;

  /// No description provided for @patientRegMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get patientRegMale;

  /// No description provided for @patientRegFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get patientRegFemale;

  /// No description provided for @patientRegBloodTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get patientRegBloodTypeLabel;

  /// No description provided for @patientRegSelectBloodType.
  ///
  /// In en, this message translates to:
  /// **'Select blood type'**
  String get patientRegSelectBloodType;

  /// No description provided for @patientRegHealthProfile.
  ///
  /// In en, this message translates to:
  /// **'Health Profile'**
  String get patientRegHealthProfile;

  /// No description provided for @patientRegHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get patientRegHealthy;

  /// No description provided for @patientRegHealthySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No known chronic conditions'**
  String get patientRegHealthySubtitle;

  /// No description provided for @patientRegHasConditions.
  ///
  /// In en, this message translates to:
  /// **'Has chronic conditions'**
  String get patientRegHasConditions;

  /// No description provided for @patientRegHasConditionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Has one or more chronic conditions'**
  String get patientRegHasConditionsSubtitle;

  /// No description provided for @patientRegDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get patientRegDiabetes;

  /// No description provided for @patientRegHypertension.
  ///
  /// In en, this message translates to:
  /// **'Hypertension'**
  String get patientRegHypertension;

  /// No description provided for @patientRegHeartDisease.
  ///
  /// In en, this message translates to:
  /// **'Heart Disease'**
  String get patientRegHeartDisease;

  /// No description provided for @patientRegCkd.
  ///
  /// In en, this message translates to:
  /// **'Chronic Kidney Disease (CKD)'**
  String get patientRegCkd;

  /// No description provided for @patientRegAsthmaCopd.
  ///
  /// In en, this message translates to:
  /// **'Asthma / COPD'**
  String get patientRegAsthmaCopd;

  /// No description provided for @patientRegType1.
  ///
  /// In en, this message translates to:
  /// **'Type 1'**
  String get patientRegType1;

  /// No description provided for @patientRegType2.
  ///
  /// In en, this message translates to:
  /// **'Type 2'**
  String get patientRegType2;

  /// No description provided for @patientRegPreDiabetic.
  ///
  /// In en, this message translates to:
  /// **'Pre-Diabetic'**
  String get patientRegPreDiabetic;

  /// No description provided for @patientRegMedicationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get patientRegMedicationsLabel;

  /// No description provided for @patientRegMedicationsHint.
  ///
  /// In en, this message translates to:
  /// **'List current medications (optional)'**
  String get patientRegMedicationsHint;

  /// No description provided for @patientRegNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get patientRegNotesLabel;

  /// No description provided for @patientRegNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes (optional)'**
  String get patientRegNotesHint;

  /// No description provided for @patientRegPersonalSettings.
  ///
  /// In en, this message translates to:
  /// **'Personal Settings'**
  String get patientRegPersonalSettings;

  /// No description provided for @patientRegDoctorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor Name'**
  String get patientRegDoctorNameLabel;

  /// No description provided for @patientRegDoctorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your physician\'s name'**
  String get patientRegDoctorNameHint;

  /// No description provided for @patientRegDoctorContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor Contact'**
  String get patientRegDoctorContactLabel;

  /// No description provided for @patientRegDoctorContactHint.
  ///
  /// In en, this message translates to:
  /// **'Phone or email'**
  String get patientRegDoctorContactHint;

  /// No description provided for @patientRegEmergencyContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get patientRegEmergencyContactLabel;

  /// No description provided for @patientRegEmergencyContactHint.
  ///
  /// In en, this message translates to:
  /// **'Name and phone number'**
  String get patientRegEmergencyContactHint;

  /// No description provided for @patientRegCalibrationOffsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Calibration Offset (mg/dL)'**
  String get patientRegCalibrationOffsetLabel;

  /// No description provided for @patientRegCalibrationOffsetHint.
  ///
  /// In en, this message translates to:
  /// **'0.0'**
  String get patientRegCalibrationOffsetHint;

  /// No description provided for @patientRegInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get patientRegInvalidNumber;

  /// No description provided for @patientRegSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get patientRegSaveContinue;

  /// No description provided for @profileUnknownName.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get profileUnknownName;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {year}'**
  String profileMemberSince(int year);

  /// No description provided for @profilePersonalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get profilePersonalInfoTitle;

  /// No description provided for @profileNoProfileSetUp.
  ///
  /// In en, this message translates to:
  /// **'No profile set up yet'**
  String get profileNoProfileSetUp;

  /// No description provided for @profileAddNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Add your name so readings can be saved.'**
  String get profileAddNamePrompt;

  /// No description provided for @profileSetUpProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up profile'**
  String get profileSetUpProfile;

  /// No description provided for @profileGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileGenderFemale;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEdit;

  /// No description provided for @profileTapEditPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap edit to add your details.'**
  String get profileTapEditPrompt;

  /// No description provided for @profileAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs'**
  String profileAgeYears(int age);

  /// No description provided for @profileSetUpYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get profileSetUpYourProfile;

  /// No description provided for @profileEditPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit personal info'**
  String get profileEditPersonalInfo;

  /// No description provided for @profileNameRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your name is required to save measurements.'**
  String get profileNameRequiredSubtitle;

  /// No description provided for @profileFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullNameLabel;

  /// No description provided for @profileYourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileYourNameHint;

  /// No description provided for @profileNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get profileNameRequiredError;

  /// No description provided for @profileMinTwoCharsError.
  ///
  /// In en, this message translates to:
  /// **'At least 2 characters'**
  String get profileMinTwoCharsError;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhoneLabel;

  /// No description provided for @profilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+1 555 000 0000'**
  String get profilePhoneHint;

  /// No description provided for @profileInvalidPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get profileInvalidPhoneError;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get profileEmailHint;

  /// No description provided for @profileInvalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get profileInvalidEmailError;

  /// No description provided for @profileCreateProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get profileCreateProfileButton;

  /// No description provided for @profileSaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChangesButton;

  /// No description provided for @profileMedicalConditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical conditions'**
  String get profileMedicalConditionsTitle;

  /// No description provided for @profileContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get profileContactsTitle;

  /// No description provided for @profileDoctorLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get profileDoctorLabel;

  /// No description provided for @profileDoctorPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor phone'**
  String get profileDoctorPhoneLabel;

  /// No description provided for @profileEmergencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get profileEmergencyLabel;

  /// No description provided for @profileEditContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit contacts'**
  String get profileEditContactsTitle;

  /// No description provided for @profileDoctorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor name'**
  String get profileDoctorNameLabel;

  /// No description provided for @profileDoctorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Dr. Smith'**
  String get profileDoctorNameHint;

  /// No description provided for @profileDoctorNameMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get profileDoctorNameMinLengthError;

  /// No description provided for @profileEmergencyContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get profileEmergencyContactLabel;

  /// No description provided for @profileEmergencyContactHint.
  ///
  /// In en, this message translates to:
  /// **'Name · +1 555 000 0001'**
  String get profileEmergencyContactHint;

  /// No description provided for @profileEmergencyContactMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Enter at least a name or number'**
  String get profileEmergencyContactMinLengthError;

  /// No description provided for @profileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSaveButton;

  /// No description provided for @profileAppSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get profileAppSettingsTitle;

  /// No description provided for @profileThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileThemeLabel;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileThemeLight;

  /// No description provided for @profileThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get profileThemeAuto;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileThemeDark;

  /// No description provided for @profileLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageLabel;

  /// No description provided for @languageNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// No description provided for @languageNameArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageNameArabic;

  /// No description provided for @profileSwitchModeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch app mode?'**
  String get profileSwitchModeDialogTitle;

  /// No description provided for @profileSwitchModeDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will return you to the mode selection screen. Your readings and data remain on the device.'**
  String get profileSwitchModeDialogContent;

  /// No description provided for @profileCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancelButton;

  /// No description provided for @profileSwitchButton.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get profileSwitchButton;

  /// No description provided for @profileAppModeTitle.
  ///
  /// In en, this message translates to:
  /// **'App mode'**
  String get profileAppModeTitle;

  /// No description provided for @profileAppModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch to a different mode (Personal or Clinic). All readings and settings remain saved on this device.'**
  String get profileAppModeDescription;

  /// No description provided for @profileSwitchModeButton.
  ///
  /// In en, this message translates to:
  /// **'Switch mode'**
  String get profileSwitchModeButton;

  /// No description provided for @profileCouldNotLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get profileCouldNotLoadError;

  /// No description provided for @remindersWaterReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Reminder'**
  String get remindersWaterReminderTitle;

  /// No description provided for @remindersEnableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminders'**
  String get remindersEnableReminders;

  /// No description provided for @remindersInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get remindersInterval;

  /// No description provided for @remindersInterval1Hr.
  ///
  /// In en, this message translates to:
  /// **'1 hr'**
  String get remindersInterval1Hr;

  /// No description provided for @remindersInterval2Hrs.
  ///
  /// In en, this message translates to:
  /// **'2 hrs'**
  String get remindersInterval2Hrs;

  /// No description provided for @remindersInterval3Hrs.
  ///
  /// In en, this message translates to:
  /// **'3 hrs'**
  String get remindersInterval3Hrs;

  /// No description provided for @remindersInterval4Hrs.
  ///
  /// In en, this message translates to:
  /// **'4 hrs'**
  String get remindersInterval4Hrs;

  /// No description provided for @remindersWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Wake Time'**
  String get remindersWakeTime;

  /// No description provided for @remindersSleepTime.
  ///
  /// In en, this message translates to:
  /// **'Sleep Time'**
  String get remindersSleepTime;

  /// No description provided for @remindersTodaysIntake.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Intake'**
  String get remindersTodaysIntake;

  /// No description provided for @remindersGlasses.
  ///
  /// In en, this message translates to:
  /// **'glasses'**
  String get remindersGlasses;

  /// No description provided for @remindersAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get remindersAm;

  /// No description provided for @remindersPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get remindersPm;

  /// No description provided for @remindersGlucoseMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Glucose Measurement'**
  String get remindersGlucoseMeasurement;

  /// No description provided for @remindersAddReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder Time'**
  String get remindersAddReminderTime;

  /// No description provided for @remindersRepeatsDaily.
  ///
  /// In en, this message translates to:
  /// **'Repeats daily'**
  String get remindersRepeatsDaily;

  /// No description provided for @remindersNoReminderTimes.
  ///
  /// In en, this message translates to:
  /// **'No reminder times set.'**
  String get remindersNoReminderTimes;

  /// No description provided for @remindersMedicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get remindersMedicationsTitle;

  /// No description provided for @remindersAddMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get remindersAddMedication;

  /// No description provided for @remindersNoMedications.
  ///
  /// In en, this message translates to:
  /// **'No medications added.'**
  String get remindersNoMedications;

  /// No description provided for @remindersTakenStatus.
  ///
  /// In en, this message translates to:
  /// **'✅  Taken'**
  String get remindersTakenStatus;

  /// No description provided for @remindersMissedStatus.
  ///
  /// In en, this message translates to:
  /// **'❌  Missed'**
  String get remindersMissedStatus;

  /// No description provided for @remindersMedicationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get remindersMedicationNameLabel;

  /// No description provided for @remindersMedicationNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Metformin'**
  String get remindersMedicationNameHint;

  /// No description provided for @remindersDoseLabel.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get remindersDoseLabel;

  /// No description provided for @remindersDoseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500 mg'**
  String get remindersDoseHint;

  /// No description provided for @remindersFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get remindersFrequencyLabel;

  /// No description provided for @remindersFrequencyOnceDaily.
  ///
  /// In en, this message translates to:
  /// **'Once daily'**
  String get remindersFrequencyOnceDaily;

  /// No description provided for @remindersFrequencyTwiceDaily.
  ///
  /// In en, this message translates to:
  /// **'Twice daily'**
  String get remindersFrequencyTwiceDaily;

  /// No description provided for @remindersFrequencyOnceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Once weekly'**
  String get remindersFrequencyOnceWeekly;

  /// No description provided for @remindersFrequencyAsNeeded.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get remindersFrequencyAsNeeded;

  /// No description provided for @notifWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'💧 Time to Hydrate'**
  String get notifWaterTitle;

  /// No description provided for @notifWaterBody.
  ///
  /// In en, this message translates to:
  /// **'Drink a glass of water to stay healthy!'**
  String get notifWaterBody;

  /// No description provided for @notifWaterChannelName.
  ///
  /// In en, this message translates to:
  /// **'Water Reminders'**
  String get notifWaterChannelName;

  /// No description provided for @notifGlucoseTitle.
  ///
  /// In en, this message translates to:
  /// **'🩸 Glucose Check'**
  String get notifGlucoseTitle;

  /// No description provided for @notifGlucoseBody.
  ///
  /// In en, this message translates to:
  /// **'Time for your glucose measurement!'**
  String get notifGlucoseBody;

  /// No description provided for @notifGlucoseChannelName.
  ///
  /// In en, this message translates to:
  /// **'Glucose Reminders'**
  String get notifGlucoseChannelName;

  /// No description provided for @notifMedTitle.
  ///
  /// In en, this message translates to:
  /// **'💊 Medication Reminder'**
  String get notifMedTitle;

  /// No description provided for @notifMedBody.
  ///
  /// In en, this message translates to:
  /// **'Take {medicationName} — {dose}'**
  String notifMedBody(String medicationName, String dose);

  /// No description provided for @notifMedChannelName.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminders'**
  String get notifMedChannelName;

  /// No description provided for @pdfReportTitle.
  ///
  /// In en, this message translates to:
  /// **'GlucoTrack Report'**
  String get pdfReportTitle;

  /// No description provided for @pdfPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period: {rangeLabel}'**
  String pdfPeriod(String rangeLabel);

  /// No description provided for @pdfGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {dateTime}'**
  String pdfGenerated(String dateTime);

  /// No description provided for @pdfPatientInformation.
  ///
  /// In en, this message translates to:
  /// **'Patient Information'**
  String get pdfPatientInformation;

  /// No description provided for @pdfName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pdfName;

  /// No description provided for @pdfAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get pdfAge;

  /// No description provided for @pdfGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get pdfGender;

  /// No description provided for @pdfBloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get pdfBloodType;

  /// No description provided for @pdfConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions: {list}'**
  String pdfConditions(String list);

  /// No description provided for @pdfStatisticalSummary.
  ///
  /// In en, this message translates to:
  /// **'Statistical Summary'**
  String get pdfStatisticalSummary;

  /// No description provided for @pdfAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get pdfAverage;

  /// No description provided for @pdfMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get pdfMin;

  /// No description provided for @pdfMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get pdfMax;

  /// No description provided for @pdfStdDev.
  ///
  /// In en, this message translates to:
  /// **'Std Dev'**
  String get pdfStdDev;

  /// No description provided for @pdfTimeInRange.
  ///
  /// In en, this message translates to:
  /// **'Time-in-Range'**
  String get pdfTimeInRange;

  /// No description provided for @pdfGlucoseReadings.
  ///
  /// In en, this message translates to:
  /// **'Glucose Readings ({count})'**
  String pdfGlucoseReadings(int count);

  /// No description provided for @pdfDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get pdfDateTime;

  /// No description provided for @pdfGlucose.
  ///
  /// In en, this message translates to:
  /// **'Glucose'**
  String get pdfGlucose;

  /// No description provided for @pdfZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get pdfZone;

  /// No description provided for @pdfBp.
  ///
  /// In en, this message translates to:
  /// **'BP'**
  String get pdfBp;

  /// No description provided for @pdfHr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get pdfHr;
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
