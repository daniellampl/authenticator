import 'package:authenticator_storage/authenticator_storage.dart';
import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';

const _hiveAccessTokenKey = 'AUTHENTICATOR_ACCESS_TOKEN';
const _hiveAccessTokenExpirationKey = 'AUTHENTICATOR_ACCESS_TOKEN_EXPIRES_IN';
const _hiveTokenTypeKey = 'AUTHENTICATOR_TOKEN_TYPE';
const _hiveRefreshTokenKey = 'AUTHENTICATOR_REFRESH_TOKEN';
const _hiveIdTokenKey = 'AUTHENTICATOR_ID_TOKEN';

class OidcTokenStorage extends SecureAuthenticatorStorage<OidcToken> {
  @override
  Future<void> persistToken(OidcToken token) async {
    await Future.wait([
      writeTokenvalue(_hiveAccessTokenKey, token.accessToken),
      writeTokenvalue(
        _hiveAccessTokenExpirationKey,
        token.expiresIn,
      ),
      writeTokenvalue(_hiveTokenTypeKey, token.tokenType),
      writeTokenvalue(_hiveRefreshTokenKey, token.refreshToken),
      writeTokenvalue(_hiveIdTokenKey, token.idToken),
    ]);
  }

  @override
  Future<void> removePersistedToken() async {
    await Future.wait([
      deleteTokenValue(_hiveAccessTokenKey),
      deleteTokenValue(_hiveAccessTokenExpirationKey),
      deleteTokenValue(_hiveTokenTypeKey),
      deleteTokenValue(_hiveRefreshTokenKey),
      deleteTokenValue(_hiveIdTokenKey),
    ]);
  }

  @override
  Future<OidcToken?> get token async {
    final tokenValues = await Future.wait<dynamic>([
      readTokenValue(_hiveAccessTokenKey),
      readTokenValue(_hiveAccessTokenExpirationKey),
      readTokenValue(_hiveTokenTypeKey),
      readTokenValue(_hiveRefreshTokenKey),
      readTokenValue(_hiveIdTokenKey),
    ]);

    final accessToken = tokenValues[0] as String?;
    if (accessToken == null) {
      return null;
    }

    return OidcToken(
      accessToken: accessToken,
      expiresIn: tokenValues[1] as int?,
      tokenType: tokenValues[2] as String?,
      refreshToken: tokenValues[3] as String?,
      idToken: tokenValues[4] as String?,
    );
  }
}
