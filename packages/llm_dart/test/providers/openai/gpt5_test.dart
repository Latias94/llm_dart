import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('GPT-5 Support', () {
    test('should support Verbosity enum', () {
      expect(Verbosity.low.value, equals('low'));
      expect(Verbosity.medium.value, equals('medium'));
      expect(Verbosity.high.value, equals('high'));

      expect(Verbosity.fromString('low'), equals(Verbosity.low));
      expect(Verbosity.fromString('medium'), equals(Verbosity.medium));
      expect(Verbosity.fromString('high'), equals(Verbosity.high));
      expect(Verbosity.fromString('invalid'), isNull);
    });

    test('should support minimal reasoning effort', () {
      expect(ReasoningEffort.minimal.value, equals('minimal'));
      expect(ReasoningEffort.fromString('minimal'),
          equals(ReasoningEffort.minimal));
    });

    test('should support verbosity in OpenAI builder', () {
      final builder = ai().openai((openai) => openai.verbosity(Verbosity.high));

      // Verify the builder accepts the verbosity method
      expect(builder, isNotNull);
    });

    test('should support GPT-5 model names', () {
      final models = ['gpt-5', 'gpt-5.1', 'gpt-5-mini', 'gpt-5-nano'];

      for (final model in models) {
        final builder = ai().model(model);
        expect(builder, isNotNull);
      }
    });
  });
}
