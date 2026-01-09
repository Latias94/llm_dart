import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:test/test.dart';

void main() {
  group('OpenAI providerTools legacy id compatibility', () {
    test('accepts openai.computer_use_preview as an alias for computer_use', () async {
      final provider = await ai()
          .provider('openai')
          .apiKey('test-key')
          .model('gpt-4o')
          .providerTools(const [
        ProviderTool(
          id: 'openai.computer_use_preview',
          options: {
            'display_width': 1024,
            'display_height': 768,
            'environment': 'browser',
          },
        ),
      ]).build();

      final openai = provider as openai_client.OpenAIProvider;
      expect(openai.config.useResponsesAPI, isTrue);
      expect(openai.config.builtInTools, isNotNull);
      expect(
        openai.config.builtInTools!.any((t) => t.toJson()['type'] == 'computer_use_preview'),
        isTrue,
      );
    });
  });
}

