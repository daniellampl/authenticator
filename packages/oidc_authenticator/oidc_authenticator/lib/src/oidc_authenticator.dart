import 'package:authenticator/authenticator.dart';
import 'package:oidc_authenticator/src/oidc_token_storage.dart';
import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';

class OidcAuthenticator extends RefreshAuthenticator<OidcToken> {
  OidcAuthenticator({
    required this.config,
  }) : super(
          delegate: OidcAuthenticatorDelegate(
            OidcAuthenticatorPlatform.instance,
            config,
          ),
          localStorage: OidcTokenStorage(),
        );

  final OidcAuthenticatorPlatform platform = OidcAuthenticatorPlatform.instance;
  final OidcConfig config;

  Future<void> authenticate({
    List<String>? scope,
    String? clientId,
    String? redirectUrl,
    String? nonce,
    OidcDisplayValue? display,
    List<OidcPromptValue>? prompt,
    int? maxAge,
    List<String>? uiLocales,
    String? idTokenHint,
    String? loginHint,
    List<String>? acrValues,
    Map<String, String>? additionalParameters,
  }) async {
    return super.signIn(
      _AuthenticateSignInProvider(
        scope: _transformScopes(scope ?? config.scope),
        clientId: clientId ?? config.clientId,
        redirectUrl: redirectUrl ?? config.redirectUrl,
        discoveryUrl: config.discoveryUrl,
        parameters: _builAuthenticateAdditionalParameters(
          nonce: nonce,
          display: display,
          maxAge: maxAge,
          uiLocales: uiLocales,
          idTokenHint: idTokenHint,
          loginHint: loginHint,
          acrValues: acrValues,
          additionalParameters: additionalParameters,
        ),
      ),
    );
  }

  Future<void> exchangeToken({
    required String grantType,
    List<String>? scope,
    Map<String, String>? additionalParameters,
  }) {
    return super.signIn(
      _TokenExchangeSignInProvider(
        clientId: config.clientId,
        redirectUrl: config.redirectUrl,
        discoveryUrl: config.discoveryUrl,
        grantType: grantType,
        scope: _transformScopes(scope ?? config.scope),
        parameters: additionalParameters,
      ),
    );
  }

  List<String> _transformScopes(List<String>? scopes) {
    final result = <String>[];

    if (scopes != null) {
      result.addAll(scopes);
    }

    if (!result.contains('openid')) {
      result.add('openid');
    }

    return result.toSet().toList();
  }

  ///
  Map<String, String> _builAuthenticateAdditionalParameters({
    String? nonce,
    OidcDisplayValue? display,
    int? maxAge,
    List<String>? uiLocales,
    String? idTokenHint,
    String? loginHint,
    List<String>? acrValues,
    OidcPromptValue? prompt,
    Map<String, String>? additionalParameters,
  }) {
    final result = <String, String>{};

    if (additionalParameters != null && additionalParameters.isNotEmpty) {
      result.addAll(additionalParameters);
    }

    if (nonce != null) {
      result['nonce'] = nonce;
    }

    if (display != null) {
      result['display'] = _displayValueToString(display);
    }

    if (maxAge != null) {
      result['max_age'] = maxAge.toString();
    }

    if (uiLocales != null && uiLocales.isNotEmpty) {
      result['ui_locales'] = uiLocales.join(' ');
    }

    if (idTokenHint != null) {
      result['id_token_hint'] = idTokenHint;
    }

    if (prompt != null) {
      result['prompt'] = _promptValueToString(prompt);
    }

    if (loginHint != null) {
      result['login_hint'] = loginHint;
    }

    if (acrValues != null && acrValues.isNotEmpty) {
      result['acr_values'] = acrValues.join(' ');
    }

    if (prompt != null) {
      result['prompt'] = _promptValueToString(prompt);
    }

    return result;
  }

  String _displayValueToString(OidcDisplayValue display) {
    switch (display) {
      case OidcDisplayValue.page:
        return 'page';
      case OidcDisplayValue.popup:
        return 'popup';
      case OidcDisplayValue.touch:
        return 'touch';
      case OidcDisplayValue.wap:
        return 'wap';
    }
  }

  String _promptValueToString(OidcPromptValue prompt) {
    switch (prompt) {
      case OidcPromptValue.none:
        return 'none';
      case OidcPromptValue.login:
        return 'login';
      case OidcPromptValue.consent:
        return 'consent';
      case OidcPromptValue.selectAccount:
        return 'select_account';
    }
  }
}

class OidcAuthenticatorDelegate
    implements RefreshAuthenticatorDelegate<OidcToken> {
  OidcAuthenticatorDelegate(
    this._platform,
    this.config,
  );

  final OidcAuthenticatorPlatform _platform;
  final OidcConfig config;

  @override
  Future<OidcToken> refreshToken(OidcToken token) {
    if (token.refreshToken == null) {
      throw Exception('Cannot refresh session. No refresh_token available!');
    }

    return _platform.refreshToken(
      RefreshTokenParams(
        clientId: config.clientId,
        redirectUrl: config.redirectUrl,
        discoveryUrl: config.discoveryUrl,
        refreshToken: token.refreshToken!,
      ),
    );
  }

  @override
  Future<OidcToken> signIn(SignInProvider signInProvider) {
    if (signInProvider is _AuthenticateSignInProvider) {
      return _platform.authenticate(
        AuthenticateParams(
          clientId: signInProvider.clientId ?? config.clientId,
          redirectUrl: signInProvider.redirectUrl ?? config.redirectUrl,
          discoveryUrl: signInProvider.discoveryUrl ?? config.discoveryUrl,
          scopes: signInProvider.scope,
          parameters: signInProvider.parameters,
        ),
      );
    } else if (signInProvider is _TokenExchangeSignInProvider) {
      return _platform.exchangeToken(
        ExchangeTokenParams(
          clientId: signInProvider.clientId ?? config.clientId,
          redirectUrl: signInProvider.redirectUrl ?? config.redirectUrl,
          discoveryUrl: signInProvider.discoveryUrl ?? config.discoveryUrl,
          grantType: signInProvider.grantType,
          scopes: signInProvider.scope,
          parameters: signInProvider.parameters,
        ),
      );
    } else {
      throw UnimplementedError();
    }
  }
}

///
class _TokenExchangeSignInProvider extends SignInProvider {
  const _TokenExchangeSignInProvider({
    required this.grantType,
    this.scope = const [],
    this.clientId,
    this.redirectUrl,
    this.discoveryUrl,
    this.parameters,
  });

  final String? clientId;
  final String? redirectUrl;
  final String? discoveryUrl;
  final String grantType;
  final List<String> scope;
  final Map<String, String>? parameters;
}

///
class _AuthenticateSignInProvider extends SignInProvider {
  const _AuthenticateSignInProvider({
    this.scope = const [],
    this.clientId,
    this.redirectUrl,
    this.discoveryUrl,
    this.parameters,
  });

  final List<String> scope;
  final String? clientId;
  final String? redirectUrl;
  final String? discoveryUrl;
  final Map<String, String>? parameters;
}
