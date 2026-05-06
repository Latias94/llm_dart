import 'dart:typed_data';

import 'package:llm_dart/core/config.dart';
import 'package:llm_dart/providers/phind/phind.dart';
import 'package:llm_dart_transport/dio.dart';
import 'package:test/test.dart';

void main() {
  group('PhindClient', () {
    test('postJson projects streamed text response into chat-completions shape',
        () async {
      final customDio = Dio();
      customDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: 'data: {"choices":[{"delta":{"content":"Hello"}}]}\n'
                    'data: {"choices":[{"delta":{"content":" world"}}]}\n',
              ),
            );
          },
        ),
      );

      final config = PhindConfig.fromLLMConfig(
        LLMConfig(
          baseUrl: 'https://phind.example/',
          apiKey: 'test-key',
          model: 'Phind-70B',
        ).withExtensions({
          'customDio': customDio,
        }),
      );
      final client = PhindClient(config);

      final response = await client.postJson(
        'chat',
        const {
          'messages': [],
        },
      );

      expect(
        response['choices'][0]['message']['content'],
        'Hello world',
      );
    });

    test('postStreamRaw decodes streamed response body as text', () async {
      final customDio = Dio();
      customDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: ResponseBody(
                  Stream<Uint8List>.fromIterable([
                    Uint8List.fromList('data: {"chunk":"hello'.codeUnits),
                    Uint8List.fromList(' world"}\n'.codeUnits),
                  ]),
                  200,
                ),
              ),
            );
          },
        ),
      );

      final config = PhindConfig.fromLLMConfig(
        LLMConfig(
          baseUrl: 'https://phind.example/',
          apiKey: 'test-key',
          model: 'Phind-70B',
        ).withExtensions({
          'customDio': customDio,
        }),
      );
      final client = PhindClient(config);

      final chunks = await client.postStreamRaw(
        'chat',
        const {
          'messages': [],
        },
      ).toList();

      expect(chunks.join(), 'data: {"chunk":"hello world"}\n');
    });
  });
}
