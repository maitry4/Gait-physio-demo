import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../models/session_model.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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
}
