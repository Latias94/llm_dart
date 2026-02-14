import 'package:llm_dart_core/llm_dart_core.dart';

import 'tool_types.dart';

/// A local tool definition bundling a tool schema and a local executor.
class LocalTool {
  final Tool tool;

  /// Optional local executor for this tool.
  ///
  /// When null, the tool is schema-only: it can be advertised to the model, but
  /// will not be executed by local tool loops.
  final ToolCallHandler? handler;
  final ToolApprovalCheck? needsApproval;
  final ToolInputStartHandler? onInputStart;
  final ToolInputDeltaHandler? onInputDelta;
  final ToolInputAvailableHandler? onInputAvailable;
  final ToolInputErrorHandler? onInputError;

  const LocalTool({
    required this.tool,
    this.handler,
    this.needsApproval,
    this.onInputStart,
    this.onInputDelta,
    this.onInputAvailable,
    this.onInputError,
  });

  String get name => tool.function.name;
}

/// A set of tool definitions (optionally locally executable).
///
/// This mirrors the spirit of Vercel AI SDK tool sets: users define tools once,
/// and higher-level orchestration (tool loops) uses both the schema and handler.
class ToolSet {
  final Map<String, LocalTool> _toolsByName;

  ToolSet._(this._toolsByName);

  factory ToolSet(Iterable<LocalTool> tools) {
    final map = <String, LocalTool>{};
    for (final t in tools) {
      map[t.name] = t;
    }
    return ToolSet._(map);
  }

  /// Tool definitions for passing to providers.
  List<Tool> get tools =>
      _toolsByName.values.map((t) => t.tool).toList(growable: false);

  /// Returns the local tool definition for [name], if present.
  LocalTool? toolByName(String name) => _toolsByName[name];

  /// Local tool handlers keyed by tool name.
  Map<String, ToolCallHandler> get handlers => {
        for (final entry in _toolsByName.entries)
          if (entry.value.handler != null) entry.key: entry.value.handler!,
      };

  /// Optional approval checks keyed by tool name.
  Map<String, ToolApprovalCheck> get approvalChecks => {
        for (final entry in _toolsByName.entries)
          if (entry.value.needsApproval != null)
            entry.key: entry.value.needsApproval!,
      };

  /// Merge two tool sets (right-hand side overrides name conflicts).
  ToolSet merge(ToolSet other) {
    return ToolSet._({
      ..._toolsByName,
      ...other._toolsByName,
    });
  }
}

/// Convenience builder for a local function tool.
LocalTool functionTool({
  required String name,
  required String description,
  required ParametersSchema parameters,
  required ToolCallHandler handler,
  ToolApprovalCheck? needsApproval,
  ToolInputStartHandler? onInputStart,
  ToolInputDeltaHandler? onInputDelta,
  ToolInputAvailableHandler? onInputAvailable,
  ToolInputErrorHandler? onInputError,
}) {
  return LocalTool(
    tool: Tool.function(
      name: name,
      description: description,
      parameters: parameters,
    ),
    handler: handler,
    needsApproval: needsApproval,
    onInputStart: onInputStart,
    onInputDelta: onInputDelta,
    onInputAvailable: onInputAvailable,
    onInputError: onInputError,
  );
}

/// Convenience builder for a schema-only function tool (no local executor).
LocalTool schemaOnlyFunctionTool({
  required String name,
  required String description,
  required ParametersSchema parameters,
  ToolApprovalCheck? needsApproval,
  ToolInputStartHandler? onInputStart,
  ToolInputDeltaHandler? onInputDelta,
  ToolInputAvailableHandler? onInputAvailable,
  ToolInputErrorHandler? onInputError,
}) {
  return LocalTool(
    tool: Tool.function(
      name: name,
      description: description,
      parameters: parameters,
    ),
    handler: null,
    needsApproval: needsApproval,
    onInputStart: onInputStart,
    onInputDelta: onInputDelta,
    onInputAvailable: onInputAvailable,
    onInputError: onInputError,
  );
}
