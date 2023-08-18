import 'dart:async';
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';
import 'package:oidc_client/oidc_client.dart';

class OidcAuthenticatorWeb extends OidcAuthenticatorPlatform {
  OidcAuthenticatorWeb();

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

    final authWindow = _openBrowserTab(url: flow.authenticationUri);

    try {
      final token = await _authorize(flow: flow);
      if (token == null) {
        // TODO(daniellampl): adjust exception
        throw Exception();
      }
      return token;
    } catch (e) {
      rethrow;
    } finally {
      authWindow.close();
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
      // TODO(daniellampl): make sure the right parameters are getting sent
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

  html.WindowBase _openBrowserTab({required Uri url}) {
    return html.window.open(url.toString(), '_blank');
  }

  Future<OidcToken?> _authorize({required Flow flow}) async {
    final c = Completer<OidcToken?>();

    await html.window.onMessage.first.then((event) async {
      final uri = Uri.parse(event.data.toString());
      final tokenResponse = await flow.callback(uri.queryParameters);

      c.complete(tokenResponse.toOidcToken());
    });

    return c.future;
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
