import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('Google image editing helper', () {
    test('edit sends Gemini image editing request with inline image input',
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
                    'finishReason': 'STOP',
                    'content': {
                      'parts': [
                        {'text': 'Edited image prompt.'},
                        {
                          'inlineData': {
                            'mimeType': 'image/png',
                            'data': base64Encode([1, 2, 3]),
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
      ).imageModel('gemini-2.5-flash-image');

      final result = await model.edit(
        GoogleImageEditRequest(
          prompt: 'Turn this cat into watercolor style.',
          images: const [
            GoogleImageEditInput.bytes([9, 8, 7], mediaType: 'image/png'),
          ],
          callOptions: const CallOptions(
            providerOptions: GoogleImageOptions(
              aspectRatio: GoogleImageAspectRatio.portrait3x4,
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent',
      );
      expect(
        capturedRequest!.body,
        {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Turn this cat into watercolor style.',
                },
                {
                  'inlineData': {
                    'mimeType': 'image/png',
                    'data': base64Encode([9, 8, 7]),
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE'],
            'imageConfig': {
              'aspectRatio': '3:4',
            },
          },
        },
      );
      expect(result.images, hasLength(1));
      expect(result.images.single.bytes, [1, 2, 3]);
    });

    test('edit supports URI-backed image inputs through fileData', () async {
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
                            'mimeType': 'image/png',
                            'data': base64Encode([4, 5, 6]),
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
      ).imageModel('gemini-2.5-flash-image');

      await model.edit(
        GoogleImageEditRequest(
          prompt: 'Blend these image cues.',
          images: [
            GoogleImageEditInput.uri(
              Uri.parse('https://generativelanguage.googleapis.com/v1beta/files/example-image'),
            ),
          ],
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
                  'text': 'Blend these image cues.',
                },
                {
                  'fileData': {
                    'mimeType': 'image/*',
                    'fileUri':
                        'https://generativelanguage.googleapis.com/v1beta/files/example-image',
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE'],
          },
        },
      );
    });

    test('createVariation uses the provider-owned default prompt', () async {
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
                            'mimeType': 'image/png',
                            'data': base64Encode([7, 8, 9]),
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
      ).imageModel('gemini-2.5-flash-image');

      await model.createVariation(
        const GoogleImageVariationRequest(
          images: [
            GoogleImageEditInput.bytes([1, 1, 1], mediaType: 'image/png'),
          ],
        ),
      );

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      final contents = requestBody['contents'] as List<Object?>;
      final message = contents.single as Map<String, Object?>;
      final parts = message['parts'] as List<Object?>;
      final promptPart = parts.first as Map<String, Object?>;

      expect(
        promptPart['text'],
        GoogleImageVariationRequest.defaultPrompt,
      );
    });

    test('edit rejects Imagen models', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('imagen-3.0-generate-002');

      await expectLater(
        () => model.edit(
          const GoogleImageEditRequest(
            prompt: 'Edit this image.',
            images: [
              GoogleImageEditInput.bytes([1, 2, 3], mediaType: 'image/png'),
            ],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('Gemini image models'),
          ),
        ),
      );
    });

    test('edit rejects non-image inputs', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('gemini-2.5-flash-image');

      await expectLater(
        () => model.edit(
          const GoogleImageEditRequest(
            prompt: 'Edit this image.',
            images: [
              GoogleImageEditInput.bytes([1, 2, 3], mediaType: 'application/pdf'),
            ],
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('image/* media type'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
