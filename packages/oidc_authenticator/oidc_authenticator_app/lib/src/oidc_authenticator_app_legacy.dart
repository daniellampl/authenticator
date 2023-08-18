// import 'dart:math';
// import 'package:authenticator/authenticator.dart';
// import 'package:authenticator_storage/authenticator_storage.dart';
// import 'package:flutter_appauth/flutter_appauth.dart';
// import 'package:oidc_authenticator_platform_interface/oidc_authenticator_platform_interface.dart';

// class OidcAuthenticatorApp extends RefreshAuthenticator<OidcToken>
//     implements OidcAuthenticatorPlatform {
//   OidcAuthenticatorApp({
//     required this.config,
//     FlutterAppAuth appAuth = const FlutterAppAuth(),
//     OidcAuthenticatorDelegate? delegate,
//   })  : _appAuth = appAuth,
//         super(
//           delegate: delegate ??
//               OidcAuthenticatorDelegate(
//                 config: config,
//                 appAuth: appAuth,
//               ),
//           localStorage: _OidcTokenStorage(),
//         );

//   final FlutterAppAuth _appAuth;
//   final OidcConfig config;

//   // static void registerWith() {
//   //   OidcAuthenticatorPlatform.instance = OidcAuthenticatorApp();
//   // }

//   @override
//   Future<void> authenticate(AuthenticateSignInProvider signInProvider) {
//     return super.signIn(signInProvider);
//   }

//   Future<void> exchangeToken({
//     required String grantType,
//     String? subjectToken,
//     String? subjectTokenType,
//     List<String>? scope,
//     Map<String, String>? additionalParameters,
//   }) async {
//     return super.signIn(
//       TokenExchangeSignInProvider(
//         subjectToken: subjectToken,
//         subjectTokenType: subjectTokenType,
//         grantType: grantType,
//         scope: scope,
//         additionalParameters: additionalParameters,
//       ),
//     );
//   }

//   Future<void> endSession({
//     String? idToken,
//     String? postLogoutRedirectUrl,
//     Map<String, String>? additionalParameters,
//   }) async {
//     await _appAuth.endSession(
//       EndSessionRequest(
//         idTokenHint: idToken,
//         discoveryUrl: config.discoveryUrl,
//         postLogoutRedirectUrl: postLogoutRedirectUrl,
//         additionalParameters: additionalParameters,
//       ),
//     );
//   }
// }

// const _noTokenResponseReceivedErrorCode = 'no_token_response_received';
// const _unknownErrorCode = 'unknown_error';

// ///
// class OidcAuthenticatorDelegate
//     implements RefreshAuthenticatorDelegate<OidcToken> {
//   const OidcAuthenticatorDelegate({
//     required this.config,
//     FlutterAppAuth? appAuth,
//   }) : _appAuth = appAuth ?? const FlutterAppAuth();

//   final OidcConfig config;
//   final FlutterAppAuth _appAuth;

//   @override
//   Future<OidcToken> refreshToken(OidcToken token) async {
//     final TokenResponse? tokenResponse;

//     try {
//       tokenResponse = await _appAuth.token(
//         TokenRequest(
//           config.clientId,
//           config.redirectUrl,
//           refreshToken: token.refreshToken,
//           discoveryUrl: config.discoveryUrl,
//           grantType: GrantType.refreshToken,
//         ),
//       );
//     } catch (e) {
//       throw OidcAuthenticatorException(
//         code: _unknownErrorCode,
//         exception: e,
//       );
//     }

//     if (tokenResponse == null) {
//       throw OidcAuthenticatorException(
//         code: _noTokenResponseReceivedErrorCode,
//         message: 'No token response received from identity provider!',
//       );
//     }

//     return tokenResponse.toOidcToken();
//   }

//   @override
//   Future<OidcToken> signIn(SignInProvider signInProvider) async {
//     if (signInProvider is TokenExchangeSignInProvider) {
//       return _exchangeToken(signInProvider);
//     } else if (signInProvider is AuthenticateSignInProvider) {
//       return _authenticate(signInProvider);
//     } else {
//       throw UnimplementedError();
//     }
//   }

//   Future<OidcToken> _authenticate(AuthenticateSignInProvider provider) async {
//     final AuthorizationTokenResponse? tokenResponse;

//     try {
//       tokenResponse = await _appAuth.authorizeAndExchangeCode(
//         AuthorizationTokenRequest(
//           config.clientId,
//           config.redirectUrl,
//           discoveryUrl: config.discoveryUrl,
//           scopes: _transformScopes(provider.scope ?? config.scope),
//           promptValues: provider.prompt != null
//               ? provider.prompt!.map(_promptValueToString).toSet().toList()
//               : [],
//           loginHint: provider.loginHint,
//           additionalParameters: provider.additionalParameters,
//           preferEphemeralSession: provider.preferEphemeralSession,
//         ),
//       );
//     } catch (e) {
//       throw OidcAuthenticatorException(
//         code: _unknownErrorCode,
//         exception: e,
//       );
//     }

//     if (tokenResponse == null) {
//       throw OidcAuthenticatorException(
//         code: _noTokenResponseReceivedErrorCode,
//         message: 'No token response received from identity provider',
//       );
//     }

//     return tokenResponse.toOidcToken();
//   }

//   Future<OidcToken> _exchangeToken(TokenExchangeSignInProvider provider) async {
//     final parameters = <String, String>{};

//     if (provider.subjectToken != null &&
//         (provider.additionalParameters != null &&
//             !provider.additionalParameters!.containsKey('subject_token'))) {
//       parameters['subject_token'] = provider.subjectToken!;
//     }

//     if (provider.subjectTokenType != null &&
//         (provider.additionalParameters != null &&
//             !provider.additionalParameters!
//                 .containsKey('subject_token_type'))) {
//       parameters['subject_token_type'] = provider.subjectTokenType!;
//     }

//     if (provider.additionalParameters != null) {
//       parameters.addAll(provider.additionalParameters!);
//     }

//     final TokenResponse? tokenResponse;

//     try {
//       tokenResponse = await _appAuth.token(
//         TokenRequest(
//           config.clientId,
//           config.redirectUrl,
//           discoveryUrl: config.discoveryUrl,
//           scopes: _transformScopes(provider.scope ?? config.scope),
//           grantType: provider.grantType,
//           additionalParameters: parameters,
//         ),
//       );
//     } catch (e) {
//       throw OidcAuthenticatorException(
//         code: _unknownErrorCode,
//         exception: e,
//       );
//     }

//     if (tokenResponse == null) {
//       throw OidcAuthenticatorException(
//         code: _noTokenResponseReceivedErrorCode,
//         message: 'No token response received from identity provider on '
//             'token exchange!',
//       );
//     }

//     return tokenResponse.toOidcToken();
//   }

//   List<String> _transformScopes(List<String>? scopes) {
//     final result = <String>[];

//     if (scopes != null) {
//       result.addAll(scopes);
//     }

//     if (!result.contains('openid')) {
//       result.add('openid');
//     }

//     return result.toSet().toList();
//   }

//   String _promptValueToString(OidcPromptValue prompt) {
//     switch (prompt) {
//       case OidcPromptValue.none:
//         return 'none';
//       case OidcPromptValue.login:
//         return 'login';
//       case OidcPromptValue.consent:
//         return 'consent';
//       case OidcPromptValue.selectAccount:
//         return 'select_account';
//     }
//   }
// }

// class OidcAuthenticator extends RefreshAuthenticator<OidcToken> {
//   OidcAuthenticator({
//     required this.config,
//     FlutterAppAuth appAuth = const FlutterAppAuth(),
//     OidcAuthenticatorDelegate? delegate,
//   })  : _appAuth = appAuth,
//         super(
//           delegate: delegate ??
//               OidcAuthenticatorDelegate(
//                 config: config,
//                 appAuth: appAuth,
//               ),
//           localStorage: _OidcTokenStorage(),
//         );

//   final OidcConfig config;
//   final FlutterAppAuth _appAuth;

//   // Future<void> authenticate({
//   //   List<String>? scope,
//   //   String? nonce,
//   //   OidcDisplayValue? display,
//   //   List<OidcPromptValue>? prompt,
//   //   int? maxAge,
//   //   List<String>? uiLocales,
//   //   String? idTokenHint,
//   //   String? loginHint,
//   //   List<String>? acrValues,
//   //   Map<String, String>? additionalParameters,
//   //   bool? preferEphemeralSession,
//   // }) async {
//   //   return super.signIn(
//   //     AuthenticateSignInProvider(
//   //       scope: scope,
//   //       prompt: prompt,
//   //       loginHint: loginHint,
//   //       preferEphemeralSession: preferEphemeralSession,
//   //       additionalParameters: _builAuthenticateAdditionalParameters(
//   //         nonce: nonce,
//   //         display: display,
//   //         maxAge: maxAge,
//   //         uiLocales: uiLocales,
//   //         idTokenHint: idTokenHint,
//   //         acrValues: acrValues,
//   //         additionalParameters: additionalParameters,
//   //       ),
//   //     ),
//   //   );
//   // }

//   Future<void> exchangeToken({
//     required String grantType,
//     String? subjectToken,
//     String? subjectTokenType,
//     List<String>? scope,
//     Map<String, String>? additionalParameters,
//   }) async {
//     return super.signIn(
//       TokenExchangeSignInProvider(
//         subjectToken: subjectToken,
//         subjectTokenType: subjectTokenType,
//         grantType: grantType,
//         scope: scope,
//         additionalParameters: additionalParameters,
//       ),
//     );
//   }

//   Future<void> endSession({
//     String? idToken,
//     String? postLogoutRedirectUrl,
//     Map<String, String>? additionalParameters,
//   }) async {
//     await _appAuth.endSession(
//       EndSessionRequest(
//         idTokenHint: idToken,
//         discoveryUrl: config.discoveryUrl,
//         postLogoutRedirectUrl: postLogoutRedirectUrl,
//         additionalParameters: additionalParameters,
//       ),
//     );
//   }

// }

// extension on TokenResponse {
//   OidcToken toOidcToken() {
//     if (accessToken == null) {
//       throw OidcAuthenticatorException(
//         code: 'no_access_token_available',
//         message:
//             'The received token response does not include an access_token!',
//       );
//     }

//     return OidcToken(
//       accessToken: accessToken!,
//       accessTokenExpiration: accessTokenExpirationDateTime,
//       tokenType: tokenType,
//       refreshToken: refreshToken,
//       idToken: idToken,
//     );
//   }
// }

// class OidcSignInProvider extends SignInProvider {
//   const OidcSignInProvider();
// }


// const _hiveAccessTokenKey = 'AUTHENTICATOR_ACCESS_TOKEN';
// const _hiveAccessTokenExpirationKey = 'AUTHENTICATOR_ACCESS_TOKEN_EXPIRATION';
// const _hiveTokenTypeKey = 'AUTHENTICATOR_TOKEN_TYPE';
// const _hiveRefreshTokenKey = 'AUTHENTICATOR_REFRESH_TOKEN';
// const _hiveIdTokenKey = 'AUTHENTICATOR_ID_TOKEN';

// class _OidcTokenStorage extends SecureAuthenticatorStorage<OidcToken> {
//   @override
//   Future<void> persistToken(OidcToken token) async {
//     await Future.wait([
//       writeTokenvalue(_hiveAccessTokenKey, token.accessToken),
//       writeTokenvalue(
//         _hiveAccessTokenExpirationKey,
//         token.accessTokenExpiration,
//       ),
//       writeTokenvalue(_hiveTokenTypeKey, token.tokenType),
//       writeTokenvalue(_hiveRefreshTokenKey, token.refreshToken),
//       writeTokenvalue(_hiveIdTokenKey, token.idToken),
//     ]);
//   }

//   @override
//   Future<void> removePersistedToken() async {
//     await Future.wait([
//       deleteTokenValue(_hiveAccessTokenKey),
//       deleteTokenValue(_hiveAccessTokenExpirationKey),
//       deleteTokenValue(_hiveTokenTypeKey),
//       deleteTokenValue(_hiveRefreshTokenKey),
//       deleteTokenValue(_hiveIdTokenKey),
//     ]);
//   }

//   @override
//   Future<OidcToken?> get token async {
//     final tokenValues = await Future.wait<dynamic>([
//       readTokenValue(_hiveAccessTokenKey),
//       readTokenValue(_hiveAccessTokenExpirationKey),
//       readTokenValue(_hiveTokenTypeKey),
//       readTokenValue(_hiveRefreshTokenKey),
//       readTokenValue(_hiveIdTokenKey),
//     ]);

//     final accessToken = tokenValues[0] as String?;
//     if (accessToken == null) {
//       return null;
//     }

//     return OidcToken(
//       accessToken: accessToken,
//       accessTokenExpiration: tokenValues[1] as DateTime?,
//       tokenType: tokenValues[2] as String?,
//       refreshToken: tokenValues[3] as String?,
//       idToken: tokenValues[4] as String?,
//     );
//   }
// }
