import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs_pkg;
import 'package:test/test.dart';

void main() {
  group('ElevenLabs package entrypoint', () {
    test('exposes short factory and model constructors', () {
      final provider = elevenlabs_pkg.elevenLabs(apiKey: 'test-key');
      final speechModel = provider.speechModel('eleven_multilingual_v2');
      final transcriptionModel = provider.transcriptionModel('scribe_v1');

      expect(provider, isA<elevenlabs_pkg.ElevenLabs>());
      expect(speechModel.providerId, 'elevenlabs');
      expect(transcriptionModel.providerId, 'elevenlabs');
    });
  });
}
