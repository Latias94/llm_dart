import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/defaults.dart';
import 'package:llm_dart_openai/openai.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAI audio providerMetadata', () {
    test('textToSpeech attaches openai + openai.speech metadata', () async {
      final config = OpenAIConfig(apiKey: 'test-key');
      final client = FakeOpenAIClient(config);
      final audio = OpenAIAudio(client, config);

      final resp = await audio.textToSpeech(const TTSRequest(text: 'hi'));

      expect(client.lastEndpoint, 'audio/speech');
      expect(resp.model, openaiDefaultTTSModel);

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('openai'), isTrue);
      expect(meta.containsKey('openai.speech'), isTrue);
      expect(
        meta['openai.speech'],
        equals({
          'model': openaiDefaultTTSModel,
          'endpoint': 'audio/speech',
        }),
      );
    });

    test('speechToText attaches openai + openai.transcription metadata',
        () async {
      final config = OpenAIConfig(apiKey: 'test-key');
      final client = FakeOpenAIClient(config);
      final audio = OpenAIAudio(client, config);

      final resp = await audio.speechToText(
        const STTRequest(audioData: [1, 2, 3], model: 'whisper-1'),
      );

      expect(client.lastEndpoint, 'audio/transcriptions');
      expect(resp.model, 'whisper-1');

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('openai'), isTrue);
      expect(meta.containsKey('openai.transcription'), isTrue);
      expect(
        meta['openai.transcription'],
        equals({
          'model': 'whisper-1',
          'endpoint': 'audio/transcriptions',
        }),
      );
    });

    test('translateAudio attaches openai + openai.transcription metadata',
        () async {
      final config = OpenAIConfig(apiKey: 'test-key');
      final client = FakeOpenAIClient(config);
      final audio = OpenAIAudio(client, config);

      final resp = await audio.translateAudio(
        const AudioTranslationRequest(audioData: [1, 2, 3], model: 'whisper-1'),
      );

      expect(client.lastEndpoint, 'audio/translations');
      expect(resp.model, 'whisper-1');

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('openai'), isTrue);
      expect(meta.containsKey('openai.transcription'), isTrue);
      expect(
        meta['openai.transcription'],
        equals({
          'model': 'whisper-1',
          'endpoint': 'audio/translations',
        }),
      );
    });
  });
}
