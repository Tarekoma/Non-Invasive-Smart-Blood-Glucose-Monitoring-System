// lib/core/database/db_helper.dart

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'db_constants.dart';

/// Singleton wrapper around the sqflite [Database].
///
/// Usage:
/// ```dart
/// final db = await DatabaseHelper.instance.database;
/// ```
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  /// Returns the open [Database], initialising it on first call.
  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  // ── Initialisation ─────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, DbConstants.dbName);

    return openDatabase(
      fullPath,
      version: DbConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Schema creation ────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createPatientsTable);
    await db.execute(_createMeasurementsTable);
    // Mandatory indexes must exist before any query runs.
    await db.execute(_createIdxPatientsPhone);
    await db.execute(_createIdxPatientsName);
    await db.execute(_createIdxMeasurements);
  }

  // ── Migration stubs ────────────────────────────────────────────
  // Add `case` blocks here as dbVersion increments.

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      switch (v) {
        // case 2: await db.execute('ALTER TABLE ...');
        default:
          break;
      }
    }
  }

  // ── DDL statements ─────────────────────────────────────────────

  static const String _createPatientsTable = '''
    CREATE TABLE ${DbConstants.tablePatients} (
      ${DbConstants.colId}               INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbConstants.colFullName}         TEXT    NOT NULL,
      ${DbConstants.colPhone}            TEXT    UNIQUE,
      ${DbConstants.colEmail}            TEXT,
      ${DbConstants.colAge}              INTEGER,
      ${DbConstants.colGender}           TEXT,
      ${DbConstants.colBloodType}        TEXT,
      ${DbConstants.colHealthStatus}     TEXT,
      ${DbConstants.colHasDiabetes}      INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colDiabetesType}     TEXT,
      ${DbConstants.colHasHypertension}  INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colHasHeartDisease}  INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colHasKidneyDisease} INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colHasAsthmaCopd}    INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colMedications}      TEXT,
      ${DbConstants.colNotes}            TEXT,
      ${DbConstants.colCreatedAt}        TEXT    NOT NULL
    )
  ''';

  static const String _createMeasurementsTable = '''
    CREATE TABLE ${DbConstants.tableMeasurements} (
      ${DbConstants.colId}           INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbConstants.colPatientId}    INTEGER NOT NULL
                                       REFERENCES ${DbConstants.tablePatients}(${DbConstants.colId})
                                       ON DELETE CASCADE,
      ${DbConstants.colGlucoseMgDl}  REAL,
      ${DbConstants.colHeartRateBpm} INTEGER,
      ${DbConstants.colBpSystolic}   INTEGER,
      ${DbConstants.colBpDiastolic}  INTEGER,
      ${DbConstants.colNotes}        TEXT,
      ${DbConstants.colMeasuredAt}   TEXT NOT NULL
    )
  ''';

  // Indexes
  static const String _createIdxPatientsPhone = '''
    CREATE INDEX ${DbConstants.idxPatientsPhone}
      ON ${DbConstants.tablePatients}(${DbConstants.colPhone})
  ''';

  static const String _createIdxPatientsName = '''
    CREATE INDEX ${DbConstants.idxPatientsName}
      ON ${DbConstants.tablePatients}(${DbConstants.colFullName})
  ''';

  static const String _createIdxMeasurements = '''
    CREATE INDEX ${DbConstants.idxMeasurements}
      ON ${DbConstants.tableMeasurements}(
        ${DbConstants.colPatientId},
        ${DbConstants.colMeasuredAt} DESC
      )
  ''';
}
