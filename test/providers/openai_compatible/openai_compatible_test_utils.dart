import 'package:dio/dio.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

/// Capturing client for OpenAI-compatible providers used in tests.
class CapturingOpenAICompatibleClient extends OpenAICompatibleClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;

  CapturingOpenAICompatibleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = body;

    return {
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content': 'ok',
          },
        },
      ],
    };
  }
}

/// Fake streaming client for OpenAI-compatible providers.
class FakeOpenAICompatibleStreamClient extends OpenAICompatibleClient {
  final List<String> chunks;

  FakeOpenAICompatibleStreamClient(
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
