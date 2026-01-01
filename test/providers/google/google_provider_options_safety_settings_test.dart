import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Google providerOptions safetySettings', () {
    test('parses safetySettings from JSON-like maps', () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerOptions: const {
          'google': {
            'safetySettings': [
              {
                'category': 'HARM_CATEGORY_HATE_SPEECH',
                'threshold': 'BLOCK_NONE',
              },
            ],
          },
        },
      );

      final config = GoogleConfig.fromLLMConfig(llmConfig);
      expect(config.safetySettings, isNotNull);
      expect(config.safetySettings, hasLength(1));
      expect(
        config.safetySettings!.first.category,
        equals(HarmCategory.harmCategoryHateSpeech),
      );
      expect(
        config.safetySettings!.first.threshold,
        equals(HarmBlockThreshold.blockNone),
      );
    });

    test('accepts typed SafetySetting entries', () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerOptions: {
          'google': {
            'safetySettings': const [
              SafetySetting(
                category: HarmCategory.harmCategoryHarassment,
                threshold: HarmBlockThreshold.blockOnlyHigh,
              ),
            ],
          },
        },
      );

      final config = GoogleConfig.fromLLMConfig(llmConfig);
      expect(config.safetySettings, isNotNull);
      expect(config.safetySettings, hasLength(1));
      expect(
        config.safetySettings!.first.category,
        equals(HarmCategory.harmCategoryHarassment),
      );
    });

    test('ignores invalid safetySettings entries', () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerOptions: const {
          'google': {
            'safetySettings': [
              {'category': 'INVALID', 'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'INVALID'},
              'not-a-map',
            ],
          },
        },
      );

      final config = GoogleConfig.fromLLMConfig(llmConfig);
      expect(config.safetySettings, isNull);
    });
  });
}
