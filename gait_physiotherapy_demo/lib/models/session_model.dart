import 'dart:convert';

class SessionModel {
  final String id;
  final String userId;
  final String date;
  final String duration;
  final String label;
  final int score;
  final double strideLength;
  final int cadence;
  final int balance;
  final int symmetry;
  final double stancePhase;
  final double swingPhase;
  final double doubleSupport;
  final String notes;
  final List<double> rawWaveform;
  final String slmInterpretation;

  SessionModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.duration,
    required this.label,
    required this.score,
    required this.strideLength,
    required this.cadence,
    required this.balance,
    required this.symmetry,
    required this.stancePhase,
    required this.swingPhase,
    required this.doubleSupport,
    required this.notes,
    required this.rawWaveform,
    required this.slmInterpretation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'duration': duration,
      'label': label,
      'score': score,
      'stride_length': strideLength,
      'cadence': cadence,
      'balance': balance,
      'symmetry': symmetry,
      'stance_phase': stancePhase,
      'swing_phase': swingPhase,
      'double_support': doubleSupport,
      'notes': notes,
      'raw_waveform': jsonEncode(rawWaveform),
      'slm_interpretation': slmInterpretation,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    List<double> rawWf = [];
    try {
      final decoded = jsonDecode(map['raw_waveform'] as String);
      if (decoded is List) {
        rawWf = decoded.map((e) => (e as num).toDouble()).toList();
      }
    } catch (_) {}

    return SessionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      date: map['date'] as String,
      duration: map['duration'] as String,
      label: map['label'] as String,
      score: map['score'] as int,
      strideLength: (map['stride_length'] as num).toDouble(),
      cadence: map['cadence'] as int,
      balance: map['balance'] as int,
      symmetry: map['symmetry'] as int,
      stancePhase: (map['stance_phase'] as num).toDouble(),
      swingPhase: (map['swing_phase'] as num).toDouble(),
      doubleSupport: (map['double_support'] as num).toDouble(),
      notes: map['notes'] as String,
      rawWaveform: rawWf,
      slmInterpretation: map['slm_interpretation'] as String,
    );
  }
}
