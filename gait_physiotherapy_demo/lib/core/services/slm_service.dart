import 'dart:async';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

class ModelInfo {
  final String name;
  final String url;
  final String filename;

  const ModelInfo({
    required this.name,
    required this.url,
    required this.filename,
  });
}

const modelsRegistry = [
  ModelInfo(
    name: "Gemma 4 E4B",
    url: "https://huggingface.co/ggml-org/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf?download=true",
    filename: "gemma-4-E4B-it-Q4_K_M.gguf",
  ),
  ModelInfo(
    name: "Phi-4 Mini",
    url: "https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-Q4_K_M.gguf?download=true",
    filename: "Phi-4-mini-instruct-Q4_K_M.gguf",
  ),
];

class SLMNativeBridge {
  static const _channel = MethodChannel('com.example.gait_physiotherapy_demo/slm_inference');

  static Future<bool> loadModel(String path) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('loadModel', {'path': path});
      return success ?? false;
    } on PlatformException catch (e) {
      throw Exception("Failed to load model: ${e.message}");
    }
  }

  static Future<String> generate(String prompt) async {
    try {
      final String? output = await _channel.invokeMethod<String>('generate', {'prompt': prompt});
      return output ?? "";
    } on PlatformException catch (e) {
      throw Exception("Failed to generate: ${e.message}");
    }
  }

  static Future<bool> unloadModel() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('unloadModel');
      return success ?? false;
    } on PlatformException catch (e) {
      throw Exception("Failed to unload model: ${e.message}");
    }
  }

  static Future<bool> keepScreenOn(bool keep) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('keepScreenOn', {'keep': keep});
      return success ?? false;
    } on PlatformException catch (e) {
      throw Exception("Failed to set keepScreenOn: ${e.message}");
    }
  }
}

class SLMService {
  static final _dio = Dio();
  static String? _loadedModelPath;

  String interpret({
    required int symmetry,
    required int score,
    required double stance,
    required int balance,
  }) {
    if (symmetry >= 88) {
      return 'Symmetric gait rhythm. Balanced stance-phase duration of ${(stance * 100).toStringAsFixed(0)}% indicates healthy joint load.';
    } else if (symmetry >= 76) {
      final imbalance = (50 - balance).abs();
      return 'Mild mechanical compensation. Left-Right stance symmetry variance of $imbalance% detected. Watch for fatigue.';
    } else {
      return 'Severe asymmetric pattern. Pronounced gait dysmotility. Recommend rehabilitation for off-balance weight load.';
    }
  }

  /// Downloads a GGUF model file from Hugging Face using Dio.
  static Future<void> downloadModel({
    required String url,
    required String savePath,
    required void Function(double progress) onProgress,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );
    } catch (e) {
      throw Exception("Failed to download model: $e");
    }
  }

  /// Ensures the model is loaded in memory. If the model path has changed,
  /// loads the new model using the MethodChannel JNI bridge.
  static Future<void> loadModelIfChanged(String modelPath) async {
    if (_loadedModelPath == modelPath) {
      return;
    }
    final success = await SLMNativeBridge.loadModel(modelPath);
    if (!success) {
      throw Exception('Failed to load LLM model at $modelPath');
    }
    _loadedModelPath = modelPath;
  }

  /// Generates a response stream using JNI llama.cpp and simulates streaming words.
  static Stream<String> generateStream({
    required String modelPath,
    required String prompt,
  }) async* {
    await loadModelIfChanged(modelPath);
    final responseText = await SLMNativeBridge.generate(prompt);

    // Simulate word-by-word streaming for the UI
    final words = responseText.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield words[i] + (i < words.length - 1 ? ' ' : '');
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }
}
