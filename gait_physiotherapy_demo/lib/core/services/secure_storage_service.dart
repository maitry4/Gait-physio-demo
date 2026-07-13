import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String _keySsid = 'hotspot_ssid';
  static const String _keyPassword = 'hotspot_password';

  static Future<void> saveHotspotCredentials(String ssid, String password) async {
    await _storage.write(key: _keySsid, value: ssid);
    await _storage.write(key: _keyPassword, value: password);
  }

  static Future<bool> hasHotspotCredentials() async {
    final ssid = await _storage.read(key: _keySsid);
    final password = await _storage.read(key: _keyPassword);
    return ssid != null && ssid.isNotEmpty && password != null && password.isNotEmpty;
  }

  static Future<Map<String, String>?> getHotspotCredentials() async {
    final ssid = await _storage.read(key: _keySsid);
    final password = await _storage.read(key: _keyPassword);
    if (ssid != null && password != null) {
      return {'ssid': ssid, 'password': password};
    }
    return null;
  }
  static Future<void> clearHotspotCredentials() async {
    await _storage.delete(key: _keySsid);
    await _storage.delete(key: _keyPassword);
  }
}