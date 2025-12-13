import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';

/// Capturing client for Ollama tests that records request bodies.
class CapturingOllamaClient extends OllamaClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;

  CapturingOllamaClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;

    return {
      'message': {'role': 'assistant', 'content': 'ok'},
      'done': true,
    };
  }
}
