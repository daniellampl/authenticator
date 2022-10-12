///
abstract class AuthenticatorToken {
  const AuthenticatorToken();

  ///
  String get authorizationHeader;
}

/// {@template authenticator.refreshable_token}
///
/// {@endtemplate}
abstract class RefreshableAuthenticatorToken extends AuthenticatorToken {
  /// {@marco authentictor.refreshable_token}
  const RefreshableAuthenticatorToken({
    required this.refreshToken,
  });

  final String refreshToken;
}
