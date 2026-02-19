import 'dart:convert';

/// Mirrors Vercel AI SDK's `parsePartialJson(...)` states.
typedef ParsePartialJsonState
    = String; // 'undefined-input' | 'successful-parse' | 'repaired-parse' | 'failed-parse'

class ParsePartialJsonResult {
  final Object? value;
  final ParsePartialJsonState state;

  const ParsePartialJsonResult({
    required this.value,
    required this.state,
  });
}

/// Best-effort parse for partial JSON.
///
/// This is primarily useful for streaming tool input deltas.
ParsePartialJsonResult parsePartialJson(String? jsonText) {
  if (jsonText == null) {
    return const ParsePartialJsonResult(
      value: null,
      state: 'undefined-input',
    );
  }

  try {
    return ParsePartialJsonResult(
      value: jsonDecode(jsonText),
      state: 'successful-parse',
    );
  } catch (_) {
    // Continue with repair attempt.
  }

  final lastObjectEnd = jsonText.lastIndexOf('}');
  final lastArrayEnd = jsonText.lastIndexOf(']');
  final lastEnd = lastObjectEnd > lastArrayEnd ? lastObjectEnd : lastArrayEnd;

  if (lastEnd > 0) {
    final prefix = jsonText.substring(0, lastEnd + 1);
    try {
      return ParsePartialJsonResult(
        value: jsonDecode(prefix),
        state: 'repaired-parse',
      );
    } catch (_) {
      // Fall through.
    }
  }

  return const ParsePartialJsonResult(
    value: null,
    state: 'failed-parse',
  );
}
