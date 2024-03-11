import 'package:flutter_secure_storage/flutter_secure_storage.dart';

///
class SecureAuthenticatorStorage {
  ///
  SecureAuthenticatorStorage({
    FlutterSecureStorage? flutterSecureStorage,
  }) : _secureStorage = flutterSecureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _secureStorage;

  Future<void> delete(String key) {
    return _secureStorage.delete(key: key);
  }

  Future<String?> read(String key) async {
    try {
      return _secureStorage.read(key: key);
    } catch (e) {
      // error can ocurr whene encryption doesn't match due to Android backup.
      // In this case we just delete the value for the key and return null.
      // see: https://github.com/mogol/flutter_secure_storage/issues/210
      await delete(key);
      return null;
    }
  }

  Future<void> write(String key, String? value) {
    if (value == null) {
      return delete(key);
    } else {
      return _secureStorage.write(
        key: key,
        value: value,
      );
    }
  }
}
