import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExecutionRegistry', () {
    test('dispatches to the registered tool handler by tool name', () async {
      final calls = <String>[];
      final registry = ToolExecutionRegistry(
        handlers: {
          'weather': (request) {
            calls.add(request.toolName);
            return const ToolExecutionResult.output({
              'temperature': 24,
            });
          },
        },
      );

      final result = await registry.call(
        const ToolExecutionRequest(
          chatId: 'chat-1',
          messageId: 'msg-1',
          toolCallId: 'tool-1',
          toolName: 'weather',
          input: {
            'location': 'Tokyo',
          },
        ),
      );

      expect(calls, ['weather']);
      expect(result, isNotNull);
      expect(result!.isError, isFalse);
      expect(result.output, {
        'temperature': 24,
      });
    });

    test('uses fallback when no named handler matches', () async {
      final calls = <String>[];
      final registry = ToolExecutionRegistry(
        fallback: (request) {
          calls.add(request.toolName);
          return const ToolExecutionResult.error('unsupported tool');
        },
      );

      final result = await registry.call(
        const ToolExecutionRequest(
          chatId: 'chat-1',
          messageId: 'msg-1',
          toolCallId: 'tool-1',
          toolName: 'calendar',
        ),
      );

      expect(calls, ['calendar']);
      expect(result, isNotNull);
      expect(result!.isError, isTrue);
      expect(result.output, 'unsupported tool');
    });

    test('withHandler returns a new registry without mutating the original',
        () async {
      final original = ToolExecutionRegistry();
      final updated = original.withHandler(
        'weather',
        (_) => const ToolExecutionResult.output('ok'),
      );

      expect(original.hasHandlerFor('weather'), isFalse);
      expect(updated.hasHandlerFor('weather'), isTrue);
      expect(
        await updated.call(
          const ToolExecutionRequest(
            chatId: 'chat-1',
            messageId: 'msg-1',
            toolCallId: 'tool-1',
            toolName: 'weather',
          ),
        ),
        isNotNull,
      );
    });
  });
}
