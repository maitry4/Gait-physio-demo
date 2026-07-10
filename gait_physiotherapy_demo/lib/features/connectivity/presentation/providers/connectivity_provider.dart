import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_iot/wifi_iot.dart';
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
  final String? connectedDeviceId;
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
    this.connectedDeviceId,
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
    String? connectedDeviceId,
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
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ConnectivityNotifier extends Notifier<ConnectivityState> {
  StreamSubscription? _btSub;

  @override
  ConnectivityState build() {
    Future.microtask(() {
      _loadSavedCredentials();
      _initHardwareListeners();
    });

    ref.onDispose(() {
      _btSub?.cancel();
    });

    return ConnectivityState();
  }

  /// Only Bluetooth adapter state is auto-detected via the OS stream.
  /// Hotspot status is intentionally NOT polled here — it's controlled
  /// manually by the user via [toggleHotspot], since `isWiFiAPEnabled()`
  /// is unreliable across many Android OEMs/versions.
  void _initHardwareListeners() {
    _btSub = FlutterBluePlus.adapterState.listen((adapterState) {
      state = state.copyWith(isBluetoothOn: adapterState == BluetoothAdapterState.on);
    });
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

  Future<void> toggleBluetooth(bool value) async {
    try {
      if (value) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      print('BT toggle error: $e');
    }
  }

  /// Manual hotspot toggle. The user is the source of truth here: tapping
  /// the pill immediately flips [isHotspotOn] to reflect what the user
  /// confirms, rather than waiting on/trusting a platform status query.
  /// We still attempt to call the platform API best-effort, but a failure
  /// there does not revert the user's manual confirmation.
  Future<void> toggleHotspot(bool value) async {
    state = state.copyWith(isHotspotOn: value, errorMessage: null);

    try {
      await WiFiForIoTPlugin.setWiFiAPEnabled(value);
    } catch (e) {
      print('Hotspot toggle error: $e');
      // Intentionally not reverting state.isHotspotOn — detection is manual,
      // so the user's confirmation stands even if the platform call fails
      // (e.g. unsupported on this device/OS version).
    }
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

  Future<bool> connectToDevice(String deviceName, String deviceId) async {
    state = state.copyWith(status: ConnectivityStatus.connecting, errorMessage: null);

    await Future.delayed(const Duration(seconds: 2));

    state = state.copyWith(
      status: ConnectivityStatus.connected,
      connectedDeviceName: deviceName,
      connectedDeviceId: deviceId,
      errorMessage: null,
    );
    return true;
  }

  void disconnect() {
    state = state.copyWith(
      status: ConnectivityStatus.disconnected,
      connectedDeviceName: null,
      connectedDeviceId: null,
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