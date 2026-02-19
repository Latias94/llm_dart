import 'package:test/test.dart';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

void main() {
  group('AnthropicClientExecutedTools', () {
    test('bashHandler parses command + restart', () async {
      final handler = AnthropicClientExecutedTools.bashHandler(
        execute: (input, {cancelToken}) async {
          expect(input.command, equals('echo hi'));
          expect(input.restart, isTrue);
          return 'ok';
        },
      );

      const raw = '{"command":"echo hi","restart":true}';
      const toolCall = V3ToolCall(
        toolCallId: 'call_1',
        toolName: 'bash',
        input: raw,
      );

      final out = await handler(
        const {'command': 'echo hi', 'restart': true},
        ToolExecutionOptions(
          toolCallId: 'call_1',
          toolName: 'bash',
          rawArguments: raw,
          messages: const [],
          stepIndex: 0,
          toolCall: toolCall,
        ),
      );

      expect(out, equals('ok'));
    });

    test('computerHandler parses coordinates + scroll fields', () async {
      final handler = AnthropicClientExecutedTools.computerHandler(
        execute: (input, {cancelToken}) async {
          expect(input.action, equals('scroll'));
          expect(input.coordinate, equals([10, 20]));
          expect(input.scrollAmount, equals(3));
          expect(input.scrollDirection, equals('down'));
          return [
            {'type': 'text', 'text': 'scrolled'},
          ];
        },
      );

      const raw =
          '{"action":"scroll","coordinate":[10,20],"scroll_amount":3,"scroll_direction":"down"}';
      const toolCall = V3ToolCall(
        toolCallId: 'call_2',
        toolName: 'computer',
        input: raw,
      );

      final out = await handler(
        const {
          'action': 'scroll',
          'coordinate': [10, 20],
          'scroll_amount': 3,
          'scroll_direction': 'down',
        },
        ToolExecutionOptions(
          toolCallId: 'call_2',
          toolName: 'computer',
          rawArguments: raw,
          messages: const [],
          stepIndex: 0,
          toolCall: toolCall,
        ),
      );

      expect(out, isA<List>());
    });

    test('textEditorHandler parses snake_case fields', () async {
      final handler = AnthropicClientExecutedTools.textEditorHandler(
        execute: (input, {cancelToken}) async {
          expect(input.command, equals('create'));
          expect(input.path, equals('/tmp/a.txt'));
          expect(input.fileText, equals('hi'));
          return 'ok';
        },
      );

      const raw = '{"command":"create","path":"/tmp/a.txt","file_text":"hi"}';
      const toolCall = V3ToolCall(
        toolCallId: 'call_3',
        toolName: 'str_replace_based_edit_tool',
        input: raw,
      );

      final out = await handler(
        const {'command': 'create', 'path': '/tmp/a.txt', 'file_text': 'hi'},
        ToolExecutionOptions(
          toolCallId: 'call_3',
          toolName: 'str_replace_based_edit_tool',
          rawArguments: raw,
          messages: const [],
          stepIndex: 0,
          toolCall: toolCall,
        ),
      );

      expect(out, equals('ok'));
    });
  });
}
