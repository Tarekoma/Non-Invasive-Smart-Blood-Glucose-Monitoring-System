// lib/features/patients/repository/patient_repository.dart

import 'package:sqflite/sqflite.dart';

import '../../../core/database/db_constants.dart';
import '../../../core/database/db_helper.dart';
import '../models/patient_model.dart';

/// Encapsulates all SQLite operations for the [patients] table.
///
/// Rules:
///   - Every method is async/await — never synchronous.
///   - Never returns raw Maps — always typed [PatientModel].
///   - No UI logic here.
class PatientRepository {
  const PatientRepository();

  // ── Insert ─────────────────────────────────────────────────────

  /// Inserts a new patient and returns the auto-generated row id.
  ///
  /// Throws a [DatabaseException] (`isUniqueConstraintError() == true`) if
  /// [patient.phone] already belongs to another patient — callers must
  /// surface this rather than silently overwrite the existing record.
  Future<int> insertPatient(PatientModel patient) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert(
      DbConstants.tablePatients,
      patient.toMap()..remove(DbConstants.colId),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ── Update ─────────────────────────────────────────────────────

  /// Updates an existing patient record. [patient.id] must not be null.
  Future<void> updatePatient(PatientModel patient) async {
    assert(patient.id != null, 'updatePatient: patient.id must not be null');
    final db = await DatabaseHelper.instance.database;
    await db.update(
      DbConstants.tablePatients,
      patient.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [patient.id],
    );
  }

  // ── Queries ────────────────────────────────────────────────────

  /// Returns a single patient by primary key, or null if not found.
  Future<PatientModel?> getPatientById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DbConstants.tablePatients,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PatientModel.fromMap(rows.first);
  }

  /// Searches patients by [full_name] OR [phone] using a LIKE pattern.
  /// Returns results ordered by [full_name] ASC.
  Future<List<PatientModel>> searchPatients(String query) async {
    if (query.trim().isEmpty) return getAllPatients();
    final db = await DatabaseHelper.instance.database;
    final pattern = '%${query.trim()}%';
    final rows = await db.query(
      DbConstants.tablePatients,
      where:
          '${DbConstants.colFullName} LIKE ? OR ${DbConstants.colPhone} LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: DbConstants.colFullName,
    );
    return rows.map(PatientModel.fromMap).toList();
  }

  /// Returns all patients ordered by [created_at] DESC (newest first).
  Future<List<PatientModel>> getAllPatients() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DbConstants.tablePatients,
      orderBy: '${DbConstants.colCreatedAt} DESC',
    );
    return rows.map(PatientModel.fromMap).toList();
  }

  /// Returns the [measured_at] timestamp of the most recent measurement
  /// for [patientId], or null if no measurements exist yet.
  Future<DateTime?> getLastMeasurementDate(int patientId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DbConstants.tableMeasurements,
      columns:  [DbConstants.colMeasuredAt],
      where:    '${DbConstants.colPatientId} = ?',
      whereArgs: [patientId],
      orderBy:  '${DbConstants.colMeasuredAt} DESC',
      limit:    1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first[DbConstants.colMeasuredAt] as String?;
    if (raw == null) return null;
    return DateTime.parse(raw);
  }
}


