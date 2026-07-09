// lib/features/measurements/models/measurement_model.dart
//
// Pure Dart — no Flutter imports.

import '../../../core/database/db_constants.dart';
import '../../../core/utils/glucose_zone.dart';

// ── MeasurementModel ───────────────────────────────────────────────────────

class MeasurementModel {
  const MeasurementModel({
    this.id,
    required this.patientId,
    required this.glucoseMgDl,
    this.heartRateBpm,
    this.bpSystolic,
    this.bpDiastolic,
    this.notes,
    required this.measuredAt,
  });

  final int?     id;
  final int      patientId;
  final double   glucoseMgDl;   // non-nullable — every measurement has a value
  final int?     heartRateBpm;
  final int?     bpSystolic;
  final int?     bpDiastolic;
  final String?  notes;
  final DateTime measuredAt;

  // ── Computed ─────────────────────────────────────────────────────────────

  GlucoseZone get zone => GlucoseZoneHelper.fromValue(glucoseMgDl);

  /// True when both systolic and diastolic BP values are present.
  bool get hasBp => bpSystolic != null && bpDiastolic != null;

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory MeasurementModel.fromMap(Map<String, dynamic> map) =>
      MeasurementModel(
        id:           map[DbConstants.colId]           as int?,
        patientId:    map[DbConstants.colPatientId]    as int,
        // Fallback to 0.0 if DB stored null (defensive for legacy rows)
        glucoseMgDl:  ((map[DbConstants.colGlucoseMgDl] as num?) ?? 0).toDouble(),
        heartRateBpm: map[DbConstants.colHeartRateBpm] as int?,
        bpSystolic:   map[DbConstants.colBpSystolic]   as int?,
        bpDiastolic:  map[DbConstants.colBpDiastolic]  as int?,
        notes:        map[DbConstants.colNotes]        as String?,
        measuredAt:   DateTime.parse(map[DbConstants.colMeasuredAt] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) DbConstants.colId: id,
        DbConstants.colPatientId:    patientId,
        DbConstants.colGlucoseMgDl:  glucoseMgDl,
        DbConstants.colHeartRateBpm: heartRateBpm,
        DbConstants.colBpSystolic:   bpSystolic,
        DbConstants.colBpDiastolic:  bpDiastolic,
        DbConstants.colNotes:        notes,
        DbConstants.colMeasuredAt:   measuredAt.toIso8601String(),
      };

  MeasurementModel copyWith({
    int?      id,
    int?      patientId,
    double?   glucoseMgDl,
    int?      heartRateBpm,
    int?      bpSystolic,
    int?      bpDiastolic,
    String?   notes,
    DateTime? measuredAt,
  }) =>
      MeasurementModel(
        id:           id           ?? this.id,
        patientId:    patientId    ?? this.patientId,
        glucoseMgDl:  glucoseMgDl  ?? this.glucoseMgDl,
        heartRateBpm: heartRateBpm ?? this.heartRateBpm,
        bpSystolic:   bpSystolic   ?? this.bpSystolic,
        bpDiastolic:  bpDiastolic  ?? this.bpDiastolic,
        notes:        notes        ?? this.notes,
        measuredAt:   measuredAt   ?? this.measuredAt,
      );

  @override
  String toString() =>
      'MeasurementModel(id=$id, patient=$patientId, '
      'glucose=$glucoseMgDl, hr=$heartRateBpm, at=$measuredAt)';
}

// ── MeasurementStats ──────────────────────────────────────────────────────

/// Aggregated statistics over a set of glucose measurements.
class MeasurementStats {
  const MeasurementStats({
    required this.average,
    required this.min,
    required this.max,
    required this.stdDev,
    required this.timeInRangePercent,
  });

  final double average;
  final double min;
  final double max;
  final double stdDev;

  /// Percentage of readings in the normal range (70–140 mg/dL).
  final double timeInRangePercent;

  static const MeasurementStats empty = MeasurementStats(
    average:            0,
    min:                0,
    max:                0,
    stdDev:             0,
    timeInRangePercent: 0,
  );

  @override
  String toString() =>
      'MeasurementStats(avg=${average.toStringAsFixed(1)}, '
      'min=${min.toStringAsFixed(1)}, max=${max.toStringAsFixed(1)}, '
      'tir=${timeInRangePercent.toStringAsFixed(1)}%)';
}
