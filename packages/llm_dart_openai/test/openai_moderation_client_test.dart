import 'dart:convert';

import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIModerationClient', () {
    test('moderateText sends moderation request with configured headers',
        () async {
      TransportRequest? capturedRequest;

      final moderation = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'modr_123',
                'model': 'omni-moderation-latest',
                'results': [
                  {
                    'flagged': false,
                    'categories': {
                      'hate': false,
                      'hate/threatening': false,
                      'harassment': false,
                      'harassment/threatening': false,
                      'self-harm': false,
                      'self-harm/intent': false,
                      'self-harm/instructions': false,
                      'sexual': false,
                      'sexual/minors': false,
                      'violence': false,
                      'violence/graphic': false,
                    },
                    'category_scores': {
                      'hate': 0.01,
                      'hate/threatening': 0.0,
                      'harassment': 0.02,
                      'harassment/threatening': 0.0,
                      'self-harm': 0.0,
                      'self-harm/intent': 0.0,
                      'self-harm/instructions': 0.0,
                      'sexual': 0.03,
                      'sexual/minors': 0.0,
                      'violence': 0.01,
                      'violence/graphic': 0.0,
                    },
                  },
                ],
              },
            );
          },
        ),
      ).moderation(
        settings: const OpenAIModerationSettings(
          defaultModel: 'omni-moderation-latest',
          organization: 'org_123',
          project: 'proj_456',
          headers: {
            'x-settings': '1',
          },
        ),
      );

      final result = await moderation.moderateText(
        'Hello world',
        timeout: const Duration(seconds: 5),
        headers: const {
          'x-call': '2',
        },
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://api.openai.com/v1/moderations',
      );
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(
        capturedRequest!.headers,
        containsPair('authorization', 'Bearer test-key'),
      );
      expect(
        capturedRequest!.headers,
        containsPair('openai-organization', 'org_123'),
      );
      expect(
        capturedRequest!.headers,
        containsPair('openai-project', 'proj_456'),
      );
      expect(
        capturedRequest!.headers,
        containsPair('content-type', 'application/json'),
      );
      expect(
        capturedRequest!.headers,
        containsPair('accept', 'application/json'),
      );
      expect(capturedRequest!.headers, containsPair('x-settings', '1'));
      expect(capturedRequest!.headers, containsPair('x-call', '2'));
      expect(
        capturedRequest!.body,
        {
          'input': 'Hello world',
          'model': 'omni-moderation-latest',
        },
      );

      expect(result.flagged, isFalse);
      expect(result.categories.sexual, isFalse);
      expect(result.categoryScores.sexual, closeTo(0.03, 0.0001));
      expect(result.categories.flaggedCategories, isEmpty);
    });

    test('moderateTexts encodes batch input and isTextSafe uses decoded flag',
        () async {
      final requests = <TransportRequest>[];
      var callCount = 0;

      final moderation = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            requests.add(request);
            callCount += 1;

            if (callCount == 1) {
              return const TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'modr_batch',
                  'model': 'omni-moderation-latest',
                  'results': [
                    {
                      'flagged': false,
                      'categories': {
                        'hate': false,
                        'hate/threatening': false,
                        'harassment': false,
                        'harassment/threatening': false,
                        'self-harm': false,
                        'self-harm/intent': false,
                        'self-harm/instructions': false,
                        'sexual': false,
                        'sexual/minors': false,
                        'violence': false,
                        'violence/graphic': false,
                      },
                      'category_scores': {
                        'hate': 0.0,
                        'hate/threatening': 0.0,
                        'harassment': 0.0,
                        'harassment/threatening': 0.0,
                        'self-harm': 0.0,
                        'self-harm/intent': 0.0,
                        'self-harm/instructions': 0.0,
                        'sexual': 0.0,
                        'sexual/minors': 0.0,
                        'violence': 0.0,
                        'violence/graphic': 0.0,
                      },
                    },
                    {
                      'flagged': true,
                      'categories': {
                        'hate': false,
                        'hate/threatening': false,
                        'harassment': true,
                        'harassment/threatening': false,
                        'self-harm': false,
                        'self-harm/intent': false,
                        'self-harm/instructions': false,
                        'sexual': false,
                        'sexual/minors': false,
                        'violence': false,
                        'violence/graphic': false,
                      },
                      'category_scores': {
                        'hate': 0.0,
                        'hate/threatening': 0.0,
                        'harassment': 0.78,
                        'harassment/threatening': 0.02,
                        'self-harm': 0.0,
                        'self-harm/intent': 0.0,
                        'self-harm/instructions': 0.0,
                        'sexual': 0.01,
                        'sexual/minors': 0.0,
                        'violence': 0.03,
                        'violence/graphic': 0.0,
                      },
                    },
                  ],
                },
              );
            }

            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'modr_safe',
                'model': 'omni-moderation-latest',
                'results': [
                  {
                    'flagged': false,
                    'categories': {
                      'hate': false,
                      'hate/threatening': false,
                      'harassment': false,
                      'harassment/threatening': false,
                      'self-harm': false,
                      'self-harm/intent': false,
                      'self-harm/instructions': false,
                      'sexual': false,
                      'sexual/minors': false,
                      'violence': false,
                      'violence/graphic': false,
                    },
                    'category_scores': {
                      'hate': 0.0,
                      'hate/threatening': 0.0,
                      'harassment': 0.0,
                      'harassment/threatening': 0.0,
                      'self-harm': 0.0,
                      'self-harm/intent': 0.0,
                      'self-harm/instructions': 0.0,
                      'sexual': 0.0,
                      'sexual/minors': 0.0,
                      'violence': 0.0,
                      'violence/graphic': 0.0,
                    },
                  },
                ],
              },
            );
          },
        ),
      ).moderation();

      final results = await moderation.moderateTexts(
        const [
          'Safe note',
          'Harassing note',
        ],
        model: 'omni-moderation-latest',
      );
      final safe = await moderation.isTextSafe('Completely safe');

      expect(requests, hasLength(2));
      expect(
        requests.first.body,
        {
          'input': ['Safe note', 'Harassing note'],
          'model': 'omni-moderation-latest',
        },
      );
      expect(results, hasLength(2));
      expect(results.first.flagged, isFalse);
      expect(results.last.flagged, isTrue);
      expect(results.last.categories.harassment, isTrue);
      expect(results.last.categories.flaggedCategories, ['harassment']);
      expect(safe, isTrue);
    });

    test('rejects non-openai profiles', () {
      expect(
        () => OpenAI(
          apiKey: 'test-key',
          profile: const XAIProfile(),
        ).moderation(),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('supports only the OpenAI profile'),
          ),
        ),
      );
    });

    test('moderate accepts string JSON bodies', () async {
      final moderation = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (_) async => TransportResponse(
            statusCode: 200,
            body: jsonEncode(_moderationResponseBody()),
          ),
        ),
      ).moderation();

      final result = await moderation.moderateText('Hello world');

      expect(result.flagged, isFalse);
      expect(result.categoryScores.harassment, 0.0);
    });

    test('moderate rejects non-object JSON bodies', () async {
      final moderation = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (_) async => const TransportResponse(
            statusCode: 200,
            body: '[]',
          ),
        ),
      ).moderation();

      await expectLater(
        () => moderation.moderateText('Hello world'),
        throwsA(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'OpenAI moderation API returned JSON that is not an object',
            ),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;

Map<String, Object?> _moderationResponseBody() {
  return {
    'id': 'modr_123',
    'model': 'omni-moderation-latest',
    'results': [
      {
        'flagged': false,
        'categories': {
          'hate': false,
          'hate/threatening': false,
          'harassment': false,
          'harassment/threatening': false,
          'self-harm': false,
          'self-harm/intent': false,
          'self-harm/instructions': false,
          'sexual': false,
          'sexual/minors': false,
          'violence': false,
          'violence/graphic': false,
        },
        'category_scores': {
          'hate': 0.0,
          'hate/threatening': 0.0,
          'harassment': 0.0,
          'harassment/threatening': 0.0,
          'self-harm': 0.0,
          'self-harm/intent': 0.0,
          'self-harm/instructions': 0.0,
          'sexual': 0.0,
          'sexual/minors': 0.0,
          'violence': 0.0,
          'violence/graphic': 0.0,
        },
      },
    ],
  };
}
