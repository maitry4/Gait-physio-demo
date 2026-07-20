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
              'Inference Engine',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<InferenceEngine>(
                segments: const [
                  ButtonSegment(
                    value: InferenceEngine.llamaCpp,
                    label: Text('GGUF (llama.cpp)'),
                    icon: Icon(Icons.psychology),
                  ),
                  ButtonSegment(
                    value: InferenceEngine.aiCore,
                    label: Text('Google AI Core'),
                    icon: Icon(Icons.android),
                  ),
                ],
                selected: {state.selectedEngine},
                onSelectionChanged: state.isRunning || state.isDownloading
                    ? null
                    : (newSelection) {
                        notifier.selectEngine(newSelection.first);
                      },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (state.selectedEngine == InferenceEngine.llamaCpp) ...[
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
                  onChanged: state.isRunning || state.isDownloading
                      ? null
                      : (m) {
                          if (m != null) notifier.selectModel(m);
                        },
                ),
              const SizedBox(height: 20),
            ],

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
                  onChanged: state.isRunning || state.isDownloading
                      ? null
                      : (v) {
                          if (v != null) notifier.selectTestType(v);
                        },
                  title: Text(type.label),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),

            if (state.isDownloading) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Downloading Model...',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          state.downloadProgress != null
                              ? '${(state.downloadProgress! * 100).toStringAsFixed(1)}%'
                              : 'Connecting...',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: state.downloadProgress,
                      backgroundColor: Colors.grey.shade200,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This might take a few minutes for larger models (2GB - 5GB+). Please do not close the app.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                onPressed: state.isRunning ||
                        state.isDownloading ||
                        (state.selectedEngine == InferenceEngine.llamaCpp &&
                            state.selectedModel == null)
                    ? null
                    : notifier.runBenchmark,
                child: state.isDownloading
                    ? const Text(
                        'Downloading Model...',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      )
                    : state.isRunning
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