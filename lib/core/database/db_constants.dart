// lib/core/database/db_constants.dart

/// All table names and column names as static const strings.
/// Reference these everywhere — never use raw string literals in queries.
abstract final class DbConstants {
  // ── Version ────────────────────────────────────────────────────
  static const int dbVersion = 1;
  static const String dbName = 'glucotrack.db';

  // ── Table names ────────────────────────────────────────────────
  static const String tablePatients     = 'patients';
  static const String tableMeasurements = 'measurements';

  // ── Index names ────────────────────────────────────────────────
  static const String idxPatientsPhone   = 'idx_patients_phone';
  static const String idxPatientsName    = 'idx_patients_name';
  static const String idxMeasurements    = 'idx_measurements_patient';

  // ── patients columns ───────────────────────────────────────────
  static const String colId               = 'id';
  static const String colFullName         = 'full_name';
  static const String colPhone            = 'phone';
  static const String colEmail            = 'email';
  static const String colAge              = 'age';
  static const String colGender           = 'gender';
  static const String colBloodType        = 'blood_type';
  static const String colHealthStatus     = 'health_status';
  static const String colHasDiabetes      = 'has_diabetes';
  static const String colDiabetesType     = 'diabetes_type';
  static const String colHasHypertension  = 'has_hypertension';
  static const String colHasHeartDisease  = 'has_heart_disease';
  static const String colHasKidneyDisease = 'has_kidney_disease';
  static const String colHasAsthmaCopd    = 'has_asthma_copd';
  static const String colMedications      = 'medications';
  static const String colNotes            = 'notes';
  static const String colCreatedAt        = 'created_at';

  // ── measurements columns ───────────────────────────────────────
  static const String colPatientId      = 'patient_id';
  static const String colGlucoseMgDl    = 'glucose_mg_dl';
  static const String colHeartRateBpm   = 'heart_rate_bpm';
  static const String colBpSystolic     = 'bp_systolic';
  static const String colBpDiastolic    = 'bp_diastolic';
  static const String colMeasuredAt     = 'measured_at';
  // colNotes is shared
}
