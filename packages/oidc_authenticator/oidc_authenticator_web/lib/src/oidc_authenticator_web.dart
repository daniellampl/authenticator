import 'dart:async';
import 'dart:html';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';
import 'package:oidc_client/oidc_client.dart';

class OidcAuthenticatorWeb extends OidcAuthenticatorPlatform {
  static void registerWith(Registrar registrar) {
    OidcAuthenticatorPlatform.instance = OidcAuthenticatorWeb();
  }

  @override
  Future<OidcToken> authenticate(AuthenticateParams params) async {
    final authenticationWindow = _openAuthenticationWindow();

    try {
      final client = await _getClient(
        clientId: params.clientId,
        discoveryUrl: params.discoveryUrl,
      );

      final flow = Flow.authorizationCodeWithPKCE(
        client: client,
        redirectUrl: Uri.parse(params.redirectUrl),
        scopes: params.scopes,
      );

      authenticationWindow.location.href = flow.authenticationUri.toString();

      final token = await _authorize(flow: flow);
      if (token == null) {
        throw Exception('No token reseive from callback!');
      }

      return token;
    } catch (e) {
      authenticationWindow.close();
      rethrow;
    }
  }

  @override
  Future<OidcToken> exchangeToken(ExchangeTokenParams params) async {
    final client = await _getClient(
      clientId: params.clientId,
      discoveryUrl: params.discoveryUrl,
    );

    final token = await client.getToken(
      grantType: params.grantType,
      additionalParameters: params.parameters,
    );

    return token.toOidcToken();
  }

  @override
  Future<OidcToken> refreshToken(RefreshTokenParams params) async {
    final client = await _getClient(
      discoveryUrl: params.discoveryUrl,
      clientId: params.clientId,
    );

    final tokenResponse =
        await client.refresh(refreshToken: params.refreshToken);
    return tokenResponse.toOidcToken();
  }

  Future<OidcClient> _getClient({
    required String discoveryUrl,
    required String clientId,
  }) async {
    final issuer = await Issuer.discover(
      Uri.parse(discoveryUrl),
    );
    return OidcClient(
      issuer: issuer,
      clientId: clientId,
    );
  }

  WindowBase _openAuthenticationWindow() {
    return window.open('', '_blank');
  }

  Future<OidcToken?> _authorize({required Flow flow}) async {
    await for (final MessageEvent event in window.onMessage) {
      final uri = Uri.parse(event.data.toString());
      final tokenResponse = await flow.callback(uri.queryParameters);
      return tokenResponse.toOidcToken();
    }

    throw PlatformException(
      code: 'error',
      message: 'No incoming window.onMessage event',
    );
  }
}

extension on TokenResponse {
  OidcToken toOidcToken() {
    return OidcToken(
      accessToken: accessToken!,
      refreshToken: refreshToken,
      // accessTokenExpiration: ,
      idToken: idToken.toString(),
      tokenType: tokenType,
    );
  }
}
