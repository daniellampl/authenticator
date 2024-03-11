/// LocalStorage is used to persist the user session in the device.
///
/// See also:
///
///   * [EmptyAuthenticatorStorage], used to disable session persistence
abstract class AuthenticatorStorage<T> {
  const AuthenticatorStorage();

  /// Persist a session in the device.
  Future<void> persistToken(T token);

  /// Remove the current persisted session.
  Future<void> removePersistedToken();

  Future<T?> get token;
}

/// A [AuthenticatorStorage] implementation that does nothing. Use this to
/// disable persistence.
class EmptyAuthenticatorStorage<T> implements AuthenticatorStorage<T> {
  /// Creates a [AuthenticatorStorage] instance that disables persistence.
  const EmptyAuthenticatorStorage();

  @override
  Future<void> persistToken(T token) async {}

  @override
  Future<void> removePersistedToken() async {}

  @override
  Future<T?> get token async => Future.value();
}
