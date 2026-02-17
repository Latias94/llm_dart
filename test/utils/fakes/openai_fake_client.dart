import 'dart:async';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';

class FakeOpenAIClient extends OpenAIClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastJsonBody;
  FormData? lastFormData;
  Map<String, String>? lastRequestHeaders;

  Map<String, dynamic> jsonResponse = const {};
  Map<String, String> jsonHeaders = const <String, String>{};
  Map<String, dynamic> formResponse = const {'text': 'hello'};
  List<int> rawResponse = const <int>[1, 2, 3];
  Stream<String> streamResponse = const Stream<String>.empty();
  Map<String, String> streamHeaders = const <String, String>{};

  FakeOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastJsonBody = body;
    return jsonResponse;
  }

  @override
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postJsonWithHeaders(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastJsonBody = body;
    lastRequestHeaders = headers;
    return (json: jsonResponse, headers: jsonHeaders);
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String endpoint,
    FormData formData, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastFormData = formData;
    return formResponse;
  }

  @override
  Future<Map<String, dynamic>> postFormWithHeaders(
    String endpoint,
    FormData formData, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastFormData = formData;
    lastRequestHeaders = headers;
    return formResponse;
  }

  @override
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postFormWithResponseHeaders(
    String endpoint,
    FormData formData, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastFormData = formData;
    lastRequestHeaders = headers;
    return (json: formResponse, headers: const <String, String>{});
  }

  @override
  Future<List<int>> postRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastJsonBody = body;
    return rawResponse;
  }

  @override
  Future<List<int>> postRawWithHeaders(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastJsonBody = body;
    lastRequestHeaders = headers;
    return rawResponse;
  }

  @override
  Future<({List<int> data, Map<String, String> headers})>
      postRawWithResponseHeaders(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastJsonBody = body;
    lastRequestHeaders = headers;
    return (data: rawResponse, headers: const <String, String>{});
  }

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) {
    lastEndpoint = endpoint;
    lastJsonBody = body;
    return streamResponse;
  }

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastJsonBody = body;
    lastRequestHeaders = headers;
    return (stream: streamResponse, headers: streamHeaders);
  }
}
