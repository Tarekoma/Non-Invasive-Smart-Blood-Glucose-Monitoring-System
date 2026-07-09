// lib/core/constants/app_constants.dart

/// App-wide compile-time constants.
/// No Flutter imports — pure Dart only.
abstract final class AppConstants {
  // ── Design canvas ──────────────────────────────────────────────
  static const double designWidth  = 390.0;
  static const double designHeight = 844.0;

  // ── Glucose zone thresholds (mg/dL) ────────────────────────────
  static const double glucoseHypoMax   = 70.0;   // < 70  → hypoglycemia
  static const double glucoseNormalMax = 140.0;  // 70–140 → normal
  static const double glucosePreMax    = 200.0;  // 140–200 → prediabetic
  // > 200 → hyperglycemia

  // ── Vitals out-of-range thresholds ────────────────────────────
  static const int hrLow        = 50;
  static const int hrHigh       = 120;
  static const int bpSysHigh    = 140;
  static const int bpDiaHigh    = 90;

  // ── SharedPreferences keys — app ──────────────────────────────
  static const String appModeKey          = 'app_mode';
  static const String themeModeKey        = 'theme_mode';
  static const String languageKey         = 'language';

  // ── SharedPreferences keys — personal patient ─────────────────
  static const String personalPatientIdKey   = 'personal_patient_id';
  static const String calibrationOffsetKey   = 'calibration_offset';
  static const String doctorNameKey          = 'doctor_name';
  static const String doctorContactKey       = 'doctor_contact';
  static const String emergencyContactKey    = 'emergency_contact';

  // ── SharedPreferences keys — water reminder ───────────────────
  static const String waterEnabledKey    = 'water_enabled';
  static const String waterIntervalKey   = 'water_interval_hours';
  static const String waterWakeTimeKey   = 'water_wake_time';
  static const String waterSleepTimeKey  = 'water_sleep_time';
  static const String waterDailyCountKey = 'water_daily_count';

  // ── SharedPreferences keys — reminders ────────────────────────
  static const String glucoseTimesKey  = 'glucose_reminder_times';
  static const String medicationsKey   = 'medication_reminders';

  // ── App mode values ────────────────────────────────────────────
  static const String modePersonal = 'personal';
  static const String modeClinic   = 'clinic';

  // ── Chart limits ───────────────────────────────────────────────
  static const int chartMaxPoints = 30;
  static const int historyPageSize = 20;

  // ── Water reminder defaults ────────────────────────────────────
  static const int waterDailyGoal          = 8;
  static const int waterDefaultIntervalHrs = 2;
  static const int waterDefaultWakeHour    = 7;
  static const int waterDefaultSleepHour   = 22;

  // ── Notification channel IDs ───────────────────────────────────
  static const String notifChannelWater    = 'glucotrack_water';
  static const String notifChannelGlucose  = 'glucotrack_glucose';
  static const String notifChannelMed      = 'glucotrack_medication';

  // ── Notification ID ranges ─────────────────────────────────────
  static const int notifIdWater       = 1000;
  static const int notifIdGlucoseBase = 2000; // +index
  static const int notifIdMedBase     = 3000; // +index
}
