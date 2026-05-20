import 'package:llm_dart_openai/src/moderation/openai_moderation_body.dart';
import 'package:llm_dart_openai/src/moderation/openai_moderation_options.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI moderation body projection', () {
    test('maps string input and default model to OpenAI JSON fields', () {
      final body = buildOpenAIModerationRequestBody(
        input: 'Hello world',
        model: null,
        settings: const OpenAIModerationSettings(
          defaultModel: 'omni-moderation-latest',
        ),
      );

      expect(
        body,
        {
          'input': 'Hello world',
          'model': 'omni-moderation-latest',
        },
      );
    });

    test('call model overrides default model', () {
      final body = buildOpenAIModerationRequestBody(
        input: const ['Safe note', 'Risky note'],
        model: 'omni-moderation-2025-09-01',
        settings: const OpenAIModerationSettings(
          defaultModel: 'omni-moderation-latest',
        ),
      );

      expect(
        body,
        {
          'input': ['Safe note', 'Risky note'],
          'model': 'omni-moderation-2025-09-01',
        },
      );
    });

    test('rejects non-string batch values', () {
      expect(
        () => buildOpenAIModerationRequestBody(
          input: ['Safe note', 42],
          model: null,
          settings: const OpenAIModerationSettings(),
        ),
        throwsArgumentError,
      );
    });
  });
}
