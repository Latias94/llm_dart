import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/chat.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

class _CapturingGoogleClient extends GoogleClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  _CapturingGoogleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;

    return {
      'modelVersion': config.model,
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'ok'}
            ],
          },
        },
      ],
    };
  }
}

void main() {
  group('GoogleChat file/image parts', () {
    test('encodes FileMessage as inlineData when within maxInlineDataSize',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        maxInlineDataSize: 1024,
      );

      final bytes = <int>[1, 2, 3, 4];
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatWithTools(
        [
          ChatMessage.file(
            role: ChatRole.user,
            mime: FileMime.pdf,
            data: bytes,
          ),
        ],
        null,
      );

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, hasLength(1));

      final parts = (contents!.single as Map)['parts'] as List;
      expect(parts, hasLength(1));

      final inlineData = (parts.single as Map)['inlineData'] as Map;
      expect(inlineData['mimeType'], equals('application/pdf'));
      expect(inlineData['data'], equals(base64Encode(bytes)));
    });

    test('encodes ImageUrlMessage as fileData with guessed mimeType', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatWithTools(
        [
          ChatMessage.imageUrl(
            role: ChatRole.user,
            url: 'https://example.com/a.webp',
          ),
        ],
        null,
      );

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, hasLength(1));

      final parts = (contents!.single as Map)['parts'] as List;
      expect(parts, hasLength(1));

      final fileData = (parts.single as Map)['fileData'] as Map;
      expect(fileData['fileUri'], equals('https://example.com/a.webp'));
      expect(fileData['mimeType'], equals('image/webp'));
    });

    test(
        'throws InvalidRequestError when FileMessage exceeds maxInlineDataSize',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        maxInlineDataSize: 3,
      );

      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      expect(
        () => chat.chatWithTools(
          [
            ChatMessage.file(
              role: ChatRole.user,
              mime: FileMime.pdf,
              data: const [1, 2, 3, 4],
            ),
          ],
          null,
        ),
        throwsA(isA<InvalidRequestError>()),
      );
    });
  });
}
