class SLMService {
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

  static Stream<String> generateStream({
    required String modelId,
    required String prompt,
  }) async* {
    // Simulate initial latency (time-to-first-token)
    await Future.delayed(const Duration(milliseconds: 1200));

    final String responseText = 
        'Based on the provided metrics, the patient demonstrates stable gait parameters. '
        'Symmetry and stance phases appear within expected ranges for this stage of rehabilitation. '
        'No severe asymmetric compensation is detected. Continue the current exercise plan to maintain progress.';

    // Simulate token-by-token streaming
    final words = responseText.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield words[i] + (i < words.length - 1 ? ' ' : '');
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }
}
