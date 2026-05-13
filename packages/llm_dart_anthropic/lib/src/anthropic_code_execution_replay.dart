import 'package:llm_dart_provider/llm_dart_provider.dart';

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
    final type = _requiredNonEmptyString(
      json['type'],
      path: 'fileHandle.type',
    );
    final fileId = _requiredNonEmptyString(
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

final class AnthropicCodeExecutionReplay {
  static const kind = 'anthropic.result.code_execution';
  static const schema = 'anthropic.execution.result.v1';
  static const canonicalToolName = 'code_execution';

  final String toolCallId;
  final String toolName;
  final AnthropicCodeExecutionBlockType blockType;
  final Map<String, Object?> block;
  final AnthropicCodeExecutionResult result;
  final ProviderMetadata? providerMetadata;

  factory AnthropicCodeExecutionReplay({
    required String toolCallId,
    String toolName = canonicalToolName,
    required AnthropicCodeExecutionBlockType blockType,
    required Map<String, Object?> block,
    ProviderMetadata? providerMetadata,
  }) {
    final normalizedBlock = _normalizeJsonObject(
      block,
      path: 'block',
    );
    final wireType = _requiredNonEmptyString(
      normalizedBlock['type'],
      path: 'block.type',
    );
    if (wireType != blockType.value) {
      throw FormatException(
        'Expected block.type to equal ${blockType.value}, got $wireType.',
      );
    }

    final wireToolCallId = _requiredNonEmptyString(
      normalizedBlock['tool_use_id'],
      path: 'block.tool_use_id',
    );
    if (wireToolCallId != toolCallId) {
      throw FormatException(
        'Expected block.tool_use_id to equal $toolCallId, got $wireToolCallId.',
      );
    }

    final result = _parseExecutionResult(
      _requiredObject(
        normalizedBlock['content'],
        path: 'block.content',
      ),
      path: 'block.content',
    );

    return AnthropicCodeExecutionReplay._(
      toolCallId: toolCallId,
      toolName: toolName,
      blockType: blockType,
      block: normalizedBlock,
      result: result,
      providerMetadata: providerMetadata,
    );
  }

  factory AnthropicCodeExecutionReplay.fromJson(
    Map<String, Object?> json, {
    ProviderMetadata? providerMetadata,
  }) {
    final normalized = _normalizeJsonObject(
      json,
      path: 'replay',
    );
    final replayRole = _requiredNonEmptyString(
      normalized['replayRole'],
      path: 'replay.replayRole',
    );
    if (replayRole != 'tool') {
      throw FormatException(
        'Expected replay.replayRole to equal "tool", got $replayRole.',
      );
    }

    final schemaValue = _requiredNonEmptyString(
      normalized['schema'],
      path: 'replay.schema',
    );
    if (schemaValue != schema) {
      throw FormatException(
        'Expected replay.schema to equal $schema, got $schemaValue.',
      );
    }

    final blockTypeValue = _requiredNonEmptyString(
      normalized['blockType'],
      path: 'replay.blockType',
    );
    final blockType = AnthropicCodeExecutionBlockType.tryParse(blockTypeValue);
    if (blockType == null) {
      throw FormatException('Unsupported replay.blockType: $blockTypeValue.');
    }

    return AnthropicCodeExecutionReplay(
      toolCallId: _requiredNonEmptyString(
        normalized['toolCallId'],
        path: 'replay.toolCallId',
      ),
      toolName: _optionalString(
            normalized['toolName'],
            path: 'replay.toolName',
          ) ??
          canonicalToolName,
      blockType: blockType,
      block: _requiredObject(
        normalized['block'],
        path: 'replay.block',
      ),
      providerMetadata: providerMetadata,
    );
  }

  const AnthropicCodeExecutionReplay._({
    required this.toolCallId,
    required this.toolName,
    required this.blockType,
    required this.block,
    required this.result,
    required this.providerMetadata,
  });

  String get resultType => result.type;

  List<AnthropicExecutionFileHandle> get fileHandles => result.fileHandles;

  bool get hasFileHandles => fileHandles.isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'schema': schema,
      'replayRole': 'tool',
      'toolCallId': toolCallId,
      'toolName': toolName,
      'blockType': blockType.value,
      'block': _normalizeJsonObject(
        block,
        path: 'block',
      ),
    };
  }

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomContentPart(
      kind: kind,
      data: toJson(),
      providerMetadata: providerMetadata ?? this.providerMetadata,
    );
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    final metadata = providerMetadata ?? this.providerMetadata;
    return CustomPromptPart(
      kind: kind,
      data: toJson(),
      providerOptions: ProviderReplayPromptPartOptions.fromMetadata(metadata),
    );
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomEvent(
      kind: kind,
      data: toJson(),
      providerMetadata: providerMetadata ?? this.providerMetadata,
    );
  }

  static AnthropicCodeExecutionReplay? tryParseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    try {
      return parseData(
        data,
        providerMetadata: providerMetadata,
      );
    } on FormatException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }

  static AnthropicCodeExecutionReplay parseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    return AnthropicCodeExecutionReplay.fromJson(
      _requiredObject(
        data,
        path: 'replay',
      ),
      providerMetadata: providerMetadata,
    );
  }

  static AnthropicCodeExecutionReplay? tryParseContentPart(ContentPart part) {
    if (part is! CustomContentPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: part.providerMetadata,
    );
  }

  static AnthropicCodeExecutionReplay? tryParsePromptPart(PromptPart part) {
    if (part is! CustomPromptPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: mergeProviderReplayMetadata(
        providerOptions: part.providerOptions,
      ),
    );
  }

  static AnthropicCodeExecutionReplay? tryParseEvent(
      LanguageModelStreamEvent event) {
    if (event is! CustomEvent || event.kind != kind) {
      return null;
    }

    return tryParseData(
      event.data,
      providerMetadata: event.providerMetadata,
    );
  }
}

AnthropicCodeExecutionResult _parseExecutionResult(
  Object? value, {
  required String path,
}) {
  final map = _requiredObject(value, path: path);
  final type = _requiredNonEmptyString(map['type'], path: '$path.type');

  switch (type) {
    case 'code_execution_result':
      return AnthropicProgrammaticCodeExecutionResult(
        stdout: _requiredString(map['stdout'], path: '$path.stdout'),
        stderr: _requiredString(map['stderr'], path: '$path.stderr'),
        returnCode: _requiredInt(
          map['return_code'],
          path: '$path.return_code',
        ),
        fileHandles: _parseFileHandles(
          map['content'],
          path: '$path.content',
        ),
      );
    case 'encrypted_code_execution_result':
      return AnthropicEncryptedCodeExecutionResult(
        encryptedStdout: _requiredString(
          map['encrypted_stdout'],
          path: '$path.encrypted_stdout',
        ),
        stderr: _requiredString(map['stderr'], path: '$path.stderr'),
        returnCode: _requiredInt(
          map['return_code'],
          path: '$path.return_code',
        ),
        fileHandles: _parseFileHandles(
          map['content'],
          path: '$path.content',
        ),
      );
    case 'bash_code_execution_result':
      return AnthropicBashCodeExecutionResult(
        stdout: _requiredString(map['stdout'], path: '$path.stdout'),
        stderr: _requiredString(map['stderr'], path: '$path.stderr'),
        returnCode: _requiredInt(
          map['return_code'],
          path: '$path.return_code',
        ),
        fileHandles: _parseFileHandles(
          map['content'],
          path: '$path.content',
        ),
      );
    case 'bash_code_execution_tool_result_error':
      return AnthropicBashCodeExecutionErrorResult(
        errorCode: _requiredNonEmptyString(
          map['error_code'],
          path: '$path.error_code',
        ),
      );
    case 'text_editor_code_execution_tool_result_error':
      return AnthropicTextEditorCodeExecutionErrorResult(
        errorCode: _requiredNonEmptyString(
          map['error_code'],
          path: '$path.error_code',
        ),
      );
    case 'text_editor_code_execution_view_result':
      return AnthropicTextEditorViewResult(
        content: _requiredString(map['content'], path: '$path.content'),
        fileType: _requiredNonEmptyString(
          map['file_type'],
          path: '$path.file_type',
        ),
        numLines: _nullableInt(map['num_lines'], path: '$path.num_lines'),
        startLine: _nullableInt(map['start_line'], path: '$path.start_line'),
        totalLines: _nullableInt(map['total_lines'], path: '$path.total_lines'),
      );
    case 'text_editor_code_execution_create_result':
      return AnthropicTextEditorCreateResult(
        isFileUpdate: _requiredBool(
          map['is_file_update'],
          path: '$path.is_file_update',
        ),
      );
    case 'text_editor_code_execution_str_replace_result':
      return AnthropicTextEditorStrReplaceResult(
        lines: _nullableStringList(map['lines'], path: '$path.lines'),
        newLines: _nullableInt(map['new_lines'], path: '$path.new_lines'),
        newStart: _nullableInt(map['new_start'], path: '$path.new_start'),
        oldLines: _nullableInt(map['old_lines'], path: '$path.old_lines'),
        oldStart: _nullableInt(map['old_start'], path: '$path.old_start'),
      );
    default:
      throw FormatException('Unsupported execution result type: $type.');
  }
}

List<AnthropicExecutionFileHandle> _parseFileHandles(
  Object? value, {
  required String path,
}) {
  final list = _requiredList(value, path: path);
  return [
    for (var index = 0; index < list.length; index++)
      AnthropicExecutionFileHandle.fromJson(
        _requiredObject(
          list[index],
          path: '$path[$index]',
        ),
      ),
  ];
}

Map<String, Object?> _normalizeJsonObject(
  Object? value, {
  required String path,
}) {
  final normalized = normalizeJsonValue(value, path: path);
  if (normalized is Map<String, Object?>) {
    return normalized;
  }

  throw FormatException('Expected a JSON object at $path.');
}

Map<String, Object?> _requiredObject(
  Object? value, {
  required String path,
}) {
  final normalized = normalizeJsonValue(value, path: path);
  if (normalized is Map<String, Object?>) {
    return normalized;
  }

  throw FormatException('Expected an object at $path.');
}

List<Object?> _requiredList(
  Object? value, {
  required String path,
}) {
  final normalized = normalizeJsonValue(value, path: path);
  if (normalized is List<Object?>) {
    return normalized;
  }

  if (normalized is List) {
    return List<Object?>.from(normalized);
  }

  throw FormatException('Expected a list at $path.');
}

String _requiredString(
  Object? value, {
  required String path,
}) {
  final normalized = _optionalString(value, path: path);
  if (normalized == null) {
    throw FormatException('Expected a string at $path.');
  }

  return normalized;
}

String _requiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final normalized = _requiredString(value, path: path);
  if (normalized.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }

  return normalized;
}

String? _optionalString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  throw FormatException('Expected a string at $path.');
}

int _requiredInt(
  Object? value, {
  required String path,
}) {
  final normalized = _nullableInt(value, path: path);
  if (normalized == null) {
    throw FormatException('Expected an int at $path.');
  }

  return normalized;
}

int? _nullableInt(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  throw FormatException('Expected an int at $path.');
}

bool _requiredBool(
  Object? value, {
  required String path,
}) {
  if (value is bool) {
    return value;
  }

  throw FormatException('Expected a bool at $path.');
}

List<String>? _nullableStringList(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final list = _requiredList(value, path: path);
  return [
    for (var index = 0; index < list.length; index++)
      _requiredString(
        list[index],
        path: '$path[$index]',
      ),
  ];
}
