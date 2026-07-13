import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _boxName = 'gait_physio_settings';
  static const String _keySlmPref = 'slm_preference';
  static const String _keyConsent = 'federated_consent';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<void> savePreferences({required String slmPref, required bool consent}) async {
    final box = Hive.box(_boxName);
    await box.put(_keySlmPref, slmPref);
    await box.put(_keyConsent, consent);
  }

  static Future<void> saveSlmPreference(String slmPref) async {
    final box = Hive.box(_boxName);
    await box.put(_keySlmPref, slmPref);
  }
  
  static Future<void> saveConsent(bool consent) async {
    final box = Hive.box(_boxName);
    await box.put(_keyConsent, consent);
  }

  static bool hasPreferences() {
    final box = Hive.box(_boxName);
    final slmPref = box.get(_keySlmPref);
    final consent = box.get(_keyConsent);
    return slmPref != null && consent != null;
  }

  static String getSlmPreference() {
    return Hive.box(_boxName).get(_keySlmPref, defaultValue: 'online');
  }

  static bool getConsent() {
    return Hive.box(_boxName).get(_keyConsent, defaultValue: false);
  }
}