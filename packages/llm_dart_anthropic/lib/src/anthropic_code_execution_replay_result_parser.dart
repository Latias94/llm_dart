import 'anthropic_code_execution_replay_json.dart';
import 'anthropic_code_execution_replay_result_models.dart';

AnthropicCodeExecutionResult anthropicParseExecutionResult(
  Object? value, {
  required String path,
}) {
  final map = anthropicReplayRequiredObject(value, path: path);
  final type =
      anthropicReplayRequiredNonEmptyString(map['type'], path: '$path.type');

  switch (type) {
    case 'code_execution_result':
      return AnthropicProgrammaticCodeExecutionResult(
        stdout:
            anthropicReplayRequiredString(map['stdout'], path: '$path.stdout'),
        stderr:
            anthropicReplayRequiredString(map['stderr'], path: '$path.stderr'),
        returnCode: anthropicReplayRequiredInt(
          map['return_code'],
          path: '$path.return_code',
        ),
        fileHandles: anthropicParseExecutionFileHandles(
          map['content'],
          path: '$path.content',
        ),
      );
    case 'encrypted_code_execution_result':
      return AnthropicEncryptedCodeExecutionResult(
        encryptedStdout: anthropicReplayRequiredString(
          map['encrypted_stdout'],
          path: '$path.encrypted_stdout',
        ),
        stderr:
            anthropicReplayRequiredString(map['stderr'], path: '$path.stderr'),
        returnCode: anthropicReplayRequiredInt(
          map['return_code'],
          path: '$path.return_code',
        ),
        fileHandles: anthropicParseExecutionFileHandles(
          map['content'],
          path: '$path.content',
        ),
      );
    case 'bash_code_execution_result':
      return AnthropicBashCodeExecutionResult(
        stdout:
            anthropicReplayRequiredString(map['stdout'], path: '$path.stdout'),
        stderr:
            anthropicReplayRequiredString(map['stderr'], path: '$path.stderr'),
        returnCode: anthropicReplayRequiredInt(
          map['return_code'],
          path: '$path.return_code',
        ),
        fileHandles: anthropicParseExecutionFileHandles(
          map['content'],
          path: '$path.content',
        ),
      );
    case 'bash_code_execution_tool_result_error':
      return AnthropicBashCodeExecutionErrorResult(
        errorCode: anthropicReplayRequiredNonEmptyString(
          map['error_code'],
          path: '$path.error_code',
        ),
      );
    case 'text_editor_code_execution_tool_result_error':
      return AnthropicTextEditorCodeExecutionErrorResult(
        errorCode: anthropicReplayRequiredNonEmptyString(
          map['error_code'],
          path: '$path.error_code',
        ),
      );
    case 'text_editor_code_execution_view_result':
      return AnthropicTextEditorViewResult(
        content: anthropicReplayRequiredString(map['content'],
            path: '$path.content'),
        fileType: anthropicReplayRequiredNonEmptyString(
          map['file_type'],
          path: '$path.file_type',
        ),
        numLines: anthropicReplayNullableInt(map['num_lines'],
            path: '$path.num_lines'),
        startLine: anthropicReplayNullableInt(map['start_line'],
            path: '$path.start_line'),
        totalLines: anthropicReplayNullableInt(map['total_lines'],
            path: '$path.total_lines'),
      );
    case 'text_editor_code_execution_create_result':
      return AnthropicTextEditorCreateResult(
        isFileUpdate: anthropicReplayRequiredBool(
          map['is_file_update'],
          path: '$path.is_file_update',
        ),
      );
    case 'text_editor_code_execution_str_replace_result':
      return AnthropicTextEditorStrReplaceResult(
        lines: anthropicReplayNullableStringList(map['lines'],
            path: '$path.lines'),
        newLines: anthropicReplayNullableInt(map['new_lines'],
            path: '$path.new_lines'),
        newStart: anthropicReplayNullableInt(map['new_start'],
            path: '$path.new_start'),
        oldLines: anthropicReplayNullableInt(map['old_lines'],
            path: '$path.old_lines'),
        oldStart: anthropicReplayNullableInt(map['old_start'],
            path: '$path.old_start'),
      );
    default:
      throw FormatException('Unsupported execution result type: $type.');
  }
}

List<AnthropicExecutionFileHandle> anthropicParseExecutionFileHandles(
  Object? value, {
  required String path,
}) {
  final list = anthropicReplayRequiredList(value, path: path);
  return [
    for (var index = 0; index < list.length; index++)
      AnthropicExecutionFileHandle.fromJson(
        anthropicReplayRequiredObject(
          list[index],
          path: '$path[$index]',
        ),
      ),
  ];
}
