import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LockService {
  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  static const String _biometricKey = 'biometric_enabled';

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your financial vault',
      );
      return didAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricKey);
    return value == 'true';
  }
}

final lockServiceProvider = Provider((ref) => LockService());
