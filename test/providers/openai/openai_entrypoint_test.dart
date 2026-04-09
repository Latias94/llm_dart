import 'package:llm_dart/providers/openai/openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI provider barrel', () {
    test('exports the focused OpenAI compatibility surface', () {
      const builderType = OpenAIBuilder;

      final provider = OpenAIProvider(
        const OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: true,
        ),
      );

      expect(builderType, equals(OpenAIBuilder));
      expect(OpenAIBuiltInTools.webSearch(), isA<OpenAIWebSearchTool>());
      expect(provider.responses, isA<OpenAIResponses>());
      expect(provider.responses, isA<OpenAIResponsesCapability>());
    });
  });
}
