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

abstract base class AnthropicCodeExecutionResult {
  const AnthropicCodeExecutionResult();

  String get type;

  List<AnthropicExecutionFileHandle> get fileHandles => const [];

  Map<String, Object?> toJson();
}
