class SlmService {
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
}
