import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteService {
  static const String _dbName = 'gait_physiotherapy.db';
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
    return _database!;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE devices (
          id TEXT PRIMARY KEY,
          name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE patients (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          age INTEGER NOT NULL,
          created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions (
          id TEXT PRIMARY KEY,
          device_id TEXT NOT NULL,
          patient_id TEXT NOT NULL,
          leg TEXT NOT NULL,
          date TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          duration REAL NOT NULL,
          steps_counted INTEGER NOT NULL,
          avg_cadence REAL NOT NULL,
          movement_smoothness_sparc REAL NOT NULL,
          stance_pct REAL NOT NULL,
          swing_pct REAL NOT NULL,
          avg_step_time REAL NOT NULL,
          avg_gait_speed REAL NOT NULL,
          slm_insights TEXT,
          FOREIGN KEY (device_id) REFERENCES devices(id),
          FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> importDatabase() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      String importPath = result.files.single.path!;

      Database? importedDb;
      try {
        importedDb = await openDatabase(importPath, readOnly: true);
        final tables = await importedDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableNames = tables.map((e) => e['name'] as String).toSet();

        if (!tableNames.contains('devices') ||
            !tableNames.contains('patients') ||
            !tableNames.contains('sessions')) {
          throw Exception('Invalid database schema. Missing required tables.');
        }
      } catch (e) {
        if (e is DatabaseException) {
          throw Exception('Invalid file format. Please select a valid SQLite database file.');
        }
        rethrow;
      } finally {
        if (importedDb != null) {
          await importedDb.close();
        }
      }

      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      File importedFile = File(importPath);
      await importedFile.copy(path);
    } else {
      throw Exception('No file selected.');
    }
  }

  static Future<void> createTestData() async {
    final db = await database;

    await db.insert(
      'devices',
      {'id': '1', 'name': 'TestDevice'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    await db.insert(
      'patients',
      {
        'id': 'patient_healthy',
        'name': 'healthy_patient',
        'age': 30,
        'created_at': nowIso,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.insert(
      'patients',
      {
        'id': 'patient_1',
        'name': 'patient1',
        'age': 45,
        'created_at': nowIso,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    int sessionCounter = 0;
    Future<void> insertSession({
      required String patientId,
      required String leg,
      required double duration,
      required int stepsCounted,
      required double avgCadence,
      required double sparc,
      required double stancePct,
      required double swingPct,
      required double avgStepTime,
      required double avgGaitSpeed,
    }) async {
      sessionCounter++;
      final start = now.subtract(Duration(minutes: sessionCounter * 5));
      final end = start.add(Duration(milliseconds: (duration * 1000).round()));

      await db.insert(
        'sessions',
        {
          'id': 'session_$sessionCounter',
          'device_id': '1',
          'patient_id': patientId,
          'leg': leg,
          'date': start.toIso8601String().split('T').first,
          'start_time': start.toIso8601String(),
          'end_time': end.toIso8601String(),
          'duration': duration,
          'steps_counted': stepsCounted,
          'avg_cadence': avgCadence,
          'movement_smoothness_sparc': sparc,
          'stance_pct': stancePct,
          'swing_pct': swingPct,
          'avg_step_time': avgStepTime,
          'avg_gait_speed': avgGaitSpeed,
          'slm_insights': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await insertSession(
      patientId: 'patient_healthy',
      leg: 'LEFT',
      duration: 18.67,
      stepsCounted: 13,
      avgCadence: 57.46,
      sparc: -5.727,
      stancePct: 61.9,
      swingPct: 37.8,
      avgStepTime: 1.047,
      avgGaitSpeed: 1.227,
    );

    await insertSession(
      patientId: 'patient_healthy',
      leg: 'RIGHT',
      duration: 18.48,
      stepsCounted: 21,
      avgCadence: 98.30,
      sparc: -4.612,
      stancePct: 59.0,
      swingPct: 39.5,
      avgStepTime: 0.669,
      avgGaitSpeed: 1.680,
    );

    await insertSession(
      patientId: 'patient_1',
      leg: 'LEFT',
      duration: 22.74,
      stepsCounted: 15,
      avgCadence: 51.29,
      sparc: -4.315,
      stancePct: 68.9,
      swingPct: 31.7,
      avgStepTime: 1.171,
      avgGaitSpeed: 0.889,
    );

    await insertSession(
      patientId: 'patient_1',
      leg: 'LEFT',
      duration: 29.14,
      stepsCounted: 20,
      avgCadence: 47.63,
      sparc: -3.740,
      stancePct: 68.5,
      swingPct: 31.6,
      avgStepTime: 1.262,
      avgGaitSpeed: 0.684,
    );

    await insertSession(
      patientId: 'patient_1',
      leg: 'LEFT',
      duration: 28.22,
      stepsCounted: 20,
      avgCadence: 52.53,
      sparc: -3.873,
      stancePct: 69.4,
      swingPct: 30.8,
      avgStepTime: 1.145,
      avgGaitSpeed: 0.749,
    );

    await insertSession(
      patientId: 'patient_1',
      leg: 'RIGHT',
      duration: 24.20,
      stepsCounted: 59,
      avgCadence: 215.84,
      sparc: -2.266,
      stancePct: 62.0,
      swingPct: 37.4,
      avgStepTime: 0.349,
      avgGaitSpeed: 1.623,
    );

    await insertSession(
      patientId: 'patient_1',
      leg: 'RIGHT',
      duration: 29.77,
      stepsCounted: 54,
      avgCadence: 178.21,
      sparc: -2.251,
      stancePct: 59.4,
      swingPct: 46.1,
      avgStepTime: 0.448,
      avgGaitSpeed: 1.595,
    );

    await insertSession(
      patientId: 'patient_1',
      leg: 'RIGHT',
      duration: 27.24,
      stepsCounted: 28,
      avgCadence: 153.16,
      sparc: -2.234,
      stancePct: 59.1,
      swingPct: 44.7,
      avgStepTime: 0.463,
      avgGaitSpeed: 0.976,
    );
  }
}
