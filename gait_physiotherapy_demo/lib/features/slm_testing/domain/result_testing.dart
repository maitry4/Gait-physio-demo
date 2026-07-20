enum SlmTestType {
  singleSession('Single Session'),
  multiSession('Multi Session');

  final String label;
  const SlmTestType(this.label);
}

class SlmModel {
  final String id;
  final String name;
  final String provider;
  final String repo;
  final String filename;
  final String quantization;
  final String runtime;
  final num recommendedRamGB;

  SlmModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.repo,
    required this.filename,
    required this.quantization,
    required this.runtime,
    required this.recommendedRamGB,
  });

  factory SlmModel.fromJson(Map<String, dynamic> json) {
    return SlmModel(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String,
      repo: json['repo'] as String,
      filename: json['filename'] as String,
      quantization: json['quantization'] as String,
      runtime: json['runtime'] as String,
      recommendedRamGB: json['recommendedRamGB'] as num,
    );
  }
}

enum InferenceEngine {
  llamaCpp,
  aiCore,
}

class BenchmarkResult {
  final String phoneModel;
  final String androidVersion;
  final String modelName;
  final String testType;
  final int latencyMs;
  final int executionTimeMs;
  final num ramUsageMB;
  final num cpuUsagePercent;
  final int batteryBefore;
  final int batteryAfter;
  final int batteryDrop;
  final String output;
  final DateTime timestamp;

  // Optional AI Core diagnostics
  final String? aiCoreStatus;
  final String? geminiNanoStatus;
  final String? modelVersion;
  final int? promptLength;

  BenchmarkResult({
    required this.phoneModel,
    required this.androidVersion,
    required this.modelName,
    required this.testType,
    required this.latencyMs,
    required this.executionTimeMs,
    required this.ramUsageMB,
    required this.cpuUsagePercent,
    required this.batteryBefore,
    required this.batteryAfter,
    required this.batteryDrop,
    required this.output,
    required this.timestamp,
    this.aiCoreStatus,
    this.geminiNanoStatus,
    this.modelVersion,
    this.promptLength,
  });
}
