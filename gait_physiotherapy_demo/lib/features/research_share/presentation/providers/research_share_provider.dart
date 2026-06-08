import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/database/database_service.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';

class ResearchShareState {
  final bool isSharingDataset;
  final String? errorMessage;

  ResearchShareState({
    this.isSharingDataset = false,
    this.errorMessage,
  });

  ResearchShareState copyWith({
    bool? isSharingDataset,
    String? Function()? errorMessage,
  }) {
    return ResearchShareState(
      isSharingDataset: isSharingDataset ?? this.isSharingDataset,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ResearchShareNotifier extends Notifier<ResearchShareState> {
  @override
  ResearchShareState build() {
    return ResearchShareState();
  }

  // ── Share Anonymous Data to Gait Research Dataset ───────────────────────
  Future<bool> shareAnonymousDataset() async {
    state = state.copyWith(isSharingDataset: true, errorMessage: () => null);

    try {
      final sessions = await DatabaseService.instance.getAllSessions();
      final users = await DatabaseService.instance.getUsers();

      if (sessions.isEmpty) {
        state = state.copyWith(isSharingDataset: false, errorMessage: () => 'No session data in SQLite database to share.');
        return false;
      }

      await Future.delayed(const Duration(seconds: 2));

      final anonymizedPayload = sessions.map((s) {
        final matchedUser = users.firstWhere((u) => u.id == s.userId,
            orElse: () => UserModel(id: 'UNKNOWN', name: 'Unknown', age: 0, dateAdded: ''));
        return {
          'age': matchedUser.age,
          'duration': s.duration,
          'label': s.label,
          'score': s.score,
          'stride_length': s.strideLength,
          'cadence': s.cadence,
          'balance': s.balance,
          'symmetry': s.symmetry,
          'stance_phase': s.stancePhase,
          'swing_phase': s.swingPhase,
          'double_support': s.doubleSupport,
          'slm_interpretation': s.slmInterpretation,
        };
      }).toList();

      print('Anonymized dataset built with ${anonymizedPayload.length} rows.');

      state = state.copyWith(isSharingDataset: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSharingDataset: false, errorMessage: () => 'Failed to anonymize: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }
}

final researchShareProvider = NotifierProvider<ResearchShareNotifier, ResearchShareState>(() {
  return ResearchShareNotifier();
});
