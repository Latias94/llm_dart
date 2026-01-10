import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIProvider stream parts', () {
    test('OpenAIProvider implements ChatStreamPartsCapability', () {
      final provider = OpenAIProvider(
        OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1',
        ),
      );

      expect(provider, isA<ChatStreamPartsCapability>());
    });
  });
}
