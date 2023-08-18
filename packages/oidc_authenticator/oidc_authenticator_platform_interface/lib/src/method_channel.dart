import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oidc_authenticator_platform_interface/src/model/model.dart';
import 'package:oidc_authenticator_platform_interface/src/platform_interface.dart';

/// An implementation of [OidcAuthenticatorPlatform] that uses method channels.
class MethodChannelOpeninSignin extends OidcAuthenticatorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('oidc_authenticator');

  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<OidcToken> authenticate(AuthenticateParams provider) {
    // TODO: implement authenticate
    throw UnimplementedError();
  }

  @override
  Future<OidcToken> exchangeToken(ExchangeTokenParams provider) {
    // TODO: implement exchangeToken
    throw UnimplementedError();
  }

  @override
  Future<OidcToken> refreshToken(RefreshTokenParams token) {
    // TODO: implement refreshToken
    throw UnimplementedError();
  }
}
