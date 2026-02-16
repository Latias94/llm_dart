import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'tool_set.dart';
import 'tool_types.dart';

/// Utilities for executing Anthropic "provider-native" tools locally.
///
/// Anthropic defines several provider-specific tools that are *client-executed*,
/// such as `bash`, `computer`, `memory`, and text editor tools.
///
/// In `llm_dart`, these tools are typically enabled via `providerTools`
/// (e.g. `AnthropicProviderTools.bash()`), and streaming parsers surface them as
/// `LLMProviderToolCallPart(providerExecuted=false)`. The tool loop bridges them
/// into local function tool calls (`ToolCall`) by using the tool name as the
/// function name.
///
/// This module provides:
/// - lightweight parsers for tool inputs
/// - handler factories that return `ToolCallHandler`
/// - optional schema definitions for allowlisting/validation
class AnthropicClientExecutedTools {
  static ToolApprovalCheck requireApprovalForToolNames(
    Set<String> toolNames,
  ) {
    final allowed = toolNames.map((t) => t.trim()).where((t) => t.isNotEmpty);
    final set = allowed.toSet();
    return (toolCall,
        {required messages, required stepIndex, cancelToken}) async {
      return set.contains(toolCall.function.name);
    };
  }

  static ToolApprovalCheck alwaysRequireApproval() =>
      requireApprovalForToolNames(
        const {
          'bash',
          'computer',
          'memory',
          'str_replace_editor',
          'str_replace_based_edit_tool',
        },
      );

  static Tool bashToolDefinition() => Tool.function(
        name: 'bash',
        description: 'Client-executed Anthropic bash tool call.',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {
            'command': ParameterProperty(
              propertyType: 'string',
              description: 'Bash command to run.',
            ),
            'restart': ParameterProperty(
              propertyType: 'boolean',
              description: 'Whether to restart the tool.',
            ),
          },
          required: ['command'],
        ),
      );

  static Tool memoryToolDefinition() => Tool.function(
        name: 'memory',
        description: 'Client-executed Anthropic memory tool call.',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {
            'command': ParameterProperty(
              propertyType: 'string',
              description: 'Memory tool command.',
            ),
            'path': ParameterProperty(
              propertyType: 'string',
              description: 'Target path for memory operation.',
            ),
          },
          required: ['command'],
        ),
      );

  static Tool textEditorToolDefinition({required String name}) => Tool.function(
        name: name,
        description: 'Client-executed Anthropic text editor tool call.',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {
            'command': ParameterProperty(
              propertyType: 'string',
              description: 'Text editor command.',
            ),
            'path': ParameterProperty(
              propertyType: 'string',
              description: 'File or directory path.',
            ),
          },
          required: ['command', 'path'],
        ),
      );

  static Tool computerToolDefinition() => Tool.function(
        name: 'computer',
        description: 'Client-executed Anthropic computer tool call.',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {
            'action': ParameterProperty(
              propertyType: 'string',
              description: 'Computer action name.',
            ),
            'coordinate': ParameterProperty(
              propertyType: 'array',
              description: 'Coordinate tuple [x, y].',
            ),
            'region': ParameterProperty(
              propertyType: 'array',
              description: 'Region tuple [x1, y1, x2, y2].',
            ),
            'text': ParameterProperty(
              propertyType: 'string',
              description: 'Text payload for keyboard actions.',
            ),
            'duration': ParameterProperty(
              propertyType: 'number',
              description: 'Duration in seconds for wait/hold_key.',
            ),
          },
          required: ['action'],
        ),
      );

  /// Create a `ToolSet` for Anthropic client-executed tools.
  ///
  /// Note: You do not need to pass these tools in the `tools:` allowlist for
  /// `streamToolLoopParts` when the model emits them as provider-defined tool
  /// calls (`providerExecuted=false`). This tool set is provided mainly for
  /// convenience and schema visibility.
  static ToolSet toolSet({
    ToolCallHandler? bash,
    ToolCallHandler? memory,
    ToolCallHandler? computer,
    ToolCallHandler? strReplaceEditor,
    ToolCallHandler? strReplaceBasedEditTool,
    ToolApprovalCheck? bashNeedsApproval,
    ToolApprovalCheck? memoryNeedsApproval,
    ToolApprovalCheck? computerNeedsApproval,
    ToolApprovalCheck? strReplaceEditorNeedsApproval,
    ToolApprovalCheck? strReplaceBasedEditToolNeedsApproval,
  }) {
    return ToolSet([
      LocalTool(
        tool: bashToolDefinition(),
        handler: bash,
        needsApproval: bashNeedsApproval,
      ),
      LocalTool(
        tool: memoryToolDefinition(),
        handler: memory,
        needsApproval: memoryNeedsApproval,
      ),
      LocalTool(
        tool: computerToolDefinition(),
        handler: computer,
        needsApproval: computerNeedsApproval,
      ),
      LocalTool(
        tool: textEditorToolDefinition(name: 'str_replace_editor'),
        handler: strReplaceEditor,
        needsApproval: strReplaceEditorNeedsApproval,
      ),
      LocalTool(
        tool: textEditorToolDefinition(name: 'str_replace_based_edit_tool'),
        handler: strReplaceBasedEditTool,
        needsApproval: strReplaceBasedEditToolNeedsApproval,
      ),
    ]);
  }

  static ToolCallHandler bashHandler({
    required FutureOr<Object?> Function(
      AnthropicBashInput input, {
      CancelToken? cancelToken,
    }) execute,
  }) {
    return (input, options) async {
      final args = input;
      final parsed = AnthropicBashInput.tryParse(args);
      if (parsed == null) {
        return 'Invalid bash input.';
      }
      return await Future.value(
        execute(parsed, cancelToken: options.cancelToken),
      );
    };
  }

  static ToolCallHandler computerHandler({
    required FutureOr<Object?> Function(
      AnthropicComputerInput input, {
      CancelToken? cancelToken,
    }) execute,
  }) {
    return (input, options) async {
      final args = input;
      final parsed = AnthropicComputerInput.tryParse(args);
      if (parsed == null) {
        return 'Invalid computer input.';
      }
      return await Future.value(
        execute(parsed, cancelToken: options.cancelToken),
      );
    };
  }

  static ToolCallHandler memoryHandler({
    required FutureOr<Object?> Function(
      AnthropicMemoryInput input, {
      CancelToken? cancelToken,
    }) execute,
  }) {
    return (input, options) async {
      final args = input;
      final parsed = AnthropicMemoryInput.tryParse(args);
      if (parsed == null) {
        return 'Invalid memory input.';
      }
      return await Future.value(
        execute(parsed, cancelToken: options.cancelToken),
      );
    };
  }

  static ToolCallHandler textEditorHandler({
    required FutureOr<Object?> Function(
      AnthropicTextEditorInput input, {
      CancelToken? cancelToken,
    }) execute,
  }) {
    return (input, options) async {
      final args = input;
      final parsed = AnthropicTextEditorInput.tryParse(args);
      if (parsed == null) {
        return 'Invalid text editor input.';
      }
      return await Future.value(
        execute(parsed, cancelToken: options.cancelToken),
      );
    };
  }
}

final class AnthropicBashInput {
  final String command;
  final bool? restart;

  const AnthropicBashInput({required this.command, this.restart});

  static AnthropicBashInput? tryParse(Map<String, dynamic> json) {
    final command = json['command'] as String?;
    final restart = json['restart'] as bool?;
    if (command == null || command.trim().isEmpty) return null;
    return AnthropicBashInput(command: command, restart: restart);
  }
}

final class AnthropicComputerInput {
  final String action;
  final List<int>? coordinate;
  final List<int>? startCoordinate;
  final List<int>? region;
  final String? text;
  final double? duration;
  final num? scrollAmount;
  final String? scrollDirection;

  const AnthropicComputerInput({
    required this.action,
    this.coordinate,
    this.startCoordinate,
    this.region,
    this.text,
    this.duration,
    this.scrollAmount,
    this.scrollDirection,
  });

  static List<int>? _readIntPair(Object? v) {
    if (v is List && v.length == 2) {
      final a = v[0];
      final b = v[1];
      if (a is int && b is int) return [a, b];
      if (a is num && b is num) return [a.toInt(), b.toInt()];
    }
    return null;
  }

  static List<int>? _readIntQuad(Object? v) {
    if (v is List && v.length == 4) {
      final out = <int>[];
      for (final item in v) {
        if (item is int) {
          out.add(item);
        } else if (item is num) {
          out.add(item.toInt());
        } else {
          return null;
        }
      }
      return out;
    }
    return null;
  }

  static AnthropicComputerInput? tryParse(Map<String, dynamic> json) {
    final action = json['action'] as String?;
    if (action == null || action.trim().isEmpty) return null;

    final coordinate = _readIntPair(json['coordinate']);
    final startCoordinate =
        _readIntPair(json['start_coordinate'] ?? json['startCoordinate']);
    final region = _readIntQuad(json['region']);

    final durationRaw = json['duration'];
    final duration = durationRaw is num ? durationRaw.toDouble() : null;

    return AnthropicComputerInput(
      action: action,
      coordinate: coordinate,
      startCoordinate: startCoordinate,
      region: region,
      text: json['text'] as String?,
      duration: duration,
      scrollAmount: json['scroll_amount'] ?? json['scrollAmount'],
      scrollDirection:
          (json['scroll_direction'] ?? json['scrollDirection']) as String?,
    );
  }
}

final class AnthropicTextEditorInput {
  final String command;
  final String path;
  final String? fileText;
  final int? insertLine;
  final String? newStr;
  final String? insertText;
  final String? oldStr;
  final List<int>? viewRange;

  const AnthropicTextEditorInput({
    required this.command,
    required this.path,
    this.fileText,
    this.insertLine,
    this.newStr,
    this.insertText,
    this.oldStr,
    this.viewRange,
  });

  static AnthropicTextEditorInput? tryParse(Map<String, dynamic> json) {
    final command = json['command'] as String?;
    final path = json['path'] as String?;
    if (command == null || command.trim().isEmpty) return null;
    if (path == null || path.trim().isEmpty) return null;

    int? readInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '');
    }

    List<int>? readIntList(Object? v) {
      if (v is! List) return null;
      final out = <int>[];
      for (final item in v) {
        final parsed = readInt(item);
        if (parsed == null) return null;
        out.add(parsed);
      }
      return out;
    }

    return AnthropicTextEditorInput(
      command: command,
      path: path,
      fileText: (json['file_text'] ?? json['fileText']) as String?,
      insertLine: readInt(json['insert_line'] ?? json['insertLine']),
      newStr: (json['new_str'] ?? json['newStr']) as String?,
      insertText: (json['insert_text'] ?? json['insertText']) as String?,
      oldStr: (json['old_str'] ?? json['oldStr']) as String?,
      viewRange: readIntList(json['view_range'] ?? json['viewRange']),
    );
  }
}

final class AnthropicMemoryInput {
  final String command;
  final String? path;
  final String? oldPath;
  final String? newPath;
  final String? fileText;
  final int? insertLine;
  final String? insertText;
  final String? oldStr;
  final String? newStr;
  final List<num>? viewRange;

  const AnthropicMemoryInput({
    required this.command,
    this.path,
    this.oldPath,
    this.newPath,
    this.fileText,
    this.insertLine,
    this.insertText,
    this.oldStr,
    this.newStr,
    this.viewRange,
  });

  static AnthropicMemoryInput? tryParse(Map<String, dynamic> json) {
    final command = json['command'] as String?;
    if (command == null || command.trim().isEmpty) return null;

    int? readInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '');
    }

    List<num>? readNumPair(Object? v) {
      if (v is List && v.length == 2 && v[0] is num && v[1] is num) {
        return [v[0] as num, v[1] as num];
      }
      return null;
    }

    return AnthropicMemoryInput(
      command: command,
      path: (json['path'] ?? json['filePath']) as String?,
      oldPath: (json['old_path'] ?? json['oldPath']) as String?,
      newPath: (json['new_path'] ?? json['newPath']) as String?,
      fileText: (json['file_text'] ?? json['fileText']) as String?,
      insertLine: readInt(json['insert_line'] ?? json['insertLine']),
      insertText: (json['insert_text'] ?? json['insertText']) as String?,
      oldStr: (json['old_str'] ?? json['oldStr']) as String?,
      newStr: (json['new_str'] ?? json['newStr']) as String?,
      viewRange: readNumPair(json['view_range'] ?? json['viewRange']),
    );
  }
}
