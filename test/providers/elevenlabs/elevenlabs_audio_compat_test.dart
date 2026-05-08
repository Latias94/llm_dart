import 'dart:io';
import 'dart:typed_data';

import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart/models/audio_models.dart';
import 'package:llm_dart/providers/elevenlabs/audio.dart';
import 'package:llm_dart/providers/elevenlabs/client.dart';
import 'package:llm_dart/providers/elevenlabs/config.dart';
import 'package:llm_dart_transport/dio.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabsAudio compatibility shell', () {
    test('textToSpeech keeps legacy request shaping and response mapping',
        () async {
      final client = _FakeElevenLabsClient(
        const ElevenLabsConfig(apiKey: 'test-key'),
      )..binaryResponse = [1, 2, 3];
      final audio = ElevenLabsAudio(client, client.config);

      final response = await audio.textToSpeech(
        const TTSRequest(
          text: 'hello world',
          voice: 'voice_123',
          model: 'eleven_turbo_v2',
          languageCode: 'en',
          speed: 1.3,
          providerOptions: modern_community.ElevenLabsSpeechOptions(
            seed: 7,
            previousText: 'before',
            nextText: 'after',
            previousRequestIds: ['a', 'b', 'c', 'd'],
            nextRequestIds: ['x', 'y'],
            enableLogging: false,
            optimizeStreamingLatency: 2,
            stability: 0.9,
            textNormalization: modern_community.ElevenLabsTextNormalization.off,
          ),
        ),
      );

      expect(client.lastBinaryEndpoint, 'text-to-speech/voice_123');
      expect(client.lastBinaryBody, {
        'text': 'hello world',
        'model_id': 'eleven_turbo_v2',
        'voice_settings': {
          'stability': 0.9,
          'speed': 1.3,
        },
        'apply_text_normalization': 'off',
        'language_code': 'en',
        'seed': 7,
        'previous_text': 'before',
        'next_text': 'after',
        'previous_request_ids': ['a', 'b', 'c'],
        'next_request_ids': ['x', 'y'],
      });
      expect(client.lastBinaryQueryParams, {
        'output_format': 'mp3_44100_128',
        'enable_logging': 'false',
        'optimize_streaming_latency': '2',
      });
      expect(response.audioData, [1, 2, 3]);
      expect(response.contentType, 'audio/mpeg');
      expect(response.voice, 'voice_123');
      expect(response.model, 'eleven_turbo_v2');
    });

    test('speechToText bytes path keeps form-data shaping and word join logic',
        () async {
      final client = _FakeElevenLabsClient(
        const ElevenLabsConfig(apiKey: 'test-key'),
      )..formResponse = {
          'text': 'raw text should be replaced',
          'language_code': 'en',
          'language_probability': 0.75,
          'words': [
            {
              'text': 'hello',
              'start': 0.0,
              'end': 0.4,
              'logprob': 0.8,
            },
            {
              'text': 'world',
              'start': 0.5,
              'end': 0.9,
            },
          ],
          'additional_formats': {
            'segments': [
              {'text': 'hello world'},
            ],
          },
        };
      final audio = ElevenLabsAudio(client, client.config);

      final response = await audio.speechToText(
        const STTRequest(
          audioData: [9, 8, 7],
          model: 'scribe_v1',
          language: 'en',
          format: 'wav',
          timestampGranularity: TimestampGranularity.character,
          providerOptions: modern_community.ElevenLabsTranscriptionOptions(
            diarize: true,
            numSpeakers: 2,
            tagAudioEvents: false,
            enableLogging: false,
          ),
        ),
      );

      expect(client.lastFormEndpoint, 'speech-to-text');
      expect(client.lastFormQueryParams, {
        'enable_logging': 'false',
      });
      expect(client.lastFormData, isNotNull);
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        containsPair('model_id', 'scribe_v1'),
      );
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        containsPair('language_code', 'en'),
      );
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        containsPair('tag_audio_events', 'false'),
      );
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        containsPair('num_speakers', '2'),
      );
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        containsPair('timestamps_granularity', 'character'),
      );
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        containsPair('diarize', 'true'),
      );
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        containsPair('file_format', 'wav'),
      );
      expect(client.lastFormData!.files, hasLength(1));
      final file = client.lastFormData!.files.single.value;
      expect(file.filename, 'audio.wav');
      expect(file.contentType?.mimeType, 'audio/wav');

      expect(response.text, 'hello world');
      expect(response.language, 'en');
      expect(response.confidence, 0.75);
      expect(response.words, hasLength(2));
      expect(response.words!.first.word, 'hello');
      expect(response.words!.first.confidence, 0.8);
      final metadata = response.providerMetadata?.namespace('elevenlabs');
      expect(metadata?['languageProbability'], 0.75);
      expect(metadata?['additionalFormats'], {
        'segments': [
          {'text': 'hello world'},
        ],
      });
    });

    test('speechToText source url path keeps form-data shaping', () async {
      final client = _FakeElevenLabsClient(
        const ElevenLabsConfig(apiKey: 'test-key'),
      )..formResponse = {
          'text': 'from source url',
        };
      final audio = ElevenLabsAudio(client, client.config);

      final response = await audio.speechToText(
        STTRequest.fromSourceUrl(
          'https://storage.example.com/audio.mp3',
          providerOptions:
              const modern_community.ElevenLabsTranscriptionOptions(
            enableLogging: false,
          ),
        ),
      );

      expect(client.lastFormEndpoint, 'speech-to-text');
      expect(client.lastFormQueryParams, {
        'enable_logging': 'false',
      });
      expect(client.lastFormData, isNotNull);
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        containsPair('source_url', 'https://storage.example.com/audio.mp3'),
      );
      expect(client.lastFormData!.files, isEmpty);
      expect(response.text, 'from source url');
    });

    test('speechToText file path keeps legacy no-query fallback path',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('llm_dart_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final audioFile =
          File('${tempDir.path}${Platform.pathSeparator}audio.mp3');
      await audioFile.writeAsBytes(const [1, 2, 3]);

      final client = _FakeElevenLabsClient(
        const ElevenLabsConfig(apiKey: 'test-key'),
      )..formResponse = {
          'text': 'from file',
        };
      final audio = ElevenLabsAudio(client, client.config);

      final response = await audio.speechToText(
        STTRequest.fromFile(
          audioFile.path,
        ),
      );

      expect(client.lastFormEndpoint, 'speech-to-text');
      expect(client.lastFormQueryParams, isNull);
      expect(response.text, 'from file');
    });
  });
}

final class _FakeElevenLabsClient extends ElevenLabsClient {
  List<int> binaryResponse = const [];
  Map<String, dynamic> formResponse = const {};
  String? lastBinaryEndpoint;
  Map<String, dynamic>? lastBinaryBody;
  Map<String, String>? lastBinaryQueryParams;
  String? lastFormEndpoint;
  FormData? lastFormData;
  Map<String, String>? lastFormQueryParams;

  _FakeElevenLabsClient(super.config);

  @override
  Future<Uint8List> postBinary(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    cancelToken,
  }) async {
    lastBinaryEndpoint = endpoint;
    lastBinaryBody = data;
    lastBinaryQueryParams = queryParams;
    return Uint8List.fromList(binaryResponse);
  }

  @override
  Future<Map<String, dynamic>> postFormData(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    cancelToken,
  }) async {
    lastFormEndpoint = endpoint;
    lastFormData = formData;
    lastFormQueryParams = queryParams;
    return formResponse;
  }
}
