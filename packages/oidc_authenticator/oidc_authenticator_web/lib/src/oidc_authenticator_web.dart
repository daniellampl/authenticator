import 'dart:async';
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';
import 'package:oidc_client/oidc_client.dart';

class OidcAuthenticatorWeb extends OidcAuthenticatorPlatform {
  static void registerWith(Registrar registrar) {
    OidcAuthenticatorPlatform.instance = OidcAuthenticatorWeb();
  }

  @override
  Future<OidcToken> authenticate(AuthenticateParams params) async {
    final client = await _getClient(
      clientId: params.clientId,
      discoveryUrl: params.discoveryUrl,
    );

    final flow = Flow.authorizationCodeWithPKCE(
      client: client,
      redirectUrl: Uri.parse(params.redirectUrl),
      scopes: params.scopes,
    );

    return _authenticateViaPopup(flow: flow);
  }

  Future<OidcToken> _authenticateViaPopup({required Flow flow}) {
    final completer = Completer<OidcToken>();

    final authWindow = html.window.open(
      flow.authenticationUri.toString(),
      'Auth',
      'width=800, height=900, scrollbars=yes',
    );

    html.window.onMessage.listen((event) async {
      final uri = Uri.parse(event.data.toString());
      final tokenResponse = await flow.callback(uri.queryParameters);

      completer.complete(tokenResponse.toOidcToken());

      authWindow.close();
    });

    return completer.future;
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
}

extension on TokenResponse {
  OidcToken toOidcToken() {
    return OidcToken(
      accessToken: accessToken!,
      expiresIn: expiresIn,
      idToken: idToken.toString(),
      refreshToken: refreshToken,
      tokenType: tokenType,
    );
  }
}
