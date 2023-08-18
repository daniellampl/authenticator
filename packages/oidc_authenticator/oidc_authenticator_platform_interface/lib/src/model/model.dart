class OidcAuthenticatorException implements Exception {
  OidcAuthenticatorException({
    required this.code,
    this.exception,
    String? message,
  }) : message = message ?? exception?.toString();

  final String code;
  final Object? exception;
  final String? message;
}

class OidcSubjectTokenType {
  ///Indicates that the token is an OAuth 2.0 access token issued by the given
  ///authorization server.
  static const String accessToken =
      'urn:ietf:params:oauth:token-type:access_token';

  ///Indicates that the token is an OAuth 2.0 refresh token issued by the given
  ///authorization server.
  static const String refreshToken =
      'urn:ietf:params:oauth:token-type:refresh_token';

  /// Indicates that the token is an ID Token.
  static const String idToken = 'urn:ietf:params:oauth:token-type:id_token';

  /// Indicates that the token is a base64url-encoded SAML 1.1 assertion.
  static const String saml1 = 'urn:ietf:params:oauth:token-type:saml1';

  /// Indicates that the token is a base64url-encoded SAML 2.0 assertion.
  static const String saml2 = 'urn:ietf:params:oauth:token-type:saml2';
}

class OidcGrantType {
  static const String tokenExchange =
      'urn:ietf:params:oauth:grant-type:token-exchange';

  static const String refreshToken = 'refresh_token';

  static const String password = 'password';
}

/// Specifies how the Authorization Server displays the authentication and
/// consent user interface pages to the End-User
enum OidcDisplayValue {
  /// The Authorization Server SHOULD display the authentication and consent UI
  /// consistent with a full User Agent page view. If the display parameter is
  /// not specified, this is the default display mode.
  page,

  /// The Authorization Server SHOULD display the authentication and consent UI
  /// consistent with a popup User Agent window. The popup User Agent window
  /// should be of an appropriate size for a login-focused dialog and should not
  ///  obscure the entire window that it is popping up over.
  popup,

  /// The Authorization Server SHOULD display the authentication and consent UI
  /// consistent with a device that leverages a touch interface.
  touch,

  /// The Authorization Server SHOULD display the authentication and consent UI
  /// consistent with a "feature phone" type display
  wap,
}

/// Specifies whether the Authorization Server prompts the End-User for
/// reauthentication and consent.
enum OidcPromptValue {
  /// The Authorization Server MUST NOT display any authentication or consent
  /// user interface pages. An error is returned if an End-User is not already
  /// authenticated or the Client does not have pre-configured consent for the
  /// requested Claims or does not fulfill other conditions for processing the
  /// request.
  none,

  /// The Authorization Server SHOULD prompt the End-User for reauthentication.
  login,

  /// The Authorization Server SHOULD prompt the End-User for consent before
  /// returning information to the Client.
  consent,

  /// The Authorization Server SHOULD prompt the End-User to select a user
  /// account. This enables an End-User who has multiple accounts at the
  /// Authorization Server to select amongst the multiple accounts that they
  /// might have current sessions for.
  selectAccount,
}

class OidcConfig {
  /// {@macro oidc_config}
  const OidcConfig({
    required this.clientId,
    required this.discoveryUrl,
    required this.redirectUrl,
    this.scope = const [],
  });

  final String clientId;
  final String redirectUrl;
  final String discoveryUrl;
  final List<String> scope;
}

class OidcToken {
  const OidcToken({
    required this.accessToken,
    this.expiresIn,
    this.tokenType,
    this.refreshToken,
    this.idToken,
  });

  final String accessToken;
  final int? expiresIn;
  final String? tokenType;
  final String? refreshToken;
  final String? idToken;

  bool get accessTokenExpired => expiresIn != null && expiresIn! <= 0;
}

class AuthenticateParams {
  const AuthenticateParams({
    required this.clientId,
    required this.redirectUrl,
    required this.discoveryUrl,
    this.scopes = const [],
    this.parameters,
  });

  final String clientId;
  final String redirectUrl;
  final String discoveryUrl;
  final List<String> scopes;
  final Map<String, String>? parameters;
}

class ExchangeTokenParams {
  const ExchangeTokenParams({
    required this.grantType,
    required this.clientId,
    required this.redirectUrl,
    required this.discoveryUrl,
    this.scopes = const [],
    this.parameters,
  });

  final String grantType;
  final String clientId;
  final String redirectUrl;
  final String discoveryUrl;
  final List<String> scopes;
  final Map<String, String>? parameters;
}

class RefreshTokenParams {
  const RefreshTokenParams({
    required this.clientId,
    required this.redirectUrl,
    required this.discoveryUrl,
    required this.refreshToken,
  });

  final String clientId;
  final String redirectUrl;
  final String discoveryUrl;
  final String refreshToken;
}
