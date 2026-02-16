import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAIClient.parseSSEChunk strictSseJson', () {
    test('defaults to tolerant mode (skips invalid JSON)', () {
      final config = OpenAICompatibleConfig(
        providerId: 'openai-compatible',
        providerName: 'OpenAI Compatible',
        baseUrl: 'https://example.com',
        model: 'gpt-test',
      );
      final client = FakeOpenAIClient(config);

      final out = client.parseSSEChunk('data: {not json}\n\n');
      expect(out, isEmpty);
    });

    test('throws ResponseFormatError when strictSseJson is enabled', () {
      final original = LLMConfig(
        baseUrl: 'https://example.com',
        model: 'gpt-test',
        providerOptions: const {
          'openai-compatible': {
            'strictSseJson': true,
          },
        },
      );

      final config = OpenAICompatibleConfig(
        providerId: 'openai-compatible',
        providerName: 'OpenAI Compatible',
        baseUrl: original.baseUrl,
        model: original.model,
        originalConfig: original,
      );
      final client = FakeOpenAIClient(config);

      expect(
        () => client.parseSSEChunk('data: {not json}\n\n'),
        throwsA(isA<ResponseFormatError>()),
      );
    });
  });
}
