import 'dart:math';
import 'package:authenticator/authenticator.dart';
import 'package:authenticator_storage/authenticator_storage.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

const _noTokenResponseReceivedErrorCode = 'no_token_response_received';
const _unknownErrorCode = 'unknown_error';

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

///
class TokenExchangeSignInProvider extends SignInProvider {
  const TokenExchangeSignInProvider({
    required this.grantType,
    this.subjectToken,
    this.subjectTokenType,
    this.scope,
    this.additionalParameters,
  });

  final String grantType;
  final String? subjectToken;
  final String? subjectTokenType;
  final List<String>? scope;
  final Map<String, String>? additionalParameters;
}

///
class AuthenticateSignInProvider extends SignInProvider {
  const AuthenticateSignInProvider({
    this.scope,
    this.prompt,
    this.loginHint,
    this.additionalParameters,
    bool? preferEphemeralSession,
  }) : preferEphemeralSession = preferEphemeralSession ?? false;

  final List<String>? scope;
  final List<OidcPromptValue>? prompt;
  final String? loginHint;
  final bool preferEphemeralSession;
  final Map<String, String>? additionalParameters;
}

///
class OidcAuthenticatorDelegate
    implements RefreshAuthenticatorDelegate<OidcToken> {
  const OidcAuthenticatorDelegate({
    required this.config,
    FlutterAppAuth? appAuth,
  }) : _appAuth = appAuth ?? const FlutterAppAuth();

  final OidcConfig config;
  final FlutterAppAuth _appAuth;

  @override
  Future<OidcToken> refreshToken(OidcToken token) async {
    final TokenResponse? tokenResponse;

    try {
      tokenResponse = await _appAuth.token(
        TokenRequest(
          config.clientId,
          config.redirectUrl,
          refreshToken: token.refreshToken,
          discoveryUrl: config.discoveryUrl,
          grantType: GrantType.refreshToken,
        ),
      );
    } catch (e) {
      throw OidcAuthenticatorException(
        code: _unknownErrorCode,
        exception: e,
      );
    }

    if (tokenResponse == null) {
      throw OidcAuthenticatorException(
        code: _noTokenResponseReceivedErrorCode,
        message: 'No token response received from identity provider!',
      );
    }

    return tokenResponse.toOidcToken();
  }

  @override
  Future<OidcToken> signIn(SignInProvider signInProvider) async {
    if (signInProvider is TokenExchangeSignInProvider) {
      return _exchangeToken(signInProvider);
    } else if (signInProvider is AuthenticateSignInProvider) {
      return _authenticate(signInProvider);
    } else {
      throw UnimplementedError();
    }
  }

  Future<OidcToken> _authenticate(AuthenticateSignInProvider provider) async {
    final AuthorizationTokenResponse? tokenResponse;

    try {
      tokenResponse = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          config.clientId,
          config.redirectUrl,
          discoveryUrl: config.discoveryUrl,
          scopes: _transformScopes(provider.scope ?? config.scope),
          promptValues: provider.prompt != null
              ? provider.prompt!.map(_promptValueToString).toSet().toList()
              : [],
          loginHint: provider.loginHint,
          additionalParameters: provider.additionalParameters,
          preferEphemeralSession: provider.preferEphemeralSession,
        ),
      );
    } catch (e) {
      throw OidcAuthenticatorException(
        code: _unknownErrorCode,
        exception: e,
      );
    }

    if (tokenResponse == null) {
      throw OidcAuthenticatorException(
        code: _noTokenResponseReceivedErrorCode,
        message: 'No token response received from identity provider',
      );
    }

    return tokenResponse.toOidcToken();
  }

  Future<OidcToken> _exchangeToken(TokenExchangeSignInProvider provider) async {
    final parameters = <String, String>{};

    if (provider.subjectToken != null &&
        (provider.additionalParameters != null &&
            !provider.additionalParameters!.containsKey('subject_token'))) {
      parameters['subject_token'] = provider.subjectToken!;
    }

    if (provider.subjectTokenType != null &&
        (provider.additionalParameters != null &&
            !provider.additionalParameters!
                .containsKey('subject_token_type'))) {
      parameters['subject_token_type'] = provider.subjectTokenType!;
    }

    if (provider.additionalParameters != null) {
      parameters.addAll(provider.additionalParameters!);
    }

    final TokenResponse? tokenResponse;

    try {
      tokenResponse = await _appAuth.token(
        TokenRequest(
          config.clientId,
          config.redirectUrl,
          discoveryUrl: config.discoveryUrl,
          scopes: _transformScopes(provider.scope ?? config.scope),
          grantType: provider.grantType,
          additionalParameters: parameters,
        ),
      );
    } catch (e) {
      throw OidcAuthenticatorException(
        code: _unknownErrorCode,
        exception: e,
      );
    }

    if (tokenResponse == null) {
      throw OidcAuthenticatorException(
        code: _noTokenResponseReceivedErrorCode,
        message: 'No token response received from identity provider on '
            'token exchange!',
      );
    }

    return tokenResponse.toOidcToken();
  }

  List<String> _transformScopes(List<String>? scopes) {
    final result = <String>[];

    if (scopes != null) {
      result.addAll(scopes);
    }

    if (!result.contains('openid')) {
      result.add('openid');
    }

    return result.toSet().toList();
  }

  String _promptValueToString(OidcPromptValue prompt) {
    switch (prompt) {
      case OidcPromptValue.none:
        return 'none';
      case OidcPromptValue.login:
        return 'login';
      case OidcPromptValue.consent:
        return 'consent';
      case OidcPromptValue.selectAccount:
        return 'select_account';
    }
  }
}

class OidcAuthenticator extends RefreshAuthenticator<OidcToken> {
  OidcAuthenticator({
    required this.config,
    FlutterAppAuth appAuth = const FlutterAppAuth(),
    OidcAuthenticatorDelegate? delegate,
  })  : _appAuth = appAuth,
        super(
          delegate: delegate ??
              OidcAuthenticatorDelegate(
                config: config,
                appAuth: appAuth,
              ),
          localStorage: _OidcTokenStorage(),
        );

  final OidcConfig config;
  final FlutterAppAuth _appAuth;

  Future<void> authenticate({
    List<String>? scope,
    String? nonce,
    OidcDisplayValue? display,
    List<OidcPromptValue>? prompt,
    int? maxAge,
    List<String>? uiLocales,
    String? idTokenHint,
    String? loginHint,
    List<String>? acrValues,
    Map<String, String>? additionalParameters,
    bool? preferEphemeralSession,
  }) async {
    return super.signIn(
      AuthenticateSignInProvider(
        scope: scope,
        prompt: prompt,
        loginHint: loginHint,
        preferEphemeralSession: preferEphemeralSession,
        additionalParameters: _builAuthenticateAdditionalParameters(
          nonce: nonce,
          display: display,
          maxAge: maxAge,
          uiLocales: uiLocales,
          idTokenHint: idTokenHint,
          acrValues: acrValues,
          additionalParameters: additionalParameters,
        ),
      ),
    );
  }

  Future<void> exchangeToken({
    required String grantType,
    String? subjectToken,
    String? subjectTokenType,
    List<String>? scope,
    Map<String, String>? additionalParameters,
  }) async {
    return super.signIn(
      TokenExchangeSignInProvider(
        subjectToken: subjectToken,
        subjectTokenType: subjectTokenType,
        grantType: grantType,
        scope: scope,
        additionalParameters: additionalParameters,
      ),
    );
  }

  Future<void> endSession({
    String? idToken,
    String? postLogoutRedirectUrl,
    Map<String, String>? additionalParameters,
  }) async {
    await _appAuth.endSession(
      EndSessionRequest(
        idTokenHint: idToken,
        discoveryUrl: config.discoveryUrl,
        postLogoutRedirectUrl: postLogoutRedirectUrl,
        additionalParameters: additionalParameters,
      ),
    );
  }

  ///
  Map<String, String> _builAuthenticateAdditionalParameters({
    String? nonce,
    OidcDisplayValue? display,
    int? maxAge,
    List<String>? uiLocales,
    String? idTokenHint,
    List<String>? acrValues,
    Map<String, String>? additionalParameters,
  }) {
    final result = <String, String>{};

    if (additionalParameters != null && additionalParameters.isNotEmpty) {
      result.addAll(additionalParameters);
    }

    if (nonce != null) {
      result['nonce'] = nonce;
    }

    if (display != null) {
      result['display'] = _displayValueToString(display);
    }

    if (maxAge != null) {
      result['max_age'] = maxAge.toString();
    }

    if (uiLocales != null && uiLocales.isNotEmpty) {
      result['ui_locales'] = uiLocales.join(' ');
    }

    if (idTokenHint != null) {
      result['id_token_hint'] = idTokenHint;
    }

    if (acrValues != null && acrValues.isNotEmpty) {
      result['acr_values'] = acrValues.join(' ');
    }

    return result;
  }

  String _displayValueToString(OidcDisplayValue display) {
    switch (display) {
      case OidcDisplayValue.page:
        return 'page';
      case OidcDisplayValue.popup:
        return 'popup';
      case OidcDisplayValue.touch:
        return 'touch';
      case OidcDisplayValue.wap:
        return 'wap';
    }
  }
}

extension on TokenResponse {
  OidcToken toOidcToken() {
    if (accessToken == null) {
      throw OidcAuthenticatorException(
        code: 'no_access_token_available',
        message:
            'The received token response does not include an access_token!',
      );
    }

    return OidcToken(
      accessToken: accessToken!,
      accessTokenExpiration: accessTokenExpirationDateTime,
      tokenType: tokenType,
      refreshToken: refreshToken,
      idToken: idToken,
    );
  }
}

class OidcSignInProvider extends SignInProvider {
  const OidcSignInProvider();
}

class OidcToken extends AuthenticatorToken {
  const OidcToken({
    required this.accessToken,
    this.accessTokenExpiration,
    this.tokenType,
    this.refreshToken,
    this.idToken,
  });

  final String accessToken;
  final DateTime? accessTokenExpiration;
  final String? tokenType;
  final String? refreshToken;
  final String? idToken;

  @override
  String get authorizationHeader => '$tokenType $accessToken';

  int? get accessTokenExpiresIn => accessTokenExpiration != null
      ? max(
          accessTokenExpiration!.difference(DateTime.now().toUtc()).inSeconds,
          0,
        )
      : null;

  bool get accessTokenExpired =>
      accessTokenExpiresIn != null && accessTokenExpiresIn! <= 0;
}

const _hiveAccessTokenKey = 'AUTHENTICATOR_ACCESS_TOKEN';
const _hiveAccessTokenExpirationKey = 'AUTHENTICATOR_ACCESS_TOKEN_EXPIRATION';
const _hiveTokenTypeKey = 'AUTHENTICATOR_TOKEN_TYPE';
const _hiveRefreshTokenKey = 'AUTHENTICATOR_REFRESH_TOKEN';
const _hiveIdTokenKey = 'AUTHENTICATOR_ID_TOKEN';

class _OidcTokenStorage extends AuthenticatorStorage<OidcToken> {
  _OidcTokenStorage({
    SecureAuthenticatorStorage? storage,
  }) : _storage = storage ?? SecureAuthenticatorStorage();

  final SecureAuthenticatorStorage _storage;

  @override
  Future<void> initialize() async {
    // this method should become obsolte once enough users migrated.
    try {
      await _storage.migrate([
        _hiveAccessTokenKey,
        _hiveAccessTokenExpirationKey,
        _hiveTokenTypeKey,
        _hiveRefreshTokenKey,
        _hiveIdTokenKey,
      ]);
    } catch (e) {
      // ignore errors, we just don't migrate.
    }
  }

  @override
  Future<void> persistToken(OidcToken token) async {
    await Future.wait([
      _storage.writeTokenvalue(_hiveAccessTokenKey, token.accessToken),
      if (token.accessTokenExpiration != null)
        _storage.writeTokenvalue(
          _hiveAccessTokenExpirationKey,
          token.accessTokenExpiration!.toIso8601String(),
        ),
      if (token.tokenType != null)
        _storage.writeTokenvalue(_hiveTokenTypeKey, token.tokenType!),
      if (token.refreshToken != null)
        _storage.writeTokenvalue(_hiveRefreshTokenKey, token.refreshToken!),
      if (token.idToken != null)
        _storage.writeTokenvalue(_hiveIdTokenKey, token.idToken!),
    ]);
  }

  @override
  Future<void> removePersistedToken() async {
    await Future.wait([
      _storage.deleteTokenValue(_hiveAccessTokenKey),
      _storage.deleteTokenValue(_hiveAccessTokenExpirationKey),
      _storage.deleteTokenValue(_hiveTokenTypeKey),
      _storage.deleteTokenValue(_hiveRefreshTokenKey),
      _storage.deleteTokenValue(_hiveIdTokenKey),
    ]);
  }

  @override
  Future<OidcToken?> get token async {
    final tokenValues = await Future.wait<dynamic>([
      _storage.readTokenValue(_hiveAccessTokenKey),
      _storage.readTokenValue(_hiveAccessTokenExpirationKey),
      _storage.readTokenValue(_hiveTokenTypeKey),
      _storage.readTokenValue(_hiveRefreshTokenKey),
      _storage.readTokenValue(_hiveIdTokenKey),
    ]);

    final accessToken = tokenValues[0] as String?;
    if (accessToken == null) {
      return null;
    }

    return OidcToken(
      accessToken: accessToken,
      accessTokenExpiration: tokenValues[1] != null
          ? DateTime.parse(tokenValues[1] as String)
          : null,
      tokenType: tokenValues[2] as String?,
      refreshToken: tokenValues[3] as String?,
      idToken: tokenValues[4] as String?,
    );
  }
}
