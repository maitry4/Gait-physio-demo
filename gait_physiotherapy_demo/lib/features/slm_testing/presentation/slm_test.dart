import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/features/slm_testing/domain/result_testing.dart';
import 'package:gait_physiotherapy_demo/features/slm_testing/presentation/provider/slm_test_provider.dart';
import 'package:gait_physiotherapy_demo/features/slm_testing/benchmark_result_card.dart';

/// SLM Benchmark screen. Purely presentational - all state comes
/// from [slmTestProvider].
class SlmTestScreen extends ConsumerWidget {
  const SlmTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(slmTestProvider);
    final notifier = ref.read(slmTestProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SLM Benchmark'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (state.isLoadingModels)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<SlmModel>(
                initialValue: state.selectedModel,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: state.models
                    .map(
                      (m) => DropdownMenuItem(value: m, child: Text(m.name)),
                    )
                    .toList(),
                onChanged: (m) {
                  if (m != null) notifier.selectModel(m);
                },
              ),

            const SizedBox(height: 20),

            const Text(
              'Test Type',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Column(
              children: SlmTestType.values.map((type) {
                return RadioListTile<SlmTestType>(
                  value: type,
                  groupValue: state.testType,
                  onChanged: (v) {
                    if (v != null) notifier.selectTestType(v);
                  },
                  title: Text(type.label),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: state.isRunning || state.selectedModel == null
                    ? null
                    : notifier.runBenchmark,
                child: state.isRunning
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Run Benchmark',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            const SizedBox(height: 24),

            if (state.results.isNotEmpty) ...[
              const Text(
                'Results',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 10),
              ...state.results.map(
                (r) => BenchmarkResultCard(result: r),
              ),
            ],
          ],
        ),
      ),
    );
  }
}