import 'package:llm_dart_core/llm_dart_core.dart';

extension ModelMessageTestExtensions on ModelMessage {
  /// Returns a best-effort text view of a prompt-first message for tests.
  ///
  /// This intentionally ignores empty cache marker parts and any non-text
  /// multimodal parts.
  String get content {
    final segments = <String>[];

    for (final part in parts) {
      if (part is TextContentPart) {
        final text = part.text.trimRight();
        if (text.isNotEmpty) segments.add(text);
      } else if (part is ReasoningContentPart) {
        final text = part.text.trimRight();
        if (text.isNotEmpty) segments.add(text);
      }
    }

    return segments.join('\n');
  }

  bool hasExtension(String key) => providerOptions.containsKey(key);

  T? getExtension<T>(String key) {
    final value = providerOptions[key];
    if (value == null) return null;
    if (value is T) return value;

    if (value is Map && T == Map<String, dynamic>) {
      return Map<String, dynamic>.from(value) as T;
    }

    return value as T;
  }
}
