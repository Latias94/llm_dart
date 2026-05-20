import 'package:llm_dart_elevenlabs/src/elevenlabs_speech_options.dart';
import 'package:llm_dart_elevenlabs/src/elevenlabs_speech_request_policy.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabs speech request policy', () {
    test('rejects invalid ratio, seed, request ids, and dictionaries', () {
      expect(
        () => validateElevenLabsSpeechOptions(
          const ElevenLabsSpeechOptions(stability: 1.1),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'providerOptions.stability',
          ),
        ),
      );
      expect(
        () => validateElevenLabsSpeechOptions(
          const ElevenLabsSpeechOptions(seed: -1),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'providerOptions.seed',
          ),
        ),
      );
      expect(
        () => validateElevenLabsSpeechOptions(
          const ElevenLabsSpeechOptions(previousRequestIds: ['']),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'providerOptions.previousRequestIds',
          ),
        ),
      );
      expect(
        () => validateElevenLabsSpeechOptions(
          const ElevenLabsSpeechOptions(
            pronunciationDictionaryLocators: [
              ElevenLabsPronunciationDictionaryLocator(
                pronunciationDictionaryId: '',
              ),
            ],
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'providerOptions.pronunciationDictionaryLocators',
          ),
        ),
      );
    });

    test('adds unsupported warnings for instructions', () {
      final warnings = <ModelWarning>[];

      warnElevenLabsSpeechUnsupportedRequestFields(
        const SpeechGenerationRequest(
          text: 'Hello',
          instructions: 'Speak warmly',
          callOptions: CallOptions(),
        ),
        warnings,
      );

      expect(warnings, hasLength(1));
      expect(warnings.single.type, ModelWarningType.unsupported);
      expect(warnings.single.feature, 'instructions');
    });
  });
}
