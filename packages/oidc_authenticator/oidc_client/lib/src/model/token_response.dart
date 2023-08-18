import 'package:json_annotation/json_annotation.dart';

part 'token_response.g.dart';

@JsonSerializable()
class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    this.tokenType,
    this.refreshToken,
    this.expiresIn,
    this.idToken,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);

  /// OAuth 2.0 Access Token
  ///
  /// This is returned unless the response_type value used is `id_token`.
  @JsonKey(name: 'access_token')
  final String? accessToken;

  /// OAuth 2.0 Token Type value
  ///
  /// The value MUST be Bearer or another token_type value that the Client has
  /// negotiated with the Authorization Server.
  @JsonKey(name: 'token_type')
  final String? tokenType;

  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  @JsonKey(name: 'expires_in')
  final int? expiresIn;

  @JsonKey(name: 'id_token')
  final String? idToken;

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);
}
