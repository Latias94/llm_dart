import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI-compatible SSE parsing', () {
    test('does not drop JSON events before [DONE] in the same chunk', () {
      final config = OpenAICompatibleConfig.fromLLMConfig(
        const LLMConfig(
          apiKey: 'k',
          baseUrl: 'https://api.example.com/v1/',
          model: 'gpt-4o',
        ),
        providerId: 'openai-compatible',
        providerName: 'OpenAI-Compatible',
      );

      final client = OpenAIClient(config);

      final chunk = [
        'data: {"id":"1","choices":[{"delta":{"content":"hi"}}]}\n\n',
        'data: [DONE]\n\n',
      ].join();

      final parsed = client.parseSSEChunk(chunk);
      expect(parsed, hasLength(1));
      expect(parsed.single['id'], equals('1'));
    });
  });
}
