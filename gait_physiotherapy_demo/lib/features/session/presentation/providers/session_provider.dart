import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:gait_physiotherapy_demo/core/database/database_service.dart';
import 'package:gait_physiotherapy_demo/core/services/sqlite_service.dart';
import 'package:gait_physiotherapy_demo/core/services/slm_service.dart';
import 'package:gait_physiotherapy_demo/features/session/domain/entities/session_entity.dart';
import 'package:gait_physiotherapy_demo/features/view_session/presentation/providers/view_session_provider.dart';

class SessionState {
  final bool isRecording;
  final String? activeRecordingUserId;
  final int recordDurationSeconds;
  final int stepCount;
  final List<double> liveWaveformPoints;
  final SessionModel? currentSessionAnalysis;
  final String? errorMessage;
  final bool isSyncingFromDevice;
  final String syncStatusMessage;

  SessionState({
    this.isRecording = false,
    this.activeRecordingUserId,
    this.recordDurationSeconds = 0,
    this.stepCount = 0,
    this.liveWaveformPoints = const [],
    this.currentSessionAnalysis,
    this.errorMessage,
    this.isSyncingFromDevice = false,
    this.syncStatusMessage = '',
  });

  SessionState copyWith({
    bool? isRecording,
    String? Function()? activeRecordingUserId,
    int? recordDurationSeconds,
    int? stepCount,
    List<double>? liveWaveformPoints,
    SessionModel? Function()? currentSessionAnalysis,
    String? Function()? errorMessage,
    bool? isSyncingFromDevice,
    String? syncStatusMessage,
  }) {
    return SessionState(
      isRecording: isRecording ?? this.isRecording,
      activeRecordingUserId: activeRecordingUserId != null ? activeRecordingUserId() : this.activeRecordingUserId,
      recordDurationSeconds: recordDurationSeconds ?? this.recordDurationSeconds,
      stepCount: stepCount ?? this.stepCount,
      liveWaveformPoints: liveWaveformPoints ?? this.liveWaveformPoints,
      currentSessionAnalysis: currentSessionAnalysis != null ? currentSessionAnalysis() : this.currentSessionAnalysis,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isSyncingFromDevice: isSyncingFromDevice ?? this.isSyncingFromDevice,
      syncStatusMessage: syncStatusMessage ?? this.syncStatusMessage,
    );
  }
}

class SessionNotifier extends Notifier<SessionState> {
  Timer? _recordTimer;
  Timer? _waveformTimer;
  final _uuid = const Uuid();
  final _slmService = SLMService();

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

  Future<void> stopRecordingAndAnalyze(String userId) async {
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

      final slmText = _slmService.interpret(
        symmetry: symmetry,
        score: score,
        stance: stance,
        balance: balance,
      );

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
      
      // Invalidate patient summary cache in SQLite when a new session is recorded
      await SQLiteService.invalidatePatientSummary(userId);
      // Invalidate overall insights to force recalculation of averages
      ref.invalidate(overallInsightsProvider(userId));
      // Refresh the patient summary state so the UI prompts to regenerate
      ref.read(patientSummaryProvider(userId).notifier).loadCachedSummary();

      await DatabaseService.instance.clearActiveSession(); // Successfully synced -> Clear active session
      await ref.read(viewSessionProvider.notifier).loadSessionsForUser(userId);

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

  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(() {
  return SessionNotifier();
});
