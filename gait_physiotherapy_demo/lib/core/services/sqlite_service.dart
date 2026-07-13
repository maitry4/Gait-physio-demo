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
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE patients ADD COLUMN overall_insights TEXT');
        }
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
          created_at TEXT NOT NULL,
          overall_insights TEXT
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

  static Future<List<Map<String, dynamic>>> getDevices() async {
    final db = await database;
    return await db.query('devices');
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
      required String slm_insights,
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
          'slm_insights': slm_insights,
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
      slm_insights:"Based on the provided gait metrics, here's a 2-sentence clinical takeaway:\nThis patient's gait is characterized as having a relatively high cadence and average gait speed, indicating good mobility and potential for quick recovery. However, the negative movement smoothness score suggests that the patient may experience some gait instability, which warrants further assessment and potential interventions to improve gait quality.",
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
      slm_insights:"Based on the provided gait metrics, here's a 2-sentence clinical takeaway:\n\nThe patient demonstrated a relatively normal gait speed (1.68 m/s) but with slightly reduced movement smoothness (-4.61), indicating potential issues with balance or coordination that may require further assessment and intervention. Additionally, the patient's cadence (98 steps/min) and step time (0.67 seconds) suggest a relatively normal gait pattern, but further analysis of the patient's overall gait mechanics is necessary to confirm these findings.",
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
      slm_insights:"Based on the provided gait metrics, here's a 2-sentence clinical takeaway:\n\nThe patient's gait appears to be relatively smooth, with a high average cadence of 51.29 steps per minute, suggesting a good level of mobility and muscle strength. However, the negative movement smoothness (SPARC) value (-4.31) indicates a slight deviation from a typical, symmetrical gait pattern, which may warrant further assessment to identify potential underlying issues.",
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
      slm_insights:"Based on the provided gait metrics, here's a 2-sentence clinical takeaway:\n\nThe patient demonstrates a relatively normal gait pattern with a moderate cadence of 47.6 steps per minute, indicating a potential need for further assessment to optimize their gait efficiency. However, the slightly negative movement smoothness (SPARC) score (-3.74) suggests some degree of gait irregularity or asymmetry that warrants further investigation and potentially targeted interventions.",
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
      slm_insights:"Based on the provided gait metrics, here's a 2-sentence clinical takeaway:\n\nThe patient demonstrated a slightly slower gait speed (0.75 mps) and reduced movement smoothness (-3.87), indicating potential gait instability or difficulty with locomotion. Further analysis of the gait pattern, including the relatively high stance phase ratio (69.43%), may be necessary to identify specific areas of concern and develop targeted interventions.",
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
      slm_insights:"Based on the provided gait metrics, here's a 2-sentence clinical takeaway:\n\nThe patient's average gait speed is within a relatively normal range (1.6231598425711153 mps), indicating some level of functional mobility, but their movement smoothness is slightly impaired (-2.265772349226957), suggesting the need for further evaluation of their gait patterns and potential interventions to improve coordination and stability.",
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
      slm_insights:"Based on the provided gait metrics, here's a 2-sentence clinical takeaway:\n\nThe patient demonstrated a relatively normal gait pattern with a moderate cadence of 178 steps per minute, but exhibited slightly reduced movement smoothness, suggesting potential issues with motor control or coordination. Further assessment is needed to determine the underlying cause of this finding, but it may warrant consideration in the patient's rehabilitation plan.",
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
      slm_insights:"Based on the provided gait metrics, here's a 2-sentence clinical takeaway:\n\nThe patient demonstrated a relatively fast average gait speed of 0.98 meters per second, suggesting potential mobility and strength, but may benefit from further analysis to assess overall gait efficiency and stability. The negative movement smoothness score (-2.23) indicates some level of gait irregularity or asymmetry, which warrants further examination to determine its impact on the patient's overall mobility and potential risk for falls.",
    );
  }

  static Future<Map<String, dynamic>> getPatientInsights(String patientId) async {
    final db = await database;

    // 1. Overall averages across all patient sessions
    final List<Map<String, dynamic>> overallResults = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sessions,
        AVG(avg_cadence) as avg_cadence,
        AVG(avg_gait_speed) as avg_gait_speed,
        AVG(avg_step_time) as avg_step_time,
        AVG(avg_step_time * avg_gait_speed) as avg_stride_length,
        AVG(stance_pct) as avg_stance_pct,
        AVG(swing_pct) as avg_swing_pct,
        AVG(movement_smoothness_sparc) as avg_sparc
      FROM sessions
      WHERE patient_id = ?
    ''', [patientId]);

    // 2. Leg-specific breakdown for bilateral symmetry comparison
    final List<Map<String, dynamic>> legResults = await db.rawQuery('''
      SELECT 
        leg,
        COUNT(*) as count,
        AVG(stance_pct) as avg_stance_pct,
        AVG(swing_pct) as avg_swing_pct,
        AVG(avg_cadence) as avg_cadence,
        AVG(avg_gait_speed) as avg_gait_speed
      FROM sessions
      WHERE patient_id = ?
      GROUP BY leg
    ''', [patientId]);

    double leftStance = 0.0;
    double rightStance = 0.0;
    for (var row in legResults) {
      final legStr = (row['leg'] as String? ?? '').toUpperCase();
      if (legStr.startsWith('LEFT')) {
        leftStance = (row['avg_stance_pct'] as num?)?.toDouble() ?? 0.0;
      } else if (legStr.startsWith('RIGHT')) {
        rightStance = (row['avg_stance_pct'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // Dynamic symmetry calculation: perfect is 100%, each 1% stance difference reduces it by 5%
    double symmetry = 100.0;
    if (leftStance > 0 && rightStance > 0) {
      symmetry = (100.0 - (leftStance - rightStance).abs() * 5.0).clamp(0.0, 100.0);
    } else {
      // Default to 85.0 if only single-sided trials exist
      symmetry = 85.0;
    }

    if (overallResults.isEmpty || overallResults.first['total_sessions'] == 0) {
      return {
        'total_sessions': 0,
        'avg_cadence': 0.0,
        'avg_gait_speed': 0.0,
        'avg_step_time': 0.0,
        'avg_stride_length': 0.0,
        'avg_stance_pct': 0.0,
        'avg_swing_pct': 0.0,
        'avg_sparc': 0.0,
        'avg_score': 0.0,
        'symmetry': 100.0,
        'leg_breakdown': <String, Map<String, dynamic>>{},
      };
    }

    final row = overallResults.first;
    final totalSessions = row['total_sessions'] as int? ?? 0;
    final avgCadence = (row['avg_cadence'] as num?)?.toDouble() ?? 0.0;
    final avgGaitSpeed = (row['avg_gait_speed'] as num?)?.toDouble() ?? 0.0;
    final avgStepTime = (row['avg_step_time'] as num?)?.toDouble() ?? 0.0;
    final avgStrideLength = (row['avg_stride_length'] as num?)?.toDouble() ?? (avgStepTime * avgGaitSpeed);
    final avgStancePct = (row['avg_stance_pct'] as num?)?.toDouble() ?? 0.0;
    final avgSwingPct = (row['avg_swing_pct'] as num?)?.toDouble() ?? 0.0;
    final avgSparc = (row['avg_sparc'] as num?)?.toDouble() ?? 0.0;
    final avgScore = (avgSparc * -10).clamp(0.0, 100.0);

    final Map<String, Map<String, dynamic>> legBreakdown = {};
    for (var legRow in legResults) {
      final leg = legRow['leg'] as String? ?? 'UNKNOWN';
      legBreakdown[leg] = {
        'count': legRow['count'] as int? ?? 0,
        'avg_stance_pct': (legRow['avg_stance_pct'] as num?)?.toDouble() ?? 0.0,
        'avg_swing_pct': (legRow['avg_swing_pct'] as num?)?.toDouble() ?? 0.0,
        'avg_cadence': (legRow['avg_cadence'] as num?)?.toDouble() ?? 0.0,
        'avg_gait_speed': (legRow['avg_gait_speed'] as num?)?.toDouble() ?? 0.0,
      };
    }

    return {
      'total_sessions': totalSessions,
      'avg_cadence': avgCadence,
      'avg_gait_speed': avgGaitSpeed,
      'avg_step_time': avgStepTime,
      'avg_stride_length': avgStrideLength,
      'avg_stance_pct': avgStancePct,
      'avg_swing_pct': avgSwingPct,
      'avg_sparc': avgSparc,
      'avg_score': avgScore,
      'symmetry': symmetry,
      'leg_breakdown': legBreakdown,
    };
  }

  static Future<void> invalidatePatientSummary(String patientId) async {
    final db = await database;
    await db.update(
      'patients',
      {'overall_insights': null},
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }
}