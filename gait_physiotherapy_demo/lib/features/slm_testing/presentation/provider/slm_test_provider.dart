import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gait_physiotherapy_demo/core/services/native_service.dart';

import 'package:gait_physiotherapy_demo/core/services/sqlite_service.dart';
import 'package:gait_physiotherapy_demo/core/services/slm_service.dart';
// import 'package:gait_physiotherapy_demo/features/slm_testing/data/native_stats_service.dart';
import 'package:gait_physiotherapy_demo/features/slm_testing/domain/result_testing.dart';

/// State for the SLM Benchmark screen. The screen only ever reads
/// this — all logic lives in [SlmTestNotifier] below.
class SlmTestState {
  final List<SlmModel> models;
  final SlmModel? selectedModel;
  final SlmTestType testType;
  final bool isLoadingModels;
  final bool isRunning;
  final String? error;
  final List<BenchmarkResult> results;

  const SlmTestState({
    this.models = const [],
    this.selectedModel,
    this.testType = SlmTestType.singleSession,
    this.isLoadingModels = false,
    this.isRunning = false,
    this.error,
    this.results = const [],
  });

  SlmTestState copyWith({
    List<SlmModel>? models,
    SlmModel? selectedModel,
    SlmTestType? testType,
    bool? isLoadingModels,
    bool? isRunning,
    String? error,
    bool clearError = false,
    List<BenchmarkResult>? results,
  }) {
    return SlmTestState(
      models: models ?? this.models,
      selectedModel: selectedModel ?? this.selectedModel,
      testType: testType ?? this.testType,
      isLoadingModels: isLoadingModels ?? this.isLoadingModels,
      isRunning: isRunning ?? this.isRunning,
      error: clearError ? null : (error ?? this.error),
      results: results ?? this.results,
    );
  }
}

final slmTestProvider =
    StateNotifierProvider<SlmTestNotifier, SlmTestState>((ref) {
  return SlmTestNotifier()..loadModels();
});

class SlmTestNotifier extends StateNotifier<SlmTestState> {
  SlmTestNotifier() : super(const SlmTestState());

  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Loads the model catalogue from `features/slm_testing/data/models.json`.
  Future<void> loadModels() async {
    state = state.copyWith(isLoadingModels: true, clearError: true);
    try {
      final raw = await rootBundle.loadString(
        'lib/features/slm_testing/data/models.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['models'] as List)
          .map((e) => SlmModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        models: list,
        selectedModel: list.isNotEmpty ? list.first : null,
        isLoadingModels: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingModels: false,
        error: 'Failed to load models.json: $e',
      );
    }
  }

  void selectModel(SlmModel model) {
    state = state.copyWith(selectedModel: model);
  }

  void selectTestType(SlmTestType type) {
    state = state.copyWith(testType: type);
  }

  /// Runs a single benchmark pass for the currently selected model
  /// and test type, and appends the result to [state.results].
  Future<void> runBenchmark() async {
    final model = state.selectedModel;
    if (model == null || state.isRunning) return;

    state = state.copyWith(isRunning: true, clearError: true);

    try {
      // --- 1. Build the deterministic prompt from the local DB ---------
      final prompt = await _buildPrompt(state.testType);

      // --- 2. Device + battery context, captured before generation -----
      final phoneModel = await _getPhoneModel();
      final androidVersion = await _getAndroidVersion();
      final batteryBefore = await _battery.batteryLevel;

      // --- 3. Run inference, timing latency (time-to-first-token) ------
      //        and total execution time with a single Stopwatch.
      //
      // NOTE: This assumes `SLMService` exposes a streaming generation
      // method of the shape:
      //   Stream<String> generateStream({required String modelId, required String prompt})
      // Adjust this call site to match your actual SLMService API if it
      // differs (e.g. rename to the real method/parameter names).
      final stopwatch = Stopwatch()..start();
      int latencyMs = 0;
      final buffer = StringBuffer();
      bool firstTokenSeen = false;

      await for (final chunk in SLMService.generateStream(
        modelId: model.id,
        prompt: prompt,
      )) {
        if (!firstTokenSeen) {
          firstTokenSeen = true;
          latencyMs = stopwatch.elapsedMilliseconds;
        }
        buffer.write(chunk);
      }
      stopwatch.stop();
      final executionTimeMs = stopwatch.elapsedMilliseconds;
      if (!firstTokenSeen) {
        // No streaming happened (e.g. single-shot response) - latency
        // and execution time collapse to the same value.
        latencyMs = executionTimeMs;
      }

      // --- 4. Sample RAM/CPU right after generation finishes ------------
      final ramUsageMB = await NativeStatsService.getMemoryUsageMB();
      final cpuUsagePercent = await NativeStatsService.getCpuUsagePercent();

      // --- 5. Battery after, and derived drop ---------------------------
      final batteryAfter = await _battery.batteryLevel;
      final batteryDrop = (batteryBefore - batteryAfter).clamp(0, 100);

      final result = BenchmarkResult(
        phoneModel: phoneModel,
        androidVersion: androidVersion,
        modelName: model.name,
        testType: state.testType.label,
        latencyMs: latencyMs,
        executionTimeMs: executionTimeMs,
        ramUsageMB: ramUsageMB,
        cpuUsagePercent: cpuUsagePercent,
        batteryBefore: batteryBefore,
        batteryAfter: batteryAfter,
        batteryDrop: batteryDrop,
        output: buffer.toString(),
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        isRunning: false,
        results: [result, ...state.results],
      );
    } catch (e) {
      state = state.copyWith(isRunning: false, error: 'Benchmark failed: $e');
    }
  }

  /// Builds a deterministic prompt straight from the local SQLite DB so
  /// that the same DB + same query + same prompt is used across every
  /// phone/model combination.
  Future<String> _buildPrompt(SlmTestType type) async {
    final db = await SQLiteService.database;

    if (type == SlmTestType.singleSession) {
      final rows = await db.query('sessions', orderBy: 'id ASC', limit: 1);
      if (rows.isEmpty) {
        throw Exception('No sessions found in the database.');
      }
      final s = rows.first;
      return 'Given the following single gait session metrics: '
          'Leg: ${s['leg']}, Steps counted: ${s['steps_counted']}, '
          'Average cadence: ${s['avg_cadence']} steps/min, '
          'Movement smoothness (SPARC): ${s['movement_smoothness_sparc']}, '
          'Stance %: ${s['stance_pct']}, Swing %: ${s['swing_pct']}, '
          'Average step time: ${s['avg_step_time']} s, '
          'Average gait speed: ${s['avg_gait_speed']} m/s. '
          'Provide a concise 2-sentence clinical summary for a physiotherapist.';
    } else {
      final patientRows = await db.query(
        'patients',
        orderBy: 'id ASC',
        limit: 1,
      );
      if (patientRows.isEmpty) {
        throw Exception('No patients found in the database.');
      }
      final patientId = patientRows.first['id'] as String;
      final insights = await SQLiteService.getPatientInsights(patientId);

      return 'Given the following aggregated gait metrics across '
          '${insights['total_sessions']} sessions: '
          'Average cadence: ${insights['avg_cadence']} steps/min, '
          'Average gait speed: ${insights['avg_gait_speed']} m/s, '
          'Average stride length: ${insights['avg_stride_length']} m, '
          'Average stance %: ${insights['avg_stance_pct']}, '
          'Average swing %: ${insights['avg_swing_pct']}, '
          'Average SPARC: ${insights['avg_sparc']}, '
          'Gait symmetry: ${insights['symmetry']}%. '
          'Provide a concise 2-sentence clinical summary for a physiotherapist '
          'covering overall progress and any asymmetry concerns.';
    }
  }

  Future<String> _getPhoneModel() async {
    if (!Platform.isAndroid) return 'Unknown device';
    try {
      final info = await _deviceInfo.androidInfo;
      return '${info.manufacturer} ${info.model}';
    } catch (_) {
      return 'Unknown device';
    }
  }

  Future<String> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 'Unknown';
    try {
      final info = await _deviceInfo.androidInfo;
      return 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
    } catch (_) {
      return 'Unknown';
    }
  }
}