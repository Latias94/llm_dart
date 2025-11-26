import '../models/chat_models.dart';

/// Utility for aggregating incremental ToolCall deltas from streaming APIs.
///
/// Many providers (including OpenAI) stream tool calls in multiple chunks:
/// - The first chunk usually contains id + function.name + initial arguments.
/// - Subsequent chunks often only include additional arguments.
///
/// This helper lets you merge those deltas into a single ToolCall per id.
class ToolCallAggregator {
  final Map<String, ToolCall> _calls = {};

  /// Add a ToolCall delta and return the aggregated ToolCall for this id.
  ///
  /// The aggregator:
  /// - Preserves the first non-empty function.name.
  /// - Concatenates all function.arguments in arrival order.
  ToolCall addDelta(ToolCall delta) {
    final existing = _calls[delta.id];
    if (existing == null) {
      _calls[delta.id] = delta;
      return delta;
    }

    final mergedName = delta.function.name.isNotEmpty
        ? delta.function.name
        : existing.function.name;

    final mergedArgsBuffer = StringBuffer()
      ..write(existing.function.arguments)
      ..write(delta.function.arguments);

    final merged = ToolCall(
      id: existing.id,
      callType: existing.callType,
      function: FunctionCall(
        name: mergedName,
        arguments: mergedArgsBuffer.toString(),
      ),
    );

    _calls[delta.id] = merged;
    return merged;
  }

  /// Get all aggregated ToolCalls that have a non-empty function.name.
  ///
  /// This is often what you want when constructing a follow-up request with
  /// completed tool calls.
  List<ToolCall> get completedCalls =>
      _calls.values.where((c) => c.function.name.isNotEmpty).toList();

  /// Clear all internal state.
  void clear() {
    _calls.clear();
  }
}
