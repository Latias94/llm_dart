import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/testing.dart';
import 'package:test/test.dart';

import 'openai_compatible_test_utils.dart';

void main() {
  group('OpenAICompatibleChat call options', () {
    test('call-level tools via callTools override config tools', () async {
      final tool = Tool.function(
        name: 'ping',
        description: 'Ping tool',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: const {},
          required: const [],
        ),
      );

      final config = OpenAICompatibleConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test/v1',
        providerId: 'test-provider',
        model: 'gpt-4.1-mini',
      );

      final client = CapturingOpenAICompatibleClient(config);
      final chat = OpenAICompatibleChat(client, config);

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: LanguageModelCallOptions(
          callTools: [FunctionCallToolSpec(tool)],
        ),
      );

      final body = client.lastRequestBody!;
      final tools = body['tools'] as List;
      expect(tools, hasLength(1));
      expect(tools.first['function']['name'], equals('ping'));
    });

    test('reasoningEffort in options overrides config', () async {
      final config = OpenAICompatibleConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test/v1',
        providerId: 'google-openai',
        model: 'gemini-2.0-flash',
        reasoningEffort: ReasoningEffort.low,
        originalConfig: const LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test/v1',
          model: 'gemini-2.0-flash',
        ),
      );

      final client = CapturingOpenAICompatibleClient(config);
      final chat = OpenAICompatibleChat(client, config);

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: const LanguageModelCallOptions(
          reasoningEffort: ReasoningEffort.high,
        ),
      );

      expect(client.lastRequestBody!['reasoning_effort'], equals('high'));
    });

    test('jsonSchema in options overrides config', () async {
      final configSchema = StructuredOutputFormat(
        name: 'ConfigSchema',
        schema: const {
          'type': 'object',
          'properties': {
            'a': {'type': 'string'},
          },
          'required': ['a'],
        },
        strict: true,
      );

      final callSchema = StructuredOutputFormat(
        name: 'CallSchema',
        schema: const {
          'type': 'object',
          'properties': {
            'b': {'type': 'string'},
          },
          'required': ['b'],
        },
        strict: true,
      );

      final config = OpenAICompatibleConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test/v1',
        providerId: 'test-provider',
        model: 'gpt-4.1-mini',
        jsonSchema: configSchema,
      );

      final client = CapturingOpenAICompatibleClient(config);
      final chat = OpenAICompatibleChat(client, config);

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: LanguageModelCallOptions(jsonSchema: callSchema),
      );

      final body = client.lastRequestBody!;
      final responseFormat = body['response_format'] as Map<String, dynamic>;
      final jsonSchema = responseFormat['json_schema'] as Map<String, dynamic>;

      expect(jsonSchema['name'], equals('CallSchema'));
      expect(
        (jsonSchema['schema'] as Map<String, dynamic>)['additionalProperties'],
        isFalse,
      );
    });

    test('headers in options are passed to the client', () async {
      final config = OpenAICompatibleConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test/v1',
        providerId: 'test-provider',
        model: 'gpt-4.1-mini',
      );

      final client = CapturingOpenAICompatibleClient(config);
      final chat = OpenAICompatibleChat(client, config);

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: const LanguageModelCallOptions(
          headers: {'X-Test': '1'},
        ),
      );

      expect(client.lastHeaders, equals({'X-Test': '1'}));
    });
  });
}
