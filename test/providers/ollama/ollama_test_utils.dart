import 'package:dio/dio.dart';
import 'package:llm_dart_ollama/testing.dart';

/// Capturing client for Ollama tests that records request bodies.
class CapturingOllamaClient extends OllamaClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;
  Map<String, String>? lastHeaders;

  CapturingOllamaClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;
    lastHeaders = headers;

    return {
      'message': {'role': 'assistant', 'content': 'ok'},
      'done': true,
    };
  }
}
