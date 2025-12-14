import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_ollama/testing.dart';
import 'package:test/test.dart';

import 'ollama_test_utils.dart';

void main() {
  group('OllamaChat call options', () {
    Tool testTool(String name) {
      return Tool.function(
        name: name,
        description: 'Test tool',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: const {},
          required: const [],
        ),
      );
    }

    test('callTools override config tools', () async {
      final config = OllamaConfig(
        model: 'llama3.2',
        tools: [testTool('config_tool')],
      );

      final client = CapturingOllamaClient(config);
      final chat = OllamaChat(client, config);

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: LanguageModelCallOptions(
          callTools: [FunctionCallToolSpec(testTool('call_tool'))],
        ),
      );

      final body = client.lastRequestBody!;
      final tools = body['tools'] as List;
      expect(tools, hasLength(1));
      expect(tools.first['function']['name'], equals('call_tool'));
    });

    test('empty callTools disables tools', () async {
      final config = OllamaConfig(
        model: 'llama3.2',
        tools: [testTool('config_tool')],
      );

      final client = CapturingOllamaClient(config);
      final chat = OllamaChat(client, config);

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: const LanguageModelCallOptions(callTools: []),
      );

      final body = client.lastRequestBody!;
      expect(body.containsKey('tools'), isFalse);
    });

    test('stopSequences/jsonSchema/headers prefer per-call options', () async {
      final config = OllamaConfig(
        model: 'llama3.2',
        stopSequences: const ['CONFIG_STOP'],
        jsonSchema: const StructuredOutputFormat(
          name: 'ConfigSchema',
          schema: {
            'type': 'object',
            'properties': {
              'a': {'type': 'string'},
            },
          },
        ),
      );

      final client = CapturingOllamaClient(config);
      final chat = OllamaChat(client, config);

      const callSchema = StructuredOutputFormat(
        name: 'CallSchema',
        schema: {
          'type': 'object',
          'properties': {
            'b': {'type': 'string'},
          },
        },
      );

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: const LanguageModelCallOptions(
          stopSequences: ['CALL_STOP'],
          jsonSchema: callSchema,
          headers: {'X-Test': '1'},
        ),
      );

      final body = client.lastRequestBody!;

      final options = body['options'] as Map<String, dynamic>?;
      expect(options, isNotNull);
      expect(options!['stop'], equals(['CALL_STOP']));

      final format = body['format'] as Map<String, dynamic>;
      expect(format['properties'], contains('b'));

      expect(client.lastHeaders, equals({'X-Test': '1'}));
    });
  });
}
