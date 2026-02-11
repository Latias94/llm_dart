/// Small JSON helpers shared across providers.
library;

import 'dart:convert';

/// Returns true if [input] is valid JSON (after trimming).
///
/// This is used for detecting when a streamed tool call argument string has
/// become complete JSON (best-effort).
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
