import '../models/chat_models.dart';

/// Utility for aggregating incremental v3 tool call deltas from streaming APIs.
///
/// Many providers (including OpenAI) stream tool calls in multiple chunks:
/// - The first chunk usually contains id + function.name + initial arguments.
/// - Subsequent chunks often only include additional arguments.
///
/// This helper lets you merge those deltas into a single ToolCall per id.
class ToolCallAggregator {
  final Map<String, V3ToolCall> _calls = {};

  /// Add a v3 tool call delta and return the aggregated tool call for this id.
  ///
  /// The aggregator:
  /// - Preserves the first non-empty toolName.
  /// - Concatenates all input chunks in arrival order.
  V3ToolCall addDelta(V3ToolCall delta) {
    final existing = _calls[delta.toolCallId];
    if (existing == null) {
      _calls[delta.toolCallId] = delta;
      return delta;
    }

    final mergedName =
        delta.toolName.isNotEmpty ? delta.toolName : existing.toolName;

    final mergedArgsBuffer = StringBuffer()
      ..write(existing.input)
      ..write(delta.input);

    final mergedProviderOptions = <String, Map<String, dynamic>>{
      ...existing.providerOptions,
      ...delta.providerOptions.map(
        (providerId, options) => MapEntry(
          providerId,
          {
            ...?existing.providerOptions[providerId],
            ...options,
          },
        ),
      ),
    };

    final merged = V3ToolCall(
      toolCallId: existing.toolCallId,
      toolName: mergedName,
      input: mergedArgsBuffer.toString(),
      providerOptions: mergedProviderOptions,
    );

    _calls[delta.toolCallId] = merged;
    return merged;
  }

  /// Get all aggregated tool calls that have a non-empty toolName.
  ///
  /// This is often what you want when constructing a follow-up request with
  /// completed tool calls.
  List<V3ToolCall> get completedCalls =>
      _calls.values.where((c) => c.toolName.isNotEmpty).toList();

  /// Clear all internal state.
  void clear() {
    _calls.clear();
  }
}
