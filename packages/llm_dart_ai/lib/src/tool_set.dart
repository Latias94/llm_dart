import 'package:llm_dart_core/llm_dart_core.dart';

import 'tool_types.dart';

/// A local tool definition bundling a tool schema and a local executor.
class LocalTool {
  final Tool tool;
  final ToolCallHandler handler;
  final ToolApprovalCheck? needsApproval;

  const LocalTool({
    required this.tool,
    required this.handler,
    this.needsApproval,
  });

  String get name => tool.function.name;
}

/// A set of locally executable tools.
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

  /// Local tool handlers keyed by tool name.
  Map<String, ToolCallHandler> get handlers => {
        for (final entry in _toolsByName.entries)
          entry.key: entry.value.handler,
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
}) {
  return LocalTool(
    tool: Tool.function(
      name: name,
      description: description,
      parameters: parameters,
    ),
    handler: handler,
    needsApproval: needsApproval,
  );
}
