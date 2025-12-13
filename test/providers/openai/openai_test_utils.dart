import 'package:dio/dio.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Test client that captures JSON request bodies instead of doing HTTP.
class CapturingOpenAIClient extends openai.OpenAIClient {
  Map<String, dynamic>? lastBody;
  String? lastEndpoint;

  CapturingOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = Map<String, dynamic>.from(body);

    // Return a minimal chat-style response to satisfy parsers.
    if (endpoint == 'chat/completions') {
      return {
        'choices': [
          {
            'message': {'role': 'assistant', 'content': 'ok'},
          }
        ],
      };
    }

    // Minimal Responses API-style response.
    if (endpoint == 'responses') {
      return {
        'output': [
          {
            'type': 'message',
            'content': [
              {'type': 'output_text', 'text': 'ok'},
            ],
          },
        ],
      };
    }

    return {};
  }
}

/// Fake OpenAI client that returns a synthetic SSE stream for testing.
///
/// The [chunks] parameter contains raw SSE data lines that will be
/// yielded in order by [postStreamRaw]. This mirrors the behavior of
/// a real OpenAI SSE endpoint but keeps tests fully deterministic.
class FakeOpenAIStreamClient extends openai.OpenAIClient {
  final List<String> chunks;

  FakeOpenAIStreamClient(
    super.config, {
    required this.chunks,
  });

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}
