import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'tool_set.dart';
import 'tool_types.dart';

/// Utilities for executing OpenAI Responses "provider-native" tools locally.
///
/// These tools are represented as `ProviderTool` in requests, but some of them
/// require **client execution** (e.g. `shell`, `local_shell`, `apply_patch`).
///
/// Streaming parsers typically emit these as `LLMProviderToolCallPart` with
/// `providerExecuted=false`, and the tool loop bridges them into local function
/// tool calls (`V3ToolCall`) by using `toolName` as the function name.
///
/// This module provides:
/// - lightweight parsers for tool inputs
/// - handler factories that return `ToolCallHandler`
/// - optional schema definitions for allowlisting/validation
class OpenAIClientExecutedTools {
  static ToolApprovalCheck requireApprovalForToolNames(
    Set<String> toolNames,
  ) {
    final allowed = toolNames.map((t) => t.trim()).where((t) => t.isNotEmpty);
    final set = allowed.toSet();
    return (toolCall,
        {required messages, required stepIndex, cancelToken}) async {
      return set.contains(toolCall.toolName);
    };
  }

  static ToolApprovalCheck alwaysRequireApproval() =>
      requireApprovalForToolNames(const {'shell', 'apply_patch'});

  /// Minimal schema for `shell` tool calls bridged into local execution.
  ///
  /// Note: OpenAI defines both `shell` and `local_shell` with different action
  /// shapes, but this library commonly normalizes both to the same tool name
  /// (`shell`) for AI SDK parity. The schema here is intentionally permissive.
  static Tool shellToolDefinition() => Tool.function(
        name: 'shell',
        description:
            'Client-executed shell tool call (OpenAI Responses provider tool).',
        inputSchema: Schema.params(
          properties: {
            'action': Schema.object(
              'Shell action object (provider-defined shape).',
              properties: const {},
            ),
          },
        ),
      );

  /// Minimal schema for `apply_patch` tool calls bridged into local execution.
  static Tool applyPatchToolDefinition() => Tool.function(
        name: 'apply_patch',
        description:
            'Client-executed apply_patch tool call (OpenAI Responses provider tool).',
        inputSchema: Schema.params(
          properties: {
            'callId': Schema.string('Tool call id.'),
            'operation': Schema.object(
              'Patch operation object (provider-defined shape).',
              properties: const {},
            ),
          },
        ),
      );

  /// Create a `ToolSet` for OpenAI client-executed tools.
  ///
  /// WARNING: Exposing these as function tools allows the model to request
  /// them directly. Prefer enabling OpenAI provider tools via `providerTools`
  /// and using `streamToolLoopParts`/`runToolLoop` with explicit approval checks.
  static ToolSet toolSet({
    ToolCallHandler? shell,
    ToolCallHandler? applyPatch,
    ToolApprovalCheck? shellNeedsApproval,
    ToolApprovalCheck? applyPatchNeedsApproval,
  }) {
    return ToolSet([
      LocalTool(
        tool: shellToolDefinition(),
        handler: shell,
        needsApproval: shellNeedsApproval,
      ),
      LocalTool(
        tool: applyPatchToolDefinition(),
        handler: applyPatch,
        needsApproval: applyPatchNeedsApproval,
      ),
    ]);
  }

  /// Create a handler for OpenAI `shell` / `local_shell` tool calls.
  ///
  /// The handler auto-detects the action shape:
  /// - `action.commands: string[]` => shell
  /// - `action.type='exec'` and `action.command: string[]` => local_shell
  ///
  /// Return shapes should match OpenAI tool outputs:
  /// - shell: `{ "output": [{ "stdout": "...", "stderr": "...", "outcome": ... }] }`
  /// - local_shell: `{ "output": "..." }`
  static ToolCallHandler shellHandler({
    required FutureOr<Map<String, dynamic>> Function(
      OpenAIShellCommandsAction action, {
      CancelToken? cancelToken,
    }) onShell,
    FutureOr<Map<String, dynamic>> Function(
      OpenAILocalShellExecAction action, {
      CancelToken? cancelToken,
    })? onLocalShell,
  }) {
    return (input, options) async {
      final args = input;
      final actionRaw = args['action'];
      if (actionRaw is! Map) {
        return {
          'output': [
            {
              'stdout': '',
              'stderr': 'Invalid shell action (expected object).',
              'outcome': {'type': 'exit', 'exitCode': 1},
            }
          ],
        };
      }

      final action = actionRaw.cast<String, dynamic>();
      final commands = action['commands'];
      if (commands is List) {
        final parsed = OpenAIShellCommandsAction.tryParse(action);
        if (parsed == null) {
          return {
            'output': [
              {
                'stdout': '',
                'stderr': 'Invalid shell action.commands (expected string[]).',
                'outcome': {'type': 'exit', 'exitCode': 1},
              }
            ],
          };
        }
        return await Future.value(
          onShell(parsed, cancelToken: options.cancelToken),
        );
      }

      final type = action['type'];
      if (type == 'exec') {
        final parsed = OpenAILocalShellExecAction.tryParse(action);
        if (parsed == null) {
          return {
            'output': 'Invalid local_shell action (expected exec + command[]).',
          };
        }
        final handler = onLocalShell;
        if (handler == null) {
          return {
            'output':
                'local_shell is not enabled. Provide onLocalShell to execute.',
          };
        }
        return await Future.value(
          handler(parsed, cancelToken: options.cancelToken),
        );
      }

      return {
        'output': [
          {
            'stdout': '',
            'stderr':
                'Unsupported shell action shape (expected commands[] or exec).',
            'outcome': {'type': 'exit', 'exitCode': 1},
          }
        ],
      };
    };
  }

  /// Create a handler for OpenAI `apply_patch` tool calls.
  ///
  /// Return shape should match OpenAI tool output:
  /// `{ "status": "completed" | "failed", "output"?: "..." }`
  static ToolCallHandler applyPatchHandler({
    required FutureOr<OpenAIApplyPatchOutput> Function(
      OpenAIApplyPatchInput input, {
      CancelToken? cancelToken,
    }) execute,
  }) {
    return (input, options) async {
      final args = input;
      final parsed = OpenAIApplyPatchInput.tryParse(args);
      if (parsed == null) {
        return const <String, dynamic>{
          'status': 'failed',
          'output': 'Invalid apply_patch input.',
        };
      }

      final out =
          await Future.value(execute(parsed, cancelToken: options.cancelToken));
      return out.toJson();
    };
  }
}

final class OpenAIShellCommandsAction {
  final List<String> commands;
  final int? timeoutMs;
  final int? maxOutputLength;

  const OpenAIShellCommandsAction({
    required this.commands,
    this.timeoutMs,
    this.maxOutputLength,
  });

  static OpenAIShellCommandsAction? tryParse(Map<String, dynamic> action) {
    final raw = action['commands'];
    if (raw is! List) return null;
    final commands = raw.whereType<String>().toList(growable: false);
    if (commands.isEmpty) return null;

    int? readInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '');
    }

    return OpenAIShellCommandsAction(
      commands: commands,
      timeoutMs: readInt(action['timeoutMs'] ?? action['timeout_ms']),
      maxOutputLength:
          readInt(action['maxOutputLength'] ?? action['max_output_length']),
    );
  }
}

final class OpenAILocalShellExecAction {
  final List<String> command;
  final int? timeoutMs;
  final String? user;
  final String? workingDirectory;
  final Map<String, String>? env;

  const OpenAILocalShellExecAction({
    required this.command,
    this.timeoutMs,
    this.user,
    this.workingDirectory,
    this.env,
  });

  static OpenAILocalShellExecAction? tryParse(Map<String, dynamic> action) {
    if (action['type'] != 'exec') return null;
    final raw = action['command'];
    if (raw is! List) return null;
    final command = raw.whereType<String>().toList(growable: false);
    if (command.isEmpty) return null;

    int? readInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '');
    }

    Map<String, String>? readStringMap(Object? v) {
      if (v is! Map) return null;
      final out = <String, String>{};
      for (final e in v.entries) {
        final key = e.key?.toString();
        final value = e.value?.toString();
        if (key == null || key.trim().isEmpty) continue;
        if (value == null) continue;
        out[key] = value;
      }
      return out.isEmpty ? null : out;
    }

    final user = action['user']?.toString();
    final wd = action['workingDirectory']?.toString() ??
        action['working_directory']?.toString();

    return OpenAILocalShellExecAction(
      command: command,
      timeoutMs: readInt(action['timeoutMs'] ?? action['timeout_ms']),
      user: (user != null && user.trim().isNotEmpty) ? user : null,
      workingDirectory: (wd != null && wd.trim().isNotEmpty) ? wd : null,
      env: readStringMap(action['env']),
    );
  }
}

sealed class OpenAIApplyPatchOperation {
  const OpenAIApplyPatchOperation();

  Map<String, dynamic> toJson();
}

final class OpenAIApplyPatchCreateFile extends OpenAIApplyPatchOperation {
  final String path;
  final String diff;

  const OpenAIApplyPatchCreateFile({
    required this.path,
    required this.diff,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'create_file',
        'path': path,
        'diff': diff,
      };
}

final class OpenAIApplyPatchUpdateFile extends OpenAIApplyPatchOperation {
  final String path;
  final String diff;

  const OpenAIApplyPatchUpdateFile({
    required this.path,
    required this.diff,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'update_file',
        'path': path,
        'diff': diff,
      };
}

final class OpenAIApplyPatchDeleteFile extends OpenAIApplyPatchOperation {
  final String path;

  const OpenAIApplyPatchDeleteFile({required this.path});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'delete_file',
        'path': path,
      };
}

final class OpenAIApplyPatchInput {
  final String callId;
  final OpenAIApplyPatchOperation operation;

  const OpenAIApplyPatchInput({
    required this.callId,
    required this.operation,
  });

  static OpenAIApplyPatchInput? tryParse(Map<String, dynamic> args) {
    final callId = args['callId']?.toString() ?? '';
    final operationRaw = args['operation'];
    if (callId.trim().isEmpty) return null;
    if (operationRaw is! Map) return null;

    final op = operationRaw.cast<String, dynamic>();
    final type = op['type']?.toString() ?? '';
    final path = op['path']?.toString() ?? '';
    if (type.trim().isEmpty || path.trim().isEmpty) return null;

    switch (type) {
      case 'create_file':
        final diff = op['diff']?.toString();
        if (diff == null) return null;
        return OpenAIApplyPatchInput(
          callId: callId,
          operation: OpenAIApplyPatchCreateFile(path: path, diff: diff),
        );
      case 'update_file':
        final diff = op['diff']?.toString();
        if (diff == null) return null;
        return OpenAIApplyPatchInput(
          callId: callId,
          operation: OpenAIApplyPatchUpdateFile(path: path, diff: diff),
        );
      case 'delete_file':
        return OpenAIApplyPatchInput(
          callId: callId,
          operation: OpenAIApplyPatchDeleteFile(path: path),
        );
      default:
        return null;
    }
  }
}

final class OpenAIApplyPatchOutput {
  final String status;
  final String? output;

  const OpenAIApplyPatchOutput.completed([this.output]) : status = 'completed';

  const OpenAIApplyPatchOutput.failed([this.output]) : status = 'failed';

  Map<String, dynamic> toJson() => {
        'status': status,
        if (output != null) 'output': output,
      };
}
