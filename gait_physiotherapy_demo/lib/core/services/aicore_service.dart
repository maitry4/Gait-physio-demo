import 'package:flutter/services.dart';

class AiCoreInfo {
  final String deviceModel;
  final String androidVersion;
  final bool aiCoreInstalled;
  final bool geminiNanoAvailable;
  final String? modelName;
  final String? modelVersion;
  final String? apiVersion;
  final String status;
  final String? error;

  AiCoreInfo({
    required this.deviceModel,
    required this.androidVersion,
    required this.aiCoreInstalled,
    required this.geminiNanoAvailable,
    this.modelName,
    this.modelVersion,
    this.apiVersion,
    required this.status,
    this.error,
  });

  factory AiCoreInfo.fromMap(Map<Object?, Object?> map) {
    return AiCoreInfo(
      deviceModel: (map['deviceModel'] as String?) ?? 'Unknown',
      androidVersion: (map['androidVersion'] as String?) ?? 'Unknown',
      aiCoreInstalled: (map['aiCoreInstalled'] as bool?) ?? false,
      geminiNanoAvailable: (map['geminiNanoAvailable'] as bool?) ?? false,
      modelName: map['modelName'] as String?,
      modelVersion: map['modelVersion'] as String?,
      apiVersion: map['apiVersion'] as String?,
      status: (map['status'] as String?) ?? 'UNAVAILABLE',
      error: map['error'] as String?,
    );
  }
}

class AiCoreService {
  static const _channel = MethodChannel('com.example.gait_physiotherapy_demo/gemini_nano');

  static Future<AiCoreInfo> checkAvailability() async {
    try {
      final Map<Object?, Object?>? res = await _channel.invokeMethod<Map<Object?, Object?>>('checkAvailability');
      if (res == null) {
        throw Exception("Failed to check AI Core availability: response was null");
      }
      return AiCoreInfo.fromMap(res);
    } on PlatformException catch (e) {
      return AiCoreInfo(
        deviceModel: 'Unknown',
        androidVersion: 'Unknown',
        aiCoreInstalled: false,
        geminiNanoAvailable: false,
        status: 'UNAVAILABLE',
        error: e.message,
      );
    }
  }

  static Future<String> generate(String prompt) async {
    try {
      final String? output = await _channel.invokeMethod<String>('generate', {'prompt': prompt});
      return output ?? "";
    } on PlatformException catch (e) {
      throw Exception(e.message ?? "Unknown error during AI Core generation");
    }
  }
}
