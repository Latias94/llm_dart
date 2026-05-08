import 'package:llm_dart/legacy.dart' as legacy;
import 'package:test/test.dart';

void main() {
  group('Legacy entrypoint', () {
    test('exports the compatibility AI builder helpers', () async {
      // ignore: deprecated_member_use_from_same_package
      final builder = legacy.ai();

      expect(builder, isA<legacy.LLMBuilder>());

      final provider = await legacy.createProvider(
        providerId: 'openai',
        apiKey: 'test-key',
        model: 'gpt-3.5-turbo',
      );

      expect(provider.toString(), contains('OpenAIProvider'));
    });

    test('keeps broad compatibility exports independently of llm_dart.dart',
        () {
      expect(() => legacy.LLMBuilder(), returnsNormally);
      // ignore: deprecated_member_use_from_same_package
      expect(() => legacy.ai(), returnsNormally);
      expect(legacy.ChatMessage, isA<Type>());
      expect(legacy.ToolCall, isA<Type>());
      expect(legacy.ToolCallAggregator, isA<Type>());
      expect(legacy.Assistant, isA<Type>());
      expect(legacy.GoogleTTSRequest, isA<Type>());
      expect(legacy.HttpConfig, isA<Type>());
    });
  });
}
