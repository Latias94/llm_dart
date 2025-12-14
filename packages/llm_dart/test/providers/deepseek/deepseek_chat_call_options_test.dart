import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/testing.dart';
import 'package:test/test.dart';

import 'deepseek_test_utils.dart';

void main() {
  group('DeepSeekChat call options', () {
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
      final config = DeepSeekConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
        tools: [testTool('config_tool')],
      );

      final client = CapturingDeepSeekClient(config);
      final chat = DeepSeekChat(client, config);

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
      final config = DeepSeekConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
        tools: [testTool('config_tool')],
        toolChoice: const AnyToolChoice(),
      );

      final client = CapturingDeepSeekClient(config);
      final chat = DeepSeekChat(client, config);

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: const LanguageModelCallOptions(callTools: []),
      );

      final body = client.lastRequestBody!;
      expect(body.containsKey('tools'), isFalse);
      expect(body.containsKey('tool_choice'), isFalse);
    });

    test('stopSequences/user/jsonSchema/headers prefer per-call options',
        () async {
      final config = DeepSeekConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
        stopSequences: const ['CONFIG_STOP'],
        user: 'config-user',
        responseFormat: const {'type': 'json_object'},
      );

      final client = CapturingDeepSeekClient(config);
      final chat = DeepSeekChat(client, config);

      final schema = StructuredOutputFormat(
        name: 'CallSchema',
        schema: const {
          'type': 'object',
          'properties': {
            'a': {'type': 'string'},
          },
          'required': ['a'],
        },
        strict: true,
      );

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: LanguageModelCallOptions(
          stopSequences: ['CALL_STOP'],
          user: 'call-user',
          jsonSchema: schema,
          headers: const {'X-Test': '1'},
        ),
      );

      final body = client.lastRequestBody!;
      expect(body['stop'], equals(['CALL_STOP']));
      expect(body['user'], equals('call-user'));

      final responseFormat = body['response_format'] as Map<String, dynamic>;
      expect(responseFormat['type'], equals('json_schema'));
      expect(client.lastHeaders, equals({'X-Test': '1'}));
    });
  });
}
