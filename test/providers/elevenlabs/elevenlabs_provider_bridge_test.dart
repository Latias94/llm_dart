import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:llm_dart/legacy.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabsProvider bridge delegation', () {
    test('textToSpeech delegates shared requests to the community speech model',
        () async {
      RequestOptions? capturedOptions;
      Object? capturedBody;
      final dio = _buildResolvedDio((options) {
        capturedOptions = options;
        capturedBody = options.data;
        return Response(
          requestOptions: options,
          statusCode: 200,
          headers: Headers.fromMap({
            'content-type': ['audio/pcm'],
            'x-request-id': ['req_tts_123'],
          }),
          data: [1, 2, 3, 4],
        );
      });

      final provider = ElevenLabsProvider(
        ElevenLabsConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          voiceId: 'voice_default',
          model: 'eleven_multilingual_v2',
          dioOverrides: ImmutableDioClientOverrides(customDio: dio),
          stability: 0.2,
          similarityBoost: 0.3,
          style: 0.4,
          useSpeakerBoost: true,
        ),
      );

      final response = await provider.textToSpeech(
        const TTSRequest(
          text: 'Hello bridge.',
          voice: 'voice_override',
          format: 'pcm',
          sampleRate: 16000,
          languageCode: 'en',
          speed: 1.1,
          seed: 7,
          previousText: 'Earlier text.',
          nextText: 'Later text.',
          previousRequestIds: ['req_prev_1', 'req_prev_2', 'req_prev_3'],
          nextRequestIds: ['req_next_1'],
          textNormalization: TextNormalization.off,
          enableLogging: false,
          optimizeStreamingLatency: 2,
          stability: 0.8,
          similarityBoost: 0.9,
          style: 1.0,
          useSpeakerBoost: false,
        ),
      );

      expect(response.audioData, [1, 2, 3, 4]);
      expect(response.contentType, 'audio/pcm');
      expect(response.requestId, 'req_tts_123');

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.uri.path, '/v1/text-to-speech/voice_override');
      expect(
        capturedOptions!.uri.queryParameters,
        {
          'output_format': 'pcm_16000',
          'enable_logging': 'false',
          'optimize_streaming_latency': '2',
        },
      );
      expect(
        capturedBody,
        {
          'text': 'Hello bridge.',
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.8,
            'similarity_boost': 0.9,
            'style': 1.0,
            'speed': 1.1,
            'use_speaker_boost': false,
          },
          'language_code': 'en',
          'seed': 7,
          'previous_text': 'Earlier text.',
          'next_text': 'Later text.',
          'previous_request_ids': ['req_prev_1', 'req_prev_2', 'req_prev_3'],
          'next_request_ids': ['req_next_1'],
          'apply_text_normalization': 'off',
        },
      );
    });

    test('speechToText with audio bytes delegates to the community model',
        () async {
      RequestOptions? capturedOptions;
      Object? capturedBody;
      final dio = _buildResolvedDio((options) {
        capturedOptions = options;
        capturedBody = options.data;
        return Response(
          requestOptions: options,
          statusCode: 200,
          headers: Headers.fromMap({
            'x-request-id': ['req_stt_456'],
          }),
          data: {
            'text': 'hello world',
            'language_code': 'en',
            'language_probability': 0.98,
            'words': [
              {
                'text': 'hello',
                'start': 0.0,
                'end': 0.5,
              },
            ],
            'additional_formats': {
              'segments': [
                {'text': 'hello world'},
              ],
            },
          },
        );
      });

      final provider = ElevenLabsProvider(
        ElevenLabsConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          dioOverrides: ImmutableDioClientOverrides(customDio: dio),
        ),
      );

      final response = await provider.speechToText(
        const STTRequest(
          audioData: [1, 2, 3],
          model: 'scribe_v1',
          language: 'en',
          format: 'pcm_s16le_16',
          timestampGranularity: TimestampGranularity.character,
          diarize: true,
          numSpeakers: 2,
          tagAudioEvents: false,
          enableLogging: false,
        ),
      );

      expect(response.text, 'hello world');
      expect(response.language, 'en');
      expect(response.confidence, 0.98);
      expect(response.languageProbability, 0.98);
      expect(response.words, isNotNull);
      expect(response.words!.single.word, 'hello');
      expect(response.additionalFormats, {
        'segments': [
          {'text': 'hello world'},
        ],
      });

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.uri.path, '/v1/speech-to-text');
      expect(
        capturedOptions!.uri.queryParameters,
        {
          'enable_logging': 'false',
        },
      );
      expect(
        capturedOptions!.headers['content-type'] as String,
        startsWith('multipart/form-data; boundary='),
      );

      final bodyText =
          utf8.decode(capturedBody! as List<int>, allowMalformed: true);
      expect(bodyText, contains('name="file"; filename="audio.pcm"'));
      expect(bodyText, contains('Content-Type: audio/pcm'));
      expect(bodyText, contains('name="model_id"'));
      expect(bodyText, contains('scribe_v1'));
      expect(bodyText, contains('name="language_code"'));
      expect(bodyText, contains('name="tag_audio_events"'));
      expect(bodyText, contains('false'));
      expect(bodyText, contains('name="num_speakers"'));
      expect(bodyText, contains('2'));
      expect(bodyText, contains('name="timestamps_granularity"'));
      expect(bodyText, contains('character'));
      expect(bodyText, contains('name="diarize"'));
      expect(bodyText, contains('name="file_format"'));
      expect(bodyText, contains('pcm_s16le_16'));
    });

    test('speechToText falls back to the legacy audio shell for file input',
        () async {
      RequestOptions? capturedOptions;
      Object? capturedBody;
      final tempDir = await Directory.systemTemp.createTemp('llm_dart_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final audioFile =
          File('${tempDir.path}${Platform.pathSeparator}audio.wav');
      await audioFile.writeAsBytes(const [1, 2, 3, 4]);

      final dio = _buildResolvedDio((options) {
        capturedOptions = options;
        capturedBody = options.data;
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'text': 'legacy file path',
            'language_code': 'en',
          },
        );
      });

      final provider = ElevenLabsProvider(
        ElevenLabsConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.elevenlabs.io/v1/',
          dioOverrides: ImmutableDioClientOverrides(customDio: dio),
        ),
      );

      final response = await provider.speechToText(
        STTRequest.fromFile(
          audioFile.path,
          language: 'en',
        ),
      );

      expect(response.text, 'legacy file path');
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.uri.path, '/v1/speech-to-text');
      expect(capturedOptions!.uri.query, isEmpty);
      expect(capturedBody, isA<FormData>());
    });
  });
}

Dio _buildResolvedDio(
  Response<dynamic> Function(RequestOptions options) handle,
) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(handle(options)),
    ),
  );
  return dio;
}
