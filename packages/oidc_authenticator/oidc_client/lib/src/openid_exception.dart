/// An exception thrown when a response is received in the openid error format.
class OpenIdException implements Exception {
  const OpenIdException({
    required this.code,
    this.message,
    this.uri,
    this.state,
  });

  factory OpenIdException.fromResponse(Map<String, dynamic> json) =>
      OpenIdException(
        code: json['error'].toString(),
        message: json['error_description'].toString(),
        uri:
            json.containsKey('error_uri') ? json['error_uri'].toString() : null,
        state: json.containsKey('state') ? json['state'].toString() : null,
      );

  /// Error code.
  final String? code;

  /// Human-readable ASCII encoded text description of the error.
  final String? message;

  /// URI of a web page that includes additional information about the error.
  final String? uri;

  /// OAuth 2.0 state value.
  final String? state;

  @override
  String toString() => 'OpenIdException($code): $message';
}
