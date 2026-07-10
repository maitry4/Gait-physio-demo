import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';
import 'package:gait_physiotherapy_demo/features/session/domain/entities/session_entity.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  bool _isMock = false;

  // In-memory fallback database for unsupported platforms (e.g. Windows desktop, Web)
  final List<Map<String, dynamic>> _mockCredentials = [];
  final List<Map<String, dynamic>> _mockUsers = [];
  final List<Map<String, dynamic>> _mockSessions = [];
  final List<Map<String, dynamic>> _mockActiveSession = [];

  DatabaseService._init() {
    if (kIsWeb) {
      _isMock = true;
    } else {
      try {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          _isMock = true;
        }
      } catch (_) {
        _isMock = true;
      }
    }
    if (_isMock) {
      _seedMockData();
    }
  }

  Future<Database?> get database async {
    if (_isMock) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('gait_physio.db');
      return _database;
    } catch (e) {
      print('SQLite Database not supported on this platform: $e. Falling back to safe in-memory store.');
      _isMock = true;
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
    await _seedDatabaseDataIfEmpty(db);
    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Credentials table
    await db.execute('''
      CREATE TABLE credentials (
        ssid TEXT,
        password TEXT,
        remember_me INTEGER
      )
    ''');

    // 2. Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT,
        age INTEGER,
        date_added TEXT
      )
    ''');

    // 3. Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        date TEXT,
        duration TEXT,
        label TEXT,
        score INTEGER,
        stride_length REAL,
        cadence INTEGER,
        balance INTEGER,
        symmetry INTEGER,
        stance_phase REAL,
        swing_phase REAL,
        double_support REAL,
        notes TEXT,
        raw_waveform TEXT,
        slm_interpretation TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 4. Active Session table (for background/killed persistence)
    await db.execute('''
      CREATE TABLE active_session (
        user_id TEXT,
        start_time TEXT,
        step_count INTEGER
      )
    ''');
  }

  // ── Credentials CRUD ───────────────────────────────────────────────────────
  Future<void> saveCredentials(String ssid, String password, bool rememberMe) async {
    final db = await database;
    if (_isMock || db == null) {
      _mockCredentials.clear();
      _mockCredentials.add({
        'ssid': ssid,
        'password': password,
        'remember_me': rememberMe ? 1 : 0,
      });
      return;
    }
    try {
      await db.delete('credentials'); // Keep only one record
      await db.insert('credentials', {
        'ssid': ssid,
        'password': password,
        'remember_me': rememberMe ? 1 : 0,
      });
    } catch (_) {
      _isMock = true;
      await saveCredentials(ssid, password, rememberMe);
    }
  }

  Future<Map<String, dynamic>?> getSavedCredentials() async {
    final db = await database;
    if (_isMock || db == null) {
      return _mockCredentials.isNotEmpty ? _mockCredentials.first : null;
    }
    try {
      final results = await db.query('credentials');
      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (_) {
      _isMock = true;
      return getSavedCredentials();
    }
  }

  Future<void> clearCredentials() async {
    final db = await database;
    if (_isMock || db == null) {
      _mockCredentials.clear();
      return;
    }
    try {
      await db.delete('credentials');
    } catch (_) {
      _isMock = true;
      await clearCredentials();
    }
  }

  // ── Users CRUD ────────────────────────────────────────────────────────────
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    if (_isMock || db == null) {
      _mockUsers.removeWhere((element) => element['id'] == user.id);
      _mockUsers.add(user.toMap());
      return 1;
    }
    try {
      return await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      _isMock = true;
      return await insertUser(user);
    }
  }

  Future<List<UserModel>> getUsers() async {
    final db = await database;
    if (_isMock || db == null) {
      final sortedMock = List<Map<String, dynamic>>.from(_mockUsers);
      sortedMock.sort((a, b) => (b['date_added'] as String).compareTo(a['date_added'] as String));
      return sortedMock.map((map) => UserModel.fromMap(map)).toList();
    }
    try {
      final maps = await db.query('users', orderBy: 'date_added DESC');
      return maps.map((map) => UserModel.fromMap(map)).toList();
    } catch (_) {
      _isMock = true;
      return getUsers();
    }
  }

  // ── Sessions CRUD ─────────────────────────────────────────────────────────
  Future<int> insertSession(SessionModel session) async {
    final db = await database;
    if (_isMock || db == null) {
      _mockSessions.removeWhere((element) => element['id'] == session.id);
      _mockSessions.add(session.toMap());
      return 1;
    }
    try {
      return await db.insert(
        'sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      _isMock = true;
      return await insertSession(session);
    }
  }

  Future<List<SessionModel>> getSessionsForUser(String userId) async {
    final db = await database;
    if (_isMock || db == null) {
      final filtered = _mockSessions.where((s) => s['user_id'] == userId).toList();
      filtered.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return filtered.map((map) => SessionModel.fromMap(map)).toList();
    }
    try {
      final maps = await db.query(
        'sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
      return maps.map((map) => SessionModel.fromMap(map)).toList();
    } catch (_) {
      _isMock = true;
      return getSessionsForUser(userId);
    }
  }

  Future<List<SessionModel>> getAllSessions() async {
    final db = await database;
    if (_isMock || db == null) {
      final sorted = List<Map<String, dynamic>>.from(_mockSessions);
      sorted.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return sorted.map((map) => SessionModel.fromMap(map)).toList();
    }
    try {
      final maps = await db.query('sessions', orderBy: 'date DESC');
      return maps.map((map) => SessionModel.fromMap(map)).toList();
    } catch (_) {
      _isMock = true;
      return getAllSessions();
    }
  }

  Future<void> close() async {
    if (_isMock) return;
    try {
      final db = await database;
      db?.close();
    } catch (_) {}
  }

  // ── Active Session CRUD ────────────────────────────────────────────────────
  Future<void> saveActiveSession(String userId, String startTime, int stepCount) async {
    final db = await database;
    if (_isMock || db == null) {
      _mockActiveSession.clear();
      _mockActiveSession.add({
        'user_id': userId,
        'start_time': startTime,
        'step_count': stepCount,
      });
      return;
    }
    try {
      await db.delete('active_session');
      await db.insert('active_session', {
        'user_id': userId,
        'start_time': startTime,
        'step_count': stepCount,
      });
    } catch (_) {
      _isMock = true;
      await saveActiveSession(userId, startTime, stepCount);
    }
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final db = await database;
    if (_isMock || db == null) {
      return _mockActiveSession.isNotEmpty ? _mockActiveSession.first : null;
    }
    try {
      final results = await db.query('active_session');
      return results.isNotEmpty ? results.first : null;
    } catch (_) {
      _isMock = true;
      return getActiveSession();
    }
  }

  Future<void> clearActiveSession() async {
    final db = await database;
    if (_isMock || db == null) {
      _mockActiveSession.clear();
      return;
    }
    try {
      await db.delete('active_session');
    } catch (_) {
      _isMock = true;
      await clearActiveSession();
    }
  }

  void _seedMockData() {
    _mockUsers.addAll([
      {
        'id': 'PT-JOHN-DOE-001',
        'name': 'John Doe',
        'age': 68,
        'date_added': '2026-05-15',
      },
      {
        'id': 'PT-JANE-SMITH-002',
        'name': 'Jane Smith',
        'age': 45,
        'date_added': '2026-05-20',
      },
      {
        'id': 'PT-ROBERT-CHEN-003',
        'name': 'Robert Chen',
        'age': 72,
        'date_added': '2026-06-01',
      },
    ]);

    final rawWf1 = List.generate(40, (i) => 1.2 * (i % 8 - 4).abs() / 4.0 + 0.2);
    final rawWf2 = List.generate(40, (i) => 1.4 * (i % 7 - 3.5).abs() / 3.5 + 0.1);
    final rawWf3 = List.generate(40, (i) => 1.5 * (i % 6 - 3).abs() / 3.0 + 0.3);

    _mockSessions.addAll([
      // John Doe Sessions
      {
        'id': 'SESS-JOHN-001',
        'user_id': 'PT-JOHN-DOE-001',
        'date': '2026-05-15',
        'duration': '02:15',
        'label': 'Compensatory Gait',
        'score': 68,
        'stride_length': 0.85,
        'cadence': 88,
        'balance': 35,
        'symmetry': 62,
        'stance_phase': 0.72,
        'swing_phase': 0.28,
        'double_support': 0.36,
        'notes': 'Baseline evaluation after hospital discharge. Exhibits pronounced left foot drop and hemiparetic circumduction pattern.',
        'raw_waveform': jsonEncode(rawWf1),
        'slm_interpretation': 'Gait pattern shows high asymmetry. Significant weight-bearing compensation on the unaffected right limb (35% left vs 65% right balance). Recommending intensive ankle-foot orthosis stabilization.',
      },
      {
        'id': 'SESS-JOHN-002',
        'user_id': 'PT-JOHN-DOE-001',
        'date': '2026-05-28',
        'duration': '03:00',
        'label': 'Compensatory Gait',
        'score': 76,
        'stride_length': 0.98,
        'cadence': 94,
        'balance': 42,
        'symmetry': 75,
        'stance_phase': 0.66,
        'swing_phase': 0.34,
        'double_support': 0.28,
        'notes': 'Second checkup after two weeks of targeted gait training and calf muscle stimulation.',
        'raw_waveform': jsonEncode(rawWf2),
        'slm_interpretation': 'Symmetry has improved from 62% to 75%. Left limb loading increased to 42%. Stance-to-swing cycle showing signs of muscular normalization. Continue plantarflexion exercises.',
      },
      {
        'id': 'SESS-JOHN-003',
        'user_id': 'PT-JOHN-DOE-001',
        'date': '2026-06-08',
        'duration': '02:45',
        'label': 'Symmetric Walk',
        'score': 87,
        'stride_length': 1.10,
        'cadence': 102,
        'balance': 48,
        'symmetry': 89,
        'stance_phase': 0.60,
        'swing_phase': 0.40,
        'double_support': 0.20,
        'notes': 'Follow-up evaluation. Walk is visibly more fluent and balanced. Patient reported feeling much more stable.',
        'raw_waveform': jsonEncode(rawWf3),
        'slm_interpretation': 'Excellent progress. Gait symmetry is near normal at 89%. Stance phase duration (60%) matches healthy joint loading baselines. Patient is safe to transition to home-based exercise routine.',
      },
      // Jane Smith Sessions
      {
        'id': 'SESS-JANE-001',
        'user_id': 'PT-JANE-SMITH-002',
        'date': '2026-05-20',
        'duration': '01:30',
        'label': 'Compensatory Gait',
        'score': 71,
        'stride_length': 0.95,
        'cadence': 90,
        'balance': 41,
        'symmetry': 70,
        'stance_phase': 0.68,
        'swing_phase': 0.32,
        'double_support': 0.30,
        'notes': 'Three weeks post right total knee arthroplasty. Hesitancy in loading the right knee during terminal stance.',
        'raw_waveform': jsonEncode(rawWf1),
        'slm_interpretation': 'Gait is significantly asymmetrical (70% symmetry) due to knee joint pain avoidance (antalgic pattern). Patient is offloading the right knee (41% balance load on right). Recommend range of motion optimization.',
      },
      {
        'id': 'SESS-JANE-002',
        'user_id': 'PT-JANE-SMITH-002',
        'date': '2026-06-05',
        'duration': '02:00',
        'label': 'Symmetric Walk',
        'score': 83,
        'stride_length': 1.08,
        'cadence': 98,
        'balance': 47,
        'symmetry': 84,
        'stance_phase': 0.62,
        'swing_phase': 0.38,
        'double_support': 0.22,
        'notes': 'Recent clinical assessment. Decreased pain score and increased knee extension extension during swing.',
        'raw_waveform': jsonEncode(rawWf2),
        'slm_interpretation': 'Joint loading is close to symmetric (84% symmetry). Weight distribution has balanced to 47% on the right limb. Extension during swing phase is normal. Continue active flexion training.',
      },
      // Robert Chen Sessions
      {
        'id': 'SESS-ROBERT-001',
        'user_id': 'PT-ROBERT-CHEN-003',
        'date': '2026-06-01',
        'duration': '03:30',
        'label': 'Compensatory Gait',
        'score': 64,
        'stride_length': 0.78,
        'cadence': 82,
        'balance': 45,
        'symmetry': 72,
        'stance_phase': 0.70,
        'swing_phase': 0.30,
        'double_support': 0.38,
        'notes': 'Initial diagnostic walk. Demonstrates short, shuffling steps and high double-support duration (38%), highlighting caution and balance instability.',
        'raw_waveform': jsonEncode(rawWf3),
        'slm_interpretation': 'Gait score (64) indicates moderate fall risk. Short stride length (0.78m) and high double support time (38%) are compensatory mechanisms for balance instability. Recommend balance board training and assistive device evaluation.',
      },
    ]);
  }

  Future<void> _seedDatabaseDataIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    if (count != null && count > 0) {
      return;
    }

    final rawWf1 = List.generate(40, (i) => 1.2 * (i % 8 - 4).abs() / 4.0 + 0.2);
    final rawWf2 = List.generate(40, (i) => 1.4 * (i % 7 - 3.5).abs() / 3.5 + 0.1);
    final rawWf3 = List.generate(40, (i) => 1.5 * (i % 6 - 3).abs() / 3.0 + 0.3);

    // Insert Users
    await db.insert('users', {
      'id': 'PT-JOHN-DOE-001',
      'name': 'John Doe',
      'age': 68,
      'date_added': '2026-05-15',
    });
    await db.insert('users', {
      'id': 'PT-JANE-SMITH-002',
      'name': 'Jane Smith',
      'age': 45,
      'date_added': '2026-05-20',
    });
    await db.insert('users', {
      'id': 'PT-ROBERT-CHEN-003',
      'name': 'Robert Chen',
      'age': 72,
      'date_added': '2026-06-01',
    });

    // Insert Sessions
    final sessions = [
      // John Doe Sessions
      {
        'id': 'SESS-JOHN-001',
        'user_id': 'PT-JOHN-DOE-001',
        'date': '2026-05-15',
        'duration': '02:15',
        'label': 'Compensatory Gait',
        'score': 68,
        'stride_length': 0.85,
        'cadence': 88,
        'balance': 35,
        'symmetry': 62,
        'stance_phase': 0.72,
        'swing_phase': 0.28,
        'double_support': 0.36,
        'notes': 'Baseline evaluation after hospital discharge. Exhibits pronounced left foot drop and hemiparetic circumduction pattern.',
        'raw_waveform': jsonEncode(rawWf1),
        'slm_interpretation': 'Gait pattern shows high asymmetry. Significant weight-bearing compensation on the unaffected right limb (35% left vs 65% right balance). Recommending intensive ankle-foot orthosis stabilization.',
      },
      {
        'id': 'SESS-JOHN-002',
        'user_id': 'PT-JOHN-DOE-001',
        'date': '2026-05-28',
        'duration': '03:00',
        'label': 'Compensatory Gait',
        'score': 76,
        'stride_length': 0.98,
        'cadence': 94,
        'balance': 42,
        'symmetry': 75,
        'stance_phase': 0.66,
        'swing_phase': 0.34,
        'double_support': 0.28,
        'notes': 'Second checkup after two weeks of targeted gait training and calf muscle stimulation.',
        'raw_waveform': jsonEncode(rawWf2),
        'slm_interpretation': 'Symmetry has improved from 62% to 75%. Left limb loading increased to 42%. Stance-to-swing cycle showing signs of muscular normalization. Continue plantarflexion exercises.',
      },
      {
        'id': 'SESS-JOHN-003',
        'user_id': 'PT-JOHN-DOE-001',
        'date': '2026-06-08',
        'duration': '02:45',
        'label': 'Symmetric Walk',
        'score': 87,
        'stride_length': 1.10,
        'cadence': 102,
        'balance': 48,
        'symmetry': 89,
        'stance_phase': 0.60,
        'swing_phase': 0.40,
        'double_support': 0.20,
        'notes': 'Follow-up evaluation. Walk is visibly more fluent and balanced. Patient reported feeling much more stable.',
        'raw_waveform': jsonEncode(rawWf3),
        'slm_interpretation': 'Excellent progress. Gait symmetry is near normal at 89%. Stance phase duration (60%) matches healthy joint loading baselines. Patient is safe to transition to home-based exercise routine.',
      },
      // Jane Smith Sessions
      {
        'id': 'SESS-JANE-001',
        'user_id': 'PT-JANE-SMITH-002',
        'date': '2026-05-20',
        'duration': '01:30',
        'label': 'Compensatory Gait',
        'score': 71,
        'stride_length': 0.95,
        'cadence': 90,
        'balance': 41,
        'symmetry': 70,
        'stance_phase': 0.68,
        'swing_phase': 0.32,
        'double_support': 0.30,
        'notes': 'Three weeks post right total knee arthroplasty. Hesitancy in loading the right knee during terminal stance.',
        'raw_waveform': jsonEncode(rawWf1),
        'slm_interpretation': 'Gait is significantly asymmetrical (70% symmetry) due to knee joint pain avoidance (antalgic pattern). Patient is offloading the right knee (41% balance load on right). Recommend range of motion optimization.',
      },
      {
        'id': 'SESS-JANE-002',
        'user_id': 'PT-JANE-SMITH-002',
        'date': '2026-06-05',
        'duration': '02:00',
        'label': 'Symmetric Walk',
        'score': 83,
        'stride_length': 1.08,
        'cadence': 98,
        'balance': 47,
        'symmetry': 84,
        'stance_phase': 0.62,
        'swing_phase': 0.38,
        'double_support': 0.22,
        'notes': 'Recent clinical assessment. Decreased pain score and increased knee extension extension during swing.',
        'raw_waveform': jsonEncode(rawWf2),
        'slm_interpretation': 'Joint loading is close to symmetric (84% symmetry). Weight distribution has balanced to 47% on the right limb. Extension during swing phase is normal. Continue active flexion training.',
      },
      // Robert Chen Sessions
      {
        'id': 'SESS-ROBERT-001',
        'user_id': 'PT-ROBERT-CHEN-003',
        'date': '2026-06-01',
        'duration': '03:30',
        'label': 'Compensatory Gait',
        'score': 64,
        'stride_length': 0.78,
        'cadence': 82,
        'balance': 45,
        'symmetry': 72,
        'stance_phase': 0.70,
        'swing_phase': 0.30,
        'double_support': 0.38,
        'notes': 'Initial diagnostic walk. Demonstrates short, shuffling steps and high double-support duration (38%), highlighting caution and balance instability.',
        'raw_waveform': jsonEncode(rawWf3),
        'slm_interpretation': 'Gait score (64) indicates moderate fall risk. Short stride length (0.78m) and high double support time (38%) are compensatory mechanisms for balance instability. Recommend balance board training and assistive device evaluation.',
      },
    ];

    for (final s in sessions) {
      await db.insert('sessions', s);
    }
  }
}