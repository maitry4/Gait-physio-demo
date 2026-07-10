import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gait_physiotherapy_demo/core/services/secure_storage_service.dart';
import 'package:gait_physiotherapy_demo/core/services/hive_service.dart';

enum CheckStatus { pending, loading, passed, failed }

class CheckState {
  final CheckStatus storageCheck;
  final CheckStatus hiveCheck;
  final CheckStatus hardwareCheck;
  final bool isComplete;

  CheckState({
    this.storageCheck = CheckStatus.pending,
    this.hiveCheck = CheckStatus.pending,
    this.hardwareCheck = CheckStatus.pending,
    this.isComplete = false,
  });

  CheckState copyWith({
    CheckStatus? storageCheck,
    CheckStatus? hiveCheck,
    CheckStatus? hardwareCheck,
    bool? isComplete,
  }) {
    return CheckState(
      storageCheck: storageCheck ?? this.storageCheck,
      hiveCheck: hiveCheck ?? this.hiveCheck,
      hardwareCheck: hardwareCheck ?? this.hardwareCheck,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class CheckNotifier extends Notifier<CheckState> {
  @override
  CheckState build() {
    Future.microtask(() => runChecks());
    return CheckState();
  }

  Future<void> runChecks() async {
    // Reset state
    state = CheckState(storageCheck: CheckStatus.loading);
    await Future.delayed(const Duration(milliseconds: 600));

    // 1. Secure Storage
    final hasCreds = await SecureStorageService.hasHotspotCredentials();
    if (!hasCreds) {
      state = state.copyWith(storageCheck: CheckStatus.failed);
      return;
    }
    state = state.copyWith(
      storageCheck: CheckStatus.passed,
      hiveCheck: CheckStatus.loading,
    );
    await Future.delayed(const Duration(milliseconds: 600));

    // 2. Hive
    final hasPrefs = HiveService.hasPreferences();
    if (!hasPrefs) {
      state = state.copyWith(hiveCheck: CheckStatus.failed);
      return;
    }
    state = state.copyWith(
      hiveCheck: CheckStatus.passed,
      hardwareCheck: CheckStatus.loading,
    );
    await Future.delayed(const Duration(milliseconds: 600));

    // 3. Hardware (Bluetooth)
    bool isBtOn = false;

    try {
      isBtOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    } catch (e) {
      print('Bluetooth check failed: $e');
    }

    if (!isBtOn) {
      state = state.copyWith(hardwareCheck: CheckStatus.failed);
      return;
    }

    state = state.copyWith(
      hardwareCheck: CheckStatus.passed,
      isComplete: true,
    );
  }
}

final checkProvider = NotifierProvider<CheckNotifier, CheckState>(() {
  return CheckNotifier();
});