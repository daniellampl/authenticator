import 'dart:async';

import 'package:authenticator/src/storage.dart';
import 'package:authenticator/src/token.dart';

/// {@template authenticator.authenticator}
///
/// {@endtemplate}
abstract class Authenticator<T extends AuthenticatorToken> {
  /// {@macro authenticator.authenticator}
  Authenticator({
    required this.delegate,
    AuthenticatorStorage<T>? localStorage,
  }) : localStorage = localStorage ?? EmptyAuthenticatorStorage<T>();

  final AuthenticatorStorage<T> localStorage;
  final AuthenticatorDelegate<T> delegate;

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
      final token = await delegate.signIn(signInProvider);
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
    required RefreshAuthenticatorDelegate<T> delegate,
    AuthenticatorStorage<T>? localStorage,
  }) : super(
          delegate: delegate,
          localStorage: localStorage,
        );

  ///
  Future<void> refresh() async {
    _assertInitialized();

    if (_token == null) {
      // TODO(daniellampl): throw proper exception
      throw Exception();
    }

    try {
      final newToken = await (delegate as RefreshAuthenticatorDelegate<T>)
          .refreshToken(_token!);
      await setToken(newToken);
    } catch (e) {
      await clearToken();
      // TODO(daniellampl): throw proper exception
      rethrow;
    }
  }
}

/// {@template authenticator.authentictor_delegate}
///
/// {@endtemplate}
abstract class AuthenticatorDelegate<T extends AuthenticatorToken> {
  /// {@marco authenticator.authentictor_delegate}
  const AuthenticatorDelegate();

  ///
  Future<T> signIn(SignInProvider signInProvider);
}

///
abstract class RefreshAuthenticatorDelegate<
    T extends RefreshableAuthenticatorToken> extends AuthenticatorDelegate<T> {
  const RefreshAuthenticatorDelegate();

  ///
  Future<T> refreshToken(T token);
}

/// {@template authenticator.sign_in_provider}
///
/// {@endtemplate}
abstract class SignInProvider {
  /// {@marco authenticator.sign_in_provider}
  const SignInProvider();
}
