import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/services/hive_service.dart';
import 'package:gait_physiotherapy_demo/core/services/sqlite_service.dart';

class SettingsState {
  final String slmPreference;
  final bool federatedLearningConsent;

  const SettingsState({
    required this.slmPreference,
    required this.federatedLearningConsent,
  });

  SettingsState copyWith({
    String? slmPreference,
    bool? federatedLearningConsent,
  }) {
    return SettingsState(
      slmPreference: slmPreference ?? this.slmPreference,
      federatedLearningConsent:
          federatedLearningConsent ?? this.federatedLearningConsent,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  // snapshot of what's actually persisted in Hive, used to detect unsaved edits
  late SettingsState _savedState;

  @override
  SettingsState build() {
    _savedState = SettingsState(
      slmPreference: HiveService.getSlmPreference(),
      federatedLearningConsent: HiveService.getConsent(),
    );
    return _savedState;
  }

  bool get hasUnsavedChanges =>
      state.slmPreference != _savedState.slmPreference ||
      state.federatedLearningConsent != _savedState.federatedLearningConsent;

  void updateSlmPreference(String value) {
    state = state.copyWith(slmPreference: value);
  }

  void updateConsent(bool value) {
    state = state.copyWith(federatedLearningConsent: value);
  }

  Future<void> save() async {
    await HiveService.saveSlmPreference(state.slmPreference);
    await HiveService.saveConsent(state.federatedLearningConsent);
    _savedState = state;
  }

  void discardChanges() {
    state = _savedState;
  }

  Future<void> importData() async {
    await SQLiteService.importDatabase();
  }

  Future<void> createTestData() async {
    await SQLiteService.createTestData();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Cheap derived provider so widgets can just watch a bool instead of
/// re-deriving equality themselves.
final hasUnsavedSettingsChangesProvider = Provider<bool>((ref) {
  ref.watch(settingsProvider); // rebuild whenever state changes
  return ref.watch(settingsProvider.notifier).hasUnsavedChanges;
});