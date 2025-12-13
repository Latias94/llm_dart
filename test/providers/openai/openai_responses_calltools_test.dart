import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_impl;
import 'package:test/test.dart';

import 'openai_test_utils.dart';

void main() {
  group('OpenAI Responses callTools integration', () {
    test('maps provider-defined web_search to web_search built-in tool',
        () async {
      final config = openai_impl.OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4.1-mini',
        useResponsesAPI: true,
      );
      final client = CapturingOpenAIClient(config);
      final responses = openai_impl.OpenAIResponses(client, config);

      final messages = <ModelMessage>[ModelMessage.userText('hello')];

      final options = LanguageModelCallOptions(
        callTools: const [
          ProviderDefinedToolSpec(
            id: 'openai.web_search',
            args: {
              'allowedDomains': ['example.com'],
            },
          ),
        ],
      );

      await responses.chatWithTools(messages, null, options: options);

      final body = client.lastBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));
      final tool = tools.first;
      expect(tool['type'], equals('web_search'));
      final filters = tool['filters'] as Map<String, dynamic>?;
      expect(filters?['allowed_domains'], equals(['example.com']));
    });

    test('maps provider-defined file_search to file_search built-in tool',
        () async {
      final config = openai_impl.OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4.1-mini',
        useResponsesAPI: true,
      );
      final client = CapturingOpenAIClient(config);
      final responses = openai_impl.OpenAIResponses(client, config);

      final messages = <ModelMessage>[ModelMessage.userText('hello')];

      final options = LanguageModelCallOptions(
        callTools: const [
          ProviderDefinedToolSpec(
            id: 'openai.file_search',
            args: {
              'vectorStoreIds': ['vs_1'],
              'maxNumResults': 10,
              'filters': {'tag': 'docs'},
            },
          ),
        ],
      );

      await responses.chatWithTools(messages, null, options: options);

      final body = client.lastBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));
      final tool = tools.first;
      expect(tool['type'], equals('file_search'));
      expect(tool['vector_store_ids'], equals(['vs_1']));
      expect(tool['max_num_results'], equals(10));
      expect(tool['filters'], equals({'tag': 'docs'}));
    });

    test(
        'maps provider-defined code_interpreter to code_interpreter built-in tool',
        () async {
      final config = openai_impl.OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4.1-mini',
        useResponsesAPI: true,
      );
      final client = CapturingOpenAIClient(config);
      final responses = openai_impl.OpenAIResponses(client, config);

      final messages = <ModelMessage>[ModelMessage.userText('hello')];

      final options = LanguageModelCallOptions(
        callTools: const [
          ProviderDefinedToolSpec(
            id: 'openai.code_interpreter',
            args: {
              'parameters': {'runtime': 'python'},
            },
          ),
        ],
      );

      await responses.chatWithTools(messages, null, options: options);

      final body = client.lastBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));
      final tool = tools.first;
      expect(tool['type'], equals('code_interpreter'));
      expect(tool['runtime'], equals('python'));
    });

    test(
        'maps provider-defined image_generation to image_generation built-in tool',
        () async {
      final config = openai_impl.OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4.1-mini',
        useResponsesAPI: true,
      );
      final client = CapturingOpenAIClient(config);
      final responses = openai_impl.OpenAIResponses(client, config);

      final messages = <ModelMessage>[ModelMessage.userText('hello')];

      final options = LanguageModelCallOptions(
        callTools: const [
          ProviderDefinedToolSpec(
            id: 'openai.image_generation',
            args: {
              'model': 'gpt-image-1',
              'parameters': {'size': '1024x1024'},
            },
          ),
        ],
      );

      await responses.chatWithTools(messages, null, options: options);

      final body = client.lastBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));
      final tool = tools.first;
      expect(tool['type'], equals('image_generation'));
      expect(tool['model'], equals('gpt-image-1'));
      expect(tool['size'], equals('1024x1024'));
    });
  });
}
