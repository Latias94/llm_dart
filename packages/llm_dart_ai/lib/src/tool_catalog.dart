import 'package:llm_dart_core/llm_dart_core.dart';

import 'tool_set.dart';
import 'tool_types.dart';

/// A lookup table for local tools.
///
/// This is a Dart-flavored counterpart to AI SDK's "dynamic tool" patterns:
/// users can keep a large tool catalog locally, and the tool loop can
/// opportunistically load tool schemas/handlers only when they are referenced
/// (e.g. via Anthropic `tool_search_*`).
abstract class ToolCatalog {
  /// Returns a local tool definition for [name], or null if unknown.
  LocalTool? lookup(String name);
}

/// A [ToolCatalog] backed by a [ToolSet].
final class ToolSetCatalog implements ToolCatalog {
  final ToolSet toolSet;

  const ToolSetCatalog(this.toolSet);

  @override
  LocalTool? lookup(String name) => toolSet.toolByName(name);
}

/// A [ToolCatalog] backed by a plain map.
final class MapToolCatalog implements ToolCatalog {
  final Map<String, LocalTool> toolsByName;

  const MapToolCatalog(this.toolsByName);

  @override
  LocalTool? lookup(String name) => toolsByName[name];
}

/// Extract tool reference names from an Anthropic tool search tool result.
///
/// This is intentionally permissive:
/// - normalized stream payload: `[{ type: 'tool_reference', toolName: '...' }]`
/// - raw provider payload: `{ type: 'tool_search_tool_search_result', tool_references: [{ tool_name: '...' }] }`
List<String> extractToolReferenceNames(Object? result) {
  final names = <String>[];

  void addName(Object? v) {
    if (v is! String) return;
    final trimmed = v.trim();
    if (trimmed.isEmpty) return;
    names.add(trimmed);
  }

  if (result is List) {
    for (final item in result) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        addName(m['toolName'] ?? m['tool_name']);
      }
    }
    return names;
  }

  if (result is Map) {
    final m = Map<String, dynamic>.from(result);
    final refs = m['tool_references'];
    if (refs is List) {
      for (final item in refs) {
        if (item is Map) {
          final ref = Map<String, dynamic>.from(item);
          addName(ref['tool_name'] ?? ref['toolName']);
        }
      }
    }
  }

  return names;
}

bool toolListContainsToolName(List<Tool> tools, String name) {
  for (final t in tools) {
    if (t.function.name == name) return true;
  }
  return false;
}

void hydrateToolsFromCatalog({
  required ToolCatalog catalog,
  required List<Tool> workingTools,
  required Map<String, ToolCallHandler> workingHandlers,
  required Map<String, ToolApprovalCheck> workingApprovalChecks,
  required Iterable<String> toolNames,
}) {
  for (final name in toolNames) {
    if (name.trim().isEmpty) continue;

    final local = catalog.lookup(name);
    if (local == null) continue;

    if (!toolListContainsToolName(workingTools, name)) {
      workingTools.add(local.tool);
    }

    final handler = local.handler;
    if (handler != null) {
      workingHandlers[name] = handler;
    }

    final approval = local.needsApproval;
    if (approval != null && !workingApprovalChecks.containsKey(name)) {
      workingApprovalChecks[name] = approval;
    }
  }
}
