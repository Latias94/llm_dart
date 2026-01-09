import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:llm_dart_openai/client.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('OpenAI escape hatches (extraBody/extraHeaders)', () {
    test('factory reads extraBody/extraHeaders from providerOptions', () async {
      final provider = await ai()
          .provider('openai')
          .apiKey('test-key')
          .model('gpt-4.1-mini')
          .providerOptions('openai', const {
        'extraBody': {'temperature': 0.123, 'foo': 'bar'},
        'extraHeaders': {'x-test': '1'},
      }).build();

      final openaiProvider = provider as openai_client.OpenAIProvider;
      expect(openaiProvider.config.extraBody,
          equals({'temperature': 0.123, 'foo': 'bar'}));
      expect(openaiProvider.config.extraHeaders, equals({'x-test': '1'}));
    });

    test('Responses API merges extraBody into request payload (extra wins)',
        () async {
      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
        providerOptions: const {
          'openai': {
            'extraBody': {'temperature': 0.123, 'foo': 'bar'},
          },
        },
      );

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
        useResponsesAPI: true,
        originalConfig: originalConfig,
        extraBody: const {'temperature': 0.123, 'foo': 'bar'},
      );

      final client = FakeOpenAIClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      await responses.chat([ChatMessage.user('test')]);

      expect(client.lastJsonBody, isNotNull);
      expect(client.lastJsonBody!['temperature'], equals(0.123));
      expect(client.lastJsonBody!['foo'], equals('bar'));
    });

    test('OpenAIClient injects extraHeaders into Dio headers', () {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
        extraHeaders: const {'x-test': '1'},
      );

      final client = OpenAIClient(config);
      expect(client.dio.options.headers['x-test'], equals('1'));
    });
  });
}
