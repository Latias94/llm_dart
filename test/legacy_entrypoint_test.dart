import 'package:llm_dart/legacy.dart' as legacy;
import 'package:test/test.dart';

void main() {
  group('Legacy entrypoint', () {
    test('exports the compatibility AI builder helpers', () async {
      final builder = legacy.ai();

      expect(builder, isA<legacy.LLMBuilder>());

      final provider = await legacy.createProvider(
        providerId: 'openai',
        apiKey: 'test-key',
        model: 'gpt-3.5-turbo',
      );

      expect(provider.toString(), contains('OpenAIProvider'));
    });
  });
}
