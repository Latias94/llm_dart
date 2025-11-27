import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Helper for aggregating OpenAI-style streaming tool calls.
///
/// Many providers (OpenAI, OpenAI-compatible endpoints, DeepSeek, etc.)
/// stream `tool_calls` in multiple chunks:
/// - The first chunk usually contains `index` + `id` + `function.name`
///   and an initial `function.arguments` fragment.
/// - Subsequent chunks typically contain only `index` +
///   incremental `function.arguments` fragments.
///
/// This helper keeps a stable tool call id per index and merges
/// arguments fragments so that callers can emit consistent
/// [ToolCallDeltaEvent] instances and later reconstruct full tool
/// calls (for example via [adaptStreamText] and [StreamToolCall]).
class ToolCallStreamState {
  /// Map from streaming index to stable tool call id.
  final Map<int, String> _toolCallIds = {};

  /// Track whether we have seen at least one id for the given index.
  bool hasIdForIndex(int index) => _toolCallIds.containsKey(index);

  /// Clear all tracked ids. Call this when starting a new stream.
  void reset() {
    _toolCallIds.clear();
  }

  /// Process a single tool call delta map from a streaming chunk.
  ///
  /// [toolCallMap] is expected to follow the OpenAI `tool_calls` structure:
  /// `{ index, id?, type, function: { name?, arguments? } }`.
  ///
  /// When a stable id can be determined (from this or a previous chunk),
  /// this method returns a [ToolCall] carrying:
  /// - [ToolCall.id]: the stable id
  /// - [ToolCall.callType]: the call type (defaults to `function`)
  /// - [ToolCall.function.name]: the function name (may be empty)
  /// - [ToolCall.function.arguments]: the raw arguments fragment
  ///
  /// Callers can then emit a [ToolCallDeltaEvent] using the returned value.
  ToolCall? processDelta(Map<String, dynamic> toolCallMap) {
    final dynamic indexValue = toolCallMap['index'];

    if (indexValue is int) {
      final index = indexValue;

      final id = toolCallMap['id'] as String?;
      if (id != null && id.isNotEmpty) {
        _toolCallIds[index] = id;
      }

      final stableId = _toolCallIds[index];
      if (stableId == null) {
        return null;
      }

      final functionMap = toolCallMap['function'] as Map<String, dynamic>?;
      if (functionMap == null) {
        return null;
      }

      final name = functionMap['name'] as String? ?? '';
      final args = functionMap['arguments'] as String? ?? '';
      final type = toolCallMap['type'] as String? ?? 'function';

      // Skip completely empty deltas to avoid noise.
      if (name.isEmpty && args.isEmpty) {
        return null;
      }

      return ToolCall(
        id: stableId,
        callType: type,
        function: FunctionCall(
          name: name,
          arguments: args,
        ),
      );
    }

    // Fallback: handle tool calls that provide a full object without index.
    if (toolCallMap.containsKey('id') && toolCallMap.containsKey('function')) {
      try {
        return ToolCall.fromJson(
          toolCallMap.map((key, value) => MapEntry(
                key.toString(),
                value,
              )),
        );
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Best-effort JSON parse check used to decide when a streamed tool
  /// call has completed its arguments.
  ///
  /// This mirrors the logic used in the TypeScript implementation
  /// to determine when to emit a final `tool-call` event.
  bool isParsableJson(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    try {
      jsonDecode(trimmed);
      return true;
    } catch (_) {
      return false;
    }
  }
}
