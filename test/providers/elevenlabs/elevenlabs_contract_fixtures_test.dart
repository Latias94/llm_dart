import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' show FormData;
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

Map<String, dynamic> _readJson(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, dynamic>();

Uint8List _decodeBase64(String value) => base64Decode(value);

String _fieldValue(FormData form, String key) =>
    form.fields.firstWhere((e) => e.key == key).value;

bool _hasField(FormData form, String key) =>
    form.fields.any((e) => e.key == key);

void main() {
  group('ElevenLabs contract fixtures', () {
    test('TTS: request mapping + providerMetadata + audio bytes', () async {
      final req = _readJson(
        'test/fixtures/elevenlabs/tts/elevenlabs-tts-basic.1.request.json',
      );
      final res = _readJson(
        'test/fixtures/elevenlabs/tts/elevenlabs-tts-basic.1.response.json',
      );

      final config = ElevenLabsConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
        voiceId: 'voice_test',
        model: 'eleven_multilingual_v2',
        stability: 0.5,
        similarityBoost: 0.75,
      );

      final client = FakeElevenLabsClient(config)
        ..ttsBytes = _decodeBase64(res['audioBase64'] as String);

      final audio = ElevenLabsAudio(client, config);
      final response = await audio.textToSpeech(
        const TTSRequest(
          text: 'Hello, world!',
          voice: 'voice_test',
          model: 'eleven_multilingual_v2',
          seed: 123,
          languageCode: 'en',
          speed: 1.25,
        ),
      );

      expect(client.lastEndpoint, equals(req['endpoint']));
      expect(
        client.lastQueryParams,
        equals((req['queryParams'] as Map).cast<String, String>()),
      );

      expect(client.lastBody, isNotNull);
      expect(client.lastBody, equals(req['body']));

      expect(response.audioData,
          equals(_decodeBase64(res['audioBase64'] as String)));
      expect(response.contentType, equals(res['contentType']));

      final metadata = response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata, contains('elevenlabs'));
      expect(metadata, contains('elevenlabs.speech'));
    });

    test('STT: multipart fields + response mapping + providerMetadata',
        () async {
      final req = _readJson(
        'test/fixtures/elevenlabs/stt/elevenlabs-stt-basic.1.request.json',
      );
      final res = _readJson(
        'test/fixtures/elevenlabs/stt/elevenlabs-stt-basic.1.response.json',
      );

      final config = ElevenLabsConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
      );

      final client = FakeElevenLabsClient(config)..sttJson = res;
      final audio = ElevenLabsAudio(client, config);

      final response = await audio.speechToText(
        const STTRequest(
          audioData: [1, 2, 3],
          model: 'scribe_v1',
          language: 'en',
          diarize: true,
          numSpeakers: 2,
          timestampGranularity: TimestampGranularity.character,
        ),
      );

      expect(client.lastEndpoint, equals(req['endpoint']));
      expect(client.lastFormData, isNotNull);

      final form = client.lastFormData!;
      expect(_hasField(form, 'model_id'), isTrue);
      expect(_fieldValue(form, 'model_id'), equals('scribe_v1'));

      final expectedFields = (req['fields'] as Map)
          .cast<String, dynamic>()
          .map((k, v) => MapEntry(k, v.toString()));
      for (final entry in expectedFields.entries) {
        expect(_hasField(form, entry.key), isTrue);
        expect(_fieldValue(form, entry.key), equals(entry.value));
      }

      final expectsFileField = req['expectsFileField'] == true;
      if (expectsFileField) {
        expect(form.files.any((e) => e.key == 'file'), isTrue);
      }

      expect(response.text, equals(res['text']));
      expect(response.language, equals(res['language_code']));

      final metadata = response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata, contains('elevenlabs'));
      expect(metadata, contains('elevenlabs.transcription'));
    });
  });
}
