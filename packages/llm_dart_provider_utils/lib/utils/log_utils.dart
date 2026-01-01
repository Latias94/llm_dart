import 'dart:convert';

/// Small helpers for making debug logs safer and more readable.
class LogUtils {
  static String truncate(String input, {int maxChars = 4096}) {
    if (input.length <= maxChars) return input;
    return '${input.substring(0, maxChars)}...[truncated]';
  }

  static String jsonEncodeTruncated(
    Object? value, {
    int maxChars = 4096,
  }) {
    try {
      return truncate(jsonEncode(value), maxChars: maxChars);
    } catch (_) {
      return truncate(value.toString(), maxChars: maxChars);
    }
  }
}
