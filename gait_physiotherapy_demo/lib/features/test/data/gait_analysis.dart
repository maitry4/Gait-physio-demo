// gait_analysis.dart
// Pure-Dart port of the SKDH-based gait analysis.
// All four discrepancies from the review have been fixed:
//   1. Min IC distance: 0.55s (was 0.30s) → correct step count
//   2. Stance/swing: trough-based, not hardcoded 60/40
//   3. SPARC: full stride window IC[i]→IC[i+2] (was step window)
//   4. Gait speed: correct Winer formula with strides/min

import 'dart:math' as math;
import 'package:gait_physiotherapy_demo/features/test/domain/gait_model.dart';


// ---------------------------------------------------------------------------
// Public result types
// ---------------------------------------------------------------------------

class StepResult {
  final double icTime;
  final double stepTime;
  final double strideTime;
  final double stanceTime;
  final double swingTime;
  final double cadence;
  final double gaitSpeed;
  final double strideSparc;

  const StepResult({
    required this.icTime,
    required this.stepTime,
    required this.strideTime,
    required this.stanceTime,
    required this.swingTime,
    required this.cadence,
    required this.gaitSpeed,
    required this.strideSparc,
  });
}

class GaitMetrics {
  final int stepCount;
  final double avgCadence;
  final double avgStepTime;
  final double avgStrideTime;
  final double avgStanceTime;
  final double avgSwingTime;
  final double stancePct;
  final double swingPct;
  final double avgGaitSpeed;
  final double avgSparc;
  final double avgImpact;
  final double samplingRate;
  final double duration;

  const GaitMetrics({
    required this.stepCount,
    required this.avgCadence,
    required this.avgStepTime,
    required this.avgStrideTime,
    required this.avgStanceTime,
    required this.avgSwingTime,
    required this.stancePct,
    required this.swingPct,
    required this.avgGaitSpeed,
    required this.avgSparc,
    required this.avgImpact,
    required this.samplingRate,
    required this.duration,
  });

  @override
  String toString() => '''
--- Extended Clinical Results ---
Steps Counted        : $stepCount
Avg Cadence          : ${avgCadence.toStringAsFixed(2)} steps/min
Movement Smoothness  : ${avgSparc.toStringAsFixed(3)} (SPARC)
Phase Ratio          : Stance ${stancePct.toStringAsFixed(1)}% | Swing ${swingPct.toStringAsFixed(1)}%
Avg Step Time        : ${avgStepTime.toStringAsFixed(3)} s
Avg Gait Speed       : ${avgGaitSpeed.toStringAsFixed(3)} m/s
Avg Impact (IC)      : ${avgImpact.toStringAsFixed(3)} g
Sampling Rate        : ${samplingRate.toStringAsFixed(2)} Hz
Duration             : ${duration.toStringAsFixed(2)} s
''';
}

// ---------------------------------------------------------------------------
// Analysis engine
// ---------------------------------------------------------------------------

class GaitAnalyzer {
  final double height;

  const GaitAnalyzer({this.height = 1.75});

  // ── Main entry point ──────────────────────────────────────────────────────
  GaitMetrics analyze(GaitDataset dataset) {
    final fs = dataset.samplingRate;
    final time = dataset.timeSeconds;
    final mag = dataset.accMagnitudes;

    final icIndices = _detectIcEvents(mag, fs);

    if (icIndices.length < 2) {
      throw StateError('Not enough step events detected. Check the data.');
    }

    final steps = _buildStepResults(icIndices, time, mag, fs);
    return _aggregate(steps, dataset, icIndices);
  }

  // ── IC Detection ──────────────────────────────────────────────────────────
  // Fix 1: minimum distance raised to 0.55s (was 0.30s).
  // At ~44 Hz, 0.30s ≈ 13 samples — too small, catches both feet.
  // 0.55s enforces one IC per stride side, matching skdh GaitLumbar.
  List<int> _detectIcEvents(List<double> mag, double fs) {
    final filtered = _lowPassFilter(mag, fs, cutoff: 20.0);

    final mean = _mean(filtered);
    final std = _std(filtered);
    final norm =
        filtered.map((v) => (v - mean) / (std == 0 ? 1 : std)).toList();

    final minDistSamples = (fs * 0.55).round(); // Fix 1
    return _findPeaks(norm, minDistance: minDistSamples, minProminence: 0.5);
  }

  // ── Per-step metrics ──────────────────────────────────────────────────────
  List<StepResult> _buildStepResults(
    List<int> icIndices,
    List<double> time,
    List<double> mag,
    double fs,
  ) {
    final results = <StepResult>[];

    for (int i = 0; i < icIndices.length - 1; i++) {
      final idx = icIndices[i];
      final nextIdx = icIndices[i + 1];

      final icTime = time[idx];
      final stepTime = time[nextIdx] - time[idx];

      // Stride = IC[i] → IC[i+2] (two steps = one full stride).
      final strideEndIdx =
          (i + 2 < icIndices.length) ? icIndices[i + 2] : null;
      final strideTime = strideEndIdx != null
          ? time[strideEndIdx] - time[idx]
          : stepTime * 2;

      // Fix 2: stance/swing derived from the acceleration trough between ICs.
      // The trough between two heel-strikes approximates toe-off, splitting
      // the step interval into stance (IC → trough) and swing (trough → next IC).
      final troughIdx = _findTrough(mag, idx, nextIdx);
      final stanceTime = time[troughIdx] - time[idx];
      final swingTime = time[nextIdx] - time[troughIdx];

      final cadence = stepTime > 0 ? 60.0 / stepTime : 0;

      // Fix 4: Winer formula — strideFreq must be in strides/min.
      // cadence (steps/min) / 2 = strides/min.
      final strideFreqPerMin = cadence / 2.0;
      final strideLength = 0.413 * height * math.sqrt(strideFreqPerMin);
      final gaitSpeed =
          strideTime > 0 ? (strideLength * strideFreqPerMin) / 60.0 : 0;

      // Fix 3: SPARC over full stride window IC[i] → IC[i+2].
      // Step window (~0.5s) produced noisier spectrum → too-negative SPARC.
      final sparcEnd = strideEndIdx ??
          math.min(nextIdx + (nextIdx - idx), mag.length - 1);
      final window = mag.sublist(idx, sparcEnd + 1);
      final sparc = _computeSparc(window, fs);

      results.add(StepResult(
        icTime: icTime,
        stepTime: stepTime,
        strideTime: strideTime,
        stanceTime: stanceTime,
        swingTime: swingTime,
        cadence: cadence.toDouble(),
        gaitSpeed: gaitSpeed.toDouble(),
        strideSparc: sparc,
      ));
    }
    for (int i = 0; i < math.min(5, results.length); i++) {
  final s = results[i];
  print('Step $i: icTime=${s.icTime.toStringAsFixed(3)}, '
        'stepTime=${s.stepTime.toStringAsFixed(3)}, '
        'cadence=${s.cadence.toStringAsFixed(2)}');
}
    return results;
  }

  /// Minimum magnitude between [startIdx] and [endIdx] — approximates toe-off.
  int _findTrough(List<double> mag, int startIdx, int endIdx) {
    int troughIdx = startIdx;
    double minVal = mag[startIdx];
    for (int i = startIdx + 1; i < endIdx && i < mag.length; i++) {
      if (mag[i] < minVal) {
        minVal = mag[i];
        troughIdx = i;
      }
    }
    return troughIdx;
  }

  // ── Aggregate ─────────────────────────────────────────────────────────────
  GaitMetrics _aggregate(
      List<StepResult> steps, GaitDataset dataset, List<int> icIndices) {
    final n = steps.length;
    double sumCad = 0, sumStep = 0, sumStride = 0;
    double sumStance = 0, sumSwing = 0, sumSpeed = 0, sumSparc = 0;

    for (final s in steps) {
      sumCad += s.cadence;
      sumStep += s.stepTime;
      sumStride += s.strideTime;
      sumStance += s.stanceTime;
      sumSwing += s.swingTime;
      sumSpeed += s.gaitSpeed;
      sumSparc += s.strideSparc;
    }

    final avgStride = sumStride / n;
    final avgStance = sumStance / n;
    final avgSwing = sumSwing / n;
    final avgStep = sumStep / n;


    final mag = dataset.accMagnitudes;
    double sumImpact = 0;
    for (final idx in icIndices) {
      sumImpact += mag[idx];
    }
    final avgImpact = icIndices.isNotEmpty ? sumImpact / icIndices.length : 0;

    return GaitMetrics(
      stepCount: n,
      avgCadence: sumCad / n,
      avgStepTime: sumStep / n,
      avgStrideTime: avgStride,
      avgStanceTime: avgStance,
      avgSwingTime: avgSwing,
      stancePct: avgStep > 0 ? (avgStance / avgStep) * 100 : 0,
      swingPct: avgStep > 0 ? (avgSwing / avgStep) * 100 : 0,
      avgGaitSpeed: sumSpeed / n,
      avgSparc: sumSparc / n,
      avgImpact: avgImpact.toDouble(),
      samplingRate: dataset.samplingRate,
      duration: dataset.durationSeconds,
    );
  }

  // =========================================================================
  // DSP helpers
  // =========================================================================

  List<double> _lowPassFilter(List<double> signal, double fs,
      {required double cutoff}) {
    const int M = 31;
    final fc = cutoff / fs;
    final kernel = List<double>.filled(M, 0);
    final half = M ~/ 2;

    for (int i = 0; i < M; i++) {
      if (i == half) {
        kernel[i] = 2 * math.pi * fc;
      } else {
        final n = i - half;
        kernel[i] = math.sin(2 * math.pi * fc * n) / n;
      }
      kernel[i] *= 0.54 - 0.46 * math.cos(2 * math.pi * i / (M - 1));
    }
    final sum = kernel.reduce((a, b) => a + b);
    for (int i = 0; i < M; i++) {
      kernel[i] /= sum;
    }

    final out = List<double>.filled(signal.length, 0);
    for (int i = 0; i < signal.length; i++) {
      double acc = 0;
      for (int j = 0; j < M; j++) {
        final si = i - j + half;
        if (si >= 0 && si < signal.length) {
          acc += signal[si] * kernel[j];
        }
      }
      out[i] = acc;
    }
    return out;
  }

  List<int> _findPeaks(
    List<double> signal, {
    required int minDistance,
    required double minProminence,
  }) {
    final candidates = <int>[];
    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        candidates.add(i);
      }
    }

    final prominent = <int>[];
    for (final idx in candidates) {
      final peak = signal[idx];
      int left = idx - 1;
      while (left > 0 && signal[left] < peak) {
        left--;
      }
      int right = idx + 1;
      while (right < signal.length - 1 && signal[right] < peak) {
        right++;
      }
      final leftMin = _minInRange(signal, left, idx);
      final rightMin = _minInRange(signal, idx, right);
      final prominence = peak - math.max(leftMin, rightMin);
      if (prominence >= minProminence) {
        prominent.add(idx);
      }
    }

    final filtered = <int>[];
    for (final idx in prominent) {
      if (filtered.isEmpty || idx - filtered.last >= minDistance) {
        filtered.add(idx);
      } else if (signal[idx] > signal[filtered.last]) {
        filtered[filtered.length - 1] = idx;
      }
    }
    return filtered;
  }

  double _minInRange(List<double> s, int start, int end) {
    double m = double.infinity;
    for (int i = start; i <= end && i < s.length; i++) {
      if (s[i] < m) m = s[i];
    }
    return m;
  }

  // SPARC – Spectral Arc Length
  double _computeSparc(List<double> window, double fs,
      {double fcMax = 10.0, double ampThr = 0.05}) {
    if (window.length < 4) return -10.0;

    final N = window.length;
    final maxBin = (fcMax * N / fs).round().clamp(0, N ~/ 2);
    final freqs = <double>[];
    final amp = <double>[];
    double maxAmp = 0;

    for (int k = 0; k <= maxBin; k++) {
      double re = 0, im = 0;
      for (int n = 0; n < N; n++) {
        final angle = 2 * math.pi * k * n / N;
        re += window[n] * math.cos(angle);
        im -= window[n] * math.sin(angle);
      }
      final a = math.sqrt(re * re + im * im) / N;
      freqs.add(k * fs / N);
      amp.add(a);
      if (a > maxAmp) maxAmp = a;
    }

    if (maxAmp == 0) return -10.0;

    final normAmp = amp.map((a) => a / maxAmp).toList();

    int lastIdx = normAmp.length - 1;
    while (lastIdx > 0 && normAmp[lastIdx] < ampThr) {
      lastIdx--;
    }

    if (lastIdx < 2) return -10.0;

    double arcLen = 0;
    final df = freqs.length > 1 ? (freqs[1] - freqs[0]) : 1.0;
    for (int i = 1; i <= lastIdx; i++) {
      final dA = normAmp[i] - normAmp[i - 1];
      arcLen += math.sqrt(df * df + dA * dA);
    }

    return -arcLen;
  }

  double _mean(List<double> v) {
    if (v.isEmpty) return 0;
    return v.reduce((a, b) => a + b) / v.length;
  }

  double _std(List<double> v) {
    if (v.length < 2) return 0;
    final m = _mean(v);
    final variance =
        v.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / v.length;
    return math.sqrt(variance);
  }
}