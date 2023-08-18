library openid_client.openid;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:oidc_client/oidc_client.dart';

import 'package:pointycastle/digests/sha256.dart';

/// Represents an Openid client.
class OidcClient {
  OidcClient({
    required this.issuer,
    required this.clientId,
    this.clientSecret,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// The id of the client.
  final String clientId;

  /// A secret for authenticating the client to the OP.
  final String? clientSecret;

  /// The [Issuer] representing the OP.
  final Issuer issuer;

  final http.Client httpClient;

  Future<UserInfo> getUserInfo() async {
    final userInfoResponse = await httpClient.get(issuer.userInfoEndpoint);

    if (userInfoResponse.isOpenidErrorResponse) {
      throw OpenIdException.fromResponse(userInfoResponse.data);
    }

    return UserInfo.fromJson(
      jsonDecode(userInfoResponse.body) as Map<String, dynamic>,
    );
  }

  Future<TokenResponse> getToken({
    required String grantType,
    Map<String, dynamic>? additionalParameters,
    Map<String, String>? headers,
  }) async {
    final response = await httpClient.post(
      issuer.tokenEndpoint,
      headers: headers,
      body: {
        'grant_type': grantType,
        'client_id': clientId,
        if (clientSecret != null) 'client_secret': clientSecret,
        if (additionalParameters != null) ...additionalParameters,
      },
    );

    if (response.isOpenidErrorResponse) {
      throw OpenIdException.fromResponse(response.data);
    }

    return TokenResponse.fromJson(response.data);
  }

  Future<TokenResponse> refresh({
    required String refreshToken,
  }) async {
    final refreshResponse = await httpClient.post(
      issuer.tokenEndpoint,
      body: <String, dynamic>{
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        if (clientSecret != null) 'client_secret': clientSecret,
      },
    );

    if (refreshResponse.isOpenidErrorResponse) {
      throw OpenIdException.fromResponse(refreshResponse.data);
    }

    return TokenResponse.fromJson(
      <String, dynamic>{
        'refresh_token': refreshToken,
        ...jsonDecode(refreshResponse.body) as Map<String, dynamic>,
      },
    );
  }

  /// Allows clients to notify the authorization server that a previously
  /// obtained refresh or access token is no longer needed
  ///
  /// See https://tools.ietf.org/html/rfc7009
  Future<void> revoke({
    required String token,
    TokenRevocationType revocationType = TokenRevocationType.accessToken,
  }) async {
    final revocationResponse = await httpClient.post(
      issuer.revocationEndpoint,
      body: <String, dynamic>{
        'token': token,
        'token_type_hint': revocationType == TokenRevocationType.accessToken
            ? 'access_token'
            : 'refresh_token',
      },
    );

    if (revocationResponse.isOpenidErrorResponse) {
      throw OpenIdException.fromResponse(revocationResponse.data);
    }
  }

  /// Returns an url to redirect to for a Relying Party to request that an
  /// OpenID Provider log out the End-User.
  ///
  /// [redirectUri] is an url to which the Relying Party is requesting that the
  /// End-User's User Agent be redirected after a logout has been performed.
  ///
  /// [state] is an opaque value used by the Relying Party to maintain state
  /// between the logout request and the callback to [redirectUri].
  ///
  /// See https://openid.net/specs/openid-connect-rpinitiated-1_0.html
  Uri? generateLogoutUrl({
    required String idToken,
    Uri? redirectUri,
    String? state,
  }) {
    return issuer.endSessionEndpoint.replace(
      queryParameters: <String, dynamic>{
        'id_token_hint': idToken,
        if (redirectUri != null)
          'post_logout_redirect_uri': redirectUri.toString(),
        if (state != null) 'state': state,
      },
    );
  }
}

enum TokenRevocationType {
  accessToken,
  refreshToken,
}

/// Represents an OpenId Provider
class Issuer {
  /// Creates an issuer from its metadata.
  const Issuer(
    this.metadata, {
    this.claimsMap = const {},
  });

  /// The OpenId Provider's metadata
  final OpenIdProviderMetadata metadata;

  final Map<String, String> claimsMap;

  static final Map<Uri, Issuer?> _discoveries = {};

  static Iterable<Uri> get knownIssuers => _discoveries.keys;

  Uri get endSessionEndpoint =>
      metadata.endSessionEndpoint ??
      (throw UnsupportedError(
        'The issuer does not provide a "end_session_endpoint".',
      ));

  /// Discovers the OpenId Provider's metadata based on its uri.
  static Future<Issuer> discover(
    Uri discoveryUrl, {
    http.Client? httpClient,
  }) async {
    final segments = discoveryUrl.pathSegments;

    assert(
      segments.last == 'openid-configuration' &&
          segments[segments.length - 2] == '.well-known',
      '`discoveryUrl` must end with "/.well-known/openid-configuration"',
    );

    if (_discoveries[discoveryUrl] != null) {
      return _discoveries[discoveryUrl]!;
    }

    final discoveryResponse = await http.get(discoveryUrl);
    return _discoveries[discoveryUrl] = Issuer(
      OpenIdProviderMetadata.fromJson(
        jsonDecode(discoveryResponse.body) as Map<String, dynamic>,
      ),
    );
  }
}

extension _IssuerX on Issuer {
  Uri get tokenEndpoint =>
      metadata.tokenEndpoint ??
      (throw UnsupportedError(
        'The issuer does not provide a "token_endpoint".',
      ));

  Uri get revocationEndpoint =>
      metadata.revocationEndpoint ??
      (throw UnsupportedError(
        'The issuer does not provide a "revocation_endpoint".',
      ));

  Uri get userInfoEndpoint =>
      metadata.userinfoEndpoint ??
      (throw UnsupportedError(
        'The issuer does not provide a "userinfo_endpoint".',
      ));
}

const _authorizationCodeGrantType = 'authorization_code';
const _authorizationCodeResponseType = 'code';
const _implicitResponseTypes = [
  'id_token token',
  'id_token',
  'token id_token',
  'token',
];

enum FlowType {
  implicit,
  authorizationCode,
  proofKeyForCodeExchange,
}

class ProofKeyForCodeExchange {
  const ProofKeyForCodeExchange({
    required this.challenge,
    required this.verifier,
  });

  final String challenge;
  final String verifier;
}

class Flow {
  Flow._({
    required this.type,
    required this.client,
    required this.responseType,
    required this.redirectUri,
    List<String> scopes = const [],
    String? state,
    this.prompt,
    this.accessType,
    Map<String, String>? additionalParameters,
    http.Client? httpClient,
  })  : state = state ?? _generateRandomString(20),
        additionalParameters = {...?additionalParameters},
        httpClient = httpClient ?? http.Client() {
    final supportedScopes = client.issuer.metadata.scopesSupported ?? [];

    for (final scope in scopes) {
      if (supportedScopes.contains(scope)) {
        this.scopes.add(scope);
        break;
      }
    }

    if (!this.scopes.contains('openid')) {
      this.scopes.add('openid');
    }

    if (type == FlowType.proofKeyForCodeExchange) {
      final verifier = _generateRandomString(50);
      final challenge = base64Url
          .encode(
            SHA256Digest().process(Uint8List.fromList(verifier.codeUnits)),
          )
          .replaceAll('=', '');

      _proofKeyForCodeExchange = ProofKeyForCodeExchange(
        verifier: verifier,
        challenge: challenge,
      );
    }
  }

  Flow.authorizationCode({
    required OidcClient client,
    required Uri redirectUri,
    List<String> scopes = const [],
    String? state,
    String? prompt,
    String? accessType,
    Map<String, String> additionalParameters = const {},
    http.Client? httpClient,
  }) : this._(
          type: FlowType.authorizationCode,
          client: client,
          responseType: _authorizationCodeResponseType,
          redirectUri: redirectUri,
          scopes: scopes,
          state: state,
          prompt: prompt,
          accessType: accessType,
          additionalParameters: additionalParameters,
          httpClient: httpClient,
        );

  Flow.authorizationCodeWithPKCE({
    required OidcClient client,
    required Uri redirectUrl,
    List<String> scopes = const [],
    String? state,
    String? prompt,
    String? accessType,
    Map<String, String> additionalParameters = const {},
    http.Client? httpClient,
  }) : this._(
          type: FlowType.proofKeyForCodeExchange,
          client: client,
          responseType: _authorizationCodeResponseType,
          redirectUri: redirectUrl,
          scopes: scopes,
          state: state,
          prompt: prompt,
          accessType: accessType,
          additionalParameters: additionalParameters,
          httpClient: httpClient,
        );

  Flow.implicit({
    required OidcClient client,
    required Uri redirectUri,
    List<String> scopes = const [],
    String? state,
    String? prompt,
    String? accessType,
    Map<String, String> additionalParameters = const {},
    http.Client? httpClient,
  }) : this._(
          type: FlowType.implicit,
          client: client,
          responseType: _implicitResponseTypes.firstWhere(
            (v) => client.issuer.metadata.responseTypesSupported.contains(v),
          ),
          redirectUri: redirectUri,
          scopes: scopes,
          state: state,
          prompt: prompt,
          accessType: accessType,
          additionalParameters: additionalParameters,
          httpClient: httpClient,
        );

  final FlowType type;
  final String? responseType;
  final OidcClient client;
  final Uri redirectUri;
  final List<String> scopes = [];
  final String state;
  final String? prompt;
  final String? accessType;
  final Map<String, String> additionalParameters;
  final http.Client httpClient;
  late ProofKeyForCodeExchange? _proofKeyForCodeExchange;

  Uri get authenticationUri => client.issuer.metadata.authorizationEndpoint
      .replace(queryParameters: _authenticationUriParameters);

  bool get _hasIdTokenResponseType =>
      responseType!.split(' ').contains('id_token');

  Map<String, String?> get _authenticationUriParameters {
    final parameters = {
      ...additionalParameters,
      'response_type': responseType,
      'scope': scopes.join(' '),
      'client_id': client.clientId,
      'redirect_uri': redirectUri.toString(),
      'state': state,
      if (_hasIdTokenResponseType) 'nonce': _generateRandomString(16),
      if (prompt != null) 'prompt': prompt,
      if (accessType != null) 'access_type': accessType,
    };

    if (type == FlowType.proofKeyForCodeExchange) {
      parameters.addAll({
        'code_challenge_method': 'S256',
        'code_challenge': _proofKeyForCodeExchange!.challenge,
      });
    }

    return parameters;
  }

  Future<TokenResponse> callback(Map<String, String> response) async {
    if (response['state'] != state) {
      throw ArgumentError('State does not match');
    }

    if (response.containsKey('code') &&
        (type == FlowType.proofKeyForCodeExchange ||
            client.clientSecret != null)) {
      return _exchangeCodeForToken(response['code']);
    } else if (response.containsKey('access_token') ||
        response.containsKey('id_token')) {
      return TokenResponse.fromJson(response);
    } else {
      return TokenResponse.fromJson(response);
    }
  }

  Future<TokenResponse> _exchangeCodeForToken(String? code) async {
    if (type == FlowType.proofKeyForCodeExchange) {
      return client.getToken(
        grantType: _authorizationCodeGrantType,
        additionalParameters: {
          'code': code,
          'redirect_uri': redirectUri.toString(),
          'code_verifier': _proofKeyForCodeExchange!.verifier,
        },
      );
    }

    final supportedAuthMethods =
        client.issuer.metadata.tokenEndpointAuthMethodsSupported ?? [];

    if (supportedAuthMethods.contains('client_secret_post')) {
      return client.getToken(
        grantType: _authorizationCodeGrantType,
        additionalParameters: {
          'code': code,
          'redirect_uri': redirectUri.toString(),
        },
      );
    } else if (supportedAuthMethods.contains('client_secret_basic')) {
      final authorizationHeaderValue =
          base64.encode('${client.clientId}:${client.clientSecret}'.codeUnits);

      return client.getToken(
        grantType: _authorizationCodeGrantType,
        headers: {'authorization': 'Basic $authorizationHeaderValue'},
        additionalParameters: {
          'code': code,
          'redirect_uri': redirectUri.toString(),
        },
      );
    } else {
      throw UnsupportedError('Unknown auth methods: $supportedAuthMethods');
    }
  }
}

String _generateRandomString(int length) {
  final r = Random.secure();
  const chars =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  return Iterable.generate(50, (_) => chars[r.nextInt(chars.length)]).join();
}

extension _ResponseX on http.Response {
  bool get isOpenidErrorResponse {
    return data.containsKey('error');
  }

  Map<String, dynamic> get data => jsonDecode(body) as Map<String, dynamic>;
}
