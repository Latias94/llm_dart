import 'anthropic_code_execution_replay_json.dart';

enum AnthropicCodeExecutionBlockType {
  codeExecutionToolResult('code_execution_tool_result'),
  bashCodeExecutionToolResult('bash_code_execution_tool_result'),
  textEditorCodeExecutionToolResult('text_editor_code_execution_tool_result');

  final String value;

  const AnthropicCodeExecutionBlockType(this.value);

  static AnthropicCodeExecutionBlockType? tryParse(String value) {
    for (final blockType in AnthropicCodeExecutionBlockType.values) {
      if (blockType.value == value) {
        return blockType;
      }
    }

    return null;
  }
}

final class AnthropicExecutionFileHandle {
  final String type;
  final String fileId;

  const AnthropicExecutionFileHandle({
    required this.type,
    required this.fileId,
  });

  factory AnthropicExecutionFileHandle.fromJson(Map<String, Object?> json) {
    final type = anthropicReplayRequiredNonEmptyString(
      json['type'],
      path: 'fileHandle.type',
    );
    final fileId = anthropicReplayRequiredNonEmptyString(
      json['file_id'],
      path: 'fileHandle.file_id',
    );
    return AnthropicExecutionFileHandle(
      type: type,
      fileId: fileId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'type': type,
      'file_id': fileId,
    };
  }
}

sealed class AnthropicCodeExecutionResult {
  const AnthropicCodeExecutionResult();

  String get type;

  List<AnthropicExecutionFileHandle> get fileHandles => const [];

  Map<String, Object?> toJson();
}

final class AnthropicProgrammaticCodeExecutionResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String stdout;
  final String stderr;
  final int returnCode;
  @override
  final List<AnthropicExecutionFileHandle> fileHandles;

  const AnthropicProgrammaticCodeExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.returnCode,
    required this.fileHandles,
    this.type = 'code_execution_result',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'stdout': stdout,
      'stderr': stderr,
      'return_code': returnCode,
      'content': [
        for (final handle in fileHandles) handle.toJson(),
      ],
    };
  }
}

final class AnthropicEncryptedCodeExecutionResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String encryptedStdout;
  final String stderr;
  final int returnCode;
  @override
  final List<AnthropicExecutionFileHandle> fileHandles;

  const AnthropicEncryptedCodeExecutionResult({
    required this.encryptedStdout,
    required this.stderr,
    required this.returnCode,
    required this.fileHandles,
    this.type = 'encrypted_code_execution_result',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'encrypted_stdout': encryptedStdout,
      'stderr': stderr,
      'return_code': returnCode,
      'content': [
        for (final handle in fileHandles) handle.toJson(),
      ],
    };
  }
}

final class AnthropicBashCodeExecutionResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String stdout;
  final String stderr;
  final int returnCode;
  @override
  final List<AnthropicExecutionFileHandle> fileHandles;

  const AnthropicBashCodeExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.returnCode,
    required this.fileHandles,
    this.type = 'bash_code_execution_result',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'stdout': stdout,
      'stderr': stderr,
      'return_code': returnCode,
      'content': [
        for (final handle in fileHandles) handle.toJson(),
      ],
    };
  }
}

final class AnthropicBashCodeExecutionErrorResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String errorCode;

  const AnthropicBashCodeExecutionErrorResult({
    required this.errorCode,
    this.type = 'bash_code_execution_tool_result_error',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'error_code': errorCode,
    };
  }
}

final class AnthropicTextEditorCodeExecutionErrorResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String errorCode;

  const AnthropicTextEditorCodeExecutionErrorResult({
    required this.errorCode,
    this.type = 'text_editor_code_execution_tool_result_error',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'error_code': errorCode,
    };
  }
}

final class AnthropicTextEditorViewResult extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String content;
  final String fileType;
  final int? numLines;
  final int? startLine;
  final int? totalLines;

  const AnthropicTextEditorViewResult({
    required this.content,
    required this.fileType,
    required this.numLines,
    required this.startLine,
    required this.totalLines,
    this.type = 'text_editor_code_execution_view_result',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'content': content,
      'file_type': fileType,
      'num_lines': numLines,
      'start_line': startLine,
      'total_lines': totalLines,
    };
  }
}

final class AnthropicTextEditorCreateResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final bool isFileUpdate;

  const AnthropicTextEditorCreateResult({
    required this.isFileUpdate,
    this.type = 'text_editor_code_execution_create_result',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'is_file_update': isFileUpdate,
    };
  }
}

final class AnthropicTextEditorStrReplaceResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final List<String>? lines;
  final int? newLines;
  final int? newStart;
  final int? oldLines;
  final int? oldStart;

  const AnthropicTextEditorStrReplaceResult({
    required this.lines,
    required this.newLines,
    required this.newStart,
    required this.oldLines,
    required this.oldStart,
    this.type = 'text_editor_code_execution_str_replace_result',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'lines': lines,
      'new_lines': newLines,
      'new_start': newStart,
      'old_lines': oldLines,
      'old_start': oldStart,
    };
  }
}

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
