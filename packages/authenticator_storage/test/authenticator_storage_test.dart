import 'package:authenticator_storage/authenticator_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _FlutterSecureStorageMock extends Mock implements FlutterSecureStorage {}

void main() {
  test(
    'When reading value throws error, then the value gets deleted.',
    () async {
      const encryptionKey = 'encryption_key';
      final flutterSecureStorage = _FlutterSecureStorageMock();

      when(() => flutterSecureStorage.read(key: encryptionKey))
          .thenThrow((_) => Exception());
      when(() => flutterSecureStorage.delete(key: encryptionKey))
          .thenAnswer((_) => Future.value());

      final value = await SecureAuthenticatorStorage(
        flutterSecureStorage: flutterSecureStorage,
      ).read(encryptionKey);

      expect(value, null);

      verify(() => flutterSecureStorage.read(key: encryptionKey)).called(1);
      verify(() => flutterSecureStorage.delete(key: encryptionKey)).called(1);
    },
  );
}
