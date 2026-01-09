import 'dart:typed_data';

import 'package:dio/dio.dart' show FormData;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_elevenlabs/client.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:test/test.dart';

class _FakeElevenLabsClient extends ElevenLabsClient {
  final Uint8List ttsBytes;
  final Map<String, dynamic> sttJson;

  _FakeElevenLabsClient(
    ElevenLabsConfig config, {
    required this.ttsBytes,
    required this.sttJson,
  }) : super(config);

  @override
  Future<Uint8List> postBinary(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    return ttsBytes;
  }

  @override
  Future<Map<String, dynamic>> postFormData(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    return sttJson;
  }
}

void main() {
  group('ElevenLabs providerMetadata', () {
    test('textToSpeech returns providerMetadata with alias', () async {
      final config = ElevenLabsConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.test/v1/',
        voiceId: 'voice_test',
        model: 'tts_test_model',
      );

      final client = _FakeElevenLabsClient(
        config,
        ttsBytes: Uint8List.fromList(const [1, 2, 3]),
        sttJson: const {'text': 'unused'},
      );

      final audio = ElevenLabsAudio(client, config);

      final response = await audio.textToSpeech(const TTSRequest(text: 'hi'));
      expect(response.voice, 'voice_test');
      expect(response.model, 'tts_test_model');

      final metadata = response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata, contains('elevenlabs'));
      expect(metadata, contains('elevenlabs.speech'));

      final payload = metadata!['elevenlabs.speech'] as Map<String, dynamic>;
      expect(payload['model'], 'tts_test_model');
      expect(payload['endpoint'], 'text-to-speech/voice_test');
      expect(payload['voice'], 'voice_test');
    });

    test('speechToText returns providerMetadata with alias', () async {
      final config = ElevenLabsConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.test/v1/',
      );

      final client = _FakeElevenLabsClient(
        config,
        ttsBytes: Uint8List(0),
        sttJson: const {
          'text': 'ok',
          'language_code': 'en',
          'language_probability': 0.9,
          'words': [
            {
              'text': 'ok',
              'start': 0.0,
              'end': 0.1,
            },
          ],
        },
      );

      final audio = ElevenLabsAudio(client, config);

      final response = await audio.speechToText(
        STTRequest(audioData: const [0, 1, 2]),
      );
      expect(response.model, 'scribe_v1');

      final metadata = response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata, contains('elevenlabs'));
      expect(metadata, contains('elevenlabs.transcription'));

      final payload =
          metadata!['elevenlabs.transcription'] as Map<String, dynamic>;
      expect(payload['model'], 'scribe_v1');
      expect(payload['endpoint'], 'speech-to-text');
    });
  });
}
