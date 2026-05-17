import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicCodeExecutionReplay', () {
    test('parses a bash execution replay payload from custom parts and events',
        () {
      const metadata = ProviderMetadata({
        'anthropic': {
          'blockType': 'bash_code_execution_tool_result',
        },
      });

      const payload = {
        'schema': 'anthropic.execution.result.v1',
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_3',
        'toolName': 'code_execution',
        'blockType': 'bash_code_execution_tool_result',
        'block': {
          'type': 'bash_code_execution_tool_result',
          'tool_use_id': 'srvtoolu_3',
          'content': {
            'type': 'bash_code_execution_result',
            'stdout': 'hi\n',
            'stderr': '',
            'return_code': 0,
            'content': [
              {
                'type': 'bash_code_execution_output',
                'file_id': 'file_123',
              },
            ],
          },
        },
      };

      final contentPart = const CustomContentPart(
        kind: AnthropicCodeExecutionReplay.kind,
        data: payload,
        providerMetadata: metadata,
      );
      final promptPart = const CustomPromptPart(
        kind: AnthropicCodeExecutionReplay.kind,
        data: payload,
        providerOptions: ProviderReplayPromptPartOptions(metadata),
      );
      final event = const CustomEvent(
        kind: AnthropicCodeExecutionReplay.kind,
        data: payload,
        providerMetadata: metadata,
      );

      final fromContent =
          AnthropicCodeExecutionReplay.tryParseContentPart(contentPart);
      final fromPrompt =
          AnthropicCodeExecutionReplay.tryParsePromptPart(promptPart);
      final fromEvent = AnthropicCodeExecutionReplay.tryParseEvent(event);

      expect(fromContent, isNotNull);
      expect(fromPrompt, isNotNull);
      expect(fromEvent, isNotNull);

      final replay = fromContent!;
      expect(replay.toolCallId, 'srvtoolu_3');
      expect(replay.toolName, 'code_execution');
      expect(
        replay.blockType,
        AnthropicCodeExecutionBlockType.bashCodeExecutionToolResult,
      );
      expect(replay.result, isA<AnthropicBashCodeExecutionResult>());
      final result = replay.result as AnthropicBashCodeExecutionResult;
      expect(result.stdout, 'hi\n');
      expect(result.stderr, '');
      expect(result.returnCode, 0);
      expect(result.fileHandles.single.fileId, 'file_123');
      expect(replay.providerMetadata, metadata);
      expect(replay.toJson(), payload);
      expect(fromPrompt!.toJson(), payload);
      final replayPromptPart = replay.toCustomPromptPart();
      expect(
        replayPromptPart.providerOptions,
        isA<ProviderReplayPromptPartOptions>().having(
          (options) => options.metadata,
          'metadata',
          metadata,
        ),
      );
      expect(fromEvent!.toJson(), payload);
    });

    test('parses text editor str_replace results into typed models', () {
      final replay = AnthropicCodeExecutionReplay.fromJson({
        'schema': 'anthropic.execution.result.v1',
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_4',
        'toolName': 'code_execution',
        'blockType': 'text_editor_code_execution_tool_result',
        'block': {
          'type': 'text_editor_code_execution_tool_result',
          'tool_use_id': 'srvtoolu_4',
          'content': {
            'type': 'text_editor_code_execution_str_replace_result',
            'lines': ['- old', '+ new'],
            'new_lines': 1,
            'new_start': 10,
            'old_lines': 1,
            'old_start': 10,
          },
        },
      });

      expect(
        replay.blockType,
        AnthropicCodeExecutionBlockType.textEditorCodeExecutionToolResult,
      );
      expect(replay.result, isA<AnthropicTextEditorStrReplaceResult>());

      final result = replay.result as AnthropicTextEditorStrReplaceResult;
      expect(result.lines, ['- old', '+ new']);
      expect(result.newLines, 1);
      expect(result.newStart, 10);
      expect(result.oldLines, 1);
      expect(result.oldStart, 10);

      final promptPart = replay.toCustomPromptPart();
      expect(promptPart.kind, AnthropicCodeExecutionReplay.kind);
      expect(promptPart.data, replay.toJson());
    });

    test('parses programmatic, encrypted, and error result variants', () {
      AnthropicCodeExecutionReplay replayFor({
        required String blockType,
        required Map<String, Object?> content,
      }) {
        return AnthropicCodeExecutionReplay.fromJson({
          'schema': 'anthropic.execution.result.v1',
          'replayRole': 'tool',
          'toolCallId': 'srvtoolu_5',
          'toolName': 'code_execution',
          'blockType': blockType,
          'block': {
            'type': blockType,
            'tool_use_id': 'srvtoolu_5',
            'content': content,
          },
        });
      }

      final programmatic = replayFor(
        blockType: 'code_execution_tool_result',
        content: {
          'type': 'code_execution_result',
          'stdout': 'ok\n',
          'stderr': '',
          'return_code': 0,
          'content': [
            {
              'type': 'code_execution_output',
              'file_id': 'file_programmatic',
            },
          ],
        },
      );
      expect(
        programmatic.result,
        isA<AnthropicProgrammaticCodeExecutionResult>(),
      );
      expect(programmatic.fileHandles.single.fileId, 'file_programmatic');

      final encrypted = replayFor(
        blockType: 'code_execution_tool_result',
        content: {
          'type': 'encrypted_code_execution_result',
          'encrypted_stdout': 'ciphertext',
          'stderr': '',
          'return_code': 0,
          'content': [
            {
              'type': 'code_execution_output',
              'file_id': 'file_encrypted',
            },
          ],
        },
      );
      expect(encrypted.result, isA<AnthropicEncryptedCodeExecutionResult>());
      expect(
        (encrypted.result as AnthropicEncryptedCodeExecutionResult)
            .encryptedStdout,
        'ciphertext',
      );

      final bashError = replayFor(
        blockType: 'bash_code_execution_tool_result',
        content: {
          'type': 'bash_code_execution_tool_result_error',
          'error_code': 'timeout',
        },
      );
      expect(bashError.result, isA<AnthropicBashCodeExecutionErrorResult>());
      expect(bashError.hasFileHandles, isFalse);

      final textEditorError = replayFor(
        blockType: 'text_editor_code_execution_tool_result',
        content: {
          'type': 'text_editor_code_execution_tool_result_error',
          'error_code': 'invalid_path',
        },
      );
      expect(
        textEditorError.result,
        isA<AnthropicTextEditorCodeExecutionErrorResult>(),
      );
    });

    test('returns null for unrelated custom parts', () {
      final contentPart = const CustomContentPart(
        kind: 'anthropic.result.web_search',
        data: {
          'replayRole': 'tool',
        },
      );

      expect(
        AnthropicCodeExecutionReplay.tryParseContentPart(contentPart),
        isNull,
      );
    });

    test('returns null for invalid execution payloads in tryParse', () {
      expect(
        AnthropicCodeExecutionReplay.tryParseData({
          'schema': 'wrong',
        }),
        isNull,
      );
    });
  });
}
