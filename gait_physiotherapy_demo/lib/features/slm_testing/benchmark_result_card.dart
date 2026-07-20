import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/features/slm_testing/domain/result_testing.dart';

/// Displays a single [BenchmarkResult] as a simple, readable Card.
/// No charts, no animations - just labeled rows.
class BenchmarkResultCard extends StatelessWidget {
  final BenchmarkResult result;

  const BenchmarkResultCard({super.key, required this.result});

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.modelName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 6),
            _row('Phone', result.phoneModel),
            _row('Android Version', result.androidVersion),
            _row('Test Type', result.testType),
            _row('Latency', '${result.latencyMs} ms'),
            _row('Execution Time', '${result.executionTimeMs} ms'),
            _row('RAM Usage', '${result.ramUsageMB.toStringAsFixed(1)} MB'),
            _row('CPU Usage', '${result.cpuUsagePercent.toStringAsFixed(1)} %'),
            _row('Battery Before', '${result.batteryBefore}%'),
            _row('Battery After', '${result.batteryAfter}%'),
            _row('Battery Drop', '${result.batteryDrop}%'),
            _row('Timestamp', result.timestamp.toString()),
            const SizedBox(height: 8),
            const Text(
              'LLM Output',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.output,
              style: const TextStyle(fontSize: 13, color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }
}