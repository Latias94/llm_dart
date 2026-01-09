import 'dart:async';

import 'package:dio/dio.dart' as dio;
import 'package:llm_dart_core/llm_dart_core.dart' show CancelToken;
import 'package:llm_dart_google/client.dart';

class FakeGoogleClient extends GoogleClient {
  String? lastEndpoint;
  dynamic lastBody;

  /// Fake JSON responses keyed by endpoint.
  final Map<String, Map<String, dynamic>> responsesByEndpoint;

  /// Fake raw stream returned from `postStreamRaw`.
  Stream<String> streamResponse = const Stream<String>.empty();

  /// Fake Dio response returned from `post`.
  dio.Response? postResponse;

  FakeGoogleClient(
    super.config, {
    Map<String, Map<String, dynamic>>? responsesByEndpoint,
  }) : responsesByEndpoint = responsesByEndpoint ?? const {};

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;

    final response = responsesByEndpoint[endpoint];
    if (response == null) {
      throw StateError('No fake response registered for endpoint: $endpoint');
    }
    return response;
  }

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    lastEndpoint = endpoint;
    lastBody = data;
    return streamResponse;
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

    return postResponse ??
        dio.Response(
          requestOptions: dio.RequestOptions(path: endpoint),
          statusCode: 200,
          data: const <String, dynamic>{},
        );
  }
}
