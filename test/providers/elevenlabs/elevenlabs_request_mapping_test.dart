import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class _CapturingHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;

    if (options.responseType == ResponseType.bytes) {
      return ResponseBody.fromBytes(
        const [0, 1, 2, 3],
        200,
        headers: {
          Headers.contentTypeHeader: ['audio/mpeg'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'text': 'ok',
        'language_code': 'en',
        'language_probability': 0.9,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  group('ElevenLabs request mapping (AI SDK parity)', () {
    test('TTS: maps voice/model + output_format + request voice settings', () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
        model: 'eleven_multilingual_v2',
      ).withTransportOptions({'customDio': customDio}).withProviderOptions(
        'elevenlabs',
        {
          'stability': 0.5,
          'similarityBoost': 0.75,
        },
      );

      final factory = ElevenLabsProviderFactory();
      final provider = factory.create(llmConfig);

      await provider.textToSpeech(
        const TTSRequest(
          text: 'Hello, world!',
          voice: 'test-voice-id',
          speed: 1.5,
          seed: 123,
        ),
      );

      final req = adapter.lastRequest;
      expect(req, isNotNull);
      expect(req!.method.toUpperCase(), equals('POST'));
      expect(req.headers['xi-api-key'], equals('test-api-key'));

      expect(req.uri.toString(), contains('/v1/text-to-speech/test-voice-id'));
      expect(req.uri.queryParameters['output_format'], equals('mp3_44100_128'));

      final body = req.data;
      expect(body, isA<Map>());
      final map = Map<String, dynamic>.from(body as Map);
      expect(map['text'], equals('Hello, world!'));
      expect(map['model_id'], equals('eleven_multilingual_v2'));
      expect(map['seed'], equals(123));
      expect(map['voice_settings'], isA<Map>());

      final voiceSettings =
          Map<String, dynamic>.from(map['voice_settings'] as Map);
      expect(voiceSettings['stability'], equals(0.5));
      expect(voiceSettings['similarity_boost'], equals(0.75));
      expect(voiceSettings['speed'], equals(1.5));
    });

    test('TTS: omits voice_settings when empty', () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
        model: 'eleven_multilingual_v2',
      ).withTransportOptions({'customDio': customDio});

      final factory = ElevenLabsProviderFactory();
      final provider = factory.create(llmConfig);

      await provider.textToSpeech(
        const TTSRequest(
          text: 'Hello, world!',
          voice: 'test-voice-id',
        ),
      );

      final req = adapter.lastRequest;
      expect(req, isNotNull);

      final body = req!.data;
      expect(body, isA<Map>());
      final map = Map<String, dynamic>.from(body as Map);
      expect(map.containsKey('voice_settings'), isFalse);
    });

    test('STT: uses multipart form-data with model_id and file', () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
        model: 'eleven_multilingual_v2',
      ).withTransportOptions({'customDio': customDio});

      final factory = ElevenLabsProviderFactory();
      final provider = factory.create(llmConfig);

      await provider.speechToText(
        const STTRequest(audioData: [1, 2, 3], model: 'scribe_v1'),
      );

      final req = adapter.lastRequest;
      expect(req, isNotNull);
      expect(req!.method.toUpperCase(), equals('POST'));
      expect(req.uri.toString(), contains('/v1/speech-to-text'));
      expect(req.headers['xi-api-key'], equals('test-api-key'));

      final contentTypeHeader = req.headers.entries
          .firstWhere(
            (e) => e.key.toLowerCase() == 'content-type',
            orElse: () => const MapEntry<String, dynamic>('', null),
          )
          .value
          ?.toString();
      expect(contentTypeHeader, isNotNull);
      expect(contentTypeHeader, startsWith('multipart/form-data'));

      final body = req.data;
      expect(body, isA<FormData>());
      final form = body as FormData;

      expect(form.fields.any((e) => e.key == 'model_id' && e.value == 'scribe_v1'),
          isTrue);
      expect(form.files.any((e) => e.key == 'file'), isTrue);
    });
  });
}

