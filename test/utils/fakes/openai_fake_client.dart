import 'dart:async';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';

class FakeOpenAIClient extends OpenAIClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastJsonBody;
  FormData? lastFormData;

  Map<String, dynamic> jsonResponse = const {};
  Map<String, dynamic> formResponse = const {'text': 'hello'};
  List<int> rawResponse = const <int>[1, 2, 3];
  Stream<String> streamResponse = const Stream<String>.empty();

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
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) {
    lastEndpoint = endpoint;
    lastJsonBody = body;
    return streamResponse;
  }
}
