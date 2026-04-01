import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';

typedef CompatBridgePredicate = bool Function(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
);

Future<ChatResponse> executeCompatChat({
  required LLMConfig originalConfig,
  required List<ChatMessage> messages,
  required List<Tool>? tools,
  required CompatBridgePredicate canUseBridge,
  required Future<ChatResponse> Function() bridge,
  required Future<ChatResponse> Function() fallback,
}) async {
  if (canUseBridge(originalConfig, messages, tools)) {
    try {
      return await bridge();
    } catch (error) {
      if (!isCompatibilityError(error)) {
        rethrow;
      }
    }
  }

  return fallback();
}

Stream<ChatStreamEvent> executeCompatChatStream({
  required LLMConfig originalConfig,
  required List<ChatMessage> messages,
  required List<Tool>? tools,
  required CompatBridgePredicate canUseBridge,
  required Stream<ChatStreamEvent> Function() bridge,
  required Stream<ChatStreamEvent> Function() fallback,
}) async* {
  if (canUseBridge(originalConfig, messages, tools)) {
    try {
      yield* bridge();
      return;
    } catch (error) {
      if (!isCompatibilityError(error)) {
        rethrow;
      }
    }
  }

  yield* fallback();
}

bool isCompatibilityError(Object error) {
  return error is UnsupportedError ||
      error is ArgumentError ||
      error is FormatException ||
      error is StateError;
}

String? compatStringValue(Object? value) {
  return switch (value) {
    null => null,
    String() => value,
    ReasoningEffort() => value.value,
    _ => value.toString(),
  };
}

Object? compatNormalizeJsonValue(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value.map(compatNormalizeJsonValue).toList(growable: false),
    Map() => value.map(
        (key, nestedValue) => MapEntry(
          key as String,
          compatNormalizeJsonValue(nestedValue),
        ),
      ),
    _ => value.toString(),
  };
}

DateTime? parseCompatUtcDate(String? value) {
  if (value == null) {
    return null;
  }

  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    return null;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);

  try {
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  } catch (_) {
    return null;
  }
}
