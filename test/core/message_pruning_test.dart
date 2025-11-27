import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('pruneModelMessages', () {
    final messagesFixture1 = <ModelMessage>[
      ModelMessage(
        role: ChatRole.user,
        parts: const [
          TextContentPart('Weather in Tokyo and Busan?'),
        ],
      ),
      ModelMessage(
        role: ChatRole.assistant,
        parts: const [
          ReasoningContentPart(
            'I need to get the weather in Tokyo and Busan.',
          ),
          ToolCallContentPart(
            toolName: 'get-weather-tool-1',
            argumentsJson: '{"city":"Tokyo"}',
            toolCallId: 'call-1',
          ),
          ToolCallContentPart(
            toolName: 'get-weather-tool-2',
            argumentsJson: '{"city":"Busan"}',
            toolCallId: 'call-2',
          ),
        ],
      ),
      ModelMessage(
        role: ChatRole.assistant,
        parts: const [
          ToolResultContentPart(
            toolCallId: 'call-1',
            toolName: 'get-weather-tool-1',
            payload: ToolResultTextPayload('sunny'),
          ),
          ToolResultContentPart(
            toolCallId: 'call-2',
            toolName: 'get-weather-tool-2',
            payload: ToolResultErrorPayload(
              'Error: Fetching weather data failed',
            ),
          ),
        ],
      ),
      ModelMessage(
        role: ChatRole.assistant,
        parts: const [
          ReasoningContentPart(
            'I have got the weather in Tokyo and Busan.',
          ),
          TextContentPart(
            'The weather in Tokyo is sunny. '
            'I could not get the weather in Busan.',
          ),
        ],
      ),
    ];

    final messagesFixture2 = <ModelMessage>[
      ModelMessage(
        role: ChatRole.user,
        parts: const [
          TextContentPart('Weather in Tokyo and Busan?'),
        ],
      ),
      ModelMessage(
        role: ChatRole.assistant,
        parts: const [
          ReasoningContentPart(
            'I need to get the weather in Tokyo and Busan.',
          ),
          ToolCallContentPart(
            toolName: 'get-weather-tool-1',
            argumentsJson: '{"city":"Tokyo"}',
            toolCallId: 'call-1',
          ),
        ],
      ),
      ModelMessage(
        role: ChatRole.assistant,
        parts: const [
          ReasoningContentPart(
            'I have got the weather in Tokyo and Busan.',
          ),
          TextContentPart(
            'The weather in Tokyo is sunny. '
            'I could not get the weather in Busan.',
          ),
        ],
      ),
    ];

    test('prunes all reasoning parts when reasoning == all', () {
      final result = pruneModelMessages(
        messages: messagesFixture1,
        reasoning: ReasoningPruneMode.all,
      );

      expect(result.length, equals(messagesFixture1.length));

      for (final message in result) {
        if (message.role == ChatRole.assistant) {
          expect(
            message.parts.whereType<ReasoningContentPart>(),
            isEmpty,
          );
        }
      }

      // Text and tool parts should still be present.
      expect(
        result[1].parts.whereType<ToolCallContentPart>(),
        isNotEmpty,
      );
      expect(
        result[3].parts.whereType<TextContentPart>(),
        isNotEmpty,
      );
    });

    test(
        'prunes reasoning before last message only when reasoning == beforeLastMessage',
        () {
      final result = pruneModelMessages(
        messages: messagesFixture1,
        reasoning: ReasoningPruneMode.beforeLastMessage,
      );

      // First assistant message should have reasoning removed.
      final firstAssistant = result[1];
      expect(firstAssistant.parts.whereType<ReasoningContentPart>(), isEmpty);

      // Last assistant message should keep its reasoning.
      final lastAssistant = result.last;
      expect(
        lastAssistant.parts.whereType<ReasoningContentPart>(),
        isNotEmpty,
      );
    });

    test('prunes all tool calls and results when toolCalls == all', () {
      final result = pruneModelMessages(
        messages: messagesFixture1,
        toolCalls: ToolCallPruneMode.all,
      );

      for (final message in result) {
        expect(
          message.parts.whereType<ToolCallContentPart>(),
          isEmpty,
        );
        expect(
          message.parts.whereType<ToolResultContentPart>(),
          isEmpty,
        );
      }

      // Reasoning and text content should remain.
      expect(
        result[1].parts.whereType<ReasoningContentPart>(),
        isNotEmpty,
      );
      expect(
        result.last.parts.whereType<TextContentPart>(),
        isNotEmpty,
      );
    });

    test(
        'prunes tool calls and results only before last message when toolCalls == beforeLastMessage',
        () {
      final result = pruneModelMessages(
        messages: messagesFixture2,
        toolCalls: ToolCallPruneMode.beforeLastMessage,
      );

      // First assistant message should have its tool call removed.
      final firstAssistant = result[1];
      expect(
        firstAssistant.parts.whereType<ToolCallContentPart>(),
        isEmpty,
      );

      // Last assistant message should keep its reasoning and text.
      final lastAssistant = result.last;
      expect(
        lastAssistant.parts.whereType<ReasoningContentPart>(),
        isNotEmpty,
      );
      expect(
        lastAssistant.parts.whereType<TextContentPart>(),
        isNotEmpty,
      );
    });

    test('respects toolNames filter when pruning tools', () {
      final result = pruneModelMessages(
        messages: messagesFixture1,
        toolCalls: ToolCallPruneMode.all,
        toolNames: const ['get-weather-tool-1'],
      );

      // Tool parts for get-weather-tool-1 should be removed.
      expect(
        result[1]
            .parts
            .whereType<ToolCallContentPart>()
            .where((p) => p.toolName == 'get-weather-tool-1'),
        isEmpty,
      );
      expect(
        result[2]
            .parts
            .whereType<ToolResultContentPart>()
            .where((p) => p.toolName == 'get-weather-tool-1'),
        isEmpty,
      );

      // Tool parts for get-weather-tool-2 should remain.
      expect(
        result[1]
            .parts
            .whereType<ToolCallContentPart>()
            .where((p) => p.toolName == 'get-weather-tool-2'),
        isNotEmpty,
      );
      expect(
        result[2]
            .parts
            .whereType<ToolResultContentPart>()
            .where((p) => p.toolName == 'get-weather-tool-2'),
        isNotEmpty,
      );
    });
  });
}
