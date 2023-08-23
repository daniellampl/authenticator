import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';

const _noTokenResponseReceivedErrorCode = 'no_token_response_received';
const _noAccessTokenAvailableErrorCode = 'no_access_token_available';
const _unknownErrorCode = 'unknown_error';

class OidcAuthenticatorApp extends OidcAuthenticatorPlatform {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  static void registerWith() {
    OidcAuthenticatorPlatform.instance = OidcAuthenticatorApp();
  }

  @override
  Future<OidcToken> authenticate(AuthenticateParams params) async {
    final AuthorizationTokenResponse? tokenResponse;

    try {
      tokenResponse = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          params.clientId,
          params.redirectUrl,
          discoveryUrl: params.discoveryUrl,
          scopes: params.scopes,
          additionalParameters: params.parameters,
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

  @override
  Future<OidcToken> exchangeToken(ExchangeTokenParams params) async {
    final TokenResponse? tokenResponse;

    try {
      tokenResponse = await _appAuth.token(
        TokenRequest(
          params.clientId,
          params.redirectUrl,
          grantType: params.grantType,
          discoveryUrl: params.discoveryUrl,
          scopes: params.scopes,
          additionalParameters: params.parameters,
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

  @override
  Future<OidcToken> refreshToken(RefreshTokenParams params) async {
    final TokenResponse? tokenResponse;

    try {
      tokenResponse = await _appAuth.token(
        TokenRequest(
          params.clientId,
          params.redirectUrl,
          discoveryUrl: params.discoveryUrl,
          refreshToken: params.refreshToken,
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
}

extension on TokenResponse {
  OidcToken toOidcToken() {
    if (accessToken == null) {
      throw OidcAuthenticatorException(
        code: _noAccessTokenAvailableErrorCode,
        message:
            'The received token response does not include an access_token!',
      );
    }

    return OidcToken(
      accessToken: accessToken!,
      // accessTokenExpiration: accessTokenExpirationDateTime,
      tokenType: tokenType,
      refreshToken: refreshToken,
      idToken: idToken,
    );
  }
}
