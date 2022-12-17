import 'dart:async';

import 'package:authenticator/src/storage.dart';
import 'package:authenticator/src/token.dart';

/// {@template authenticator.authenticator}
///
/// {@endtemplate}
abstract class Authenticator<T extends AuthenticatorToken> {
  /// {@macro authenticator.authenticator}
  Authenticator({
    required this.client,
    AuthenticatorStorage<T>? localStorage,
  }) : localStorage = localStorage ?? EmptyAuthenticatorStorage<T>();

  final AuthenticatorStorage<T> localStorage;
  final AuthenticatorClient<T> client;

  /// Whether [initialize] already got called.
  bool _initialized = false;

  /// Gets the currently persited token.
  T? get token => _initialized ? _token : null;
  T? _token;

  ///
  final StreamController<T?> _tokenStreamController =
      StreamController.broadcast();

  ///
  Stream<T?> get tokenStream => _tokenStreamController.stream;

  ///
  bool get isAuthenticated => _token != null;

  ///
  Stream<bool> get authenticated =>
      tokenStream.map((token) => token != null).asBroadcastStream().distinct();

  /// Initializes the authenticator.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await localStorage.initialize();

    final persistedToken = await localStorage.token;
    if (persistedToken != null) {
      _updateToken(persistedToken);
    }

    _initialized = true;
  }

  ///
  Future<void> signIn(SignInProvider signInProvider) async {
    _assertInitialized();

    try {
      final token = await client.signIn(signInProvider);
      await setToken(token);
    } catch (e) {
      await clearToken();
      // TODO(daniellampl): throw proper exception
      rethrow;
    }
  }

  ///
  Future<void> setToken(T token) async {
    _assertInitialized();

    await localStorage.persistToken(token);
    _updateToken(token);
  }

  ///
  Future<void> clearToken() async {
    _assertInitialized();

    await localStorage.removePersistedToken();
    _updateToken(null);
  }

  void _updateToken(T? token) {
    _token = token;
    _notifyTokenChanged();
  }

  void _notifyTokenChanged() {
    _tokenStreamController.add(_token);
  }

  void _assertInitialized() {
    assert(
      _initialized,
      'Authenticator must be initialized before interacting with it!',
    );
  }
}

/// {@template authenticator.refresh_authenticator}
///
/// {@endtemplate}
class RefreshAuthenticator<T extends RefreshableAuthenticatorToken>
    extends Authenticator<T> {
  /// {@marco authenticator.refresh_authenticator}
  RefreshAuthenticator({
    required AuthenticatorClient<T> client,
    AuthenticatorStorage<T>? localStorage,
  }) : super(
          client: client,
          localStorage: localStorage,
        );

  ///
  Future<void> refresh() async {
    _assertInitialized();

    final refreshToken = _token?.refreshToken;

    if (refreshToken == null) {
      // TODO(daniellampl): throw proper exception
      throw Exception();
    }

    try {
      final newToken = await client.refreshToken(refreshToken);
      await setToken(newToken);
    } catch (e) {
      await clearToken();
      // TODO(daniellampl): throw proper exception
      rethrow;
    }
  }
}

/// {@template authenticator.authentictor_client}
///
/// {@endtemplate}
abstract class AuthenticatorClient<T extends AuthenticatorToken> {
  /// {@marco authenticator.authentictor_client}
  const AuthenticatorClient();

  ///
  Future<T> signIn(SignInProvider signInProvider);

  Future<T> refreshToken(String refreshToken) {
    throw UnimplementedError();
  }
}

/// {@template authenticator.sign_in_provider}
///
/// {@endtemplate}
abstract class SignInProvider {
  /// {@marco authenticator.sign_in_provider}
  const SignInProvider();
}
