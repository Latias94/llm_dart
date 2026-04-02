import 'package:llm_dart/ai.dart' as llm;
import 'package:test/test.dart';

void main() {
  group('AI entrypoint', () {
    test('exports the focused modern AI surface', () {
      final model = llm.AI.openai(apiKey: 'test-key').chatModel('gpt-5-mini');
      final cancellation = llm.TransportCancellation();
      const options = llm.OpenAIGenerateTextOptions();
      const request = llm.GenerateTextOptions(maxOutputTokens: 32);

      expect(model.providerId, 'openai');
      expect(cancellation.isCancelled, isFalse);
      expect(options, isA<llm.OpenAIGenerateTextOptions>());
      expect(request.maxOutputTokens, 32);
    });
  });
}
