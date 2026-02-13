import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:test/test.dart';

class _FakeClient extends OpenAIClient {
  final Map<String, dynamic> response;

  _FakeClient(super.config, this.response);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    return response;
  }

  @override
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postJsonWithHeaders(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    return (json: response, headers: const <String, String>{});
  }
}

void main() {
  group('OpenAI-compatible chat finishReason', () {
    test('maps stop', () async {
      const config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-mini',
      );
      final client = _FakeClient(config, {
        'id': 'chatcmpl_1',
        'model': 'gpt-4o-mini',
        'choices': [
          {
            'index': 0,
            'finish_reason': 'stop',
            'message': {'role': 'assistant', 'content': 'hi'},
          }
        ],
      });

      final chat = OpenAIChat(client, config);
      final response = await chat.chatWithTools([ChatMessage.user('x')], null);

      expect(response, isA<ChatResponseWithFinishReason>());
      final finishReason =
          (response as ChatResponseWithFinishReason).finishReason!;
      expect(finishReason.unified, equals(LLMUnifiedFinishReason.stop));
      expect(finishReason.raw, equals('stop'));
    });
  });
}
