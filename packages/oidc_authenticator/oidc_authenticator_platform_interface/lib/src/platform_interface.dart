import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';
import 'package:oidc_authenticator_platform_interface/src/method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class OidcAuthenticatorPlatform extends PlatformInterface {
  /// Constructs a OpeninSigninPlatform.
  OidcAuthenticatorPlatform() : super(token: _token);

  static final Object _token = Object();

  static OidcAuthenticatorPlatform _instance = MethodChannelOpeninSignin();

  /// The default instance of [OidcAuthenticatorPlatform] to use.
  ///
  /// Defaults to [MethodChannelOpeninSignin].
  static OidcAuthenticatorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OidcAuthenticatorPlatform] when
  /// they register themselves.
  static set instance(OidcAuthenticatorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<OidcToken> authenticate(AuthenticateParams params);

  Future<OidcToken> exchangeToken(ExchangeTokenParams params);

  Future<OidcToken> refreshToken(RefreshTokenParams params);
}
