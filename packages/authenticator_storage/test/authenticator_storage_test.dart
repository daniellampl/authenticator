import 'package:authenticator_storage/authenticator_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

const _encryptionKeyKey = 'authenticator_encryption_key';
const _migrationKeys = ['key_1', 'key_2', 'key_3'];

class _FlutterSecureStorageMock extends Mock implements FlutterSecureStorage {}

class _HiveBoxServiceMock extends Mock implements HiveBoxService {}

void main() {
  test(
      'When no Hive box encryption key is stored, then nothing should be '
      'migrated.', () async {
    final flutterSecureStorage = _FlutterSecureStorageMock();
    final hiveBoxService = _HiveBoxServiceMock();

    when(() => flutterSecureStorage.read(key: _encryptionKeyKey))
        .thenAnswer((_) => Future.value());

    await SecureAuthenticatorStorage(
      flutterSecureStorage: flutterSecureStorage,
      hiveService: hiveBoxService,
    ).migrate(_migrationKeys);

    _verifyNotMigrated(flutterSecureStorage, hiveBoxService);
  });

  test(
    'When Hive box encryption key is stored, then data should be migrated '
    'to FlutterSecureStorage.',
    () async {
      const encryptionKey = 'encryption_key';
      final flutterSecureStorage = _FlutterSecureStorageMock();
      final hiveBoxService = _HiveBoxServiceMock();

      when(() => flutterSecureStorage.read(key: _encryptionKeyKey))
          .thenAnswer((_) => Future.value(encryptionKey));
      when(() => flutterSecureStorage.delete(key: _encryptionKeyKey))
          .thenAnswer((_) => Future.value());
      when(
        () => flutterSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) => Future.value());
      when(() => hiveBoxService.open(any())).thenAnswer((_) => Future.value());
      when(() => hiveBoxService.read(any())).thenReturn('value');
      when(hiveBoxService.destroy).thenAnswer((_) => Future.value());

      await SecureAuthenticatorStorage(
        flutterSecureStorage: flutterSecureStorage,
        hiveService: hiveBoxService,
      ).migrate(_migrationKeys);

      verify(() => flutterSecureStorage.delete(key: _encryptionKeyKey))
          .called(1);
      verify(() => hiveBoxService.open(encryptionKey)).called(1);

      for (final migrationKey in _migrationKeys) {
        verify(() => hiveBoxService.read(migrationKey)).called(1);
        verify(
          () => flutterSecureStorage.write(
            key: migrationKey,
            value: any(named: 'value'),
          ),
        ).called(1);
      }

      verify(hiveBoxService.destroy).called(1);
    },
  );

  test(
      'When error ocurrs while reading encrpytion key from '
      'FlutterSecureStorage, then every value should be deleted entirely.',
      () async {
    final flutterSecureStorage = _FlutterSecureStorageMock();
    final hiveBoxService = _HiveBoxServiceMock();

    when(() => flutterSecureStorage.read(key: _encryptionKeyKey))
        .thenThrow(Exception());
    when(flutterSecureStorage.deleteAll).thenAnswer((_) => Future.value());

    await SecureAuthenticatorStorage(
      flutterSecureStorage: flutterSecureStorage,
      hiveService: hiveBoxService,
    ).migrate(_migrationKeys);

    verify(flutterSecureStorage.deleteAll).called(1);
    _verifyNotMigrated(flutterSecureStorage, hiveBoxService);
  });
}

void _verifyNotMigrated(
  FlutterSecureStorage flutterSecureStorage,
  HiveBoxService hiveBoxService,
) {
  verify(() => flutterSecureStorage.read(key: _encryptionKeyKey)).called(1);
  verifyNever(() => flutterSecureStorage.delete(key: _encryptionKeyKey));
  verifyNever(
    () => flutterSecureStorage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  );
  verifyNever(() => hiveBoxService.open(any()));
  verifyNever(() => hiveBoxService.read(any()));
  verifyNever(hiveBoxService.destroy);
}
