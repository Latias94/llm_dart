import 'dart:async';

import 'package:dio/dio.dart' as dio;
import 'package:llm_dart_core/llm_dart_core.dart' show CancelToken;
import 'package:llm_dart_google/client.dart';

class FakeGoogleClient extends GoogleClient {
  String? lastEndpoint;
  dynamic lastBody;
  Map<String, String>? lastHeaders;

  final List<
      ({
        String method,
        String endpoint,
        dynamic body,
        Map<String, String>? headers
      })> calls = [];

  /// Fake JSON responses keyed by endpoint.
  final Map<String, Map<String, dynamic>> responsesByEndpoint;

  /// Fake JSON responses keyed by GET endpoint.
  final Map<String, Map<String, dynamic>> getResponsesByEndpoint;

  /// Fallback JSON response returned when `responsesByEndpoint` has no entry.
  ///
  /// When null, missing responses throw to catch incomplete test setup.
  final Map<String, dynamic>? defaultJsonResponse;

  /// Fake raw stream returned from `postStreamRaw`.
  Stream<String> streamResponse = const Stream<String>.empty();

  /// Fake response headers returned from `postStreamRawWithHeaders`.
  Map<String, String> streamHeaders = const <String, String>{};

  /// Fake response headers returned from `postJsonWithHeaders`.
  Map<String, String> jsonHeaders = const <String, String>{};

  /// Fake Dio response returned from `post`.
  dio.Response? postResponse;

  FakeGoogleClient(
    super.config, {
    Map<String, Map<String, dynamic>>? responsesByEndpoint,
    Map<String, Map<String, dynamic>>? getResponsesByEndpoint,
    this.defaultJsonResponse,
  })  : responsesByEndpoint = responsesByEndpoint ?? const {},
        getResponsesByEndpoint = getResponsesByEndpoint ?? const {};

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    lastHeaders = null;
    calls.add((method: 'POST', endpoint: endpoint, body: data, headers: null));

    final response = responsesByEndpoint[endpoint];
    if (response == null) {
      final fallback = defaultJsonResponse;
      if (fallback != null) return fallback;
      throw StateError('No fake response registered for endpoint: $endpoint');
    }
    return response;
  }

  @override
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postJsonWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    lastHeaders = headers;
    calls.add(
      (method: 'POST', endpoint: endpoint, body: data, headers: headers),
    );
    final json = await postJson(
      endpoint,
      data,
      cancelToken: cancelToken,
    );
    return (json: json, headers: jsonHeaders);
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = null;
    lastHeaders = headers;
    calls
        .add((method: 'GET', endpoint: endpoint, body: null, headers: headers));

    final response = getResponsesByEndpoint[endpoint];
    if (response == null) {
      final fallback = defaultJsonResponse;
      if (fallback != null) return fallback;
      throw StateError(
        'No fake GET response registered for endpoint: $endpoint',
      );
    }
    return response;
  }

  @override
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      getJsonWithHeaders(
    String endpoint, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    final json = await getJson(
      endpoint,
      headers: headers,
      cancelToken: cancelToken,
    );
    return (json: json, headers: jsonHeaders);
  }

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    lastEndpoint = endpoint;
    lastBody = data;
    lastHeaders = null;
    calls.add((method: 'POST', endpoint: endpoint, body: data, headers: null));
    return streamResponse;
  }

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    lastHeaders = null;
    calls.add((method: 'POST', endpoint: endpoint, body: data, headers: null));
    return (stream: streamResponse, headers: streamHeaders);
  }

  @override
  Future<dio.Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    lastHeaders = options?.headers?.cast<String, String>();
    calls.add((
      method: 'POST',
      endpoint: endpoint,
      body: data,
      headers: lastHeaders,
    ));

    return postResponse ??
        dio.Response(
          requestOptions: dio.RequestOptions(path: endpoint),
          statusCode: 200,
          data: const <String, dynamic>{},
        );
  }
}
