import 'dart:async';
import 'dart:io';
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
    name: "Qwen 2.5 0.5B (Fastest - 390MB)",
    url: "https://hf-mirror.com/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf?download=true",
    filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
  ),
  ModelInfo(
    name: "Qwen 2.5 1.5B (Recommended - 1.1GB)",
    url: "https://hf-mirror.com/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf?download=true",
    filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
  ),
  ModelInfo(
    name: "Llama 3.2 1B (Balanced - 1.2GB)",
    url: "https://hf-mirror.com/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf?download=true",
    filename: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
  ),
  ModelInfo(
    name: "Gemma 4 E4B (Large - 2.2GB)",
    url: "https://hf-mirror.com/ggml-org/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf?download=true",
    filename: "gemma-4-E4B-it-Q4_K_M.gguf",
  ),
  ModelInfo(
    name: "Phi-4 Mini (Large - 2.4GB)",
    url: "https://hf-mirror.com/matrixportalx/Phi-4-mini-instruct-Q4_K_M-GGUF/resolve/main/Phi-4-mini-instruct-Q4_K_M.gguf?download=true",
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
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 60),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    ),
  );
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

  /// Downloads a model file using optimized native HttpClient and direct file descriptor writes.
  static Future<void> downloadModel({
    required String url,
    required String savePath,
    required void Function(double progress) onProgress,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception("Server returned status code: ${response.statusCode}");
      }
      
      final contentLength = response.contentLength;
      final file = File(savePath);
      
      // Open file in write mode using a low-level RandomAccessFile descriptor
      final raf = await file.open(mode: FileMode.write);
      
      int received = 0;
      double lastProgress = -0.01;
      
      await for (final chunk in response) {
        await raf.writeFrom(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          final progress = received / contentLength;
          if (progress - lastProgress >= 0.005 || progress >= 0.999) {
            lastProgress = progress;
            onProgress(progress);
          }
        }
      }
      await raf.close();
    } catch (e) {
      throw Exception("Failed to download model: $e");
    } finally {
      client.close();
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
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
}
