import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const String _pinKey = 'user_pin';

  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  static Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  static Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
  }

  static Future<bool> verifyPin(String pin) async {
    final storedPin = await getPin();
    return storedPin == pin;
  }

  static Future<bool> isPinSet() async {
    return await getPin() != null;
  }
}
