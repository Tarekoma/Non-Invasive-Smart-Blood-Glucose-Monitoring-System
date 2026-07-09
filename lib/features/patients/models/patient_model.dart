// lib/features/patients/models/patient_model.dart
//
// Pure Dart — zero Flutter imports.

import '../../../core/database/db_constants.dart';

class PatientModel {
  const PatientModel({
    this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.age,
    this.gender,
    this.bloodType,
    this.healthStatus,
    this.hasDiabetes      = false,
    this.diabetesType,
    this.hasHypertension  = false,
    this.hasHeartDisease  = false,
    this.hasKidneyDisease = false,
    this.hasAsthmaCopd    = false,
    this.medications,
    this.notes,
    required this.createdAt,
  });

  final int?     id;
  final String   fullName;
  final String?  phone;
  final String?  email;
  final int?     age;
  final String?  gender;       // 'male' | 'female'
  final String?  bloodType;    // 'A+' | 'A-' | etc.
  final String?  healthStatus; // 'healthy' | 'has_conditions'
  final bool     hasDiabetes;
  final String?  diabetesType; // 'type1' | 'type2' | 'pre'
  final bool     hasHypertension;
  final bool     hasHeartDisease;
  final bool     hasKidneyDisease;
  final bool     hasAsthmaCopd;
  final String?  medications;
  final String?  notes;
  final DateTime createdAt;

  // ── Computed getters ────────────────────────────────────────────

  /// Returns true when the patient has no chronic conditions.
  bool get isHealthy => healthStatus == 'healthy';

  /// Returns a readable list of the patient's disease labels.
  List<String> get diseaseLabels {
    if (isHealthy) return [];
    final labels = <String>[];
    if (hasDiabetes) {
      final sub = switch (diabetesType) {
        'type1' => 'Diabetes (Type 1)',
        'type2' => 'Diabetes (Type 2)',
        'pre'   => 'Pre-Diabetic',
        _       => 'Diabetes',
      };
      labels.add(sub);
    }
    if (hasHypertension)  labels.add('Hypertension');
    if (hasHeartDisease)  labels.add('Heart Disease');
    if (hasKidneyDisease) labels.add('Chronic Kidney Disease');
    if (hasAsthmaCopd)    labels.add('Asthma / COPD');
    return labels;
  }

  // ── De/serialisation ────────────────────────────────────────────

  factory PatientModel.fromMap(Map<String, dynamic> map) => PatientModel(
        id:               map[DbConstants.colId]               as int?,
        fullName:         map[DbConstants.colFullName]         as String,
        phone:            map[DbConstants.colPhone]            as String?,
        email:            map[DbConstants.colEmail]            as String?,
        age:              map[DbConstants.colAge]              as int?,
        gender:           map[DbConstants.colGender]           as String?,
        bloodType:        map[DbConstants.colBloodType]        as String?,
        healthStatus:     map[DbConstants.colHealthStatus]     as String?,
        hasDiabetes:      (map[DbConstants.colHasDiabetes]     as int? ?? 0) == 1,
        diabetesType:     map[DbConstants.colDiabetesType]     as String?,
        hasHypertension:  (map[DbConstants.colHasHypertension]  as int? ?? 0) == 1,
        hasHeartDisease:  (map[DbConstants.colHasHeartDisease]  as int? ?? 0) == 1,
        hasKidneyDisease: (map[DbConstants.colHasKidneyDisease] as int? ?? 0) == 1,
        hasAsthmaCopd:    (map[DbConstants.colHasAsthmaCopd]    as int? ?? 0) == 1,
        medications:      map[DbConstants.colMedications]      as String?,
        notes:            map[DbConstants.colNotes]            as String?,
        createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) DbConstants.colId: id,
        DbConstants.colFullName:         fullName,
        DbConstants.colPhone:            phone,
        DbConstants.colEmail:            email,
        DbConstants.colAge:              age,
        DbConstants.colGender:           gender,
        DbConstants.colBloodType:        bloodType,
        DbConstants.colHealthStatus:     healthStatus,
        DbConstants.colHasDiabetes:      hasDiabetes      ? 1 : 0,
        DbConstants.colDiabetesType:     diabetesType,
        DbConstants.colHasHypertension:  hasHypertension  ? 1 : 0,
        DbConstants.colHasHeartDisease:  hasHeartDisease  ? 1 : 0,
        DbConstants.colHasKidneyDisease: hasKidneyDisease ? 1 : 0,
        DbConstants.colHasAsthmaCopd:    hasAsthmaCopd    ? 1 : 0,
        DbConstants.colMedications:      medications,
        DbConstants.colNotes:            notes,
        DbConstants.colCreatedAt:        createdAt.toIso8601String(),
      };

  PatientModel copyWith({
    int?     id,
    String?  fullName,
    String?  phone,
    String?  email,
    int?     age,
    String?  gender,
    String?  bloodType,
    String?  healthStatus,
    bool?    hasDiabetes,
    String?  diabetesType,
    bool?    hasHypertension,
    bool?    hasHeartDisease,
    bool?    hasKidneyDisease,
    bool?    hasAsthmaCopd,
    String?  medications,
    String?  notes,
    DateTime? createdAt,
  }) =>
      PatientModel(
        id:               id               ?? this.id,
        fullName:         fullName         ?? this.fullName,
        phone:            phone            ?? this.phone,
        email:            email            ?? this.email,
        age:              age              ?? this.age,
        gender:           gender           ?? this.gender,
        bloodType:        bloodType        ?? this.bloodType,
        healthStatus:     healthStatus     ?? this.healthStatus,
        hasDiabetes:      hasDiabetes      ?? this.hasDiabetes,
        diabetesType:     diabetesType     ?? this.diabetesType,
        hasHypertension:  hasHypertension  ?? this.hasHypertension,
        hasHeartDisease:  hasHeartDisease  ?? this.hasHeartDisease,
        hasKidneyDisease: hasKidneyDisease ?? this.hasKidneyDisease,
        hasAsthmaCopd:    hasAsthmaCopd    ?? this.hasAsthmaCopd,
        medications:      medications      ?? this.medications,
        notes:            notes            ?? this.notes,
        createdAt:        createdAt        ?? this.createdAt,
      );

  @override
  String toString() =>
      'PatientModel(id=$id, name=$fullName, phone=$phone)';
}
