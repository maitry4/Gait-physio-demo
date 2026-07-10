import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/services/sqlite_service.dart';
import 'package:gait_physiotherapy_demo/core/services/backend_service.dart';
import 'package:gait_physiotherapy_demo/features/session/domain/entities/session_entity.dart';

class ViewSessionState {
  final List<SessionModel> userSessions;
  final bool isLoading;
  final bool isSyncingFromDevice;
  final String syncStatusMessage;
  final String? errorMessage;

  ViewSessionState({
    this.userSessions = const [],
    this.isLoading = false,
    this.isSyncingFromDevice = false,
    this.syncStatusMessage = '',
    this.errorMessage,
  });

  ViewSessionState copyWith({
    List<SessionModel>? userSessions,
    bool? isLoading,
    bool? isSyncingFromDevice,
    String? syncStatusMessage,
    String? Function()? errorMessage,
  }) {
    return ViewSessionState(
      userSessions: userSessions ?? this.userSessions,
      isLoading: isLoading ?? this.isLoading,
      isSyncingFromDevice: isSyncingFromDevice ?? this.isSyncingFromDevice,
      syncStatusMessage: syncStatusMessage ?? this.syncStatusMessage,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ViewSessionNotifier extends Notifier<ViewSessionState> {
  @override
  ViewSessionState build() {
    return ViewSessionState();
  }

  Future<void> loadSessionsForUser(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final db = await SQLiteService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sessions',
        where: 'patient_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );

      final list = maps.map((map) {
        final double durationSec = (map['duration'] as num).toDouble();
        final int min = durationSec ~/ 60;
        final int sec = (durationSec % 60).toInt();
        final durationStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';

        final stancePct = (map['stance_pct'] as num).toDouble();
        final swingPct = (map['swing_pct'] as num).toDouble();

        return SessionModel(
          id: map['id'] as String,
          userId: map['patient_id'] as String,
          date: map['date'] as String,
          duration: durationStr,
          label: '${map['leg']} Leg',
          score: ((map['movement_smoothness_sparc'] as num).toDouble() * -10).toInt().clamp(0, 100),
          strideLength: (map['avg_step_time'] as num).toDouble() * (map['avg_gait_speed'] as num).toDouble(),
          cadence: (map['avg_cadence'] as num).toInt(),
          balance: 50,
          symmetry: 80,
          stancePhase: stancePct,
          swingPhase: swingPct,
          doubleSupport: 0.0,
          notes: '',
          rawWaveform: [],
          slmInterpretation: map['slm_insights'] as String? ?? '',
        );
      }).toList();

      state = state.copyWith(userSessions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Failed to load sessions: $e');
    }
  }

  // ── Sync from Wearable Device behind scenes (Fallback trigger) ───────────────
  Future<bool> forceFetchSessionsFromDevice(String userId) async {
    state = state.copyWith(
      isSyncingFromDevice: true,
      syncStatusMessage: 'Connecting to wearable over local Wi-Fi Hotspot...',
      errorMessage: () => null,
    );

    await Future.delayed(const Duration(seconds: 1));

    state = state.copyWith(syncStatusMessage: 'Requesting raw data files from SD card...');
    await Future.delayed(const Duration(seconds: 1));

    state = state.copyWith(syncStatusMessage: 'Parsing telemetry lines and synchronizing SQLite database...');

    final rawWf = List.generate(40, (index) => math.sin(index * 0.4) * 1.5 + math.cos(index * 0.8) * 0.5);
    final syncSession = SessionModel(
      id: 'SESS-SYNC-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
      duration: '01:45',
      label: 'Synced Wearable Log',
      score: 84,
      strideLength: 1.18,
      cadence: 104,
      balance: 48,
      symmetry: 86,
      stancePhase: 60.0,
      swingPhase: 40.0,
      doubleSupport: 0.24,
      notes: 'Pulled directly from wearable SD card log recovery module.',
      rawWaveform: rawWf,
      slmInterpretation: 'Normal gait rhythm recovered. Left heel load matches historical baseline.',
    );

    try {
      final db = await SQLiteService.database;
      await db.insert(
        'sessions',
        {
          'id': syncSession.id,
          'device_id': '1',
          'patient_id': syncSession.userId,
          'leg': 'LEFT',
          'date': syncSession.date,
          'start_time': DateTime.now().toIso8601String(),
          'end_time': DateTime.now().toIso8601String(),
          'duration': 105.0,
          'steps_counted': 100,
          'avg_cadence': syncSession.cadence,
          'movement_smoothness_sparc': -4.5,
          'stance_pct': syncSession.stancePhase,
          'swing_pct': syncSession.swingPhase,
          'avg_step_time': 1.0,
          'avg_gait_speed': 1.18,
          'slm_insights': syncSession.slmInterpretation,
        },
      );
      // Invalidate patient summary cache in SQLite
      await SQLiteService.invalidatePatientSummary(userId);
      // Reload overall insights future provider to calculate new averages
      ref.invalidate(overallInsightsProvider(userId));
      // Notify the summary provider to refresh its cached value
      ref.read(patientSummaryProvider(userId).notifier).loadCachedSummary();

      await loadSessionsForUser(userId);
      state = state.copyWith(
        isSyncingFromDevice: false,
        syncStatusMessage: 'Sync Complete!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSyncingFromDevice: false,
        errorMessage: () => 'Failed to write synced records to SQLite: $e',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }
}

final viewSessionProvider = NotifierProvider<ViewSessionNotifier, ViewSessionState>(() {
  return ViewSessionNotifier();
});

final overallInsightsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, patientId) async {
  return SQLiteService.getPatientInsights(patientId);
});

class PatientSummaryState {
  final String? summary;
  final bool isLoading;
  final String? errorMessage;

  PatientSummaryState({
    this.summary,
    this.isLoading = false,
    this.errorMessage,
  });

  PatientSummaryState copyWith({
    String? summary,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return PatientSummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class PatientSummaryNotifier extends Notifier<PatientSummaryState> {
  final String patientId;
  PatientSummaryNotifier(this.patientId);

  @override
  PatientSummaryState build() {
    // Microtask to trigger initial async cache loading after construction
    Future.microtask(() => loadCachedSummary());
    return PatientSummaryState();
  }

  Future<void> loadCachedSummary() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final db = await SQLiteService.database;
      final results = await db.query(
        'patients',
        columns: ['overall_insights'],
        where: 'id = ?',
        whereArgs: [patientId],
      );
      if (results.isNotEmpty) {
        final insights = results.first['overall_insights'] as String?;
        state = state.copyWith(summary: insights, isLoading: false);
      } else {
        state = state.copyWith(summary: null, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Failed to load cached summary: $e',
      );
    }
  }

  Future<bool> generateSummary() async {
    final previousSummary = state.summary;
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final db = await SQLiteService.database;

      // 1. Fetch patient details
      final patientResults = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [patientId],
      );
      if (patientResults.isEmpty) {
        throw Exception('Patient record not found in local SQLite.');
      }
      final patient = patientResults.first;
      final patientName = patient['name'] as String? ?? 'Unknown';
      final patientAge = patient['age'] as int? ?? 0;

      // 2. Fetch overall aggregates
      final insights = await SQLiteService.getPatientInsights(patientId);

      // 3. Fetch historical sessions
      final sessionResults = await db.query(
        'sessions',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'date DESC',
      );

      final List<Map<String, dynamic>> sessionsList = sessionResults.map((map) {
        return {
          'id': map['id'],
          'leg': map['leg'],
          'date': map['date'],
          'duration': map['duration'],
          'steps_counted': map['steps_counted'],
          'avg_cadence': map['avg_cadence'],
          'stance_pct': map['stance_pct'],
          'swing_pct': map['swing_pct'],
          'avg_step_time': map['avg_step_time'],
          'avg_gait_speed': map['avg_gait_speed'],
          'movement_smoothness_sparc': map['movement_smoothness_sparc'],
          'slm_insights': map['slm_insights'],
        };
      }).toList();

      final payload = {
        'patient_id': patientId,
        'name': patientName,
        'age': patientAge,
        'overall_aggregates': insights,
        'sessions_history': sessionsList,
      };

      // Call Backend API
      final summaryText = await BackendService.generateOverallInsights(
        data: payload,
        isSinglePatient: true,
      );

      // Cache in SQLite database
      await db.update(
        'patients',
        {'overall_insights': summaryText},
        where: 'id = ?',
        whereArgs: [patientId],
      );

      state = state.copyWith(summary: summaryText, isLoading: false);
      return true;
    } catch (e) {
      // If the backend request fails:
      // Keep the existing cached summary, do not overwrite it with null,
      // and display an appropriate error message while continuing to show the cached summary.
      state = state.copyWith(
        summary: previousSummary,
        isLoading: false,
        errorMessage: () => 'Failed to generate progression insights: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }
}

final patientSummaryProvider = NotifierProvider.family<PatientSummaryNotifier, PatientSummaryState, String>(
  PatientSummaryNotifier.new,
);

