import 'package:authenticator/authenticator.dart';
import 'package:authenticator_storage/authenticator_storage.dart';
import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';

const _hiveAccessTokenKey = 'AUTHENTICATOR_ACCESS_TOKEN';
const _hiveAccessTokenExpirationKey = 'AUTHENTICATOR_ACCESS_TOKEN_EXPIRES_IN';
const _hiveTokenTypeKey = 'AUTHENTICATOR_TOKEN_TYPE';
const _hiveRefreshTokenKey = 'AUTHENTICATOR_REFRESH_TOKEN';
const _hiveIdTokenKey = 'AUTHENTICATOR_ID_TOKEN';

class OidcTokenStorage extends AuthenticatorStorage<OidcToken> {
  OidcTokenStorage({
    SecureAuthenticatorStorage? storage,
  }) : _storage = storage ?? SecureAuthenticatorStorage();

  final SecureAuthenticatorStorage _storage;

  @override
  Future<void> persistToken(OidcToken token) async {
    await Future.wait([
      _storage.write(_hiveAccessTokenKey, token.accessToken),
      if (token.expiresIn != null)
        _storage.write(
          _hiveAccessTokenExpirationKey,
          token.expiresIn!.toString(),
        ),
      if (token.tokenType != null)
        _storage.write(_hiveTokenTypeKey, token.tokenType!),
      if (token.refreshToken != null)
        _storage.write(_hiveRefreshTokenKey, token.refreshToken!),
      if (token.idToken != null)
        _storage.write(_hiveIdTokenKey, token.idToken!),
    ]);
  }

  @override
  Future<void> removePersistedToken() async {
    await Future.wait([
      _storage.delete(_hiveAccessTokenKey),
      _storage.delete(_hiveAccessTokenExpirationKey),
      _storage.delete(_hiveTokenTypeKey),
      _storage.delete(_hiveRefreshTokenKey),
      _storage.delete(_hiveIdTokenKey),
    ]);
  }

  @override
  Future<OidcToken?> get token async {
    final tokenValues = await Future.wait<dynamic>([
      _storage.read(_hiveAccessTokenKey),
      _storage.read(_hiveAccessTokenExpirationKey),
      _storage.read(_hiveTokenTypeKey),
      _storage.read(_hiveRefreshTokenKey),
      _storage.read(_hiveIdTokenKey),
    ]);

    final accessToken = tokenValues[0] as String?;
    if (accessToken == null) {
      return null;
    }

    return OidcToken(
      accessToken: accessToken,
      expiresIn: tokenValues[1] != null ? int.parse(tokenValues[1]) : null,
      tokenType: tokenValues[2] as String?,
      refreshToken: tokenValues[3] as String?,
      idToken: tokenValues[4] as String?,
    );
  }
}
