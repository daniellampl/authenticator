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
      if (token.expiresIn != null)
        _storage.writeTokenvalue(
          _hiveAccessTokenExpirationKey,
          token.expiresIn!.toString(),
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
      expiresIn: tokenValues[1] != null ? int.parse(tokenValues[1]) : null,
      tokenType: tokenValues[2] as String?,
      refreshToken: tokenValues[3] as String?,
      idToken: tokenValues[4] as String?,
    );
  }
}
