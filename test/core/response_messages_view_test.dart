// Response message view tests validate conversion into assistant/tool
// message groupings for prompt-first ModelMessage conversations.

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

/// Local helper used only for tests to build a response-style view over
/// content parts produced by a model.
///
/// This mirrors the intent of the Vercel AI SDK's `toResponseMessages`
/// function in a simplified form:
/// - Text, reasoning, files, and tool-call parts are grouped into a
///   single assistant message.
/// - Tool-result parts are grouped into a separate "tool" message
///   represented here as a user-role message, which matches how
///   tool results are typically sent back to providers.
List<ModelMessage> _toResponseModelMessages(List<ChatContentPart> parts) {
  final assistantParts = <ChatContentPart>[];
  final toolResultParts = <ToolResultContentPart>[];

  for (final part in parts) {
    if (part is ToolResultContentPart) {
      toolResultParts.add(part);
    } else {
      assistantParts.add(part);
    }
  }

  final messages = <ModelMessage>[];

  if (assistantParts.isNotEmpty) {
    messages.add(
      ModelMessage(
        role: ChatRole.assistant,
        parts: assistantParts,
      ),
    );
  }

  if (toolResultParts.isNotEmpty) {
    messages.add(
      ModelMessage(
        role: ChatRole.user,
        parts: toolResultParts,
      ),
    );
  }

  return messages;
}

void main() {
  group('_toResponseModelMessages', () {
    test('returns assistant message with text when no tool parts', () {
      final content = <ChatContentPart>[
        const TextContentPart('Hello, world!'),
      ];

      final messages = _toResponseModelMessages(content);

      expect(messages, hasLength(1));
      final assistant = messages.single;
      expect(assistant.role, ChatRole.assistant);
      expect(assistant.parts, hasLength(1));
      expect(assistant.parts.first, isA<TextContentPart>());
      expect((assistant.parts.first as TextContentPart).text, 'Hello, world!');
    });

    test('includes tool calls in the assistant message', () {
      final content = <ChatContentPart>[
        const TextContentPart('Using a tool'),
        const ToolCallContentPart(
          toolName: 'testTool',
          argumentsJson: '{"value":1}',
          toolCallId: 'call-1',
        ),
      ];

      final messages = _toResponseModelMessages(content);

      expect(messages, hasLength(1));
      final assistant = messages.single;
      expect(assistant.role, ChatRole.assistant);
      expect(
        assistant.parts.whereType<TextContentPart>().single.text,
        'Using a tool',
      );
      final toolCall = assistant.parts.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolName, 'testTool');
      expect(toolCall.toolCallId, 'call-1');
      expect(toolCall.argumentsJson, '{"value":1}');
    });

    test('splits tool results into a separate message', () {
      final content = <ChatContentPart>[
        const TextContentPart('Tool used'),
        const ToolCallContentPart(
          toolName: 'testTool',
          argumentsJson: '{}',
          toolCallId: 'call-1',
        ),
        const ToolResultContentPart(
          toolCallId: 'call-1',
          toolName: 'testTool',
          payload: ToolResultTextPayload('Tool result'),
        ),
      ];

      final messages = _toResponseModelMessages(content);

      expect(messages, hasLength(2));

      final assistant = messages[0];
      expect(assistant.role, ChatRole.assistant);
      expect(
        assistant.parts.whereType<TextContentPart>().single.text,
        'Tool used',
      );
      expect(
        assistant.parts.whereType<ToolCallContentPart>().single.toolName,
        'testTool',
      );

      final toolMessage = messages[1];
      expect(toolMessage.role, ChatRole.user);
      final toolResult =
          toolMessage.parts.whereType<ToolResultContentPart>().single;
      expect(toolResult.toolName, 'testTool');
      expect(toolResult.toolCallId, 'call-1');
      expect(toolResult.payload, isA<ToolResultTextPayload>());
      expect(
        (toolResult.payload as ToolResultTextPayload).value,
        'Tool result',
      );
    });

    test('handles error tool results as separate message', () {
      final content = <ChatContentPart>[
        const TextContentPart('Tool used'),
        const ToolCallContentPart(
          toolName: 'testTool',
          argumentsJson: '{}',
          toolCallId: 'call-1',
        ),
        const ToolResultContentPart(
          toolCallId: 'call-1',
          toolName: 'testTool',
          payload: ToolResultErrorPayload('Tool error'),
        ),
      ];

      final messages = _toResponseModelMessages(content);

      expect(messages, hasLength(2));

      final toolMessage = messages[1];
      final toolResult =
          toolMessage.parts.whereType<ToolResultContentPart>().single;
      expect(toolResult.payload, isA<ToolResultErrorPayload>());
      expect(
        (toolResult.payload as ToolResultErrorPayload).message,
        'Tool error',
      );
    });
  });
}
