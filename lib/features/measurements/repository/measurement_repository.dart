// lib/features/measurements/repository/measurement_repository.dart

import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/db_constants.dart';
import '../../../core/database/db_helper.dart';
import '../models/measurement_model.dart';

class MeasurementRepository {
  const MeasurementRepository();

  // ── Insert ─────────────────────────────────────────────────────────────

  /// Inserts a measurement and returns the auto-generated row id.
  Future<int> insertMeasurement(MeasurementModel m) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert(
      DbConstants.tableMeasurements,
      m.toMap()..remove(DbConstants.colId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Queries ────────────────────────────────────────────────────────────

  /// Returns the [limit] most recent measurements for [patientId],
  /// ordered by [measured_at] DESC. Default limit is 30.
  Future<List<MeasurementModel>> getMeasurementsForPatient(
    int patientId, {
    int limit = 30,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DbConstants.tableMeasurements,
      where:     '${DbConstants.colPatientId} = ?',
      whereArgs: [patientId],
      orderBy:   '${DbConstants.colMeasuredAt} DESC',
      limit:     limit,
    );
    return rows.map(MeasurementModel.fromMap).toList();
  }

  /// Returns measurements in [from]–[to] inclusive, ordered by
  /// [measured_at] ASC (chronological — correct for chart X-axis).
  /// Hard-capped at 30 rows so the chart is never overloaded.
  Future<List<MeasurementModel>> getMeasurementsInRange(
    int patientId,
    DateTime from,
    DateTime to,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DbConstants.tableMeasurements,
      where:
          '${DbConstants.colPatientId} = ? '
          'AND ${DbConstants.colMeasuredAt} >= ? '
          'AND ${DbConstants.colMeasuredAt} <= ?',
      whereArgs: [
        patientId,
        from.toIso8601String(),
        to.toIso8601String(),
      ],
      orderBy: '${DbConstants.colMeasuredAt} ASC',
      limit:   30,
    );
    return rows.map(MeasurementModel.fromMap).toList();
  }

  /// Computes aggregate statistics for all readings of [patientId].
  /// AVG, MIN, MAX, STDDEV, and time-in-range are computed in Dart.
  Future<MeasurementStats> getStats(int patientId) async {
    // Pull up to 1000 rows for stat computation — not for the chart.
    final rows = await getMeasurementsForPatient(patientId, limit: 1000);
    // glucoseMgDl is now non-nullable; skip rows where value is sentinel 0.0
    final values = rows
        .map((m) => m.glucoseMgDl)
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) return MeasurementStats.empty;

    final n        = values.length;
    final sum      = values.fold(0.0, (a, b) => a + b);
    final avg      = sum / n;
    final minVal   = values.reduce(math.min);
    final maxVal   = values.reduce(math.max);

    final variance = values.fold(
        0.0, (acc, v) => acc + (v - avg) * (v - avg)) / n;
    final stdDev   = math.sqrt(variance);

    final inRange  = values
        .where((v) =>
            v >= AppConstants.glucoseHypoMax &&
            v <= AppConstants.glucoseNormalMax)
        .length;
    final tir = (inRange / n) * 100;

    return MeasurementStats(
      average:            avg,
      min:                minVal,
      max:                maxVal,
      stdDev:             stdDev,
      timeInRangePercent: tir,
    );
  }
}
