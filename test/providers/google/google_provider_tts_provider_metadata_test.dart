import 'dart:convert';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/client.dart';
import 'package:llm_dart_google/google.dart';
import 'package:test/test.dart';

class _FakeGoogleClient extends GoogleClient {
  String? lastEndpoint;
  dynamic lastBody;

  _FakeGoogleClient(super.config);

  @override
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;

    final responseData = <String, dynamic>{
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'inlineData': {
                  'data': base64Encode(const [1, 2, 3]),
                  'mimeType': 'audio/pcm',
                }
              }
            ]
          }
        }
      ],
      'usageMetadata': {
        'promptTokenCount': 1,
        'candidatesTokenCount': 1,
        'totalTokenCount': 2,
      },
      'modelVersion': 'gemini-2.5-flash-preview-tts',
    };

    return Response(
      requestOptions: RequestOptions(path: endpoint),
      statusCode: 200,
      data: responseData,
    );
  }
}

void main() {
  group('GoogleProvider textToSpeech providerMetadata', () {
    test('attaches google + google.speech metadata with endpoint + model',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash-preview-tts',
      );

      final client = _FakeGoogleClient(config);
      final provider = GoogleProvider(config, client: client);

      final response = await provider.textToSpeech(
        const TTSRequest(
          text: 'hi',
          model: 'gemini-2.5-flash-preview-tts',
          voice: 'Kore',
        ),
      );

      expect(client.lastEndpoint,
          'models/gemini-2.5-flash-preview-tts:generateContent');

      final meta = response.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('google'), isTrue);
      expect(meta.containsKey('google.speech'), isTrue);
      expect(
        meta['google.speech'],
        equals({
          'model': 'gemini-2.5-flash-preview-tts',
          'endpoint': 'models/gemini-2.5-flash-preview-tts:generateContent',
        }),
      );
    });
  });
}
