// csv_loader.dart
// Reads the accelerometer TXT/CSV file from Flutter assets
// and returns a GaitDataset.
//
// File format:
//   - First row is skipped (header row).
//   - Columns: SerialNumber, Timestamp, x_acc, y_acc, z_acc
//   - Bad / unparseable lines are silently skipped.

import 'package:flutter/services.dart' show rootBundle;

import 'package:gait_physiotherapy_demo/features/test/domain/gait_model.dart';

class CsvLoader {
  /// Load a [GaitDataset] from an asset path.
  ///
  /// Example:
  /// final data = await CsvLoader.load(
  ///   "assets/gait_data.txt",
  /// );
  ///
  /// Throws an exception if asset cannot be loaded.
  static Future<GaitDataset> load(String assetPath) async {
    // Read file from Flutter asset bundle
    final content = await rootBundle.loadString(assetPath);

    final lines = content.split('\n');

    final samples = <GaitSample>[];

    // Skip first row (header)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      try {
        final fields = line.split(',');

        // Expected:
        // SerialNumber, Timestamp, x_acc, y_acc, z_acc
        if (fields.length < 5) continue;

        final sample = GaitSample.fromCsvRow(fields);

        samples.add(sample);

      } catch (_) {
        // Ignore invalid rows
        continue;
      }
    }


    if (samples.isEmpty) {
      throw StateError(
        'No valid data rows found in asset: $assetPath',
      );
    }


    // Convert timestamp into relative seconds
    final startTimestamp = samples.first.timestamp;


    final timeSeconds = samples
        .map(
          (sample) =>
              (sample.timestamp - startTimestamp) / 1000.0,
        )
        .toList();


    return GaitDataset(
      samples: samples,
      timeSeconds: timeSeconds,
    );
  }
}