import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
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

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
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
        callOptions: const CallOptions(
          timeout: Duration(seconds: 5),
          headers: {
            'x-call': '2',
          },
          providerOptions: GoogleSpeechOptions(
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
  });
}

typedef _FakeTransportClient = FakeTransportClient;
