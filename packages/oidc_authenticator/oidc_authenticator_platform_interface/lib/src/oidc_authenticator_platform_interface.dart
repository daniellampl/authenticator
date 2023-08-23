import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class OidcAuthenticatorPlatform extends PlatformInterface {
  /// Constructs a OpeninSigninPlatform.
  OidcAuthenticatorPlatform() : super(token: _token);

  static final Object _token = Object();

  static OidcAuthenticatorPlatform _instance = _PlaceholderPlatformImpl();

  /// The default instance of [OidcAuthenticatorPlatform] to use.
  static OidcAuthenticatorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OidcAuthenticatorPlatform] when
  /// they register themselves.
  static set instance(OidcAuthenticatorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<OidcToken> authenticate(AuthenticateParams params) {
    throw UnimplementedError(
      'authenticate is not implemented on the current platform.',
    );
  }

  Future<OidcToken> exchangeToken(ExchangeTokenParams params) {
    throw UnimplementedError(
      'exchangeToken is not implemented on the current platform.',
    );
  }

  Future<OidcToken> refreshToken(RefreshTokenParams params) {
    throw UnimplementedError(
      'refreshToken is not implemented on the current platform.',
    );
  }
}

class _PlaceholderPlatformImpl extends OidcAuthenticatorPlatform {}
