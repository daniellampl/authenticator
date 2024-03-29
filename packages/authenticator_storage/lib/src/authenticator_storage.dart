import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _hiveBoxName = 'authenticator';
const _encryptionKeySecureStorageKey = 'authenticator_encryption_key';

class HiveBoxService {
  HiveBoxService();

  Box<dynamic>? _box;

  bool get _isOpen => _box != null && _box!.isOpen;

  Future<void> open(String encryptionKey) async {
    // this means we still use hive and have to migrate.
    await Hive.initFlutter('authenticator');

    _box = await Hive.openBox<dynamic>(
      _hiveBoxName,
      encryptionCipher: HiveAesCipher(base64Url.decode(encryptionKey)),
    );
  }

  dynamic read(String key) {
    if (_isOpen) {
      return _box!.get(key);
    } else {
      return null;
    }
  }

  Future<void> destroy() async {
    if (_isOpen) {
      return _box!.deleteFromDisk();
    }
  }
}

///
class SecureAuthenticatorStorage {
  ///
  SecureAuthenticatorStorage({
    FlutterSecureStorage? flutterSecureStorage,
    HiveBoxService? hiveService,
  })  : _secureStorage = flutterSecureStorage ?? const FlutterSecureStorage(),
        _hiveBoxService = hiveService ?? HiveBoxService();

  final HiveBoxService _hiveBoxService;
  final FlutterSecureStorage _secureStorage;

  /// Migrate form a Hive [Box] to [FlutterSecureStorage] only if an encryption
  /// key for the [Box] is available.
  Future<void> migrate(List<String> keys) async {
    String? encryptionKey;
    try {
      encryptionKey = await _readEncryptionKey();

      if (encryptionKey != null) {
        // remove encryption key so that the next time we initialize the storage
        // we do not have to migrate anymore.
        await _deleteEncryptionKey();
      }
    } catch (e) {
      // error can ocurr whene encryption doesn't match due to Android backup.
      // In this case we just delete the whole secure stoarge, so we do not end
      // up reading corrupted information anymore.
      // see: https://github.com/mogol/flutter_secure_storage/issues/210
      await _secureStorage.deleteAll();
    }

    if (encryptionKey != null) {
      await _hiveBoxService.open(encryptionKey);

      final values = keys.map(_hiveBoxService.read).toList();

      await Future.wait([
        for (var i = 0; i < values.length; i++)
          write(keys[i], values[i]?.toString()),
      ]);

      await _hiveBoxService.destroy();
    }
  }

  Future<void> delete(String key) {
    return _secureStorage.delete(
      key: key,
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  Future<String?> read(String key) {
    return _secureStorage.read(
      key: key,
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  Future<void> write(String key, String? value) {
    if (value == null) {
      return delete(key);
    } else {
      return _secureStorage.write(
        key: key,
        value: value,
        aOptions: const AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );
    }
  }

  Future<String?> _readEncryptionKey() {
    // not stored in encrypted SharedPreferences
    return _secureStorage.read(key: _encryptionKeySecureStorageKey);
  }

  Future<void> _deleteEncryptionKey() {
    // not stored in encrypted SharedPreferences
    return _secureStorage.delete(key: _encryptionKeySecureStorageKey);
  }
}
