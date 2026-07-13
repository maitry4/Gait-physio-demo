import 'package:flutter/services.dart';

/// Thin wrapper around the Android platform channel that exposes
/// approximate RAM and CPU usage for the current process.
///
/// See `MainActivity.kt` for the native implementation. Values are
/// approximate by design — good enough for relative comparisons
/// across devices/models, not lab-grade profiling.
class NativeStatsService {
  NativeStatsService._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.gait_physiotherapy_demo/system_stats',
  );

  /// Resident memory (PSS) used by this process, in MB.
  static Future<double> getMemoryUsageMB() async {
    try {
      final result = await _channel.invokeMethod<double>('getMemoryUsageMB');
      return result ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Approximate CPU usage of this process over a short sampling
  /// window, as a percentage of a single core (0-100 per core).
  static Future<double> getCpuUsagePercent() async {
    try {
      final result = await _channel.invokeMethod<double>('getCpuUsagePercent');
      return result ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}