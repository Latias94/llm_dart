import 'package:llm_dart_core/llm_dart_core.dart';

/// Merge provider-native tools by stable id.
///
/// Semantics:
/// - Tools are keyed by `ProviderTool.id` (trimmed).
/// - [override] wins when ids collide.
/// - Empty/blank ids are ignored.
List<ProviderTool>? mergeProviderToolsById(
  List<ProviderTool>? base,
  List<ProviderTool>? override,
) {
  final a = base;
  final b = override;
  if ((a == null || a.isEmpty) && (b == null || b.isEmpty)) return null;

  final byId = <String, ProviderTool>{};
  if (a != null) {
    for (final t in a) {
      final id = t.id.trim();
      if (id.isEmpty) continue;
      byId[id] = t;
    }
  }
  if (b != null) {
    for (final t in b) {
      final id = t.id.trim();
      if (id.isEmpty) continue;
      byId[id] = t;
    }
  }

  return byId.isEmpty ? null : byId.values.toList(growable: false);
}
