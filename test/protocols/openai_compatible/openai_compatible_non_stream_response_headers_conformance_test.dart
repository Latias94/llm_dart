import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAI-compatible non-stream response headers (conformance)', () {
    test('exposes response headers via responseMetadata', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o-mini',
      );

      final client = FakeOpenAIClient(config)
        ..jsonHeaders = const {'x-test': '1'}
        ..jsonResponse = const {
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'created': 1700000000,
          'choices': [
            {
              'index': 0,
              'message': {
                'role': 'assistant',
                'content': 'Hello',
              },
              'finish_reason': 'stop',
            }
          ],
        };

      final chat = OpenAIChat(client, config);

      final response = await chat.chat([ChatMessage.user('Hi')]);
      expect(response, isA<ChatResponseWithResponseMetadata>());

      final meta =
          (response as ChatResponseWithResponseMetadata).responseMetadata;
      expect(meta, isNotNull);
      expect(meta!.headers, containsPair('x-test', '1'));
      expect(meta.body, isA<Map<String, dynamic>>());

      final result = await generateText(model: chat, prompt: 'Hi');
      expect(result.responseMetadata, isNotNull);
      expect(result.responseMetadata!.headers, containsPair('x-test', '1'));
      expect(result.responseMetadata!.body, isA<Map<String, dynamic>>());
      expect(result.responseMessages, hasLength(1));
      expect(result.responseMessages.first.role, equals(ChatRole.assistant));
      expect(result.responseMessages.first.content, equals('Hello'));
    });
  });
}
