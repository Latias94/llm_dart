import 'anthropic_code_execution_replay_result_core.dart';

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
