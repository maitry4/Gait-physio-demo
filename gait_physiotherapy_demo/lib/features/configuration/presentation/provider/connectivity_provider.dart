import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:gait_physiotherapy_demo/core/services/secure_storage_service.dart';
import 'package:gait_physiotherapy_demo/core/services/sqlite_service.dart';
enum ConnectivityStatus { disconnected, scanning, connecting, connected }

class ConnectivityState {
  final ConnectivityStatus status;
  final bool isBluetoothOn;
  final bool isHotspotOn;
  final String ssid;
  final String password;
  final bool rememberMe;
  final List<Map<String, dynamic>> scannedDevices;
  final List<Map<String, dynamic>> dbDevices;
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
    this.dbDevices = const [],
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
    List<Map<String, dynamic>>? dbDevices,
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
      dbDevices: dbDevices ?? this.dbDevices,
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
      _loadDbDevices();
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
      final creds = await SecureStorageService.getHotspotCredentials();
      if (creds != null) {
        state = state.copyWith(
          ssid: creds['ssid'] as String,
          password: creds['password'] as String,
          rememberMe: true,
        );
      }
    } catch (e) {
      print('Credentials load failed: $e');
    }
  }

  Future<void> _loadDbDevices() async {
    try {
      final devices = await SQLiteService.getDevices();
      state = state.copyWith(dbDevices: devices);
    } catch (e) {
      print('DB devices load failed: $e');
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
      SecureStorageService.saveHotspotCredentials(ssid, password);
    } else {
      SecureStorageService.clearHotspotCredentials();
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

  // for device List
  Future<void> startScanning() async {
    if (!state.isBluetoothOn || !state.isHotspotOn) {
      state = state.copyWith(errorMessage: 'Please enable Bluetooth and Hotspot first');
      return;
    }
    state = state.copyWith(status: ConnectivityStatus.scanning, errorMessage: null, scannedDevices: []);

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      
      FlutterBluePlus.scanResults.listen((results) {
        final devices = results.map((r) => {
          'name': r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown Device',
          'id': r.device.remoteId.str,
          'signal': (r.rssi + 100).clamp(0, 100),
        }).toList();

        // Sort by signal strength descending
        devices.sort((a, b) => (b['signal'] as int).compareTo(a['signal'] as int));
        
        state = state.copyWith(scannedDevices: devices);
      });
    } catch (e) {
      print('Scan error: $e');
      state = state.copyWith(errorMessage: 'Failed to start scanning: $e', status: ConnectivityStatus.disconnected);
    }
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