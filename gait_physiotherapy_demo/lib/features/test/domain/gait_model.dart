// gait_model.dart
// Model representing a single row from the accelerometer CSV/TXT file.

class GaitSample {
  final int serialNumber;
  final double timestamp; // raw ms timestamp
  final double xAcc;
  final double yAcc;
  final double zAcc;

  const GaitSample({
    required this.serialNumber,
    required this.timestamp,
    required this.xAcc,
    required this.yAcc,
    required this.zAcc,
  });

  /// Parse one CSV line.
  /// Expected format: SerialNumber,Timestamp,x_acc,y_acc,z_acc
  /// Acceleration values may be prefixed with "acc:".
  factory GaitSample.fromCsvRow(List<String> fields) {
    double parseAcc(String raw) {
      final cleaned = raw.trim().replaceFirst(RegExp(r'^acc:', caseSensitive: false), '');
      return double.parse(cleaned);
    }

    return GaitSample(
      serialNumber: int.parse(fields[0].trim()),
      timestamp: double.parse(fields[1].trim()),
      xAcc: parseAcc(fields[2]),
      yAcc: parseAcc(fields[3]),
      zAcc: parseAcc(fields[4]),
    );
  }

  /// Euclidean magnitude of the acceleration vector.
  double get magnitude => _sqrt(xAcc * xAcc + yAcc * yAcc + zAcc * zAcc);

  static double _sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 20; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }

  @override
  String toString() =>
      'GaitSample(sn=$serialNumber, t=$timestamp, '
      'x=$xAcc, y=$yAcc, z=$zAcc)';
}

/// The full dataset: all samples plus derived time axis.
class GaitDataset {
  final List<GaitSample> samples;

  /// Time in seconds relative to the first sample.
  final List<double> timeSeconds;

  const GaitDataset({
    required this.samples,
    required this.timeSeconds,
  });

  int get length => samples.length;

  /// Estimated sampling rate in Hz.
  double get samplingRate {
    if (timeSeconds.length < 2) return 0;
    double sum = 0;
    for (int i = 1; i < timeSeconds.length; i++) {
      sum += timeSeconds[i] - timeSeconds[i - 1];
    }
    final avgDt = sum / (timeSeconds.length - 1);
    return avgDt > 0 ? 1.0 / avgDt : 0;
  }

  double get durationSeconds =>
      timeSeconds.isNotEmpty ? timeSeconds.last : 0;

  List<double> get accMagnitudes =>
      samples.map((s) => s.magnitude).toList();
}