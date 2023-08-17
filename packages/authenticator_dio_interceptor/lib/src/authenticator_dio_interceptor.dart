import 'dart:io';

import 'package:authenticator/authenticator.dart';
import 'package:dio/dio.dart';

typedef ShouldRefresh = bool Function(int);

///
class AuthenticatorDioInterceptor<T extends AuthenticatorToken>
    extends QueuedInterceptor {
  ///
  AuthenticatorDioInterceptor(
    this.authenticator, {
    this.shouldRefresh,
  }) : _httpClient = Dio();

  final RefreshAuthenticator<T> authenticator;
  final ShouldRefresh? shouldRefresh;
  final Dio _httpClient;

  T? get _token => authenticator.token;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _applyAuthorizationHeader(options);
    super.onRequest(options, handler);
  }

  @override
  Future<dynamic> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_token == null || !_shouldRefresh(response)) {
      return handler.next(response);
    }

    try {
      final refreshResponse = await _refreshAndRetry(response);
      handler.resolve(refreshResponse);
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;

    if (response == null || !_shouldRefresh(response) || _token == null) {
      return handler.next(err);
    }

    try {
      final refreshedResponse = await _refreshAndRetry(response);
      handler.resolve(refreshedResponse);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  Future<Response> _refreshAndRetry(Response response) async {
    await authenticator.refresh();

    _httpClient.options.baseUrl = response.requestOptions.baseUrl;

    final requestOptions = response.requestOptions;
    await _applyAuthorizationHeader(requestOptions);
    return _httpClient.fetch<dynamic>(requestOptions);
  }

  bool _shouldRefresh(Response response) {
    final statusCode = response.statusCode;

    return statusCode != null &&
        (shouldRefresh ?? _defaultShouldRefresh).call(statusCode);
  }

  Future<void> _applyAuthorizationHeader(RequestOptions requestOptions) async {
    final token = _token;
    if (token == null) {
      return;
    }

    requestOptions.headers[HttpHeaders.authorizationHeader] =
        token.authorizationHeader;
  }

  bool _defaultShouldRefresh(int statusCode) {
    return statusCode == HttpStatus.unauthorized;
  }
}
