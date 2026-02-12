import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('GoogleChat request metadata part', () {
    test('emits LLMRequestMetadataPart when enabled', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-pro',
        providerOptions: const {
          'google': {
            'emitRequestMetadata': true,
          },
        },
      );
      final config = GoogleConfig.fromLLMConfig(llmConfig);

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream.fromIterable(const [
          'data: {"candidates":[{"content":{"parts":[{"text":"Hello"}],"role":"model"},"finishReason":"STOP","index":0}]}\n\n',
          'data: [DONE]\n\n',
        ]);

      final chat = GoogleChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('hi')]).toList();

      final requestMeta = parts.whereType<LLMRequestMetadataPart>().toList();
      expect(requestMeta, hasLength(1));

      final body = requestMeta.single.body as Map<String, dynamic>;
      expect(body['contents'], isNotNull);
    });
  });
}
