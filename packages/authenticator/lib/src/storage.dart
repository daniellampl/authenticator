import 'package:authenticator/authenticator.dart';

/// LocalStorage is used to persist the user session in the device.
///
/// See also:
///
///   * [EmptyAuthenticatorStorage], used to disable session persistence
abstract class AuthenticatorStorage<T extends AuthenticatorToken> {
  const AuthenticatorStorage();

  /// Initialize the storage to persist session.
  Future<void> initialize();

  /// Remove the current persisted session.
  Future<void> removePersistedToken();

  /// Persist a session in the device.
  Future<void> persistToken(T token);

  Future<T?> get token;
}

/// A [AuthenticatorStorage] implementation that does nothing. Use this to
/// disable persistence.
class EmptyAuthenticatorStorage<T extends AuthenticatorToken>
    implements AuthenticatorStorage<T> {
  /// Creates a [AuthenticatorStorage] instance that disables persistence.
  const EmptyAuthenticatorStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> persistToken(T token) async {}

  @override
  Future<void> removePersistedToken() async {}

  @override
  Future<T?> get token async => Future.value();
}
