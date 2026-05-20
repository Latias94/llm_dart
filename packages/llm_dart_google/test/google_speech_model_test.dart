import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'dart:convert';

import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleSpeechModel', () {
    test('Google factory exposes a Google speech model', () {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('gemini-2.5-flash-preview-tts');

      expect(model.providerId, 'google');
      expect(model.baseUrl, Google.defaultBaseUrl);
    });

    test('generateSpeech sends a single-speaker request and decodes audio',
        () async {
      TransportRequest? capturedRequest;
      final cancelToken = ProviderCancellation();

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              headers: const {
                'x-request-id': 'google-speech-1',
              },
              body: {
                'modelVersion': 'gemini-2.5-flash-preview-tts',
                'usageMetadata': {
                  'promptTokenCount': 8,
                  'totalTokenCount': 12,
                },
                'candidates': [
                  {
                    'finishReason': 'STOP',
                    'content': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/wav',
                            'data': base64Encode([1, 2, 3, 4]),
                          },
                        },
                      ],
                    },
                  },
                ],
              },
            );
          },
        ),
      ).speechModel(
        'gemini-2.5-flash-preview-tts',
        settings: const GoogleSpeechModelSettings(
          headers: {
            'x-settings': '1',
          },
          defaultVoice: 'Kore',
        ),
      );

      final result = await generateSpeech(
        model: model,
        text: 'Hello world.',
        voice: 'Puck',
        callOptions: CallOptions(
          timeout: const Duration(seconds: 5),
          headers: const {
            'x-call': '2',
          },
          cancellation: cancelToken,
          providerOptions: const GoogleSpeechOptions(
            temperature: 0.4,
            topP: 0.9,
            topK: 32,
            maxOutputTokens: 256,
            stopSequences: ['END'],
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent',
      );
      expect(capturedRequest!.cancellation, isNotNull);
      expect(capturedRequest!.headers, {
        'x-goog-api-key': 'test-key',
        'content-type': 'application/json',
        'accept': 'application/json',
        'x-settings': '1',
        'x-call': '2',
      });
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(
        capturedRequest!.body,
        {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Hello world.',
                },
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': 'Puck',
                },
              },
            },
            'temperature': 0.4,
            'topP': 0.9,
            'topK': 32,
            'maxOutputTokens': 256,
            'stopSequences': ['END'],
          },
        },
      );
      expect(result.audioBytes, [1, 2, 3, 4]);
      expect(result.mediaType, 'audio/wav');
      expect(result.warnings, isEmpty);
      expect(result.responseMetadata, isNotNull);
      expect(result.responseMetadata!.modelId, 'gemini-2.5-flash-preview-tts');
      expect(result.responseMetadata!.timestamp, isA<DateTime>());
      expect(
        result.responseMetadata!.headers,
        containsPair('x-request-id', 'google-speech-1'),
      );
      expect(
        result.providerMetadata?.namespace('google'),
        {
          'generationApi': 'generateContent',
          'modelVersion': 'gemini-2.5-flash-preview-tts',
          'usage': {
            'promptTokenCount': 8,
            'totalTokenCount': 12,
          },
          'finishReasons': ['STOP'],
        },
      );
    });

    test('speech model falls back to the configured default voice', () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/pcm',
                            'data': base64Encode([5, 6]),
                          },
                        },
                      ],
                    },
                  },
                ],
              },
            );
          },
        ),
      ).speechModel(
        'gemini-2.5-flash-preview-tts',
        settings: const GoogleSpeechModelSettings(defaultVoice: 'Kore'),
      );

      final result = await generateSpeech(
        model: model,
        text: 'Hello world.',
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Hello world.',
                },
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': 'Kore',
                },
              },
            },
          },
        },
      );
      expect(result.audioBytes, [5, 6]);
      expect(result.mediaType, 'audio/pcm');
      expect(result.responseMetadata, isNotNull);
      expect(result.responseMetadata!.modelId, 'gemini-2.5-flash-preview-tts');
    });

    test('speech model supports provider-owned multi-speaker options',
        () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/pcm',
                            'data': base64Encode([7, 8]),
                          },
                        },
                      ],
                    },
                  },
                ],
              },
            );
          },
        ),
      ).speechModel('gemini-2.5-flash-preview-tts');

      await generateSpeech(
        model: model,
        text: 'Speaker1: Hello. Speaker2: Hi.',
        callOptions: const CallOptions(
          providerOptions: GoogleSpeechOptions(
            speakers: [
              GoogleSpeechSpeakerVoice(
                speaker: 'Speaker1',
                voice: 'Kore',
              ),
              GoogleSpeechSpeakerVoice(
                speaker: 'Speaker2',
                voice: 'Puck',
              ),
            ],
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Speaker1: Hello. Speaker2: Hi.',
                },
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'multiSpeakerVoiceConfig': {
                'speakerVoiceConfigs': [
                  {
                    'speaker': 'Speaker1',
                    'voiceConfig': {
                      'prebuiltVoiceConfig': {
                        'voiceName': 'Kore',
                      },
                    },
                  },
                  {
                    'speaker': 'Speaker2',
                    'voiceConfig': {
                      'prebuiltVoiceConfig': {
                        'voiceName': 'Puck',
                      },
                    },
                  },
                ],
              },
            },
          },
        },
      );
    });

    test('speech model warning-drops unsupported shared speech fields',
        () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/pcm',
                            'data': base64Encode([1, 2]),
                          },
                        },
                      ],
                    },
                  },
                ],
              },
            );
          },
        ),
      ).speechModel('gemini-2.5-flash-preview-tts');

      final result = await generateSpeech(
        model: model,
        text: 'Hello world.',
        outputFormat: 'mp3',
        instructions: 'Speak clearly.',
        speed: 1.2,
        language: 'en',
      );

      expect(capturedRequest, isNotNull);
      expect(result.audioBytes, [1, 2]);
      expect(
        result.warnings.map((warning) => warning.field),
        ['outputFormat', 'instructions', 'speed', 'language'],
      );
    });

    test('speech model rejects incompatible provider options', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('gemini-2.5-flash-preview-tts');

      await expectLater(
        () => generateSpeech(
          model: model,
          text: 'Hello',
          callOptions: const CallOptions(
            providerOptions: GoogleImageOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected GoogleSpeechOptions'),
          ),
        ),
      );
    });

    test('speech model rejects mixed single-speaker and multi-speaker input',
        () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('gemini-2.5-flash-preview-tts');

      await expectLater(
        () => generateSpeech(
          model: model,
          text: 'Hello',
          voice: 'Kore',
          callOptions: const CallOptions(
            providerOptions: GoogleSpeechOptions(
              speakers: [
                GoogleSpeechSpeakerVoice(
                  speaker: 'Speaker1',
                  voice: 'Puck',
                ),
              ],
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('do not allow request.voice together'),
          ),
        ),
      );
    });

    test('speech response rejects non-object JSON bodies', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (_) async => const TransportResponse(
            statusCode: 200,
            body: '[]',
          ),
        ),
      ).speechModel('gemini-2.5-flash-preview-tts');

      await expectLater(
        () => generateSpeech(
          model: model,
          text: 'Hello',
        ),
        throwsA(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains('Google speech API returned JSON that is not an object'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
