import 'package:llm_dart/ai.dart' as ai;
import 'package:llm_dart/llm_dart.dart' as root;
import 'package:test/test.dart';

void main() {
  group('AI entrypoint', () {
    test('is an explicit alias of the root modern surface', () {
      final aiModel = ai.AI.openai(apiKey: 'test-key').chatModel('gpt-5-mini');
      final rootModel =
          root.AI.openai(apiKey: 'test-key').chatModel('gpt-5-mini');
      final root.TransportCancellation cancellation = ai.TransportCancellation();
      const root.OpenAIGenerateTextOptions rootOptions =
          ai.OpenAIGenerateTextOptions();
      const ai.GenerateTextOptions aiRequest =
          root.GenerateTextOptions(maxOutputTokens: 32);

      expect(aiModel.providerId, 'openai');
      expect(rootModel.providerId, aiModel.providerId);
      expect(rootModel.modelId, aiModel.modelId);
      expect(cancellation.isCancelled, isFalse);
      expect(rootOptions, isA<ai.OpenAIGenerateTextOptions>());
      expect(aiRequest.maxOutputTokens, 32);
    });
  });
}
