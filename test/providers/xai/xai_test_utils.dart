import 'package:dio/dio.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart' as xai;

/// Capturing XAI client used in tests to verify request bodies.
class CapturingXAIClient extends xai.XAIClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;

  CapturingXAIClient(xai.XAIConfig config) : super(config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;

    // Minimal valid xAI-style response.
    return {
      'id': 'chatcmpl-1',
      'model': 'grok-3',
      'object': 'chat.completion',
      'choices': [
        {
          'index': 0,
          'finish_reason': 'stop',
          'message': {
            'role': 'assistant',
            'content': 'ok',
            'reasoning_content': null,
            'tool_calls': null,
          },
        },
      ],
      'usage': {
        'prompt_tokens': 3,
        'completion_tokens': 5,
        'total_tokens': 8,
        'completion_tokens_details': {'reasoning_tokens': 2},
      },
      'citations': ['https://example.com'],
    };
  }
}
