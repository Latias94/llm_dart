import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_openai/src/speech/openai_speech_model_body.dart';
import 'package:llm_dart_openai/src/speech/openai_speech_options.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI speech body projection', () {
    test('maps common speech fields to OpenAI JSON fields', () {
      final body = buildOpenAISpeechRequestBody(
        modelId: 'gpt-4o-mini-tts',
        request: SpeechGenerationRequest(
          text: 'Hello world.',
          voice: 'alloy',
          outputFormat: 'wav',
          instructions: 'Speak calmly.',
          speed: 1.1,
        ),
        options: null,
        outputFormat: 'wav',
      );

      expect(
        body,
        {
          'model': 'gpt-4o-mini-tts',
          'input': 'Hello world.',
          'voice': 'alloy',
          'response_format': 'wav',
          'instructions': 'Speak calmly.',
          'speed': 1.1,
        },
      );
    });

    test('common fields override OpenAI provider options', () {
      final body = buildOpenAISpeechRequestBody(
        modelId: 'gpt-4o-mini-tts',
        request: SpeechGenerationRequest(
          text: 'Hello world.',
          instructions: 'Use shared instructions.',
          speed: 1.5,
        ),
        options: const OpenAISpeechOptions(
          instructions: 'Use provider instructions.',
          speed: 0.75,
        ),
        outputFormat: 'opus',
      );

      expect(
        body,
        {
          'model': 'gpt-4o-mini-tts',
          'input': 'Hello world.',
          'voice': 'alloy',
          'response_format': 'opus',
          'instructions': 'Use shared instructions.',
          'speed': 1.5,
        },
      );
    });

    test('falls back to OpenAI provider options when common fields are absent',
        () {
      final body = buildOpenAISpeechRequestBody(
        modelId: 'gpt-4o-mini-tts',
        request: SpeechGenerationRequest(
          text: 'Hello world.',
        ),
        options: const OpenAISpeechOptions(
          instructions: 'Use provider instructions.',
          speed: 0.75,
        ),
        outputFormat: 'mp3',
      );

      expect(
        body,
        {
          'model': 'gpt-4o-mini-tts',
          'input': 'Hello world.',
          'voice': 'alloy',
          'response_format': 'mp3',
          'instructions': 'Use provider instructions.',
          'speed': 0.75,
        },
      );
    });
  });
}
