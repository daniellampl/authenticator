import 'dart:convert';

import 'package:authenticator/authenticator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _encryptionKeySecureStorageKey = 'authenticator_encryption_key';

///
abstract class SecureAuthenticatorStorage<T extends AuthenticatorToken>
    implements AuthenticatorStorage<T> {
  ///
  SecureAuthenticatorStorage({
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage secureStorage;

  late _KeyValueStorage _storage;

  @override
  Future<void> initialize() async {
    final encryptionKey =
        await _readEncryptionKey() ?? await _generateEncryptionKey();

    await Hive.initFlutter('authenticator');
    final box = await Hive.openBox<dynamic>(
      _hiveBoxName,
      encryptionCipher: HiveAesCipher(base64Url.decode(encryptionKey)),
    );

    _storage = _HiveKeyValueStorage(box);
  }

  ///
  Future<void> deleteTokenValue(String key) {
    return _storage.delete(key);
  }

  ///
  Future<dynamic> readTokenValue(String key) async {
    return _storage.read(key);
  }

  ///
  Future<void> writeTokenvalue(String key, dynamic value) {
    return _storage.write(key, value);
  }

  Future<String> _generateEncryptionKey() async {
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: _encryptionKeySecureStorageKey,
      value: base64UrlEncode(key),
    );

    return (await _readEncryptionKey())!;
  }

  Future<String?> _readEncryptionKey() {
    return secureStorage.read(key: _encryptionKeySecureStorageKey);
  }
}

const _hiveBoxName = 'authenticator';

/// A [_KeyValueStorage] that uses `hive` for storing token values.
class _HiveKeyValueStorage implements _KeyValueStorage {
  /// Creates a [_KeyValueStorage] instance that uses `hive` for storing
  /// token values.
  const _HiveKeyValueStorage(this.box);

  final Box<dynamic> box;

  @override
  Future<void> delete(String key) {
    return box.delete(key);
  }

  @override
  Future<dynamic> read(String key) async {
    return box.get(key);
  }

  @override
  Future<void> write(String key, dynamic value) {
    return box.put(key, value);
  }
}

/// An interface for a simple key value storages.
abstract class _KeyValueStorage {
  /// Reads a value that is stored under a [key].
  Future<dynamic> read(String key);

  /// Stores a [value] for a specific [key] in the storage.
  Future<void> write(String key, dynamic value);

  /// Deletes the value of a [key] from the storage.
  Future<void> delete(String key);
}
