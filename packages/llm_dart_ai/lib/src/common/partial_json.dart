import 'dart:convert';

import 'json_repair.dart';

export 'json_repair.dart' show fixJson;

enum PartialJsonParseState {
  undefinedInput,
  successfulParse,
  repairedParse,
  failedParse,
}

final class PartialJsonParseResult {
  final Object? value;
  final PartialJsonParseState state;

  const PartialJsonParseResult({
    required this.value,
    required this.state,
  });
}

PartialJsonParseResult parsePartialJson(String? jsonText) {
  if (jsonText == null) {
    return const PartialJsonParseResult(
      value: null,
      state: PartialJsonParseState.undefinedInput,
    );
  }

  final direct = _tryParseJson(jsonText);
  if (direct.success) {
    return PartialJsonParseResult(
      value: direct.value,
      state: PartialJsonParseState.successfulParse,
    );
  }

  final repaired = _tryParseJson(fixJson(jsonText));
  if (repaired.success) {
    return PartialJsonParseResult(
      value: repaired.value,
      state: PartialJsonParseState.repairedParse,
    );
  }

  return const PartialJsonParseResult(
    value: null,
    state: PartialJsonParseState.failedParse,
  );
}

_JsonParseAttempt _tryParseJson(String text) {
  try {
    return _JsonParseAttempt(
      success: true,
      value: jsonDecode(text),
    );
  } on FormatException {
    return const _JsonParseAttempt(
      success: false,
      value: null,
    );
  }
}

final class _JsonParseAttempt {
  final bool success;
  final Object? value;

  const _JsonParseAttempt({
    required this.success,
    required this.value,
  });
}
