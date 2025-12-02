import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabs Vercel-style factory', () {
    test('speech()/transcription() create audio capabilities', () {
      final eleven = createElevenLabs(
        apiKey: 'test-key',
        baseUrl: 'https://api.elevenlabs.test/v1',
        headers: const {'X-Custom': 'value'},
        name: 'my-elevenlabs',
        timeout: const Duration(seconds: 10),
      );

      final speechModel = eleven.speech('eleven_multilingual_v2');
      final sttModel = eleven.transcription('scribe_v1');

      expect(speechModel, isA<AudioCapability>());
      expect(sttModel, isA<AudioCapability>());

      // Underlying provider should be ElevenLabsProvider with correct config.
      final provider = speechModel as ElevenLabsProvider;
      expect(provider.config.apiKey, equals('test-key'));
      expect(
        provider.config.baseUrl,
        equals('https://api.elevenlabs.test/v1/'),
      );
    });

    test('elevenlabs() alias forwards to createElevenLabs', () {
      final instance = elevenlabs(
        apiKey: 'test-key',
        name: 'alias-elevenlabs',
      );

      final speechModel = instance.speech('eleven_multilingual_v2');
      expect(speechModel, isA<AudioCapability>());
    });
  });
}
