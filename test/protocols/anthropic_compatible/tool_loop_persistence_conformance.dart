import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_json_client.dart';

typedef AnthropicCompatibleChatFactory = ChatCapability Function(
  AnthropicClient client,
  AnthropicConfig config,
);

Tool _weatherTool() {
  return Tool.function(
    name: 'getWeather',
    description: 'get weather',
    parameters: const ParametersSchema(
      schemaType: 'object',
      properties: {
        'city': ParameterProperty(
          propertyType: 'string',
          description: 'city',
        ),
      },
      required: ['city'],
    ),
  );
}

void registerAnthropicCompatibleToolLoopPersistenceConformanceTests({
  required String groupName,
  required AnthropicConfig config,
  required AnthropicCompatibleChatFactory createChat,
  required String expectedProviderMetadataKey,
  required String expectedModel,
}) {
  group(groupName, () {
    test('assistantMessage preserves tool_use blocks for next request',
        () async {
      final client = FakeAnthropicCompatibleJsonClient(
        config,
        responses: [
          {
            'id': 'msg_tool_1',
            'model': expectedModel,
            'stop_reason': 'tool_use',
            'usage': {
              'input_tokens': 10,
              'output_tokens': 5,
            },
            'content': [
              {
                'type': 'thinking',
                'thinking': 'I should call the tool.',
              },
              {
                'type': 'text',
                'text': 'Let me check.',
              },
              {
                'type': 'tool_use',
                'id': 'toolu_1',
                'name': 'getWeather',
                'input': {'city': 'London'},
              },
            ],
          },
          {
            'id': 'msg_tool_2',
            'model': expectedModel,
            'stop_reason': 'end_turn',
            'usage': {
              'input_tokens': 20,
              'output_tokens': 3,
            },
            'content': [
              {
                'type': 'text',
                'text': 'Done.',
              }
            ],
          },
        ],
      );

      final chat = createChat(client, config);

      final first = await chat.chatWithTools(
        [ChatMessage.user('Hi')],
        [_weatherTool()],
      );

      expect(first.toolCalls, isNotNull);
      expect(first.toolCalls!, hasLength(1));
      expect(first.toolCalls!.single.id, equals('toolu_1'));
      expect(first.toolCalls!.single.function.name, equals('getWeather'));
      expect(first.toolCalls!.single.function.arguments,
          equals('{"city":"London"}'));

      expect(first.thinking, contains('I should call the tool.'));

      final meta = first.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey(expectedProviderMetadataKey), isTrue);
      expect(
          meta[expectedProviderMetadataKey]['stopReason'], equals('tool_use'));

      expect(first, isA<ChatResponseWithAssistantMessage>());
      final assistantMessage =
          (first as ChatResponseWithAssistantMessage).assistantMessage;

      final anthropicExt =
          assistantMessage.getProtocolPayload<Map<String, dynamic>>(
        'anthropic',
      );
      expect(anthropicExt, isNotNull);

      final blocks = anthropicExt!['contentBlocks'];
      expect(blocks, isA<List>());
      final typedBlocks = (blocks as List)
          .whereType<Map>()
          .cast<Map<String, dynamic>>()
          .toList();
      expect(typedBlocks.any((b) => b['type'] == 'tool_use'), isTrue);

      final toolResult = ChatMessage.toolResult(
        results: [
          ToolCall(
            id: 'toolu_1',
            callType: 'function',
            function: const FunctionCall(
              name: 'getWeather',
              arguments: '{"temp":20}',
            ),
          ),
        ],
      );

      await chat.chatWithTools(
        [
          ChatMessage.user('Hi'),
          assistantMessage,
          toolResult,
        ],
        [_weatherTool()],
      );

      expect(client.requests, hasLength(2));
      final secondRequest = client.requests[1];
      final messages = secondRequest['messages'] as List<dynamic>;
      expect(messages, hasLength(3));

      final user0 = messages[0] as Map<String, dynamic>;
      expect(user0['role'], equals('user'));

      final assistant1 = messages[1] as Map<String, dynamic>;
      expect(assistant1['role'], equals('assistant'));
      final assistantContent = assistant1['content'] as List<dynamic>;
      expect(
        assistantContent.whereType<Map>().any((b) => b['type'] == 'thinking'),
        isTrue,
      );
      expect(
        assistantContent.whereType<Map>().any((b) => b['type'] == 'tool_use'),
        isTrue,
      );
      final toolUseBlock = assistantContent
          .whereType<Map>()
          .cast<Map<String, dynamic>>()
          .firstWhere((b) => b['type'] == 'tool_use');
      expect(toolUseBlock['id'], equals('toolu_1'));
      expect(toolUseBlock['name'], equals('getWeather'));
      expect(toolUseBlock['input'], equals({'city': 'London'}));

      final user2 = messages[2] as Map<String, dynamic>;
      expect(user2['role'], equals('user'));
      final user2Content = user2['content'] as List<dynamic>;
      final toolResultBlock = user2Content
          .whereType<Map>()
          .cast<Map<String, dynamic>>()
          .firstWhere((b) => b['type'] == 'tool_result');
      expect(toolResultBlock['tool_use_id'], equals('toolu_1'));
      expect(toolResultBlock['content'], equals('{"temp":20}'));
      expect(toolResultBlock['is_error'], isFalse);
    });
  });
}
