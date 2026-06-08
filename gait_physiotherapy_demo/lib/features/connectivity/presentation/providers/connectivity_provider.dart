import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/database/database_service.dart';

enum ConnectivityStatus { disconnected, scanning, connecting, connected }

class ConnectivityState {
  final ConnectivityStatus status;
  final bool isBluetoothOn;
  final bool isHotspotOn;
  final String ssid;
  final String password;
  final bool rememberMe;
  final List<Map<String, dynamic>> scannedDevices;
  final String? connectedDeviceName;
  final String? errorMessage;

  ConnectivityState({
    this.status = ConnectivityStatus.disconnected,
    this.isBluetoothOn = false,
    this.isHotspotOn = false,
    this.ssid = '',
    this.password = '',
    this.rememberMe = false,
    this.scannedDevices = const [],
    this.connectedDeviceName,
    this.errorMessage,
  });

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    bool? isBluetoothOn,
    bool? isHotspotOn,
    String? ssid,
    String? password,
    bool? rememberMe,
    List<Map<String, dynamic>>? scannedDevices,
    String? connectedDeviceName,
    String? errorMessage,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      isBluetoothOn: isBluetoothOn ?? this.isBluetoothOn,
      isHotspotOn: isHotspotOn ?? this.isHotspotOn,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      scannedDevices: scannedDevices ?? this.scannedDevices,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ConnectivityNotifier extends Notifier<ConnectivityState> {
  @override
  ConnectivityState build() {
    Future.microtask(() => _loadSavedCredentials());
    return ConnectivityState();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final creds = await DatabaseService.instance.getSavedCredentials();
      if (creds != null) {
        state = state.copyWith(
          ssid: creds['ssid'] as String,
          password: creds['password'] as String,
          rememberMe: (creds['remember_me'] as int) == 1,
        );
      }
    } catch (e) {
      print('Credentials load failed: $e');
    }
  }

  void updateCredentials(String ssid, String password, bool rememberMe) {
    state = state.copyWith(
      ssid: ssid,
      password: password,
      rememberMe: rememberMe,
      errorMessage: null,
    );
    if (rememberMe) {
      DatabaseService.instance.saveCredentials(ssid, password, true);
    } else {
      DatabaseService.instance.clearCredentials();
    }
  }

  void toggleBluetooth(bool value) {
    state = state.copyWith(isBluetoothOn: value, errorMessage: null);
  }

  void toggleHotspot(bool value) {
    state = state.copyWith(isHotspotOn: value, errorMessage: null);
  }

  void startScanning() {
    if (!state.isBluetoothOn || !state.isHotspotOn) {
      state = state.copyWith(errorMessage: 'Please enable Bluetooth and Hotspot first');
      return;
    }
    state = state.copyWith(status: ConnectivityStatus.scanning, errorMessage: null);

    // Simulate finding devices after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (state.status == ConnectivityStatus.scanning) {
        state = state.copyWith(
          scannedDevices: [
            {'name': 'Gait Physio Band 1', 'id': 'GP:01:AB:CD', 'signal': 90},
            {'name': 'Gait Physio Band 2', 'id': 'GP:02:EF:GH', 'signal': 74},
            {'name': 'Gait Physio Band 3', 'id': 'GP:03:IJ:KL', 'signal': 52},
          ],
        );
      }
    });
  }

  Future<bool> connectToDevice(String deviceName, {bool simulateFailure = false}) async {
    state = state.copyWith(status: ConnectivityStatus.connecting, errorMessage: null);

    await Future.delayed(const Duration(seconds: 2));

    if (simulateFailure) {
      state = state.copyWith(
        status: ConnectivityStatus.disconnected,
        errorMessage: 'Bluetooth Connection Failed. Device responded with error code 0xEF.',
      );
      return false;
    } else {
      state = state.copyWith(
        status: ConnectivityStatus.connected,
        connectedDeviceName: deviceName,
        errorMessage: null,
      );
      return true;
    }
  }

  void disconnect() {
    state = state.copyWith(
      status: ConnectivityStatus.disconnected,
      connectedDeviceName: null,
      scannedDevices: const [],
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final connectivityProvider = NotifierProvider<ConnectivityNotifier, ConnectivityState>(() {
  return ConnectivityNotifier();
});
