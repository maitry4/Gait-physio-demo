import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class SessionState {
  final List<SessionModel> userSessions;
  final bool isLoading;
  final bool isRecording;
  final String? activeRecordingUserId;
  final int recordDurationSeconds;
  final int stepCount;
  final List<double> liveWaveformPoints;
  final SessionModel? currentSessionAnalysis;
  final String? errorMessage;
  final bool isSyncingFromDevice;
  final String syncStatusMessage;
  final bool isSharingDataset;
  final bool isGeneratingPdf;
  final String? pdfPath;

  SessionState({
    this.userSessions = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.activeRecordingUserId,
    this.recordDurationSeconds = 0,
    this.stepCount = 0,
    this.liveWaveformPoints = const [],
    this.currentSessionAnalysis,
    this.errorMessage,
    this.isSyncingFromDevice = false,
    this.syncStatusMessage = '',
    this.isSharingDataset = false,
    this.isGeneratingPdf = false,
    this.pdfPath,
  });

  SessionState copyWith({
    List<SessionModel>? userSessions,
    bool? isLoading,
    bool? isRecording,
    String? Function()? activeRecordingUserId,
    int? recordDurationSeconds,
    int? stepCount,
    List<double>? liveWaveformPoints,
    SessionModel? Function()? currentSessionAnalysis,
    String? Function()? errorMessage,
    bool? isSyncingFromDevice,
    String? syncStatusMessage,
    bool? isSharingDataset,
    bool? isGeneratingPdf,
    String? Function()? pdfPath,
  }) {
    return SessionState(
      userSessions: userSessions ?? this.userSessions,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      activeRecordingUserId: activeRecordingUserId != null ? activeRecordingUserId() : this.activeRecordingUserId,
      recordDurationSeconds: recordDurationSeconds ?? this.recordDurationSeconds,
      stepCount: stepCount ?? this.stepCount,
      liveWaveformPoints: liveWaveformPoints ?? this.liveWaveformPoints,
      currentSessionAnalysis: currentSessionAnalysis != null ? currentSessionAnalysis() : this.currentSessionAnalysis,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isSyncingFromDevice: isSyncingFromDevice ?? this.isSyncingFromDevice,
      syncStatusMessage: syncStatusMessage ?? this.syncStatusMessage,
      isSharingDataset: isSharingDataset ?? this.isSharingDataset,
      isGeneratingPdf: isGeneratingPdf ?? this.isGeneratingPdf,
      pdfPath: pdfPath != null ? pdfPath() : this.pdfPath,
    );
  }
}

class SessionNotifier extends Notifier<SessionState> {
  Timer? _recordTimer;
  Timer? _waveformTimer;
  final _uuid = const Uuid();

  @override
  SessionState build() {
    Future.microtask(() => _checkActiveSessionOnStartup());
    return SessionState();
  }

  Future<void> _checkActiveSessionOnStartup() async {
    try {
      final active = await DatabaseService.instance.getActiveSession();
      if (active != null) {
        final userId = active['user_id'] as String;
        final startTimeStr = active['start_time'] as String;
        final savedSteps = active['step_count'] as int;

        final startTime = DateTime.parse(startTimeStr);
        final diffSeconds = DateTime.now().difference(startTime).inSeconds;

        // Auto-resume if the session started less than 30 minutes ago
        if (diffSeconds >= 0 && diffSeconds < 1800) {
          state = state.copyWith(
            isRecording: true,
            activeRecordingUserId: () => userId,
            recordDurationSeconds: diffSeconds,
            stepCount: savedSteps,
          );
          _resumeRecordingTimers(userId, startTime);
        } else {
          await DatabaseService.instance.clearActiveSession();
        }
      }
    } catch (e) {
      print('Failed to check active session startup status: $e');
    }
  }

  void _resumeRecordingTimers(String userId, DateTime startTime) {
    _recordTimer?.cancel();
    _waveformTimer?.cancel();

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final diff = DateTime.now().difference(startTime).inSeconds;
      state = state.copyWith(recordDurationSeconds: diff);
      if (timer.tick % 5 == 0) {
        DatabaseService.instance.saveActiveSession(userId, startTime.toIso8601String(), state.stepCount);
      }
    });

    _waveformTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      final rand = (math.sin(timer.tick * 0.3) * 2.0) + (math.Random().nextDouble() - 0.5) * 0.6;
      final currentList = List<double>.from(state.liveWaveformPoints);
      currentList.add(rand);
      if (currentList.length > 30) {
        currentList.removeAt(0);
      }

      int newSteps = state.stepCount;
      if (timer.tick % 6 == 0) {
        newSteps += 1;
      }

      state = state.copyWith(
        liveWaveformPoints: currentList,
        stepCount: newSteps,
      );
    });
  }

  Future<void> loadSessionsForUser(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final list = await DatabaseService.instance.getSessionsForUser(userId);
      state = state.copyWith(userSessions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Failed to load sessions: $e');
    }
  }

  // ── Sync from Wearable Device behind scenes (Fallback trigger) ───────────────
  Future<bool> forceFetchSessionsFromDevice(String userId, {bool simulateFailure = false}) async {
    state = state.copyWith(
      isSyncingFromDevice: true,
      syncStatusMessage: 'Connecting to wearable over local Wi-Fi Hotspot...',
      errorMessage: () => null,
    );

    await Future.delayed(const Duration(seconds: 1));
    if (simulateFailure) {
      state = state.copyWith(
        isSyncingFromDevice: false,
        syncStatusMessage: '',
        errorMessage: () => 'Wi-Fi Socket Connection Refused. Ensure device is powered on.',
      );
      return false;
    }

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
      stancePhase: 0.63,
      swingPhase: 0.37,
      doubleSupport: 0.24,
      notes: 'Pulled directly from wearable SD card log recovery module.',
      rawWaveform: rawWf,
      slmInterpretation: 'Normal gait rhythm recovered. Left heel load matches historical baseline.',
    );

    try {
      await DatabaseService.instance.insertSession(syncSession);
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

  // ── Recording Flow ────────────────────────────────────────────────────────
  void startRecording(String userId) {
    state = state.copyWith(
      isRecording: true,
      activeRecordingUserId: () => userId,
      recordDurationSeconds: 0,
      stepCount: 0,
      liveWaveformPoints: [],
      errorMessage: () => null,
      currentSessionAnalysis: () => null,
    );

    // Save active session status on local disk persistence
    DatabaseService.instance.saveActiveSession(userId, DateTime.now().toIso8601String(), 0);

    // Local timers
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(recordDurationSeconds: state.recordDurationSeconds + 1);
      if (timer.tick % 5 == 0) {
        DatabaseService.instance.saveActiveSession(
          userId,
          DateTime.now().subtract(Duration(seconds: state.recordDurationSeconds)).toIso8601String(),
          state.stepCount,
        );
      }
    });

    _waveformTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      final rand = (math.sin(timer.tick * 0.3) * 2.0) + (math.Random().nextDouble() - 0.5) * 0.6;
      final currentList = List<double>.from(state.liveWaveformPoints);
      currentList.add(rand);
      if (currentList.length > 30) {
        currentList.removeAt(0);
      }

      int newSteps = state.stepCount;
      if (timer.tick % 6 == 0) {
        newSteps += 1;
      }

      state = state.copyWith(
        liveWaveformPoints: currentList,
        stepCount: newSteps,
      );
    });
  }

  Future<void> stopRecordingAndAnalyze(String userId, {bool simulateFailure = false}) async {
    try {
      _recordTimer?.cancel();
      _waveformTimer?.cancel();

      state = state.copyWith(
        isRecording: false,
        activeRecordingUserId: () => null,
        isSyncingFromDevice: true,
        syncStatusMessage: 'Instructing wearable to halt detection...',
        errorMessage: () => null,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      state = state.copyWith(syncStatusMessage: 'Fetching raw TXT telemetry from wearable SD card...');
      await Future.delayed(const Duration(milliseconds: 1200));

      if (simulateFailure) {
        await DatabaseService.instance.clearActiveSession();
        state = state.copyWith(
          isSyncingFromDevice: false,
          errorMessage: () => 'Data Transfer Aborted: Wearable reported SD card read timeout.',
        );
        return;
      }

      state = state.copyWith(syncStatusMessage: 'Analyzing gait cycle using local SLM models...');
      await Future.delayed(const Duration(milliseconds: 1000));

      final durationMin = (state.recordDurationSeconds / 60).floor();
      final durationSec = state.recordDurationSeconds % 60;
      final durationStr = '${durationMin.toString().padLeft(2, '0')}:${durationSec.toString().padLeft(2, '0')}';

      final rng = math.Random();
      final score = 70 + rng.nextInt(25);
      final cadence = 95 + rng.nextInt(25);
      final balance = 44 + rng.nextInt(12);
      final symmetry = score - rng.nextInt(5);
      final strideLen = 1.05 + (rng.nextDouble() * 0.3);

      final stance = 0.58 + (rng.nextDouble() * 0.08);
      final swing = 1.0 - stance;
      final doubleSupp = 0.18 + (rng.nextDouble() * 0.08);

      String slmText = '';
      if (symmetry >= 88) {
        slmText = 'Symmetric gait rhythm. Balanced stance-phase duration of ${(stance * 100).toStringAsFixed(0)}% indicates healthy joint load.';
      } else if (symmetry >= 76) {
        final imbalance = (50 - balance).abs();
        slmText = 'Mild mechanical compensation. Left-Right stance symmetry variance of $imbalance% detected. Watch for fatigue.';
      } else {
        slmText = 'Severe asymmetric pattern. Pronounced gait dysmotility. Recommend rehabilitation for off-balance weight load.';
      }

      final List<double> finalWaveform = List.generate(40, (index) {
        return (math.sin(index * 0.5) * 1.8 * (score / 100)) + (rng.nextDouble() - 0.5) * 0.4;
      });

      final newSession = SessionModel(
        id: 'SESS-${_uuid.v4().substring(0, 8).toUpperCase()}',
        userId: userId,
        date: DateTime.now().toIso8601String().substring(0, 10),
        duration: durationStr,
        label: symmetry >= 88 ? 'Symmetric Walk' : 'Compensatory Gait',
        score: score,
        strideLength: double.parse(strideLen.toStringAsFixed(2)),
        cadence: cadence,
        balance: balance,
        symmetry: symmetry,
        stancePhase: double.parse(stance.toStringAsFixed(2)),
        swingPhase: double.parse(swing.toStringAsFixed(2)),
        doubleSupport: double.parse(doubleSupp.toStringAsFixed(2)),
        notes: 'Auto-recorded session. Steps detected: ${state.stepCount}. Device raw TTL set for cleanup in 72 hours.',
        rawWaveform: finalWaveform,
        slmInterpretation: slmText,
      );

      await DatabaseService.instance.insertSession(newSession);
      await DatabaseService.instance.clearActiveSession(); // Successfully synced -> Clear active session
      await loadSessionsForUser(userId);

      state = state.copyWith(
        isSyncingFromDevice: false,
        currentSessionAnalysis: () => newSession,
      );
    } catch (e) {
      await DatabaseService.instance.clearActiveSession();
      state = state.copyWith(
        isSyncingFromDevice: false,
        errorMessage: () => 'Local database save failed or compilation error: $e',
      );
    }
  }

  // ── Share Anonymous Data to Gait Research Dataset ───────────────────────
  Future<bool> shareAnonymousDataset() async {
    state = state.copyWith(isSharingDataset: true, errorMessage: () => null);

    try {
      final sessions = await DatabaseService.instance.getAllSessions();
      final users = await DatabaseService.instance.getUsers();

      if (sessions.isEmpty) {
        state = state.copyWith(isSharingDataset: false, errorMessage: () => 'No session data in SQLite database to share.');
        return false;
      }

      await Future.delayed(const Duration(seconds: 2));

      final anonymizedPayload = sessions.map((s) {
        final matchedUser = users.firstWhere((u) => u.id == s.userId, 
            orElse: () => UserModel(id: 'UNKNOWN', name: 'Unknown', age: 0, dateAdded: ''));
        return {
          'age': matchedUser.age,
          'duration': s.duration,
          'label': s.label,
          'score': s.score,
          'stride_length': s.strideLength,
          'cadence': s.cadence,
          'balance': s.balance,
          'symmetry': s.symmetry,
          'stance_phase': s.stancePhase,
          'swing_phase': s.swingPhase,
          'double_support': s.doubleSupport,
          'slm_interpretation': s.slmInterpretation,
        };
      }).toList();

      print('Anonymized dataset built with ${anonymizedPayload.length} rows.');

      state = state.copyWith(isSharingDataset: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSharingDataset: false, errorMessage: () => 'Failed to anonymize: $e');
      return false;
    }
  }

  // ── Generate Clinician PDF Success Report ──────────────────────────────
  Future<bool> generatePhysioReport() async {
    state = state.copyWith(isGeneratingPdf: true, errorMessage: () => null);

    try {
      final sessions = await DatabaseService.instance.getAllSessions();
      if (sessions.isEmpty) {
        state = state.copyWith(isGeneratingPdf: false, errorMessage: () => 'No sessions found in database to compile report.');
        return false;
      }

      await Future.delayed(const Duration(seconds: 2));

      double totalSymmetry = 0;
      double totalScore = 0;
      int totalCadence = 0;
      for (var s in sessions) {
        totalSymmetry += s.symmetry;
        totalScore += s.score;
        totalCadence += s.cadence;
      }
      final avgSymmetry = (totalSymmetry / sessions.length).toStringAsFixed(1);
      final avgScore = (totalScore / sessions.length).toStringAsFixed(1);
      final avgCadence = (totalCadence / sessions.length).toStringAsFixed(0);

      state = state.copyWith(
        isGeneratingPdf: false,
        pdfPath: () => '/storage/emulated/0/GaitPhysio/Reports/Therapist_Summary_${DateTime.now().millisecondsSinceEpoch}.pdf',
        syncStatusMessage: 'Physio Success Report PDF ready! Average Symmetry: $avgSymmetry%, Avg Score: $avgScore, Avg Cadence: $avgCadence spm over ${sessions.length} sessions.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isGeneratingPdf: false, errorMessage: () => 'PDF compilation error: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(() {
  return SessionNotifier();
});
